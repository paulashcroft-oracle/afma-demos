set define off

prompt AFMA 030 - Create CSIRO CAAB Agent API

create or replace package csiro_caab_agent_api as
  function dataset_summary_markdown return clob;

  function deterministic_answer_html(
    p_user_prompt in clob
  ) return clob;

  function build_ai_context(
    p_user_prompt in clob
  ) return clob;

  function ask_json(
    p_user_prompt        in clob,
    p_service_static_id  in varchar2 default null
  ) return clob;
end csiro_caab_agent_api;
/

create or replace package body csiro_caab_agent_api as
  procedure append_text(
    p_clob in out nocopy clob,
    p_text in varchar2
  ) is
  begin
    if p_text is not null then
      dbms_lob.writeappend(p_clob, length(p_text), p_text);
    end if;
  end append_text;

  procedure append_line(
    p_clob in out nocopy clob,
    p_text in varchar2 default null
  ) is
  begin
    append_text(p_clob, p_text || chr(10));
  end append_line;

  function html_escape(
    p_value in varchar2
  ) return varchar2 is
  begin
    return apex_escape.html(p_value);
  end html_escape;

  function clob_excerpt(
    p_value     in clob,
    p_max_chars in pls_integer default 1000
  ) return varchar2 is
  begin
    if p_value is null then
      return null;
    end if;

    return dbms_lob.substr(p_value, least(p_max_chars, 3000), 1);
  end clob_excerpt;

  function config_value(
    p_key in varchar2
  ) return varchar2 is
    l_value csiro_caab_config.config_value%type;
  begin
    select config_value
      into l_value
      from csiro_caab_config
     where config_key = upper(p_key);

    return nullif(trim(l_value), '');
  exception
    when no_data_found then
      return null;
  end config_value;

  function compact_prompt(
    p_user_prompt in clob
  ) return varchar2 is
  begin
    if p_user_prompt is null then
      return null;
    end if;

    return trim(dbms_lob.substr(p_user_prompt, 500, 1));
  end compact_prompt;

  function app_agent_exists(
    p_agent_static_id in varchar2
  ) return boolean is
    l_count number;
    l_app_id number := to_number(coalesce(v('APP_ID'), '0'));
  begin
    if l_app_id = 0 or p_agent_static_id is null then
      return false;
    end if;

    execute immediate q'[
      select count(*)
        from apex_appl_ai_agents
       where application_id = :app_id
         and upper(agent_static_id) = upper(:agent_static_id)
    ]'
      into l_count
      using l_app_id, p_agent_static_id;

    return l_count > 0;
  exception
    when others then
      return false;
  end app_agent_exists;

  function valid_service_static_id(
    p_service_static_id in varchar2
  ) return varchar2 is
    l_static_id varchar2(255);
  begin
    if p_service_static_id is null then
      return null;
    end if;

    select remote_server_static_id
      into l_static_id
      from apex_workspace_ai_services
     where upper(remote_server_static_id) = upper(trim(p_service_static_id))
       and provider_type_code = 'OCI_GENAI'
       fetch first 1 row only;

    return l_static_id;
  exception
    when no_data_found then
      return null;
    when others then
      return null;
  end valid_service_static_id;

  function service_name_for_static_id(
    p_service_static_id in varchar2
  ) return varchar2 is
    l_name varchar2(255);
  begin
    if p_service_static_id is null then
      return null;
    end if;

    select remote_server_name
      into l_name
      from apex_workspace_ai_services
     where upper(remote_server_static_id) = upper(trim(p_service_static_id))
       fetch first 1 row only;

    return l_name;
  exception
    when others then
      return null;
  end service_name_for_static_id;

  function dataset_summary_markdown return clob is
    l_result clob;
    l_total number;
    l_active number;
    l_non_current number;
    l_species number;
    l_genera number;
    l_families number;
    l_common_names number;
    l_regions number;
    l_last_load varchar2(100);
  begin
    dbms_lob.createtemporary(l_result, true);

    select count(*),
           count(case when coalesce(non_current_flag, 'N') not in ('Y', 'T') and coalesce(list_status_code, 'A') = 'A' then 1 end),
           count(case when coalesce(non_current_flag, 'N') in ('Y', 'T') then 1 end),
           count(case when upper(taxon_rank) = 'SPECIES' then 1 end),
           count(case when upper(taxon_rank) = 'GENUS' then 1 end),
           count(case when upper(taxon_rank) = 'FAMILY' then 1 end)
      into l_total,
           l_active,
           l_non_current,
           l_species,
           l_genera,
           l_families
      from csiro_caab_taxa;

    select count(*),
           count(distinct region_code)
      into l_common_names,
           l_regions
      from csiro_caab_common_names;

    select max(to_char(loaded_at, 'YYYY-MM-DD HH24:MI TZH:TZM'))
      into l_last_load
      from csiro_caab_loads
     where load_status = 'LOADED';

    append_line(l_result, '# CSIRO CAAB Dataset Snapshot');
    append_line(l_result, '- Total records: ' || to_char(l_total, 'FM999G999G999'));
    append_line(l_result, '- Active/current records: ' || to_char(l_active, 'FM999G999G999'));
    append_line(l_result, '- Non-current records: ' || to_char(l_non_current, 'FM999G999G999'));
    append_line(l_result, '- Species rows: ' || to_char(l_species, 'FM999G999G999'));
    append_line(l_result, '- Genus rows: ' || to_char(l_genera, 'FM999G999G999'));
    append_line(l_result, '- Family rows: ' || to_char(l_families, 'FM999G999G999'));
    append_line(l_result, '- Common-name and alias rows: ' || to_char(l_common_names, 'FM999G999G999'));
    append_line(l_result, '- Common-name regions: ' || to_char(l_regions, 'FM999G999G999'));
    append_line(l_result, '- Last AFMA load: ' || coalesce(l_last_load, 'not loaded yet'));
    append_line(l_result);

    append_line(l_result, '## Largest Classes');
    for r in (
      select coalesce(class_name, '(not supplied)') label,
             count(*) value
        from csiro_caab_taxa
       group by coalesce(class_name, '(not supplied)')
       order by count(*) desc
       fetch first 10 rows only
    ) loop
      append_line(l_result, '- ' || r.label || ': ' || to_char(r.value, 'FM999G999G999'));
    end loop;

    return l_result;
  end dataset_summary_markdown;

  procedure append_match_table(
    p_html        in out nocopy clob,
    p_user_prompt in clob,
    p_limit       in pls_integer default 20
  ) is
    l_query varchar2(500) := compact_prompt(p_user_prompt);
    l_count number := 0;
  begin
    append_line(p_html, '<div class="afma-caab-section">');
    append_line(p_html, '<h3>Matching CAAB Records</h3>');
    append_line(p_html, '<div class="afma-caab-table-wrap"><table class="afma-caab-table">');
    append_line(p_html, '<thead><tr><th>SPCODE</th><th>Name</th><th>Common Name</th><th>Family</th><th>Class</th><th>Status</th></tr></thead><tbody>');

    for r in (
      with raw_tokens as (
        select lower(regexp_substr(l_query, '[[:alnum:]_''-]{3,}', 1, level)) token
          from dual
       connect by level <= least(12, regexp_count(l_query, '[[:alnum:]_''-]{3,}'))
      ),
      tokens as (
        select token
          from raw_tokens
         where token not in (
           'about','after','all','and','any','are','around','ask','caab','code','codes',
           'data','demo','find','for','from','give','including','include','info','into',
           'list','me','name','names','please','show','species','tell','that','the',
           'this','used','using','want','what','when','where','which','with'
         )
      )
      select spcode,
             scientific_name,
             common_name,
             family,
             class_name,
             list_status_code,
             non_current_flag
        from csiro_caab_taxa t
       where l_query is null
          or not exists (select 1 from tokens where token is not null)
          or exists (
               select 1
                 from tokens
                where token is not null
                  and (
                    instr(
                      lower(
                        coalesce(t.scientific_name, '') || ' ' ||
                        coalesce(t.display_name, '') || ' ' ||
                        coalesce(t.common_name, '') || ' ' ||
                        coalesce(t.common_names_list, '') || ' ' ||
                        coalesce(t.family, '') || ' ' ||
                        coalesce(t.genus, '') || ' ' ||
                        coalesce(t.species, '') || ' ' ||
                        coalesce(t.kingdom, '') || ' ' ||
                        coalesce(t.phylum, '') || ' ' ||
                        coalesce(t.class_name, '')
                      ),
                      token
                    ) > 0
                    or exists (
                      select 1
                        from csiro_caab_common_names cn
                       where cn.spcode = t.spcode
                         and instr(lower(cn.common_name), token) > 0
                    )
                  )
             )
       order by case
                  when exists (
                    select 1
                      from tokens
                     where token is not null
                       and (
                         instr(lower(coalesce(t.common_name, '')), token) > 0
                         or exists (
                           select 1
                             from csiro_caab_common_names cn
                            where cn.spcode = t.spcode
                              and instr(lower(cn.common_name), token) > 0
                         )
                       )
                  ) then 0
                  else 1
                end,
                case when coalesce(non_current_flag, 'N') in ('Y', 'T') then 1 else 0 end,
                case when upper(taxon_rank) = 'SPECIES' then 0 else 1 end,
                scientific_name nulls last
       fetch first p_limit rows only
    ) loop
      l_count := l_count + 1;
      append_line(
        p_html,
        '<tr><td><code>' || html_escape(r.spcode) || '</code></td>' ||
        '<td><strong>' || html_escape(r.scientific_name) || '</strong></td>' ||
        '<td>' || html_escape(r.common_name) || '</td>' ||
        '<td>' || html_escape(r.family) || '</td>' ||
        '<td>' || html_escape(r.class_name) || '</td>' ||
        '<td><span class="afma-caab-chip">' ||
        html_escape(coalesce(r.list_status_code, '')) ||
        case when r.non_current_flag is not null then ' / ' || html_escape(r.non_current_flag) end ||
        '</span></td></tr>'
      );
    end loop;

    if l_count = 0 then
      append_line(p_html, '<tr><td colspan="6">No matching CAAB records were found for this prompt.</td></tr>');
    end if;

    append_line(p_html, '</tbody></table></div></div>');
  end append_match_table;

  procedure append_common_names_table(
    p_html        in out nocopy clob,
    p_user_prompt in clob,
    p_limit       in pls_integer default 20
  ) is
    l_query varchar2(500) := compact_prompt(p_user_prompt);
    l_count number := 0;
  begin
    append_line(p_html, '<div class="afma-caab-section">');
    append_line(p_html, '<h3>Australian Common Names And Aliases</h3>');
    append_line(p_html, '<div class="afma-caab-table-wrap"><table class="afma-caab-table">');
    append_line(p_html, '<thead><tr><th>Name</th><th>Species</th><th>Kind</th><th>Region</th><th>Years</th><th>Source</th></tr></thead><tbody>');

    for r in (
      with raw_tokens as (
        select lower(regexp_substr(l_query, '[[:alnum:]_''-]{3,}', 1, level)) token
          from dual
       connect by level <= least(12, regexp_count(l_query, '[[:alnum:]_''-]{3,}'))
      ),
      tokens as (
        select token
          from raw_tokens
         where token not in (
           'about','after','all','and','any','are','around','ask','caab','code','codes',
           'data','demo','find','for','from','give','including','include','info','into',
           'list','me','name','names','please','show','species','tell','that','the',
           'this','used','using','want','what','when','where','which','with'
         )
      )
      select common_name,
             scientific_name,
             name_kind,
             coalesce(region_name, jurisdiction, 'Australia') region_label,
             first_observed_year,
             last_observed_year,
             source_name,
             source_confidence,
             synthetic_flag
        from csiro_caab_common_name_search_v cn
       where l_query is null
          or exists (
               select 1
                 from tokens
                where token is not null
                  and instr(
                        lower(
                          coalesce(cn.common_name, '') || ' ' ||
                          coalesce(cn.scientific_name, '') || ' ' ||
                          coalesce(cn.caab_common_name, '') || ' ' ||
                          coalesce(cn.family, '') || ' ' ||
                          coalesce(cn.region_name, '') || ' ' ||
                          coalesce(cn.jurisdiction, '') || ' ' ||
                          coalesce(cn.locality, '')
                        ),
                        token
                      ) > 0
             )
       order by case
                  when cn.name_kind in ('LOCAL_ALIAS', 'MARKET_ALIAS', 'LEGACY_ALIAS')
                   and exists (
                     select 1
                       from tokens
                      where token is not null
                        and (
                          instr(lower(coalesce(cn.region_name, '')), token) > 0
                          or instr(lower(coalesce(cn.jurisdiction, '')), token) > 0
                        )
                   ) then 0
                  else 1
                end,
                case
                  when exists (
                    select 1
                      from tokens
                     where token is not null
                       and instr(lower(coalesce(cn.common_name, '')), token) > 0
                  ) then 0
                  else 1
                end,
                case
                  when exists (
                    select 1
                      from tokens
                     where token is not null
                       and (
                         instr(lower(coalesce(cn.region_name, '')), token) > 0
                         or instr(lower(coalesce(cn.jurisdiction, '')), token) > 0
                       )
                  ) then 0
                  else 1
                end,
                case name_kind
                  when 'LOCAL_ALIAS' then 1
                  when 'MARKET_ALIAS' then 2
                  when 'STANDARD' then 3
                  when 'CSIRO_PRIMARY' then 4
                  when 'CSIRO_ALT' then 5
                  else 6
                end,
                scientific_name,
                common_name
       fetch first p_limit rows only
    ) loop
      l_count := l_count + 1;
      append_line(
        p_html,
        '<tr><td><strong>' || html_escape(r.common_name) || '</strong></td><td>' || html_escape(r.scientific_name) || '</td>' ||
        '<td>' || html_escape(replace(initcap(r.name_kind), '_', ' ')) || '</td>' ||
        '<td>' || html_escape(r.region_label) || '</td>' ||
        '<td>' || html_escape(
          case
            when r.first_observed_year is null and r.last_observed_year is null then null
            else coalesce(to_char(r.first_observed_year), '?') || '-' || coalesce(to_char(r.last_observed_year), '?')
          end
        ) || '</td>' ||
        '<td>' || html_escape(r.source_name) || ' <span class="afma-caab-chip">' || html_escape(r.source_confidence) || '</span></td></tr>'
      );
    end loop;

    if l_count = 0 then
      append_line(p_html, '<tr><td colspan="6">No common-name aliases matched this prompt.</td></tr>');
    end if;

    append_line(p_html, '</tbody></table></div></div>');
  end append_common_names_table;

  procedure append_class_chart(
    p_html in out nocopy clob
  ) is
    l_max number := 1;
  begin
    select greatest(max(record_count), 1)
      into l_max
      from (
        select count(*) record_count
          from csiro_caab_taxa
         group by coalesce(class_name, '(not supplied)')
      );

    append_line(p_html, '<div class="afma-caab-section">');
    append_line(p_html, '<h3>Largest Taxonomic Classes</h3>');
    append_line(p_html, '<div class="afma-caab-bars">');

    for r in (
      select coalesce(class_name, '(not supplied)') label,
             count(*) value
        from csiro_caab_taxa
       group by coalesce(class_name, '(not supplied)')
       order by count(*) desc
       fetch first 8 rows only
    ) loop
      append_line(
        p_html,
        '<div class="afma-caab-bar-row"><span>' || html_escape(r.label) || '</span>' ||
        '<div class="afma-caab-bar-track"><div class="afma-caab-bar-fill" style="width:' ||
        replace(to_char(round((r.value / l_max) * 100, 1), 'FM990D0'), ',', '.') ||
        '%"></div></div><strong>' || to_char(r.value, 'FM999G999G999') || '</strong></div>'
      );
    end loop;

    append_line(p_html, '</div></div>');
  end append_class_chart;

  function deterministic_answer_html(
    p_user_prompt in clob
  ) return clob is
    l_html clob;
    l_total number;
    l_active number;
    l_species number;
    l_prompt varchar2(500) := compact_prompt(p_user_prompt);
  begin
    dbms_lob.createtemporary(l_html, true);

    select count(*),
           count(case when coalesce(non_current_flag, 'N') not in ('Y', 'T') and coalesce(list_status_code, 'A') = 'A' then 1 end),
           count(case when upper(taxon_rank) = 'SPECIES' then 1 end)
      into l_total,
           l_active,
           l_species
      from csiro_caab_taxa;

    append_line(l_html, '<div class="afma-caab-answer">');
    append_line(l_html, '<div class="afma-caab-answer-head">');
    append_line(l_html, '<span class="afma-caab-mode">Deterministic CAAB Explorer</span>');
    append_line(l_html, '<h2>' || case when l_prompt is not null then 'Results for "' || html_escape(l_prompt) || '"' else 'CAAB Dataset Overview' end || '</h2>');
    append_line(l_html, '<p>This answer is grounded directly in the CSIRO CAAB tables. If the selected AI model is unavailable, the demo still returns a reliable data-backed response.</p>');
    append_line(l_html, '</div>');
    append_line(l_html, '<div class="afma-caab-stats">');
    append_line(l_html, '<div><span>Total records</span><strong>' || to_char(l_total, 'FM999G999G999') || '</strong></div>');
    append_line(l_html, '<div><span>Active records</span><strong>' || to_char(l_active, 'FM999G999G999') || '</strong></div>');
    append_line(l_html, '<div><span>Species rows</span><strong>' || to_char(l_species, 'FM999G999G999') || '</strong></div>');
    append_line(l_html, '</div>');

    append_match_table(l_html, p_user_prompt, 24);
    append_common_names_table(l_html, p_user_prompt, 24);
    append_class_chart(l_html);

    append_line(l_html, '</div>');
    return l_html;
  end deterministic_answer_html;

  function build_ai_context(
    p_user_prompt in clob
  ) return clob is
    l_context clob;
    l_query varchar2(500) := compact_prompt(p_user_prompt);
  begin
    dbms_lob.createtemporary(l_context, true);

    append_line(l_context, 'You are the CSIRO CAAB Agent for an AFMA APEX demo running on Oracle Autonomous Database 26ai.');
    append_line(l_context, 'Answer questions about the CSIRO Codes for Australian Aquatic Biota dataset loaded into table CSIRO_CAAB_TAXA.');
    append_line(l_context, 'Use only the supplied dataset context as evidence. If the context is insufficient, say what query/filter would be needed.');
    append_line(l_context, 'Return concise Markdown. You may include simple Markdown tables, bullet lists, and Mermaid-safe chart suggestions.');
    append_line(l_context, 'Do not invent species records, counts, images, URLs, load dates, or AFMA production claims.');
    append_line(l_context);
    append_line(l_context, dataset_summary_markdown);
    append_line(l_context);
    append_line(l_context, '## Matching Rows For User Prompt');

    for r in (
      with raw_tokens as (
        select lower(regexp_substr(l_query, '[[:alnum:]_''-]{3,}', 1, level)) token
          from dual
       connect by level <= least(12, regexp_count(l_query, '[[:alnum:]_''-]{3,}'))
      ),
      tokens as (
        select token
          from raw_tokens
         where token not in (
           'about','after','all','and','any','are','around','ask','caab','code','codes',
           'data','demo','find','for','from','give','including','include','info','into',
           'list','me','name','names','please','show','species','tell','that','the',
           'this','used','using','want','what','when','where','which','with'
         )
      )
      select spcode,
             scientific_name,
             authority,
             common_name,
             family,
             kingdom,
             phylum,
             class_name,
             order_name,
             genus,
             species,
             habitat_code,
             list_status_code,
             non_current_flag,
             superseded_by,
             recent_synonyms,
             taxon_www_notes
        from csiro_caab_taxa t
       where exists (
               select 1
                 from tokens
                where token is not null
                  and (
                    instr(
                      lower(
                        coalesce(t.scientific_name, '') || ' ' ||
                        coalesce(t.display_name, '') || ' ' ||
                        coalesce(t.common_name, '') || ' ' ||
                        coalesce(t.common_names_list, '') || ' ' ||
                        coalesce(t.family, '') || ' ' ||
                        coalesce(t.genus, '') || ' ' ||
                        coalesce(t.species, '') || ' ' ||
                        coalesce(t.kingdom, '') || ' ' ||
                        coalesce(t.phylum, '') || ' ' ||
                        coalesce(t.class_name, '')
                      ),
                      token
                    ) > 0
                    or exists (
                      select 1
                        from csiro_caab_common_names cn
                       where cn.spcode = t.spcode
                         and instr(lower(cn.common_name), token) > 0
                    )
                  )
             )
       order by case
                  when exists (
                    select 1
                      from tokens
                     where token is not null
                       and (
                         instr(lower(coalesce(t.common_name, '')), token) > 0
                         or exists (
                           select 1
                             from csiro_caab_common_names cn
                            where cn.spcode = t.spcode
                              and instr(lower(cn.common_name), token) > 0
                         )
                       )
                  ) then 0
                  else 1
                end,
                case when coalesce(non_current_flag, 'N') in ('Y', 'T') then 1 else 0 end,
                case when upper(taxon_rank) = 'SPECIES' then 0 else 1 end,
                scientific_name nulls last
       fetch first 30 rows only
    ) loop
      append_line(l_context, '- SPCODE ' || r.spcode || ': ' || r.scientific_name || ' | common: ' || r.common_name || ' | family: ' || r.family || ' | class: ' || r.class_name || ' | habitat: ' || r.habitat_code || ' | status: ' || r.list_status_code || '/' || r.non_current_flag);
      if r.recent_synonyms is not null then
        append_line(l_context, '  Recent synonyms: ' || clob_excerpt(r.recent_synonyms, 500));
      end if;
      if r.taxon_www_notes is not null then
        append_line(l_context, '  Notes: ' || clob_excerpt(r.taxon_www_notes, 500));
      end if;
    end loop;

    append_line(l_context);
    append_line(l_context, '## Matching Common Names And Regional Aliases');

    for r in (
      with raw_tokens as (
        select lower(regexp_substr(l_query, '[[:alnum:]_''-]{3,}', 1, level)) token
          from dual
       connect by level <= least(12, regexp_count(l_query, '[[:alnum:]_''-]{3,}'))
      ),
      tokens as (
        select token
          from raw_tokens
         where token not in (
           'about','after','all','and','any','are','around','ask','caab','code','codes',
           'data','demo','find','for','from','give','including','include','info','into',
           'list','me','name','names','please','show','species','tell','that','the',
           'this','used','using','want','what','when','where','which','with'
         )
      )
      select common_name,
             scientific_name,
             name_kind,
             region_name,
             jurisdiction,
             locality,
             first_observed_year,
             last_observed_year,
             source_name,
             source_confidence,
             synthetic_flag,
             notes
        from csiro_caab_common_name_search_v cn
       where exists (
               select 1
                 from tokens
                where token is not null
                  and instr(
                        lower(
                          coalesce(cn.common_name, '') || ' ' ||
                          coalesce(cn.scientific_name, '') || ' ' ||
                          coalesce(cn.caab_common_name, '') || ' ' ||
                          coalesce(cn.family, '') || ' ' ||
                          coalesce(cn.region_name, '') || ' ' ||
                          coalesce(cn.jurisdiction, '') || ' ' ||
                          coalesce(cn.locality, '')
                        ),
                        token
                      ) > 0
             )
       order by case
                  when cn.name_kind in ('LOCAL_ALIAS', 'MARKET_ALIAS', 'LEGACY_ALIAS')
                   and exists (
                     select 1
                       from tokens
                      where token is not null
                        and (
                          instr(lower(coalesce(cn.region_name, '')), token) > 0
                          or instr(lower(coalesce(cn.jurisdiction, '')), token) > 0
                        )
                   ) then 0
                  else 1
                end,
                case
                  when exists (
                    select 1
                      from tokens
                     where token is not null
                       and instr(lower(coalesce(cn.common_name, '')), token) > 0
                  ) then 0
                  else 1
                end,
                case
                  when exists (
                    select 1
                      from tokens
                     where token is not null
                       and (
                         instr(lower(coalesce(cn.region_name, '')), token) > 0
                         or instr(lower(coalesce(cn.jurisdiction, '')), token) > 0
                       )
                  ) then 0
                  else 1
                end,
                scientific_name, common_name
       fetch first 30 rows only
    ) loop
      append_line(
        l_context,
        '- ' || r.common_name || ' => ' || r.scientific_name ||
        ' | kind: ' || r.name_kind ||
        ' | region: ' || coalesce(r.region_name, r.jurisdiction, 'Australia') ||
        ' | years: ' || coalesce(to_char(r.first_observed_year), '?') || '-' || coalesce(to_char(r.last_observed_year), '?') ||
        ' | source: ' || r.source_name || ' (' || r.source_confidence || ')' ||
        case when r.synthetic_flag = 'Y' then ' | demo-curated' end
      );
      if r.notes is not null then
        append_line(l_context, '  Notes: ' || r.notes);
      end if;
    end loop;

    append_line(l_context);
    append_line(l_context, '## User Prompt');
    append_line(l_context, clob_excerpt(p_user_prompt, 3000));

    return l_context;
  end build_ai_context;

  function try_ai_markdown(
    p_user_prompt in clob,
    p_service_static_id in varchar2,
    p_error       out varchar2
  ) return clob is
    l_agent_static_id varchar2(255) := coalesce(config_value('AI_AGENT_STATIC_ID'), 'AFMA_CAAB_AGENT');
    l_service_static_id varchar2(255);
    l_prompt clob;
    l_response clob;
  begin
    p_error := null;
    l_prompt := build_ai_context(p_user_prompt);
    l_service_static_id := coalesce(
      valid_service_static_id(p_service_static_id),
      valid_service_static_id(config_value('AI_SERVICE_STATIC_ID'))
    );

    if l_service_static_id is not null then
      execute immediate q'[
        begin
          :result := apex_ai.chat(
            p_prompt => :prompt,
            p_service_static_id => :service_static_id,
            p_temperature => 0.2
          );
        end;
      ]'
        using out l_response, in l_prompt, in l_service_static_id;
      return l_response;
    end if;

    if app_agent_exists(l_agent_static_id) then
      execute immediate q'[
        begin
          :result := apex_ai.chat(
            p_agent_static_id => :agent_static_id,
            p_prompt => :prompt
          );
        end;
      ]'
        using out l_response, in l_agent_static_id, in l_prompt;
      return l_response;
    end if;

    p_error := 'No valid AFMA APEX Generative AI Service or AI Agent is configured for this request.';
    return null;
  exception
    when others then
      p_error := substr(sqlerrm, 1, 1000);
      return null;
  end try_ai_markdown;

  function ask_json(
    p_user_prompt        in clob,
    p_service_static_id  in varchar2 default null
  ) return clob is
    l_json clob;
    l_answer_markdown clob;
    l_answer_html clob;
    l_ai_error varchar2(1000);
    l_effective_service_static_id varchar2(255);
  begin
    if p_user_prompt is null or dbms_lob.getlength(p_user_prompt) = 0 then
      raise_application_error(-20110, 'Ask a CAAB question before sending.');
    end if;

    l_effective_service_static_id := coalesce(
      valid_service_static_id(p_service_static_id),
      valid_service_static_id(config_value('AI_SERVICE_STATIC_ID'))
    );

    l_answer_markdown := try_ai_markdown(p_user_prompt, l_effective_service_static_id, l_ai_error);

    if l_answer_markdown is null then
      l_answer_html := deterministic_answer_html(p_user_prompt);
    end if;

    apex_json.initialize_clob_output;
    apex_json.open_object;
    apex_json.write('success', true);
    apex_json.write('mode', case when l_answer_markdown is not null then 'APEX_AI' else 'DETERMINISTIC_FALLBACK' end);
    apex_json.write('aiError', l_ai_error);
    apex_json.write('selectedServiceStaticId', l_effective_service_static_id);
    apex_json.write('selectedServiceName', service_name_for_static_id(l_effective_service_static_id));
    apex_json.write('answerMarkdown', l_answer_markdown);
    apex_json.write('answerHtml', l_answer_html);
    apex_json.write('supportingHtml', case when l_answer_markdown is not null then deterministic_answer_html(p_user_prompt) end);
    apex_json.close_object;
    l_json := apex_json.get_clob_output;
    apex_json.free_output;

    return l_json;
  exception
    when others then
      apex_json.initialize_clob_output;
      apex_json.open_object;
      apex_json.write('success', false);
      apex_json.write('message', substr(sqlerrm, 1, 1000));
      apex_json.close_object;
      l_json := apex_json.get_clob_output;
      apex_json.free_output;
      return l_json;
  end ask_json;
end csiro_caab_agent_api;
/

prompt AFMA 030 complete
