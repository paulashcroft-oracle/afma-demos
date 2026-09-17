-- Run as AFMA (SQLcl or APEX SQL Scripts) after the candidate package is compiled.
-- Read-only acceptance: the deliberately absent service prevents provider requests.
set define off
set serveroutput on

declare
  l_json clob;
  l_value varchar2(4000);
  l_total number;
  l_count number := 0;
  l_code varchar2(20);
  l_context clob;
  l_html clob;
  l_response json_object_t;
  l_elapsed number;
  l_stages number;
  procedure assert_true(p_ok boolean, p_label varchar2) is
  begin
    if p_ok is null or not p_ok then
      raise_application_error(-20190, 'FAIL: ' || p_label);
    end if;
    l_count := l_count + 1;
  end;
  procedure ask(p_question varchar2) is
  begin
    l_json := csiro_caab_agent_api.ask_json(p_question, 'caab_unavailable_service_acceptance');
    select json_value(l_json, '$.success') into l_value from dual;
    assert_true(l_value = 'true', 'Valid JSON response for ' || substr(p_question, 1, 70));
    select json_value(l_json, '$.aiAttempted') into l_value from dual;
    assert_true(l_value = 'false', 'No model request');
    l_response := json_object_t.parse(l_json);
    l_html := l_response.get_clob('answerHtml');
    select json_value(l_json, '$.timingsMs.total' returning number),
           json_value(l_json, '$.timingsMs.retrieval' returning number) +
           json_value(l_json, '$.timingsMs.resolution' returning number) +
           json_value(l_json, '$.timingsMs.model' returning number) +
           json_value(l_json, '$.timingsMs.render' returning number)
      into l_elapsed, l_stages from dual;
    assert_true(l_elapsed >= l_stages and l_stages >= 0, 'Stage timings are consistent');
    dbms_output.put_line('PASS ' || substr(p_question, 1, 75) || ': ' || l_elapsed || ' ms');
  end;
begin
  ask('37354001');
  assert_true(dbms_lob.instr(l_json, 'Argyrosomus japonicus') > 0, 'Mulloway exact code');
  select json_value(l_json, '$.route') into l_value from dual;
  assert_true(l_value = 'EXACT_CODE', 'Exact code route');

  select to_char(n, 'FM00000000') into l_code
    from (select 99999999 - level + 1 n from dual connect by level <= 100)
   where not exists (select 1 from csiro_caab_taxa t where t.spcode = to_char(n, 'FM00000000'))
   fetch first 1 row only;
  ask(l_code);
  assert_true(dbms_lob.instr(l_json, 'No catalogue record') > 0, 'Absent code is explicit');

  ask('37354001 rank SPLURGE');
  assert_true(dbms_lob.instr(l_html, 'and the supplied filters') > 0, 'Existing code excluded by filter is not reported absent');

  ask('Argyrosomus japonicus');
  select json_value(l_json, '$.route') into l_value from dual;
  assert_true(l_value = 'EXACT_NAME', 'Scientific name route');

  ask('37311515');
  assert_true(dbms_lob.instr(l_json, '37311151') > 0, 'Superseded code is preserved');
  assert_true(dbms_lob.instr(l_json, 'non-current flag: Y') > 0, 'Non-current flag is visible');

  ask('jewie');
  assert_true(dbms_lob.instr(l_json, '37354001') > 0, 'Exact local alias identifies Mulloway');
  assert_true(dbms_lob.instr(l_html, 'Demo-curated / synthetic') > 0, 'Synthetic provenance is visible');

  ask('flake');
  select json_value(l_json, '$.matchingTaxaTotal' returning number) into l_total from dual;
  assert_true(l_total > 1, 'Ambiguous alias retains multiple taxa');
  assert_true(dbms_lob.instr(lower(l_html), 'ambiguous') > 0, 'Ambiguous alias is explained');
  assert_true(dbms_lob.instr(lower(l_html), 'species verification') > 0, 'Alias caveat is retained');

  for r in (select column_value habitat from table(apex_t_varchar2('M', 'C,SH', 'M,E'))) loop
    ask('habitat code ' || r.habitat);
    select count(*) into l_total from csiro_caab_taxa where upper(trim(habitat_code)) = r.habitat;
    select json_value(l_json, '$.matchingTaxaTotal' returning number) into l_elapsed from dual;
    assert_true(l_total = l_elapsed, 'Raw habitat-code equality for ' || r.habitat);
  end loop;

  ask('rank species');
  select count(*) into l_total from csiro_caab_taxa where upper(trim(taxon_rank)) = 'SPECIES';
  select json_value(l_json, '$.matchingTaxaTotal' returning number) into l_elapsed from dual;
  assert_true(l_total = l_elapsed, 'Species rank uses its actual column');

  ask('order Perciformes');
  select count(*) into l_total from csiro_caab_taxa where upper(trim(order_name)) = 'PERCIFORMES';
  select json_value(l_json, '$.matchingTaxaTotal' returning number) into l_elapsed from dual;
  assert_true(l_total = l_elapsed and l_total > 0, 'Order uses its actual column');

  ask('rank SPECIES order Perciformes habitat code M');
  select count(*) into l_total from csiro_caab_taxa
   where upper(trim(taxon_rank)) = 'SPECIES' and upper(trim(order_name)) = 'PERCIFORMES'
     and upper(trim(habitat_code)) = 'M';
  select json_value(l_json, '$.matchingTaxaTotal' returning number) into l_elapsed from dual;
  assert_true(l_total = l_elapsed and l_total > 0, 'Typed filters intersect');

  for r in (select column_value question from table(apex_t_varchar2(
    'habitat code M, E', 'habitat code M habitat code M',
    'not habitat code M', 'habitat code M or F', 'habitat code'))) loop
    ask(r.question);
    select json_value(l_json, '$.route') into l_value from dual;
    assert_true(l_value = 'CLARIFICATION', 'Unsupported raw-filter syntax clarifies');
  end loop;

  ask('rank SPLURGE');
  select json_value(l_json, '$.matchingTaxaTotal' returning number) into l_elapsed from dual;
  assert_true(l_elapsed = 0, 'Unknown rank does not drop its filter');

  ask('CAAB catalogue counts');
  select json_value(l_json, '$.route') into l_value from dual;
  assert_true(l_value = 'CATALOGUE_COUNTS', 'Catalogue counts route');
  select count(*) into l_total from csiro_caab_taxa;
  assert_true(dbms_lob.instr(l_json, to_char(l_total, 'FM999G999G999')) > 0, 'Catalogue count agrees with SQL');

  ask('show a chart of the largest taxonomic classes');
  select json_value(l_json, '$.route') into l_value from dual;
  assert_true(l_value = 'CLASS_SUMMARY', 'Chart uses grouped SQL');
  assert_true(dbms_lob.instr(l_json, 'afma-caab-bars') > 0, 'Class chart is rendered');

  ask('How many tuna occur in NSW?');
  select json_value(l_json, '$.route') into l_value from dual;
  assert_true(l_value <> 'CATALOGUE_COUNTS', 'Qualified count does not become a global count');
  assert_true(dbms_lob.instr(l_json, 'jewfish') = 0, 'Unrelated NSW alias excluded');

  ask('Please could you tell me what you can find in the catalogue about Argyrosomus japonicus');
  assert_true(dbms_lob.instr(l_json, '37354001') > 0, 'Polite prefix does not consume useful tokens');

  ask('current and non-current sharks');
  select json_value(l_json, '$.route') into l_value from dual;
  assert_true(l_value = 'CLARIFICATION', 'Mixed status asks for clarification');

  l_context := csiro_caab_agent_api.build_ai_context('sharks');
  assert_true(dbms_lob.getlength(l_context) <= 24000, 'Context stays within character budget');
  assert_true(dbms_lob.instr(l_context, 'matchingTaxaTotal') > 0, 'Context distinguishes total from sample');
  assert_true(dbms_lob.instr(l_context, 'nonCurrentFlag') > 0, 'Context retains status provenance');

  ask('What is the most populous species?');
  select json_value(l_json, '$.route') into l_value from dual;
  assert_true(l_value = 'ABUNDANCE_LIMITATION', 'Abundance limitation is deterministic');

  ask('Which of those are current?');
  select json_value(l_json, '$.route') into l_value from dual;
  assert_true(l_value = 'CLARIFICATION', 'Independent follow-up requests clarification');

  ask('Explain sharks and their taxonomy');
  select json_value(l_json, '$.mode') into l_value from dual;
  assert_true(l_value = 'DETERMINISTIC_FALLBACK', 'Unknown model produces honest fallback');
  assert_true(dbms_lob.instr(l_json, 'ORA-') = 0, 'No raw Oracle exception in JSON');

  l_json := csiro_caab_agent_api.ask_json(to_clob(rpad('x', 3001, 'x')), 'caab_unavailable_service_acceptance');
  select json_value(l_json, '$.success') into l_value from dual;
  assert_true(l_value = 'false', 'Overlength question rejected');
  dbms_output.put_line('READ-ONLY ACCEPTANCE PASSED: ' || l_count || ' checks; zero model requests.');
end;
/
