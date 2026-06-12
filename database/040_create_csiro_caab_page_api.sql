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
    append_line(p_html, '<style>');
    append_line(p_html, '.afma-caab-shell{--afma-navy:#183a54;--afma-teal:#007f7a;--afma-cyan:#00a6c8;--afma-green:#5c9f38;--afma-ink:#1f2933;--afma-muted:#5c6b73;--afma-line:#d8e1e7;--afma-soft:#f5f9fb;color:var(--afma-ink)}');
    append_line(p_html, '.afma-caab-home{display:grid;gap:1.4rem}');
    append_line(p_html, '.afma-caab-hero{min-height:min(66vh,44rem);display:grid;grid-template-columns:minmax(0,1.1fr) minmax(18rem,.9fr);gap:clamp(1rem,3vw,2.5rem);align-items:center;padding:clamp(1rem,3vw,2.5rem) 0;border-bottom:1px solid var(--afma-line)}');
    append_line(p_html, '.afma-caab-hero h1{font-size:clamp(2.1rem,4.5vw,4.4rem);line-height:1.02;margin:.2rem 0 .8rem;font-weight:850;letter-spacing:0;color:var(--afma-navy)}');
    append_line(p_html, '.afma-caab-hero p{font-size:clamp(1rem,1.6vw,1.25rem);line-height:1.55;color:var(--afma-muted);max-width:58rem}');
    append_line(p_html, '.afma-caab-kicker{font-weight:800;text-transform:uppercase;color:var(--afma-teal);letter-spacing:.08em;font-size:.82rem}');
    append_line(p_html, '.afma-caab-cta-row{display:grid;grid-template-columns:repeat(2,minmax(0,1fr));gap:.8rem;max-width:64rem}');
    append_line(p_html, '.afma-caab-cta{display:inline-grid;grid-template-columns:auto 1fr auto;align-items:center;gap:1rem;margin-top:1.2rem;padding:1rem 1.1rem;border:1px solid #86cfd6;background:linear-gradient(135deg,#e8fbff,#f4fbef);border-radius:8px;color:var(--afma-navy);text-decoration:none;box-shadow:0 12px 32px rgba(0,74,96,.14);max-width:32rem}');
    append_line(p_html, '.afma-caab-cta:hover{text-decoration:none;transform:translateY(-1px);box-shadow:0 16px 40px rgba(0,74,96,.2)}');
    append_line(p_html, '.afma-caab-cta strong{display:block;font-size:1.08rem}.afma-caab-cta span{display:block;color:var(--afma-muted);font-size:.9rem;margin-top:.15rem}');
    append_line(p_html, '.afma-caab-cta-icon{width:4rem;height:4rem;border-radius:8px;background:#fff;display:grid;place-items:center;border:1px solid #cbeef2;overflow:hidden}');
    append_line(p_html, '.afma-caab-visual{min-height:22rem;border-radius:8px;background:linear-gradient(180deg,#dff8fc,#f6fff7);border:1px solid #cbe7ec;display:grid;place-items:center;overflow:hidden;position:relative}');
    append_line(p_html, '.afma-caab-visual svg{width:min(100%,34rem);height:auto;display:block}');
    append_line(p_html, '.afma-caab-stats{display:grid;grid-template-columns:repeat(3,minmax(0,1fr));gap:.75rem;margin-top:1rem}');
    append_line(p_html, '.afma-caab-stats div{border:1px solid var(--afma-line);border-radius:8px;padding:.9rem 1rem;background:#fff}.afma-caab-stats span{display:block;color:var(--afma-muted);font-size:.8rem;font-weight:700;text-transform:uppercase}.afma-caab-stats strong{display:block;font-size:1.55rem;color:var(--afma-navy);margin-top:.25rem}');
    append_line(p_html, '.afma-caab-grid{display:grid;grid-template-columns:repeat(3,minmax(0,1fr));gap:1rem}.afma-caab-panel{border:1px solid var(--afma-line);border-radius:8px;padding:1rem;background:#fff}.afma-caab-panel h3{margin:.1rem 0 .4rem;font-size:1rem;color:var(--afma-navy)}.afma-caab-panel p{margin:0;color:var(--afma-muted);line-height:1.45}');
    append_line(p_html, '.afma-caab-agent{display:grid;grid-template-rows:auto minmax(0,1fr) auto;gap:0;height:calc(100dvh - var(--ut-header-height,4rem) - 1.25rem);min-height:34rem;overflow:hidden;position:relative}.afma-caab-agent-head{position:sticky;top:0;z-index:20;background:rgba(255,255,255,.98);backdrop-filter:blur(10px);border:1px solid var(--afma-line);border-radius:8px;padding:.85rem .85rem 1rem;margin-bottom:.75rem;box-shadow:0 8px 22px rgba(24,58,84,.08)}');
    append_line(p_html, '.afma-caab-toolbar{display:flex;align-items:center;justify-content:space-between;gap:1rem;flex-wrap:wrap;border-bottom:1px solid var(--afma-line);padding-bottom:.8rem}.afma-caab-toolbar h1{margin:0;color:var(--afma-navy);font-size:clamp(1.45rem,2.6vw,2.2rem)}');
    append_line(p_html, '.afma-caab-source{display:flex;gap:.5rem;align-items:center;flex-wrap:wrap}.afma-caab-btn{display:inline-flex;align-items:center;gap:.45rem;border:1px solid var(--afma-line);border-radius:8px;background:#fff;color:var(--afma-navy);padding:.55rem .75rem;text-decoration:none;font-weight:700}.afma-caab-btn[aria-disabled="true"]{opacity:.58;cursor:not-allowed}');
    append_line(p_html, '.afma-caab-model{display:flex;gap:.6rem;align-items:center;flex-wrap:wrap;border:1px solid var(--afma-line);border-radius:8px;background:#fff;padding:.55rem .65rem;margin-top:.75rem}.afma-caab-model label{font-size:.78rem;font-weight:850;text-transform:uppercase;color:var(--afma-muted)}.afma-caab-model select{min-width:min(100%,24rem);border:1px solid var(--afma-line);border-radius:8px;padding:.45rem .55rem;background:#fff;color:var(--afma-navy)}');
    append_line(p_html, '.afma-caab-thread{border:1px solid var(--afma-line);border-radius:8px;background:var(--afma-soft);padding:1rem;overflow:auto;min-height:0;scroll-behavior:smooth}.afma-caab-message{max-width:min(78rem,100%);border:1px solid var(--afma-line);background:#fff;border-radius:8px;padding:1rem;margin-bottom:.85rem;box-shadow:0 8px 22px rgba(24,58,84,.06)}');
    append_line(p_html, '.afma-caab-message--user{width:80%;max-width:80%;margin-left:20%;background:#e8f7fa;border-color:#bfe7ee}.afma-caab-message--user .afma-caab-label{text-align:right;color:#376577}.afma-caab-label{font-size:.75rem;font-weight:800;text-transform:uppercase;color:var(--afma-muted);margin-bottom:.4rem}');
    append_line(p_html, '.afma-caab-composer{position:sticky;bottom:0;z-index:20;display:grid;grid-template-columns:1fr auto;gap:.75rem;align-items:end;background:rgba(255,255,255,.98);backdrop-filter:blur(10px);border:1px solid var(--afma-line);border-radius:8px;padding:.75rem;margin-top:.75rem;box-shadow:0 -10px 28px rgba(24,58,84,.10)}.afma-caab-input{min-height:4rem;max-height:11rem;resize:vertical;border:1px solid var(--afma-line);border-radius:8px;padding:.8rem;font:inherit}.afma-caab-send{height:3.75rem;border:0;border-radius:8px;background:var(--afma-teal);color:white;font-weight:850;padding:0 1.1rem}.afma-caab-send:disabled{opacity:.6;cursor:wait}');
    append_line(p_html, '.afma-caab-section{margin-top:1rem}.afma-caab-section h3{margin:.2rem 0 .6rem;color:var(--afma-navy)}.afma-caab-table-wrap{overflow:auto;border:1px solid var(--afma-line);border-radius:8px}.afma-caab-table{width:100%;border-collapse:collapse;background:#fff}.afma-caab-table th,.afma-caab-table td{padding:.55rem .65rem;border-bottom:1px solid var(--afma-line);text-align:left;vertical-align:top}.afma-caab-table th{font-size:.75rem;text-transform:uppercase;color:var(--afma-muted);background:#f7fafc}.afma-caab-chip{display:inline-flex;border-radius:999px;background:#edf7ee;color:#2f6f2d;padding:.12rem .45rem;font-size:.75rem;font-weight:800}');
    append_line(p_html, '.afma-caab-answer-head{border-left:4px solid var(--afma-teal);padding-left:.85rem}.afma-caab-answer-head h2{margin:.1rem 0 .25rem;color:var(--afma-navy)}.afma-caab-mode{display:inline-flex;background:#edf7ff;color:#0f5f7a;border-radius:999px;padding:.18rem .55rem;font-size:.72rem;font-weight:850;text-transform:uppercase}');
    append_line(p_html, '.afma-caab-bars{display:grid;gap:.45rem}.afma-caab-bar-row{display:grid;grid-template-columns:minmax(8rem,16rem) 1fr 5rem;gap:.65rem;align-items:center}.afma-caab-bar-row span{font-size:.9rem}.afma-caab-bar-track{height:.75rem;background:#e6eef2;border-radius:999px;overflow:hidden}.afma-caab-bar-fill{height:100%;background:linear-gradient(90deg,var(--afma-teal),var(--afma-green))}');
    append_line(p_html, '.afma-caab-markdown{overflow:auto}.afma-caab-markdown h1,.afma-caab-markdown h2,.afma-caab-markdown h3{color:var(--afma-navy)}.afma-caab-markdown table{border-collapse:collapse;width:100%;margin:.75rem 0}.afma-caab-markdown th,.afma-caab-markdown td{border:1px solid var(--afma-line);padding:.45rem;vertical-align:top}.afma-caab-markdown th{background:#f7fafc;color:var(--afma-muted);font-size:.82rem;text-transform:uppercase}.afma-caab-markdown ul,.afma-caab-markdown ol{padding-left:1.4rem}.afma-caab-markdown li{margin:.25rem 0}.afma-caab-markdown pre{overflow:auto;background:#f7fafc;border:1px solid var(--afma-line);border-radius:8px;padding:.75rem}.afma-caab-markdown blockquote{margin:.75rem 0;padding:.1rem .85rem;border-left:4px solid var(--afma-cyan);background:#f7fbfd}.afma-caab-markdown hr{border:0;border-top:1px solid var(--afma-line);margin:1rem 0}.afma-caab-markdown code{font-size:.92em}.afma-caab-markdown img{max-width:min(100%,42rem);border-radius:8px;border:1px solid var(--afma-line)}.afma-caab-mermaid{overflow:auto;background:#fff;border:1px solid var(--afma-line);border-radius:8px;padding:.75rem;margin:.75rem 0}.afma-caab-mermaid svg{max-width:100%;height:auto}.afma-caab-mermaid-error{border-color:#f0b8b8;background:#fff8f8}');
    append_line(p_html, '@media (max-width:800px){.afma-caab-agent{height:calc(100dvh - var(--ut-header-height,4rem) - .75rem);min-height:30rem}.afma-caab-hero{grid-template-columns:1fr;min-height:auto}.afma-caab-grid,.afma-caab-stats,.afma-caab-cta-row{grid-template-columns:1fr}.afma-caab-toolbar{align-items:flex-start}.afma-caab-source{width:100%;overflow:auto;flex-wrap:nowrap;padding-bottom:.15rem}.afma-caab-model select{width:100%;min-width:0}.afma-caab-composer{grid-template-columns:1fr}.afma-caab-send{width:100%}.afma-caab-message--user{width:100%;max-width:100%;margin-left:0}.afma-caab-bar-row{grid-template-columns:1fr}.afma-caab-visual{min-height:16rem}}');
    append_line(p_html, '</style>');
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
      append_line(p_html, '<option value="">Workspace default</option>');
    end if;
  exception
    when others then
      append_line(p_html, '<option value="">Workspace default</option>');
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
    append_line(l_html, '<div class="afma-caab-agent-head"><div class="afma-caab-toolbar"><h1>CSIRO CAAB Agent</h1><div class="afma-caab-source"><a class="afma-caab-btn" href="' || page_url(1) || '">Home</a><a class="afma-caab-btn" href="' || page_url(3) || '">Reports</a><a class="afma-caab-btn" href="' || l_source_url || '" target="_blank" rel="noopener">Open CAAB dump</a><button class="afma-caab-btn" type="button" aria-disabled="true" title="Tracked separately as afma-004">Refresh data</button></div></div>');
    append_line(l_html, '<div class="afma-caab-model"><label for="afmaCaabModel">AI model</label><select id="afmaCaabModel" aria-label="AI model">');
    append_model_options(l_html);
    append_line(l_html, '</select></div></div>');
    append_line(l_html, '<div class="afma-caab-thread" id="afmaCaabThread"><div class="afma-caab-message"><div class="afma-caab-label">CSIRO CAAB Agent</div><div class="afma-caab-markdown"><p>Ask about Australian aquatic biota, taxonomy, common names, habitat codes, current/non-current status, families, or species groups.</p></div></div></div>');
    append_line(l_html, '<div class="afma-caab-composer" id="afmaCaabComposer"><textarea class="afma-caab-input" id="afmaCaabPrompt" rows="3" placeholder="Ask about sharks, tuna, a CAAB code, a family, or the largest taxonomic groups"></textarea><button class="afma-caab-send" id="afmaCaabSend" type="button">Ask</button></div>');
    append_line(l_html, '<script>');
    append_line(l_html, '(function(){');
    append_line(l_html, q'~function esc(v){return String(v||"").replace(/[&<>"']/g,function(c){return {"&":"&amp;","<":"&lt;",">":"&gt;","\"":"&quot;","'":"&#39;"}[c];});}~');
    append_line(l_html, q'~function safeHref(v){var h=String(v||"").trim();return /^https?:\/\//i.test(h)?h:"";}~');
    append_line(l_html, q'~function inlineMd(v){var s=esc(v);s=s.replace(/!\[([^\]]*)\]\((https?:\/\/[^)\s]+)\)/g,function(_,a,u){return "<img src=\""+safeHref(u)+"\" alt=\""+esc(a)+"\" loading=\"lazy\">";});s=s.replace(/\[([^\]]+)\]\((https?:\/\/[^)\s]+)\)/g,function(_,a,u){return "<a href=\""+safeHref(u)+"\" target=\"_blank\" rel=\"noopener\">"+inlineMd(a)+"</a>";});s=s.replace(/`([^`]+)`/g,"<code>$1</code>");s=s.replace(/\*\*([^*]+)\*\*/g,"<strong>$1</strong>");s=s.replace(/\*([^*\n]+)\*/g,"<em>$1</em>");return s;}~');
    append_line(l_html, q'~function tableLike(line){return ((String(line||"").match(/\|/g)||[]).length>=2);}~');
    append_line(l_html, q'~function tableSep(line){return /^\s*\|?\s*:?-{2,}:?\s*(\|\s*:?-{2,}:?\s*)+\|?\s*$/.test(line||"");}~');
    append_line(l_html, q'~function tableRow(line){var r=String(line||"").trim();if(r.charAt(0)==="|"){r=r.slice(1);}if(r.endsWith("|")){r=r.slice(0,-1);}return r.split("|").map(function(c){return c.trim();});}~');
    append_line(l_html, q'~function renderTable(rows,hasSep){var head=tableRow(rows[0]),bodyRows=(hasSep?rows.slice(2):rows.slice(1)).filter(tableLike),width=head.length;bodyRows.map(tableRow).forEach(function(r){width=Math.max(width,r.length);});while(head.length<width){head.push("");}var body=bodyRows.map(tableRow);return "<table><thead><tr>"+head.map(function(c){return "<th>"+inlineMd(c)+"</th>";}).join("")+"</tr></thead><tbody>"+body.map(function(r){while(r.length<width){r.push("");}return "<tr>"+r.slice(0,width).map(function(c){return "<td>"+inlineMd(c)+"</td>";}).join("")+"</tr>";}).join("")+"</tbody></table>";}~');
    append_line(l_html, q'~function md(v){var lines=String(v||"").replace(/\r\n?/g,"\n").split("\n"),out=[],para=[],items=[],listTag=null,code=[],codeLang="",inCode=false;function flushPara(){if(para.length){out.push("<p>"+para.map(inlineMd).join("<br>")+"</p>");para=[];}}function flushList(){if(items.length){out.push("<"+listTag+">"+items.map(function(x){return "<li>"+x+"</li>";}).join("")+"</"+listTag+">");items=[];listTag=null;}}function flushCode(){var src=code.join("\n");if(/^mermaid$/i.test(codeLang)){out.push("<div class=\"afma-caab-mermaid\" data-mermaid-source=\""+esc(src)+"\"><pre><code>"+esc(src)+"</code></pre></div>");}else{out.push("<pre><code>"+esc(src)+"</code></pre>");}code=[];codeLang="";}for(var i=0;i<lines.length;i++){var line=lines[i],m=line.match(/^```\s*([A-Za-z0-9_-]+)?/);if(m){if(inCode){flushCode();inCode=false;}else{flushPara();flushList();codeLang=(m[1]||"").toLowerCase();inCode=true;}continue;}if(inCode){code.push(line);continue;}if(!line.trim()){flushPara();flushList();continue;}if(tableLike(line)&&i+1<lines.length&&(tableSep(lines[i+1])||tableLike(lines[i+1]))){var rows=[line],hasSep=false;i++;if(tableSep(lines[i])){rows.push(lines[i]);hasSep=true;i++;}while(i<lines.length&&lines[i].trim()&&tableLike(lines[i])){rows.push(lines[i]);i++;}i--;flushPara();flushList();out.push(renderTable(rows,hasSep));continue;}m=line.match(/^(#{1,6})\s+(.+)$/);if(m){flushPara();flushList();out.push("<h"+m[1].length+">"+inlineMd(m[2])+"</h"+m[1].length+">");continue;}if(/^\s*([-*_])\s*(\1\s*){2,}$/.test(line)){flushPara();flushList();out.push("<hr>");continue;}m=line.match(/^\s*>\s?(.+)$/);if(m){flushPara();flushList();out.push("<blockquote>"+inlineMd(m[1])+"</blockquote>");continue;}m=line.match(/^\s*[-*]\s+(.+)$/);if(m){flushPara();if(listTag&&listTag!=="ul"){flushList();}listTag="ul";items.push(inlineMd(m[1]));continue;}m=line.match(/^\s*\d+[.)]\s+(.+)$/);if(m){flushPara();if(listTag&&listTag!=="ol"){flushList();}listTag="ol";items.push(inlineMd(m[1]));continue;}para.push(line);}if(inCode){flushCode();}flushPara();flushList();return out.join("");}~');
    append_line(l_html, q'~function safeMd(v){try{return md(v);}catch(e){return "<pre>"+esc(v)+"</pre>";}}~');
    append_line(l_html, q'~var mermaidLoader;function ensureMermaid(){if(window.mermaid&&typeof window.mermaid.initialize==="function"){if(!window.__afmaMermaidInitialized){window.mermaid.initialize({startOnLoad:false,securityLevel:"strict",theme:"default"});window.__afmaMermaidInitialized=true;}return Promise.resolve(window.mermaid);}if(mermaidLoader){return mermaidLoader;}mermaidLoader=new Promise(function(resolve,reject){var s=document.createElement("script");s.src="https://cdn.jsdelivr.net/npm/mermaid@10/dist/mermaid.min.js";s.async=true;s.onload=function(){if(!window.mermaid||typeof window.mermaid.initialize!=="function"){reject(new Error("Mermaid loaded but global API was unavailable."));return;}if(!window.__afmaMermaidInitialized){window.mermaid.initialize({startOnLoad:false,securityLevel:"strict",theme:"default"});window.__afmaMermaidInitialized=true;}resolve(window.mermaid);};s.onerror=function(){reject(new Error("Unable to load Mermaid library."));};document.head.appendChild(s);});return mermaidLoader;}~');
    append_line(l_html, q'~function renderMermaid(scope){var nodes=(scope||document).querySelectorAll(".afma-caab-mermaid[data-mermaid-source]:not([data-rendered])");if(!nodes.length){return;}ensureMermaid().then(function(mermaid){nodes.forEach(function(node,idx){var src=node.getAttribute("data-mermaid-source")||"";var id="afmaCaabMermaid"+Date.now()+"_"+idx;mermaid.render(id,src).then(function(result){node.innerHTML=result.svg;node.setAttribute("data-rendered","Y");}).catch(function(err){node.classList.add("afma-caab-mermaid-error");node.setAttribute("data-rendered","ERR");node.title=err&&err.message?err.message:String(err);});});}).catch(function(){nodes.forEach(function(node){node.setAttribute("data-rendered","SKIP");});});}~');
    append_line(l_html, 'function add(kind,html){var t=document.getElementById("afmaCaabThread");var d=document.createElement("div");d.className="afma-caab-message"+(kind==="user"?" afma-caab-message--user":"");d.innerHTML="<div class=\"afma-caab-label\">"+(kind==="user"?"You":"CSIRO CAAB Agent")+"</div><div class=\"afma-caab-markdown\">"+html+"</div>";t.appendChild(d);t.scrollTop=t.scrollHeight;return d;}');
    append_line(l_html, 'var prompt=document.getElementById("afmaCaabPrompt"),send=document.getElementById("afmaCaabSend"),model=document.getElementById("afmaCaabModel");if(!send||!prompt){return;}');
    append_line(l_html, 'function ask(){var q=prompt.value.trim(),m=model?model.value:"";if(!q||send.disabled){return;}add("user",esc(q));prompt.value="";send.disabled=true;var hold=add("agent","<p>Thinking...</p>");apex.server.process("CSIRO_CAAB_AGENT_ASK",{x01:q,x02:m},{dataType:"json"}).then(function(r){if(!r||!r.success){hold.querySelector(".afma-caab-markdown").innerHTML="<p>"+esc((r&&r.message)||"No response returned.")+"</p>";return;}var html=r.answerMarkdown?safeMd(r.answerMarkdown):(r.answerHtml||"");if(r.selectedServiceName){html="<p><strong>Model:</strong> "+esc(r.selectedServiceName)+"</p>"+html;}if(r.supportingHtml){html+="<details class=\"afma-caab-section\"><summary>Grounding details</summary>"+r.supportingHtml+"</details>";}var target=hold.querySelector(".afma-caab-markdown");target.innerHTML=html;renderMermaid(target);}).catch(function(err){hold.querySelector(".afma-caab-markdown").innerHTML="<p>"+esc(err&&err.message?err.message:err)+"</p>";}).finally(function(){send.disabled=false;prompt.focus();});}');
    append_line(l_html, 'prompt.addEventListener("keydown",function(e){if(e.key==="Enter"&&!e.shiftKey){e.preventDefault();ask();}});');
    append_line(l_html, 'send.addEventListener("click",ask);');
    append_line(l_html, '})();');
    append_line(l_html, '</script></div>');
    return l_html;
  end agent_html;
end csiro_caab_page_api;
/

prompt AFMA 040 complete
