set define off

prompt AFMA 040 - Create CSIRO CAAB page API

create or replace package csiro_caab_page_api as
  function home_html return clob;
  function agent_html return clob;
end csiro_caab_page_api;
/

create or replace package body csiro_caab_page_api as
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

  function page_url(
    p_page in number
  ) return varchar2 is
  begin
    return apex_util.prepare_url('f?p=' || v('APP_ID') || ':' || p_page || ':' || v('APP_SESSION') || ':::::');
  end page_url;

  function html_escape(
    p_value in varchar2
  ) return varchar2 is
  begin
    return apex_escape.html(p_value);
  end html_escape;

  function html_attr(
    p_value in varchar2
  ) return varchar2 is
  begin
    return apex_escape.html_attribute(p_value);
  end html_attr;

  procedure append_base_css(
    p_html in out nocopy clob
  ) is
  begin
    apex_css.add_file(p_name => 'caab', p_directory => v('APP_FILES'), p_version => '20260917');
  end append_base_css;

  procedure append_ocean_svg(
    p_html in out nocopy clob
  ) is
  begin
    append_line(p_html, '<svg viewBox="0 0 640 420" role="img" aria-label="Stylised Australian marine taxonomy graphic">');
    append_line(p_html, '<defs><linearGradient id="sea" x1="0" x2="1"><stop offset="0" stop-color="#00a6c8"/><stop offset="1" stop-color="#5c9f38"/></linearGradient></defs>');
    append_line(p_html, '<rect width="640" height="420" rx="0" fill="#e8fbff"/>');
    append_line(p_html, '<path d="M0 272c82-42 148-30 210-10 80 26 145 17 216-26 70-42 143-48 214-18v202H0z" fill="#d9f2df"/>');
    append_line(p_html, '<path d="M58 250c42-92 124-148 220-160 118-15 210 31 296 111" fill="none" stroke="url(#sea)" stroke-width="18" stroke-linecap="round" opacity=".85"/>');
    append_line(p_html, '<g fill="#183a54"><path d="M247 170c46-30 101-24 144 16-42 46-102 53-151 19l-38 23 12-44-12-43z"/><circle cx="355" cy="180" r="7" fill="#fff"/></g>');
    append_line(p_html, '<g fill="#007f7a" opacity=".9"><path d="M126 300c18-49 44-75 77-78-26 31-39 63-39 96z"/><path d="M186 315c6-45 25-75 58-91-13 34-15 67-5 100z"/><path d="M475 320c-5-48 7-84 37-109 3 39 15 71 37 97z"/></g>');
    append_line(p_html, '<g fill="none" stroke="#00a6c8" stroke-width="5" opacity=".75"><circle cx="112" cy="110" r="18"/><circle cx="514" cy="93" r="13"/><circle cx="455" cy="146" r="9"/></g>');
    append_line(p_html, '<g font-family="Arial, sans-serif" font-weight="800" fill="#183a54"><text x="68" y="72" font-size="22">CAAB</text><text x="68" y="99" font-size="13">taxonomy + AI exploration</text></g>');
    append_line(p_html, '</svg>');
  end append_ocean_svg;

  procedure append_model_options(
    p_html in out nocopy clob
  ) is
    l_count number := 0;
  begin
    for r in (
      select remote_server_static_id,
             remote_server_name
        from apex_workspace_ai_services
       where provider_type_code = 'OCI_GENAI'
         and lower(replace(remote_server_static_id, '-', '_')) not in
             ('cohere_command_latest', 'cohere_command_plus_latest')
         and lower(coalesce(json_value(attributes, '$.servingMode.modelId'), model_name, remote_server_name)) not in
             ('cohere.command-latest', 'cohere.command-plus-latest')
       order by case when remote_server_static_id = 'google_gemini_2_5_pro' then 0 else 1 end,
                remote_server_name
    ) loop
      l_count := l_count + 1;
      append_line(
        p_html,
        '<option value="' || html_attr(r.remote_server_static_id) || '">' ||
        html_escape(r.remote_server_name) ||
        '</option>'
      );
    end loop;

    if l_count = 0 then
      append_line(p_html, '<option value="">No AI model available</option>');
    end if;
  exception
    when others then
      append_line(p_html, '<option value="">AI model list unavailable</option>');
  end append_model_options;

  function home_html return clob is
    l_html clob;
    l_total number := 0;
    l_active number := 0;
    l_species number := 0;
  begin
    dbms_lob.createtemporary(l_html, true);

    begin
      select count(*),
             count(case when coalesce(non_current_flag, 'N') not in ('Y', 'T') and coalesce(list_status_code, 'A') = 'A' then 1 end),
             count(case when upper(taxon_rank) = 'SPECIES' then 1 end)
        into l_total,
             l_active,
             l_species
        from csiro_caab_taxa;
    exception
      when others then
        null;
    end;

    append_line(l_html, '<div class="afma-caab-shell afma-caab-home">');
    append_base_css(l_html);
    append_line(l_html, '<section class="afma-caab-hero">');
    append_line(l_html, '<div>');
    append_line(l_html, '<div class="afma-caab-kicker">AFMA demo application</div>');
    append_line(l_html, '<h1>AFMA CAAB AI Demo</h1>');
    append_line(l_html, '<p>This application highlights possible AFMA use cases using inbuilt AI in Oracle Autonomous Database 26ai and APEX, grounded in CSIRO Codes for Australian Aquatic Biota data.</p>');
    append_line(l_html, '<div class="afma-caab-cta-row">');
    append_line(l_html, '<a class="afma-caab-cta" href="' || page_url(2) || '">');
    append_line(l_html, '<span class="afma-caab-cta-icon">');
    append_ocean_svg(l_html);
    append_line(l_html, '</span><span><strong>Explore CSIRO CAAB with AI</strong><span>Ask taxonomy, species, common-name, habitat, and status questions from the loaded dataset.</span></span><span aria-hidden="true">&rarr;</span></a>');
    append_line(l_html, '<a class="afma-caab-cta" href="' || page_url(3) || '">');
    append_line(l_html, '<span class="afma-caab-cta-icon">');
    append_ocean_svg(l_html);
    append_line(l_html, '</span><span><strong>View visual CAAB reports</strong><span>Inspect taxonomy mix, source coverage, fish aliases, and Australian region coverage.</span></span><span aria-hidden="true">&rarr;</span></a>');
    append_line(l_html, '</div>');
    append_line(l_html, '<div class="afma-caab-stats"><div><span>Records</span><strong>' || to_char(l_total, 'FM999G999G999') || '</strong></div><div><span>Active</span><strong>' || to_char(l_active, 'FM999G999G999') || '</strong></div><div><span>Species</span><strong>' || to_char(l_species, 'FM999G999G999') || '</strong></div></div>');
    append_line(l_html, '</div><div class="afma-caab-visual">');
    append_ocean_svg(l_html);
    append_line(l_html, '</div></section>');
    append_line(l_html, '<section class="afma-caab-grid">');
    append_line(l_html, '<article class="afma-caab-panel"><h3>Operational discovery</h3><p>Search names, families, taxonomic ranks, status flags, and habitat codes from a verified AFMA schema table.</p></article>');
    append_line(l_html, '<article class="afma-caab-panel"><h3>AI-grounded responses</h3><p>The agent page is designed for rich text, tables, visual highlights, charts, and linked source context.</p></article>');
    append_line(l_html, '<article class="afma-caab-panel"><h3>Refresh-ready source</h3><p>The CSIRO dump endpoint and load ledger are captured so scheduled refresh can become a focused follow-up task.</p></article>');
    append_line(l_html, '</section></div>');

    return l_html;
  end home_html;

  function agent_html return clob is
    l_html clob;
    l_source_url varchar2(1000) := 'https://www.cmar.csiro.au/data/caab/create_caab_extract.cfm';
  begin
    dbms_lob.createtemporary(l_html, true);
    append_line(l_html, '<div class="afma-caab-shell afma-caab-agent">');
    append_base_css(l_html);
    append_line(l_html, '<div class="afma-caab-agent-head"><div class="afma-caab-toolbar"><h1>CSIRO CAAB Agent</h1><div class="afma-caab-source"><a class="afma-caab-btn" href="' || page_url(1) || '">Home</a><a class="afma-caab-btn" href="' || page_url(3) || '">Reports</a><a class="afma-caab-btn" href="' || l_source_url || '" target="_blank" rel="noopener">Open CAAB dump</a><button class="afma-caab-btn" type="button" disabled aria-disabled="true" title="Data refresh is not available in this demo.">Refresh unavailable</button></div></div>');
    append_line(l_html, '<div class="afma-caab-model"><label for="afmaCaabModel">AI model</label><select id="afmaCaabModel" aria-label="AI model">');
    append_model_options(l_html);
    append_line(l_html, '</select><button id="afmaCaabCounts" type="button" class="afma-caab-btn">Catalogue counts</button></div><p class="afma-caab-help" id="afmaCaabHelp">Each question is answered independently. Include names or codes again in follow-up questions. Enter sends; Shift+Enter starts a new line.</p></div>');
    append_line(l_html, '<div class="afma-caab-thread" id="afmaCaabThread"><div class="afma-caab-message"><div class="afma-caab-label">CSIRO CAAB Agent</div><div class="afma-caab-markdown"><p>Ask about Australian aquatic biota, taxonomy, common names, habitat codes, current/non-current status, families, or species groups.</p></div></div></div>');
    append_line(l_html, '<div class="afma-caab-composer" id="afmaCaabComposer"><div class="afma-caab-prompt-field"><label for="afmaCaabPrompt">Question about the CAAB catalogue</label><textarea class="afma-caab-input" id="afmaCaabPrompt" rows="3" maxlength="3000" aria-describedby="afmaCaabHelp" placeholder="Try 37354001, tuna NSW, or a scientific name"></textarea><div id="afmaCaabStatus" class="afma-caab-status" role="status" aria-live="polite" aria-atomic="true"></div></div><button class="afma-caab-send" id="afmaCaabSend" type="button">Ask</button></div>');
    append_line(l_html, '</div>');
    apex_javascript.add_library(
      p_name => 'caab-agent', p_directory => v('APP_FILES'),
      p_version => '20260917', p_check_to_add_minified => false
    );
    return l_html;
  end agent_html;
end csiro_caab_page_api;
/

prompt AFMA 040 complete
