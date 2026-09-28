set define off

-- Execution authority: AFMA parsing schema owner through the verified AFMA APEX SQL Commands session.
-- Target: AIDEMODB workspace/schema AFMA; database-rendered page API consumed by APEX page 4.
prompt AFMA 120 - Create Catch Monitor reviewer page API

create or replace package afma_cm_page_api as
  function workbench_html return clob;
end afma_cm_page_api;
/

create or replace package body afma_cm_page_api as
  procedure add_text(
    p_html in out nocopy clob,
    p_text in varchar2
  ) is
  begin
    if p_text is not null then
      dbms_lob.writeappend(p_html, length(p_text), p_text);
    end if;
  end add_text;

  procedure add_line(
    p_html in out nocopy clob,
    p_text in varchar2 default null
  ) is
  begin
    add_text(p_html, p_text || chr(10));
  end add_line;

  function h(p_value in varchar2) return varchar2 is
  begin
    return apex_escape.html(p_value);
  end h;

  function a(p_value in varchar2) return varchar2 is
  begin
    return apex_escape.html_attribute(p_value);
  end a;

  function badge_class(p_value in varchar2) return varchar2 is
    l_value varchar2(100) := upper(coalesce(p_value, 'UNKNOWN'));
  begin
    if l_value in ('MATCH','CONFIRMED','COVERED','FROZEN_FOR_REVIEW','REVIEW_COMPLETE') then
      return 'cm-badge-ok';
    elsif l_value in ('NEEDS_REVIEW','POSSIBLE_INTERACTION','PENDING_REVIEW','UNCONFIRMED_INTERNAL_ONLY','MEDIA_GAP') then
      return 'cm-badge-warn';
    elsif l_value in ('REJECTED','PROHIBITED','TAKEDOWN','SPECIES_DIFFERENCE','UNREPORTED_VIDEO_EVENT') then
      return 'cm-badge-risk';
    end if;
    return 'cm-badge-neutral';
  end badge_class;

  function fmt_second(p_second in number) return varchar2 is
  begin
    return lpad(trunc(coalesce(p_second, 0) / 60), 2, '0') || ':' ||
           lpad(mod(trunc(coalesce(p_second, 0)), 60), 2, '0');
  end fmt_second;

  function fmt_range(
    p_start_second in number,
    p_end_second   in number
  ) return varchar2 is
  begin
    return fmt_second(p_start_second) ||
           case
             when p_end_second is not null and p_end_second <> p_start_second
             then '–' || fmt_second(p_end_second)
           end;
  end fmt_range;

  function workbench_html return clob is
    l_html clob;
    l_trip_id number;
    l_trip afma_cm_trips%rowtype;
    l_report_id number;
    l_version_no number;
    l_report_status varchar2(30);
    l_source_type varchar2(30);
    l_run_id number;
    l_analysis_mode varchar2(40);
    l_model_version varchar2(200);
    l_manifest varchar2(200);
    l_source_url varchar2(2000);
    l_embed_url varchar2(2000);
    l_media_title varchar2(500);
    l_media_source varchar2(120);
    l_duration_seconds number;
    l_run_notes varchar2(2000);
    l_requested_ref varchar2(40);
    l_annotation_status varchar2(60);
    l_open_count number := 0;
    l_asset_count number := 0;
    l_gap_count number := 0;
    l_reported_count number := 0;
    l_video_count number;
    l_outcome varchar2(40);
    l_editable boolean := false;
    l_metadata_prompt_active_count number := 0;
  begin
    dbms_lob.createtemporary(l_html, true);

    if apex_application.g_request like 'SCENARIO-%' then
      l_requested_ref := substr(apex_application.g_request, length('SCENARIO-') + 1);
    end if;

    begin
      select trip_id
        into l_trip_id
        from afma_cm_trips
       where trip_ref = coalesce(l_requested_ref, 'CM-QLD-002')
         and not exists (
           select 1
             from afma_cm_video_submissions vs
             join afma_cm_analysis_runs sr on sr.analysis_run_id = vs.analysis_run_id
            where sr.trip_id = afma_cm_trips.trip_id
              and (vs.processing_status <> 'ANALYSIS_COMPLETE'
                   or coalesce(vs.processing_stage, '~') <> 'READY_FOR_REVIEW')
         );
    exception
      when no_data_found then
        select min(trip_id) keep (dense_rank first order by created_at desc)
          into l_trip_id
          from afma_cm_trips t
         where t.status <> 'ARCHIVED'
           and not exists (
             select 1
               from afma_cm_video_submissions vs
               join afma_cm_analysis_runs sr on sr.analysis_run_id = vs.analysis_run_id
              where sr.trip_id = t.trip_id
                and (vs.processing_status <> 'ANALYSIS_COMPLETE'
                     or coalesce(vs.processing_stage, '~') <> 'READY_FOR_REVIEW')
           );
    end;

    if l_trip_id is null then
      return '<div class="t-Alert t-Alert--warning">No Catch Monitor trip is available.</div>';
    end if;

    select * into l_trip from afma_cm_trips where trip_id = l_trip_id;

    select report_version_id, version_no, report_status, source_type
      into l_report_id, l_version_no, l_report_status, l_source_type
      from afma_cm_report_versions
     where trip_id = l_trip_id
       and version_no = (select max(version_no) from afma_cm_report_versions where trip_id = l_trip_id);

    l_editable := l_report_status in ('DRAFT','RECORDED');

    select ar.analysis_run_id, ar.analysis_mode, ar.model_version, ar.media_manifest,
           m.source_record_url, m.embed_url, m.title, m.source_system,
           m.duration_seconds, ar.run_notes
      into l_run_id, l_analysis_mode, l_model_version, l_manifest,
           l_source_url, l_embed_url, l_media_title, l_media_source,
           l_duration_seconds, l_run_notes
      from afma_cm_analysis_runs ar
      join afma_cm_media_assets m on m.media_asset_id = ar.media_asset_id
     where ar.trip_id = l_trip_id
       and ar.analysis_run_id = (select max(analysis_run_id) from afma_cm_analysis_runs where trip_id = l_trip_id);

    select count(case when reviewer_status = 'NEEDS_REVIEW' then 1 end),
           count(*)
      into l_open_count, l_video_count
      from afma_cm_observations
     where analysis_run_id = l_run_id;

    select count(*),
           count(case when coverage_status in ('MEDIA_GAP','NEEDS_TAXON_REVIEW') then 1 end)
      into l_asset_count, l_gap_count
      from afma_cm_media_assets
     where trip_id = l_trip_id;

    select count(*)
      into l_reported_count
      from afma_cm_reported_catch rc
      join afma_cm_operations op on op.operation_id = rc.operation_id
     where op.report_version_id = l_report_id;

    l_annotation_status := case
      when l_model_version = 'analysis-not-started' then 'Analysis not started'
      when l_model_version = 'annotation-pending' then 'Annotation pending'
      when l_model_version = 'source-described-minimum-v1' then 'Source-described summary'
      when l_model_version = 'synthetic-ui-fixture-v1' then 'Synthetic UI fixture'
      when l_model_version like 'human-ground-truth%' then 'Human-reviewed ground truth'
      when l_model_version like 'manual-video-annotation%' then 'Time-coded manual annotation'
      else 'Demo evidence run'
    end;

    select count(*)
      into l_metadata_prompt_active_count
      from afma_cm_prompt_contracts
     where prompt_key = 'catch-monitor-metadata'
       and contract_status = 'ACTIVE';

    add_line(l_html, '<div class="cm-shell" id="cmShell" data-trip-id="' || l_trip_id || '">');
    add_line(l_html, q'~<style>
.cm-shell{display:grid;gap:1rem;color:#1d2935}
.cm-intake{background:#fff;border:1px solid #cbdbe3;border-radius:10px;box-shadow:0 8px 24px rgba(18,54,76,.06);overflow:hidden}.cm-intake__head{display:flex;justify-content:space-between;gap:1rem;align-items:flex-start;padding:1rem;border-bottom:1px solid #d7e1e7;background:#f7fbfc}.cm-intake__head h2{margin:0;color:#12364c;font-size:1.2rem}.cm-intake__head p{margin:.25rem 0 0;color:#526672;line-height:1.45;max-width:70rem}.cm-disclosure{display:grid;grid-template-columns:repeat(4,minmax(0,1fr));gap:.65rem;padding:1rem;background:#eef7f8}.cm-disclosure article{background:#fff;border:1px solid #cbdbe3;border-radius:8px;padding:.7rem}.cm-disclosure h3{margin:0 0 .25rem;color:#12364c;font-size:.84rem}.cm-disclosure p{margin:0;color:#526672;font-size:.78rem;line-height:1.42}.cm-prompt-review{margin:1rem;border:1px solid #b9cbd4;border-radius:9px;background:#fff}.cm-prompt-review>summary{cursor:pointer;padding:.8rem;font-weight:850;color:#12364c;background:#f4f8fa}.cm-prompt-review__body{padding:.8rem}.cm-prompt-review pre{white-space:pre-wrap;max-height:18rem;overflow:auto;background:#102a3a;color:#eff9fb;padding:.7rem;border-radius:7px;font-size:.74rem;line-height:1.45}.cm-prompt-review__ack{display:flex;align-items:flex-start;gap:.45rem;padding:.65rem;background:#fff8e7;border:1px solid #f1c36c;border-radius:7px;margin:.7rem 0}.cm-intake__form{padding:1rem}.cm-intake__fields{display:grid;grid-template-columns:1fr 1fr;gap:.7rem}.cm-intake__field{min-width:0}.cm-intake__field--wide{grid-column:1/-1}.cm-intake__field label,.cm-intake__mode>label{display:block;font-size:.7rem;font-weight:850;text-transform:uppercase;color:#5d6c76;margin-bottom:.25rem}.cm-intake__field input,.cm-intake__field textarea{width:100%;border:1px solid #b9cbd4;border-radius:6px;padding:.55rem;background:#fff}.cm-intake__field textarea{min-height:4.5rem;resize:vertical}.cm-intake__modes{display:grid;grid-template-columns:1fr 1fr;gap:.7rem;margin-top:.7rem}.cm-intake__mode{border:1px solid #d7e1e7;border-radius:8px;padding:.8rem;background:#fbfdfe}.cm-intake__mode h3{margin:0 0 .2rem;color:#12364c;font-size:.95rem}.cm-intake__mode p{margin:0 0 .65rem;color:#5d6c76;font-size:.8rem;line-height:1.4}.cm-intake__acks{display:grid;gap:.45rem;margin-top:.8rem;padding:.75rem;border:1px solid #f1c36c;background:#fff8e7;border-radius:8px}.cm-intake__status{margin-top:.7rem;padding:.65rem .75rem;border-left:4px solid #9a6200;background:#fff8e7;color:#6e4900;font-size:.82rem;line-height:1.45}.cm-native-slot .t-Form-fieldContainer{margin:0}.cm-native-slot .t-Form-labelContainer{padding-top:0}.cm-native-slot .t-Form-label{font-size:.7rem;font-weight:850;text-transform:uppercase;color:#5d6c76}.cm-native-slot .t-Form-inputContainer{padding-bottom:0}.cm-intake__ledger{border-top:1px solid #d7e1e7;padding:1rem}.cm-intake__ledger h3{margin:0 0 .5rem;color:#12364c;font-size:1rem}.cm-metadata-row td{padding-top:0;background:#fbfdfe}.cm-metadata{border:1px solid #d7e1e7;border-radius:8px;padding:.65rem}.cm-metadata summary{cursor:pointer;color:#12364c;font-weight:800}.cm-metadata__body{display:grid;grid-template-columns:minmax(0,1.4fr) minmax(16rem,.6fr);gap:.8rem;margin-top:.7rem}.cm-metadata__fields{display:grid;grid-template-columns:1fr 1fr;gap:.55rem}.cm-metadata__fields .cm-field--wide{grid-column:1/-1}.cm-metadata__fields textarea{min-height:4.5rem;resize:vertical}.cm-metadata__proposal{border-left:4px solid #0c6e9d;background:#eef7f8;padding:.7rem;border-radius:6px}.cm-metadata__proposal h4{margin:0 0 .35rem;color:#12364c}.cm-metadata__proposal p{margin:.3rem 0;color:#526672;font-size:.8rem;line-height:1.4}
.cm-selector{display:grid;grid-template-columns:minmax(18rem,.7fr) minmax(0,1.3fr);gap:1rem;align-items:end;background:#fff;border:1px solid #cbdbe3;border-radius:10px;padding:1rem;box-shadow:0 8px 24px rgba(18,54,76,.06)}.cm-selector label{display:block;font-size:.72rem;font-weight:850;text-transform:uppercase;letter-spacing:.045em;color:#5d6c76;margin-bottom:.3rem}.cm-selector select{width:100%;border:1px solid #9fb8c5;border-radius:7px;background:#fff;padding:.62rem;color:#12364c;font-weight:750}.cm-selector h2{margin:0 0 .25rem;color:#12364c;font-size:1.05rem}.cm-selector p{margin:0;color:#526672;line-height:1.45}.cm-selector__meta{display:flex;gap:.4rem;flex-wrap:wrap;margin-top:.55rem}
.cm-hero{background:linear-gradient(128deg,#12364c 0%,#075c72 58%,#007d78 100%);color:white;border-radius:12px;padding:clamp(1rem,3vw,2rem);box-shadow:0 18px 40px rgba(18,54,76,.18)}.cm-hero__top{display:flex;align-items:flex-start;justify-content:space-between;gap:1rem;flex-wrap:wrap}.cm-kicker{font-size:.75rem;font-weight:850;text-transform:uppercase;letter-spacing:.11em;color:#9ce8e0}.cm-hero h1{margin:.25rem 0 .45rem;font-size:clamp(1.65rem,3.4vw,2.8rem);line-height:1.08}.cm-hero p{margin:0;max-width:68rem;color:#e6f4f5;line-height:1.5}.cm-demo{display:inline-flex;align-items:center;gap:.45rem;border:1px solid rgba(255,255,255,.45);background:rgba(255,255,255,.12);border-radius:999px;padding:.4rem .7rem;font-size:.78rem;font-weight:800}.cm-stats{display:grid;grid-template-columns:repeat(4,minmax(0,1fr));gap:.7rem;margin-top:1.15rem}.cm-stat{background:rgba(255,255,255,.1);border:1px solid rgba(255,255,255,.22);border-radius:9px;padding:.7rem}.cm-stat span{display:block;font-size:.7rem;text-transform:uppercase;letter-spacing:.06em;color:#c7e8e9}.cm-stat strong{display:block;font-size:1.35rem;margin-top:.15rem}
.cm-alert{display:flex;gap:.65rem;align-items:flex-start;border-radius:9px;padding:.75rem .9rem;border:1px solid #f1c36c;background:#fff8e7;color:#6e4900}.cm-alert strong{display:block}.cm-alert p{margin:.2rem 0 0;line-height:1.45}.cm-grid{display:grid;grid-template-columns:minmax(0,1.05fr) minmax(22rem,.95fr);gap:1rem}.cm-card{background:#fff;border:1px solid #d7e1e7;border-radius:10px;box-shadow:0 8px 24px rgba(18,54,76,.06);overflow:hidden}.cm-card__head{display:flex;justify-content:space-between;align-items:flex-start;gap:.8rem;padding:.9rem 1rem;border-bottom:1px solid #d7e1e7;background:#fbfdfe}.cm-card__head h2{margin:0;color:#12364c;font-size:1.08rem}.cm-card__head p{margin:.2rem 0 0;color:#5d6c76;font-size:.83rem}.cm-card__body{padding:1rem}.cm-video{aspect-ratio:16/9;width:100%;border:0;background:#071924}.cm-meta{display:flex;gap:.45rem;flex-wrap:wrap;margin-top:.7rem}.cm-badge{display:inline-flex;align-items:center;border-radius:999px;padding:.18rem .5rem;font-size:.72rem;font-weight:850;text-transform:uppercase;letter-spacing:.025em}.cm-badge-ok{background:#e6f4e8;color:#27642c}.cm-badge-warn{background:#fff0cd;color:#795000}.cm-badge-risk{background:#fde8e8;color:#8f2020}.cm-badge-neutral{background:#eaf1f5;color:#3b5668}.cm-table-wrap{overflow:auto}.cm-table{width:100%;border-collapse:collapse}.cm-table th,.cm-table td{padding:.65rem .7rem;border-bottom:1px solid #d7e1e7;text-align:left;vertical-align:top}.cm-table th{background:#f5f8fa;color:#5d6c76;font-size:.7rem;text-transform:uppercase;letter-spacing:.045em}.cm-table td{font-size:.88rem}.cm-table small{display:block;color:#5d6c76;margin-top:.18rem;line-height:1.35}.cm-spcode{font-family:ui-monospace,SFMono-Regular,Menlo,monospace;font-size:.76rem;color:#0c6e9d}
.cm-btn{border:1px solid #b8cbd4;background:white;color:#12364c;border-radius:7px;padding:.48rem .68rem;font-weight:800;cursor:pointer}.cm-btn:hover{background:#f1f7f9}.cm-btn-primary{background:#007d78;border-color:#007d78;color:white}.cm-btn-danger{border-color:#e1b1b1;color:#a32929}.cm-btn:disabled{opacity:.48;cursor:not-allowed}.cm-actions{display:flex;gap:.45rem;flex-wrap:wrap}.cm-form{display:grid;grid-template-columns:2fr .7fr .8fr 1fr auto;gap:.55rem;align-items:end;margin-top:.8rem;padding:.8rem;background:#f4f8fa;border:1px solid #d7e1e7;border-radius:8px}.cm-field label{display:block;font-size:.7rem;font-weight:850;text-transform:uppercase;color:#5d6c76;margin-bottom:.25rem}.cm-field input,.cm-field select,.cm-review select,.cm-review input{width:100%;border:1px solid #b9cbd4;border-radius:6px;padding:.48rem;background:white}.cm-events{display:grid;gap:.65rem}.cm-event{border:1px solid #d7e1e7;border-left:5px solid #0c6e9d;border-radius:8px;padding:.75rem}.cm-event-wildlife{border-left-color:#9a6200}.cm-event__top{display:flex;justify-content:space-between;gap:.7rem}.cm-event h3{margin:0;font-size:.95rem;color:#12364c}.cm-event p{margin:.35rem 0;color:#5d6c76;font-size:.84rem;line-height:1.4}.cm-review{display:grid;grid-template-columns:1.2fr .55fr 1fr auto;gap:.45rem;margin-top:.6rem;align-items:end}.cm-review label{font-size:.68rem;color:#5d6c76;text-transform:uppercase;font-weight:800}.cm-section-title{display:flex;justify-content:space-between;align-items:center;gap:.7rem;margin:.1rem 0 .7rem}.cm-section-title h2{margin:0;color:#12364c;font-size:1.25rem}.cm-media-grid{display:grid;grid-template-columns:repeat(3,minmax(0,1fr));gap:.75rem}.cm-media{border:1px solid #d7e1e7;border-radius:8px;padding:.75rem}.cm-media h3{margin:.2rem 0 .3rem;font-size:.92rem;color:#12364c}.cm-media p{margin:.25rem 0;color:#5d6c76;font-size:.8rem;line-height:1.4}.cm-link{color:#0c6e9d;font-weight:750}.cm-guidance{display:grid;grid-template-columns:repeat(3,minmax(0,1fr));gap:.65rem}.cm-guidance a{display:block;border:1px solid #d7e1e7;border-radius:8px;padding:.7rem;text-decoration:none;color:#12364c;font-weight:800;background:#fff}.cm-guidance small{display:block;color:#5d6c76;font-weight:400;margin-top:.2rem}.cm-footnote{font-size:.78rem;color:#5d6c76;line-height:1.45}.cm-loading{opacity:.56;pointer-events:none}
@media(max-width:920px){.cm-disclosure{grid-template-columns:1fr 1fr}.cm-selector,.cm-grid,.cm-metadata__body{grid-template-columns:1fr}.cm-stats{grid-template-columns:repeat(2,1fr)}.cm-media-grid,.cm-guidance{grid-template-columns:1fr}.cm-form,.cm-review{grid-template-columns:1fr 1fr}.cm-form .cm-field:first-child,.cm-review .cm-field:first-child{grid-column:1/-1}}
.cm-intake>summary{cursor:pointer;list-style:none}.cm-intake>summary::-webkit-details-marker{display:none}.cm-intake>summary .cm-intake__toggle{font-weight:850;color:#0c6e9d;white-space:nowrap}.cm-intake[open]>summary{border-bottom:1px solid #d7e1e7}.cm-video-placeholder{display:grid;place-items:center;min-height:18rem;padding:2rem;text-align:center;border:2px dashed #b9cbd4;border-radius:8px;background:#f4f8fa;color:#526672}.cm-video-placeholder strong{display:block;color:#12364c;font-size:1.05rem;margin-bottom:.35rem}
.cm-clearance{background:#fff;border:1px solid #cbdbe3;border-radius:10px;box-shadow:0 8px 24px rgba(18,54,76,.06);overflow:hidden}.cm-clearance__head{display:flex;justify-content:space-between;gap:1rem;align-items:flex-start;padding:.9rem 1rem;border-bottom:1px solid #d7e1e7;background:#fbfdfe}.cm-clearance__head h2{margin:0;color:#12364c;font-size:1.08rem}.cm-clearance__head p{margin:.2rem 0 0;color:#5d6c76;font-size:.83rem;line-height:1.4}.cm-progress{display:grid;grid-template-columns:minmax(10rem,1fr) 3rem;gap:.55rem;align-items:center;min-width:14rem}.cm-progress__track{height:.65rem;border-radius:999px;background:#dfe9ee;overflow:hidden}.cm-progress__fill{display:block;height:100%;background:linear-gradient(90deg,#0c6e9d,#007d78);border-radius:inherit}.cm-progress strong{font-size:.78rem;color:#12364c;text-align:right}.cm-stage-note{max-width:34rem}.cm-clearance__empty{padding:1rem;color:#526672}.cm-nowrap{white-space:nowrap}
@media(max-width:700px){.cm-intake__fields,.cm-intake__modes,.cm-disclosure{grid-template-columns:1fr}.cm-intake__field--wide{grid-column:auto}}
@media(max-width:560px){.cm-stats{grid-template-columns:1fr 1fr}.cm-form,.cm-review{grid-template-columns:1fr}.cm-form .cm-field:first-child,.cm-review .cm-field:first-child{grid-column:auto}.cm-actions{width:100%}.cm-btn{flex:1}}
</style>~');

    add_line(l_html, '<details class="cm-intake"><summary class="cm-intake__head"><div><h2 id="cmIntakeTitle">Add or manage AFMA test footage</h2><p>Upload a short video, register a source URL, or review recent submissions and the data-handling notice.</p></div><span class="cm-intake__toggle">Expand</span></summary>');
    add_line(l_html, '<div class="cm-disclosure"><article><h3>Stored</h3><p>Uploaded bytes are copied into <strong>AFMA.AIDEMODB</strong> in OCI Sydney (<strong>ap-sydney-1</strong>). A URL submission stores the URL and description only. Records remain until an authorised deletion; a 30-day retention review is recorded, but automatic purge is not yet enabled.</p></article><article><h3>Processed</h3><p>No model call occurs at intake. When analysis is enabled, content is sent through OCI Generative AI in Chicago (<strong>us-chicago-1</strong>). Oracle documents Gemini 2.5 Pro as externally hosted by Google, with US calls processed in a Google Americas location.</p></article><article><h3>Data use</h3><p>Oracle states OCI Generative AI does not retain inference input/output. Google states customer data is not used to train or fine-tune models without permission; Vertex AI may use transient in-memory caching and contract-dependent abuse monitoring. Treat Google as a processing party.</p></article><article><h3>Exposure</h3><p>Content is available to authorised app/database users and, when analysis is started, the OCI-to-Google processing path. A linked video host may log access. Do not enter signed URLs, credentials, or uncleared personal, vessel or operational information.</p></article></div>');
    for p in (
      select prompt_contract_id, prompt_version, purpose_text, service_static_id, model_id,
             system_prompt, task_prompt_template, response_json_schema, contract_status,
             approved_at, approved_by, activated_at, activated_by
        from afma_cm_prompt_contracts
       where prompt_key = 'catch-monitor-metadata'
       order by created_at desc
       fetch first 1 row only
    ) loop
      add_line(l_html, '<details class="cm-prompt-review"' || case when p.contract_status <> 'ACTIVE' then ' open' end || '><summary>Prompt contract review · ' || h(p.prompt_version) || ' · <span class="cm-badge ' || badge_class(case when p.contract_status = 'ACTIVE' then 'CONFIRMED' else 'PENDING_REVIEW' end) || '">' || h(p.contract_status) || '</span></summary><div class="cm-prompt-review__body"><p>' || h(p.purpose_text) || '</p><p><strong>Model:</strong> ' || h(p.model_id) || ' · <strong>APEX service:</strong> ' || h(p.service_static_id) || ' · <strong>OCI entry:</strong> us-chicago-1 · <strong>processing:</strong> Google Americas</p><h3>Exact system prompt</h3><pre>' || h(dbms_lob.substr(p.system_prompt, 32767, 1)) || '</pre><h3>Exact task prompt</h3><pre>' || h(dbms_lob.substr(p.task_prompt_template, 32767, 1)) || '</pre><details><summary><strong>Exact JSON response schema</strong></summary><pre>' || h(dbms_lob.substr(p.response_json_schema, 32767, 1)) || '</pre></details><p><strong>Activation effect:</strong> enables an explicit Generate action for uploaded video metadata only. It does not analyse registered page URLs, create catch events, change reported data, publish a compliance finding, or process submissions automatically.</p>');
      if p.contract_status = 'ACTIVE' then
        add_line(l_html, '<p><span class="cm-badge cm-badge-ok">Approved and active</span> Approved by ' || h(p.approved_by) || ' at ' || h(to_char(p.approved_at, 'DD Mon YYYY HH24:MI')) || '; activated by ' || h(p.activated_by) || ' at ' || h(to_char(p.activated_at, 'DD Mon YYYY HH24:MI')) || '.</p>');
      else
        add_line(l_html, '<label class="cm-prompt-review__ack"><input type="checkbox" id="cmPromptAck"> <span>I have reviewed the exact system prompt, task prompt, JSON schema and activation effect above. I authorise this metadata-only contract for controlled internal testing.</span></label><button type="button" class="cm-btn cm-btn-primary" id="cmApproveMetadataPrompt" data-prompt-id="' || p.prompt_contract_id || '">Approve and activate metadata prompt</button>');
      end if;
      add_line(l_html, '</div></details>');
    end loop;
    add_line(l_html, '<div class="cm-intake__form"><div class="cm-intake__fields"><div class="cm-intake__field"><label for="P4_VIDEO_TITLE">Working title (optional)</label><div class="cm-native-slot" id="cmVideoTitleSlot"></div></div><div class="cm-intake__field"><label for="P4_VIDEO_DESCRIPTION">Reviewer notes (optional)</label><div class="cm-native-slot" id="cmVideoDescriptionSlot"></div></div></div><p class="cm-footnote">These are initial human notes, not required truths. After analysis, Gemini Pro can propose the title, description, region, fishery and fishing method; an AFMA reviewer can edit and confirm every field.</p><div class="cm-intake__modes"><article class="cm-intake__mode"><h3>Upload a video</h3><p>MP4, MPEG, MOV, AVI, WebM, WMV, 3GPP or FLV; maximum 35 MiB for the current direct-analysis path.</p><label for="P4_VIDEO_FILE">Video file</label><div class="cm-native-slot" id="cmVideoFileSlot"></div><div class="cm-actions"><button type="button" class="cm-btn cm-btn-primary" id="cmUploadVideo">Upload and process</button></div></article><article class="cm-intake__mode"><h3>Register a source URL</h3><p>Use an HTTPS video or video-page URL. Page URLs enter the project-import queue because APEX does not extract their video bytes.</p><label for="P4_VIDEO_URL">HTTPS video or video-page URL</label><div class="cm-native-slot" id="cmVideoUrlSlot"></div><div class="cm-actions"><button type="button" class="cm-btn cm-btn-primary" id="cmRegisterUrl">Register for import</button></div></article></div><div class="cm-intake__acks"><div class="cm-native-slot" id="cmRightsAckSlot"></div><div class="cm-native-slot" id="cmHandlingAckSlot"></div></div><div class="cm-intake__status"><strong>Workflow:</strong> uploads enter the analysis queue with their stored BLOB. Page URLs wait for this project to import authorised video bytes. A source is added to the scenario selector only after analysis, validation and CAAB matching reach <strong>Ready for review</strong>.</div><p class="cm-footnote"><a class="cm-link" href="https://docs.oracle.com/en-us/iaas/Content/generative-ai/data-handling.htm" target="_blank" rel="noopener">Oracle data handling</a> · <a class="cm-link" href="https://docs.oracle.com/en-us/iaas/Content/generative-ai/model-endpoint-regions.htm" target="_blank" rel="noopener">Oracle regional/external-call notes</a> · <a class="cm-link" href="https://docs.cloud.google.com/vertex-ai/generative-ai/docs/vertex-ai-zero-data-retention" target="_blank" rel="noopener">Google Vertex AI retention/training notes</a></p></div>');
    add_line(l_html, '<div class="cm-intake__ledger"><h3>Recent test submissions</h3><div class="cm-table-wrap"><table class="cm-table"><thead><tr><th>Submission</th><th>Input</th><th>Stored payload</th><th>Status</th><th>Retention review</th><th></th></tr></thead><tbody>');
    declare
      l_submission_rows number := 0;
    begin
      for v in (
        select submission_id,
               submission_ref,
               input_method,
               display_title,
               description_text,
               region_text,
               fishery_text,
               gear_method_text,
               ai_display_title,
               ai_description_text,
               ai_region_text,
               ai_fishery_text,
               ai_gear_method_text,
               ai_video_summary,
               ai_metadata_confidence,
               metadata_status,
               metadata_model_id,
               metadata_prompt_version,
               source_url,
               original_filename,
               file_bytes,
               processing_status,
               retention_review_at,
               created_at,
               created_by
          from afma_cm_video_submissions
         order by created_at desc
         fetch first 10 rows only
      ) loop
        l_submission_rows := l_submission_rows + 1;
        add_line(l_html, '<tr><td><strong>' || h(v.display_title) || '</strong><small>' || h(v.submission_ref) || ' · ' || h(to_char(v.created_at, 'DD Mon YYYY HH24:MI')) || ' · ' || h(v.created_by) || case when v.description_text is not null then '<br>' || h(v.description_text) end || '</small></td><td><span class="cm-badge cm-badge-neutral">' || h(v.input_method) || '</span></td><td>' ||
          case when v.processing_status = 'DELETED' then '<em>Payload cleared</em>'
               when v.input_method = 'UPLOAD' then h(v.original_filename) || '<small>' || h(to_char(v.file_bytes / 1048576, 'FM990D00')) || ' MiB in AIDEMODB</small>'
               else '<a class="cm-link" href="' || a(v.source_url) || '" target="_blank" rel="noopener">Open registered URL</a><small>URL metadata only</small>' end ||
          '</td><td><span class="cm-badge ' || badge_class(case when v.processing_status = 'DELETED' then 'REJECTED' when v.processing_status = 'READY_FOR_ANALYSIS' then 'CONFIRMED' else 'PENDING_REVIEW' end) || '">' ||
          h(case v.processing_status when 'AWAITING_PROMPT_APPROVAL' then 'Awaiting source approval' when 'AWAITING_IMPORT' then 'Awaiting project import' when 'READY_FOR_ANALYSIS' then 'Source approved' else replace(initcap(v.processing_status), '_', ' ') end) ||
          '</span><small>AI metadata: ' || h(case v.metadata_status when 'AWAITING_PROMPT_APPROVAL' then 'Not started' when 'NOT_REQUESTED' then 'Not requested' else replace(initcap(v.metadata_status), '_', ' ') end) || case when v.input_method = 'URL' and v.processing_status = 'AWAITING_IMPORT' then '<br>No video bytes stored; project import required' end || '</small></td><td>' || h(to_char(v.retention_review_at, 'DD Mon YYYY')) || '</td><td><div class="cm-actions">' || case when v.processing_status <> 'DELETED' then '<button type="button" class="cm-btn cm-btn-danger cm-delete-submission" data-submission-id="' || v.submission_id || '">Delete payload</button>' end || '</div></td></tr>');
        if v.processing_status <> 'DELETED' then
          add_line(l_html, '<tr class="cm-metadata-row"><td colspan="6"><details class="cm-metadata" data-submission-id="' || v.submission_id || '"><summary>AI-proposed and reviewer-approved video metadata · ' || h(v.metadata_status) || '</summary><div class="cm-metadata__body"><div class="cm-metadata__fields"><div class="cm-field cm-field--wide"><label>Reviewer-approved title</label><input class="cm-meta-title" type="text" maxlength="500" value="' || a(v.display_title) || '"></div><div class="cm-field cm-field--wide"><label>Reviewer-approved description</label><textarea class="cm-meta-description" maxlength="2000">' || h(v.description_text) || '</textarea></div><div class="cm-field"><label>Region / location</label><input class="cm-meta-region" type="text" maxlength="500" value="' || a(v.region_text) || '"></div><div class="cm-field"><label>Fishery / activity</label><input class="cm-meta-fishery" type="text" maxlength="500" value="' || a(v.fishery_text) || '"></div><div class="cm-field cm-field--wide"><label>Fishing method / gear</label><input class="cm-meta-gear" type="text" maxlength="500" value="' || a(v.gear_method_text) || '"></div><div class="cm-actions cm-field--wide"><button type="button" class="cm-btn cm-btn-primary cm-save-metadata">Save reviewer metadata</button>' ||
            case
              when v.input_method = 'UPLOAD' and v.processing_status = 'READY_FOR_ANALYSIS' and l_metadata_prompt_active_count > 0 then '<button type="button" class="cm-btn cm-request-metadata">Generate with Gemini Pro</button>'
              when v.input_method = 'URL' then '<button type="button" class="cm-btn" disabled title="APEX attachments require video bytes; upload the file for analysis">Upload required for AI metadata</button>'
              when v.processing_status = 'AWAITING_PROMPT_APPROVAL' then '<button type="button" class="cm-btn" disabled title="Approve this submission before any model call">Approve submission before AI metadata</button>'
              else '<button type="button" class="cm-btn" disabled title="Review and approve the metadata prompt contract above">Awaiting prompt approval</button>'
            end ||
            '</div></div><aside class="cm-metadata__proposal"><h4>Gemini Pro proposal</h4>' ||
            case when v.ai_display_title is null then '<p><strong>Not generated.</strong> ' || case when v.input_method = 'URL' then 'This registered page URL is metadata-only in the current APEX path; upload the video file to send its bytes to Gemini Pro.' else 'Approve the prompt contract above, then explicitly generate a proposal.' end || '</p>'
                 else '<p><strong>' || h(v.ai_display_title) || '</strong></p><p>' || h(v.ai_description_text) || '</p><p><strong>Region:</strong> ' || h(v.ai_region_text) || '<br><strong>Fishery:</strong> ' || h(v.ai_fishery_text) || '<br><strong>Method:</strong> ' || h(v.ai_gear_method_text) || '</p><p><strong>Confidence:</strong> ' || h(to_char(v.ai_metadata_confidence * 100, 'FM990')) || '% · ' || h(v.metadata_model_id) || ' · ' || h(v.metadata_prompt_version) || '</p><p>' || h(v.ai_video_summary) || '</p><button type="button" class="cm-btn cm-apply-ai-metadata" data-title="' || a(v.ai_display_title) || '" data-description="' || a(v.ai_description_text) || '" data-region="' || a(v.ai_region_text) || '" data-fishery="' || a(v.ai_fishery_text) || '" data-gear="' || a(v.ai_gear_method_text) || '">Use proposal in editable fields</button>' end ||
            '</aside></div></details></td></tr>');
        end if;
      end loop;
      if l_submission_rows = 0 then
        add_line(l_html, '<tr><td colspan="6"><strong>No AFMA test footage has been submitted yet.</strong><small>Use either intake path above; the supplied video library remains available below.</small></td></tr>');
      end if;
    end;
    add_line(l_html, '</tbody></table></div></div></details>');

    add_line(l_html, '<section class="cm-clearance"><div class="cm-clearance__head"><div><h2>Video processing &amp; clearance</h2><p>Registered sources remain here until media import, Gemini analysis, CAAB matching and deterministic checks are complete. Only cleared results appear in the scenario selector.</p></div><button type="button" class="cm-btn" id="cmRefreshClearance">Refresh progress</button></div><div class="cm-table-wrap"><table class="cm-table"><thead><tr><th>Source</th><th>Current stage</th><th>Progress</th><th>Proposed events</th><th>Last update</th></tr></thead><tbody>');
    declare
      l_clearance_rows number := 0;
    begin
      for q in (
        select vs.submission_ref,
               vs.display_title,
               vs.input_method,
               vs.source_url,
               vs.processing_status,
               vs.processing_stage,
               vs.progress_percent,
               vs.processing_message,
               vs.last_progress_at,
               (select count(*) from afma_cm_observations o where o.analysis_run_id = vs.analysis_run_id) proposed_events
          from afma_cm_video_submissions vs
         where vs.processing_status <> 'DELETED'
         order by case when vs.processing_status = 'ANALYSIS_COMPLETE' then 1 else 0 end,
                  vs.created_at desc
         fetch first 20 rows only
      ) loop
        l_clearance_rows := l_clearance_rows + 1;
        add_line(l_html, '<tr><td><strong>' || h(q.display_title) || '</strong><small>' || h(q.submission_ref) || ' · ' || h(q.input_method) || case when q.source_url is not null then ' · <a class="cm-link" href="' || a(q.source_url) || '" target="_blank" rel="noopener">Open source</a>' end || '</small></td><td><span class="cm-badge ' || badge_class(case when q.processing_status = 'ANALYSIS_COMPLETE' then 'CONFIRMED' when q.processing_status = 'ANALYSIS_FAILED' then 'REJECTED' else 'PENDING_REVIEW' end) || '">' || h(case q.processing_stage when 'AWAITING_PROJECT_IMPORT' then 'Awaiting project import' when 'QUEUED_FOR_ANALYSIS' then 'Queued for analysis' when 'READY_FOR_REVIEW' then 'Ready for review' else replace(initcap(q.processing_stage), '_', ' ') end) || '</span><small class="cm-stage-note">' || h(q.processing_message) || '</small></td><td><div class="cm-progress" role="progressbar" aria-valuemin="0" aria-valuemax="100" aria-valuenow="' || h(to_char(q.progress_percent)) || '"><span class="cm-progress__track"><span class="cm-progress__fill" style="width:' || h(to_char(q.progress_percent)) || '%"></span></span><strong>' || h(to_char(q.progress_percent)) || '%</strong></div></td><td>' || h(to_char(q.proposed_events)) || '<small>Not reviewable until cleared</small></td><td class="cm-nowrap">' || h(to_char(coalesce(q.last_progress_at, systimestamp), 'DD Mon HH24:MI')) || '</td></tr>');
      end loop;
      if l_clearance_rows = 0 then
        add_line(l_html, '<tr><td colspan="5" class="cm-clearance__empty">No submitted videos are waiting for processing.</td></tr>');
      end if;
    end;
    add_line(l_html, '</tbody></table></div></section>');

    add_line(l_html, '<section class="cm-selector"><div><label for="cmScenario">Video scenario</label><select id="cmScenario">');
    for s in (
      select t.trip_ref, t.fishery_name, t.region_name
        from afma_cm_trips t
       where exists (
         select 1 from afma_cm_media_assets m
          where m.trip_id = t.trip_id and m.asset_role = 'SOURCE_VIDEO'
       )
         and t.status <> 'ARCHIVED'
         and not exists (
           select 1
             from afma_cm_video_submissions vs
             join afma_cm_analysis_runs sr on sr.analysis_run_id = vs.analysis_run_id
            where sr.trip_id = t.trip_id
              and (vs.processing_status <> 'ANALYSIS_COMPLETE'
                   or coalesce(vs.processing_stage, '~') <> 'READY_FOR_REVIEW')
         )
       order by case
                  when t.trip_ref = l_requested_ref then 0
                  when t.trip_ref = 'CM-QLD-002' then 1
                  when t.trip_ref = 'CM-QLD-003' then 2
                  when t.trip_ref = 'CM-QLD-004' then 3
                  when t.trip_ref = 'CM-WA-001' then 4
                  when t.trip_ref = 'CM-QLD-001' then 5
                  when substr(t.trip_ref, 1, 7) = 'CM-SUB-' then 6
                  else 9
                end,
                t.created_at desc
    ) loop
      add_line(l_html, '<option value="' || a(s.trip_ref) || '" data-url="' || a(apex_page.get_url(p_page => 4, p_request => 'SCENARIO-' || s.trip_ref)) || '"' || case when s.trip_ref = l_trip.trip_ref then ' selected' end || '>' || h(s.fishery_name) || ' — ' || h(s.region_name) || '</option>');
    end loop;
    add_line(l_html, '</select></div><div><h2>What this footage shows</h2><p>' || h(l_trip.notes) || '</p><div class="cm-selector__meta"><span class="cm-badge cm-badge-neutral">' || h(l_annotation_status) || '</span><span class="cm-badge cm-badge-neutral">' || h(l_trip.region_name) || '</span><span class="cm-badge cm-badge-neutral">' || h(l_trip.gear_method) || '</span></div></div></section>');

    add_line(l_html, '<section class="cm-hero"><div class="cm-hero__top"><div><div class="cm-kicker">Authorised AFMA reviewer workspace</div><h1>Catch Monitor · ' || h(l_trip.trip_ref) || '</h1><p>' || h(l_trip.fishery_name) || ' · ' || h(l_trip.gear_method) || ' · ' || h(l_trip.region_name) || '</p></div><span class="cm-demo">DEMO DATA · ' || h(l_trip.source_type) || '</span></div>');
    add_line(l_html, '<div class="cm-stats"><div class="cm-stat"><span>Reported version</span><strong>v' || l_version_no || '</strong></div><div class="cm-stat"><span>Reported catch lines</span><strong>' || l_reported_count || '</strong></div><div class="cm-stat"><span>Evidence events</span><strong>' || l_video_count || '</strong></div><div class="cm-stat"><span>Needs review</span><strong>' || l_open_count || '</strong></div></div></section>');

    add_line(l_html, '<div class="cm-alert"><span aria-hidden="true">&#9888;</span><div><strong>AI-assisted review — reviewer confirmation required</strong><p>This demonstration proposes evidence events; it does not make a compliance finding, alter a logbook/e-log, or infer quota, legal size, weight or post-release condition from video.</p></div></div>');

    add_line(l_html, '<div class="cm-grid"><section class="cm-card"><div class="cm-card__head"><div><h2>Source video &amp; evidence timeline</h2><p>' || h(l_media_title) || ' · ' || h(l_media_source) || case when l_duration_seconds is not null then ' · ' || h(to_char(l_duration_seconds)) || ' seconds' end || '</p></div><span class="cm-badge cm-badge-warn">Internal demo source</span></div><div class="cm-card__body">');
    if l_embed_url is null then
      add_line(l_html, '<div class="cm-video-placeholder"><div><strong>Video analysis has not started</strong><p>The source is registered and selectable, but no video was fetched and no evidence events were created.</p>' || case when lower(l_source_url) like 'https://%' then '<a class="cm-btn cm-btn-primary" href="' || a(l_source_url) || '" target="_blank" rel="noopener">Open registered source</a>' end || '</div></div>');
    elsif lower(l_embed_url) like '%.mp4%' then
      add_line(l_html, '<video class="cm-video" src="' || a(l_embed_url) || '" title="' || a(l_media_title) || '" controls preload="metadata" playsinline></video>');
    else
      add_line(l_html, '<iframe class="cm-video" src="' || a(l_embed_url) || '" title="' || a(l_media_title) || '" loading="lazy" allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture" allowfullscreen></iframe>');
    end if;
    add_line(l_html, '<div class="cm-meta"><span class="cm-badge cm-badge-neutral">' || h(l_annotation_status) || '</span><span class="cm-badge cm-badge-neutral">' || h(l_model_version) || '</span><span class="cm-badge cm-badge-neutral">Manifest ' || h(l_manifest) || '</span>' || case when lower(l_source_url) like 'https://%' then '<a class="cm-link" href="' || a(l_source_url) || '" target="_blank" rel="noopener">Open original source</a>' end || '</div>');
    add_line(l_html, '<p class="cm-footnote"><strong>Evidence status:</strong> ' || h(l_run_notes) || '</p></div></section>');

    add_line(l_html, '<section class="cm-card"><div class="cm-card__head"><div><h2>Review queue</h2><p>Confirm, correct, reject or escalate each proposed event.</p></div><span class="cm-badge ' || badge_class(case when l_open_count = 0 then 'CONFIRMED' else 'NEEDS_REVIEW' end) || '">' || l_open_count || ' unresolved</span></div><div class="cm-card__body"><div class="cm-events">');
    if l_video_count = 0 then
      add_line(l_html, '<div class="cm-alert"><span aria-hidden="true">&#9432;</span><div><strong>No evidence events published</strong><p>' || case when l_model_version = 'analysis-not-started' then 'This submitted source is ready for reviewer setup, but no model call has been started. Add normal reported inputs now; upload or otherwise make the video bytes available before analysis.' else 'This candidate remains selectable for playback and assessment, but its review queue stays empty until time-coded ground truth is approved.' end || '</p></div></div>');
    end if;
    for o in (
      select o.*,
             coalesce(t.common_name, t.scientific_name, o.ai_taxon_text, 'Unresolved') display_name,
             t.scientific_name,
             t.spcode taxon_spcode
        from afma_cm_observations o
        left join csiro_caab_taxa t on t.spcode = coalesce(o.reviewed_spcode, o.ai_spcode)
       where o.analysis_run_id = l_run_id
       order by o.start_second, o.observation_id
    ) loop
      add_line(l_html, '<article class="cm-event ' || case when o.observation_type = 'WILDLIFE' then 'cm-event-wildlife' end || '" data-observation-id="' || o.observation_id || '"><div class="cm-event__top"><div><h3>' || fmt_range(o.start_second, o.end_second) || ' · ' || h(replace(initcap(o.observation_type), '_', ' ')) || ' · ' || h(o.display_name) || '</h3><div><span class="cm-spcode">' || h(coalesce(o.taxon_spcode, 'CAAB unresolved')) || '</span> · confidence ' || to_char(o.ai_confidence * 100, 'FM990') || '% · proposed count ' || h(to_char(o.ai_count)) || '</div></div><span class="cm-badge ' || badge_class(o.reviewer_status) || '">' || h(o.reviewer_status) || '</span></div>');
      if o.evidence_role = 'PREVIEW_OR_REPLAY' or o.evidence_group_ref is not null then
        add_line(l_html, '<div class="cm-meta">' ||
          case when o.evidence_role = 'PREVIEW_OR_REPLAY' then '<span class="cm-badge cm-badge-warn">Edited preview / possible duplicate</span>' end ||
          case when o.evidence_group_ref is not null then '<span class="cm-badge cm-badge-neutral">Evidence group ' || h(o.evidence_group_ref) || '</span>' end ||
          '</div>');
      end if;
      add_line(l_html, '<p>' || h(o.evidence_text) || '</p>');
      if o.reviewed_by is not null then
        add_line(l_html, '<p><strong>Reviewer:</strong> ' || h(o.reviewed_by) || ' · ' || h(o.reviewed_interaction_class) || case when o.reviewer_notes is not null then ' · ' || h(o.reviewer_notes) end || '</p>');
      end if;
      add_line(l_html, '<div class="cm-review"><div class="cm-field"><label>Reviewed CAAB identity</label><select class="cm-review-spcode"><option value="">Unresolved / higher taxon</option>');
      for s in (
        select distinct t.spcode,
               coalesce(t.common_name, t.scientific_name) display_name,
               t.scientific_name
          from csiro_caab_taxa t
         where t.spcode = o.ai_spcode
            or t.spcode in (
              select rc.spcode
                from afma_cm_reported_catch rc
                join afma_cm_operations op on op.operation_id = rc.operation_id
               where op.report_version_id = l_report_id
                 and rc.spcode is not null
            )
         order by display_name
      ) loop
        add_line(l_html, '<option value="' || a(s.spcode) || '"' || case when s.spcode = coalesce(o.reviewed_spcode, o.ai_spcode) then ' selected' end || '>' || h(s.display_name) || ' — ' || h(s.spcode) || '</option>');
      end loop;
      add_line(l_html, '</select></div><div class="cm-field"><label>Count</label><input class="cm-review-count" type="number" min="0" value="' || a(to_char(coalesce(o.reviewed_count, o.ai_count))) || '"></div><div class="cm-field"><label>Interaction classification</label><select class="cm-review-interaction">');
      for c in (
        select 'NOT_APPLICABLE' value_name, 'Not applicable' display_name, 1 seq from dual union all
        select 'SIGHTING', 'Wildlife sighting', 2 from dual union all
        select 'POSSIBLE_INTERACTION', 'Possible interaction', 3 from dual union all
        select 'CONFIRMED_INTERACTION', 'Confirmed interaction', 4 from dual union all
        select 'INCONCLUSIVE', 'Inconclusive', 5 from dual
        order by seq
      ) loop
        add_line(l_html, '<option value="' || c.value_name || '"' || case when c.value_name = coalesce(o.reviewed_interaction_class, o.ai_interaction_class) then ' selected' end || '>' || c.display_name || '</option>');
      end loop;
      add_line(l_html, '</select></div><div class="cm-actions"><button class="cm-btn cm-btn-primary cm-review-action" data-decision="CONFIRMED">Confirm</button><button class="cm-btn cm-review-action" data-decision="CORRECTED">Correct</button><button class="cm-btn cm-btn-danger cm-review-action" data-decision="REJECTED">Reject</button><button class="cm-btn cm-review-action" data-decision="ESCALATED">Escalate</button></div></div></article>');
    end loop;
    add_line(l_html, '</div></div></section></div>');

    add_line(l_html, '<section class="cm-card"><div class="cm-card__head"><div><h2>Reported Data</h2><p>Normal fisher-input fields recorded by a demo operator for comparison; this is not a fisher portal.</p></div><div class="cm-actions"><span class="cm-badge ' || badge_class(l_report_status) || '">' || h(l_report_status) || ' · v' || l_version_no || '</span>');
    if l_editable then
      add_line(l_html, '<button class="cm-btn cm-btn-primary" id="cmFreeze">Freeze for review</button>');
    else
      add_line(l_html, '<button class="cm-btn" id="cmAmend">Create amendment</button>');
    end if;
    add_line(l_html, '</div></div><div class="cm-table-wrap"><table class="cm-table"><thead><tr><th>Reported species / CAAB mapping</th><th>Count</th><th>Weight</th><th>State</th><th>Notes</th></tr></thead><tbody>');
    for r in (
      select rc.*,
             t.scientific_name,
             t.common_name
        from afma_cm_reported_catch rc
        join afma_cm_operations op on op.operation_id = rc.operation_id
        left join csiro_caab_taxa t on t.spcode = rc.spcode
       where op.report_version_id = l_report_id
       order by rc.reported_catch_id
    ) loop
      add_line(l_html, '<tr><td><strong>' || h(r.original_taxon_text) || '</strong><small>' || h(coalesce(r.common_name, r.scientific_name, 'No CAAB match')) || ' · <span class="cm-spcode">' || h(coalesce(r.spcode, r.mapping_status)) || '</span></small></td><td>' || h(to_char(r.reported_count)) || '</td><td>' || case when r.reported_weight_kg is null then '—' else h(to_char(r.reported_weight_kg, 'FM999G990D0')) || ' kg' end || '</td><td>' || h(replace(initcap(r.catch_state), '_', ' ')) || '</td><td>' || h(r.notes) || '</td></tr>');
    end loop;
    add_line(l_html, '</tbody></table></div>');
    if l_editable then
      add_line(l_html, '<div class="cm-card__body"><div class="cm-form"><div class="cm-field"><label for="cmTaxonText">Reported species / taxon text</label><input id="cmTaxonText" type="text" placeholder="e.g. Common coral trout"></div><div class="cm-field"><label for="cmCount">Count</label><input id="cmCount" type="number" min="0"></div><div class="cm-field"><label for="cmWeight">Weight kg</label><input id="cmWeight" type="number" min="0" step="0.1"></div><div class="cm-field"><label for="cmState">State</label><select id="cmState"><option value="RETAINED">Retained</option><option value="DISCARDED_ALIVE">Discarded alive</option><option value="DISCARDED_DEAD">Discarded dead</option><option value="UNKNOWN">Unknown</option></select></div><button class="cm-btn cm-btn-primary" id="cmAddCatch">Add reported line</button></div></div>');
    else
      add_line(l_html, '<div class="cm-card__body"><p class="cm-footnote">This comparison version is immutable. Use <strong>Create amendment</strong> to copy it into a new editable version; the frozen source remains unchanged.</p></div>');
    end if;
    add_line(l_html, '</section>');

    add_line(l_html, '<section class="cm-card"><div class="cm-card__head"><div><h2>Reported wildlife interactions</h2><p>Protected-species or wildlife interaction fields supplied in the comparison record.</p></div></div><div class="cm-table-wrap"><table class="cm-table"><thead><tr><th>Reported wildlife / CAAB mapping</th><th>Count</th><th>Interaction</th><th>Notes</th></tr></thead><tbody>');
    declare
      l_interaction_rows number := 0;
    begin
      for i in (
        select ri.*, coalesce(t.common_name, t.scientific_name, ri.original_taxon_text) display_name
          from afma_cm_reported_interactions ri
          join afma_cm_operations op on op.operation_id = ri.operation_id
          left join csiro_caab_taxa t on t.spcode = ri.spcode
         where op.report_version_id = l_report_id
         order by ri.reported_interaction_id
      ) loop
        l_interaction_rows := l_interaction_rows + 1;
        add_line(l_html, '<tr><td><strong>' || h(i.original_taxon_text) || '</strong><small>' || h(i.display_name) || ' · <span class="cm-spcode">' || h(coalesce(i.spcode, 'UNRESOLVED')) || '</span></small></td><td>' || h(to_char(i.reported_count)) || '</td><td>' || h(coalesce(i.interaction_kind, 'Not supplied')) || '</td><td>' || h(i.notes) || '</td></tr>');
      end loop;
      if l_interaction_rows = 0 then
        add_line(l_html, '<tr><td colspan="4"><strong>None reported in the supplied comparison data.</strong><small>This is an explicit absence in the demo record, not proof that no interaction occurred.</small></td></tr>');
      end if;
    end;
    add_line(l_html, '</tbody></table></div>');
    if l_editable then
      add_line(l_html, '<div class="cm-card__body"><div class="cm-form"><div class="cm-field"><label for="cmInteractionTaxon">Reported wildlife / taxon text</label><input id="cmInteractionTaxon" type="text" placeholder="e.g. Marine turtle"></div><div class="cm-field"><label for="cmInteractionCount">Count</label><input id="cmInteractionCount" type="number" min="0"></div><div class="cm-field"><label for="cmInteractionKind">Interaction</label><select id="cmInteractionKind"><option value="SIGHTING">Sighting</option><option value="POSSIBLE_INTERACTION">Possible interaction</option><option value="CONFIRMED_INTERACTION">Confirmed interaction</option><option value="INCONCLUSIVE">Inconclusive</option></select></div><div></div><button class="cm-btn cm-btn-primary" id="cmAddInteraction">Add interaction</button></div></div>');
    end if;
    add_line(l_html, '</section>');

    add_line(l_html, '<section class="cm-card"><div class="cm-card__head"><div><h2>Reconciliation</h2><p>Frozen reported information remains unchanged; video totals use confirmed/corrected results where available.</p></div><button class="cm-btn cm-btn-primary" id="cmComplete"' || case when l_open_count > 0 then ' disabled title="Review every observation first"' end || '>Complete review</button></div><div class="cm-table-wrap"><table class="cm-table"><thead><tr><th>CAAB identity</th><th>Reported</th><th>Video</th><th>Outcome</th><th>Reviewer basis</th></tr></thead><tbody>');
    for r in (
      select rc.reported_catch_id,
             rc.spcode,
             rc.original_taxon_text,
             coalesce(t.common_name, t.scientific_name, rc.original_taxon_text) display_name,
             t.scientific_name,
             rc.reported_count
        from afma_cm_reported_catch rc
        join afma_cm_operations op on op.operation_id = rc.operation_id
        left join csiro_caab_taxa t on t.spcode = rc.spcode
       where op.report_version_id = l_report_id
       order by display_name
    ) loop
      select sum(case when o.reviewer_status = 'REJECTED' then 0 else coalesce(o.reviewed_count, o.ai_count, 0) end)
        into l_video_count
        from afma_cm_observations o
       where o.analysis_run_id = l_run_id
         and o.observation_type = 'CATCH'
         and coalesce(o.reviewed_spcode, o.ai_spcode, '~') = coalesce(r.spcode, '~');
      if l_open_count > 0 then
        l_outcome := 'PENDING_REVIEW';
      elsif l_video_count is null then
        l_outcome := 'REPORTED_NOT_OBSERVED';
      elsif l_video_count = r.reported_count then
        l_outcome := 'MATCH';
      elsif l_video_count > r.reported_count then
        l_outcome := 'VIDEO_HIGHER';
      else
        l_outcome := 'REPORTED_HIGHER';
      end if;
      add_line(l_html, '<tr><td><strong>' || h(r.display_name) || '</strong><small>' || h(r.scientific_name) || ' · <span class="cm-spcode">' || h(coalesce(r.spcode, 'UNRESOLVED')) || '</span></small></td><td>' || h(to_char(r.reported_count)) || '</td><td>' || h(coalesce(to_char(l_video_count), '—')) || '</td><td><span class="cm-badge ' || badge_class(l_outcome) || '">' || h(l_outcome) || '</span></td><td>' || case when l_open_count > 0 then 'Awaiting officer decisions' else 'Officer-reviewed evidence' end || '</td></tr>');
    end loop;
    add_line(l_html, '</tbody></table></div></section>');

    add_line(l_html, '<section><div class="cm-section-title"><h2>CAAB-linked media library</h2><div><span class="cm-badge cm-badge-neutral">' || l_asset_count || ' assets</span> <span class="cm-badge ' || badge_class(case when l_gap_count > 0 then 'MEDIA_GAP' else 'COVERED' end) || '">' || l_gap_count || ' gaps</span></div></div><div class="cm-media-grid">');
    for m in (
      select m.*,
             coalesce(t.common_name, t.scientific_name, m.original_taxon_text, 'General guidance') taxon_name,
             t.scientific_name
        from afma_cm_media_assets m
        left join csiro_caab_taxa t on t.spcode = m.spcode
       where m.trip_id = l_trip_id
       order by case m.asset_role when 'SOURCE_VIDEO' then 1 when 'REFERENCE_DISPLAY' then 2 else 3 end,
                m.media_asset_id
    ) loop
      add_line(l_html, '<article class="cm-media"><span class="cm-badge ' || badge_class(m.rights_status) || '">' || h(m.rights_status) || '</span><h3>' || h(m.title) || '</h3><p><strong>' || h(m.taxon_name) || '</strong>' || case when m.spcode is not null then ' · <span class="cm-spcode">' || h(m.spcode) || '</span>' end || '</p><p>' || h(m.approved_purposes) || '</p><p>' || h(m.restrictions) || '</p>' || case when lower(m.source_record_url) like 'https://%' then '<a class="cm-link" href="' || a(m.source_record_url) || '" target="_blank" rel="noopener">Open source record</a>' end || '</article>');
    end loop;
    add_line(l_html, '</div><p class="cm-footnote">Hybrid incremental population: CAAB taxonomy remains complete, while approved visual assets are added for the selected fishery and expanded only when new footage introduces a media gap or ambiguous taxon.</p></section>');

    add_line(l_html, '<section><div class="cm-section-title"><h2>Reviewer guidance</h2></div><div class="cm-guidance"><a href="https://www.afma.gov.au/fisheries-management/monitoring-tools/electronic-monitoring-program" target="_blank" rel="noopener">Electronic monitoring program<small>AFMA · program and in-house footage review context</small></a><a href="https://www.afma.gov.au/logbooks-and-elogs" target="_blank" rel="noopener">Logbooks and e-logs<small>AFMA · existing reporting obligations remain unchanged</small></a><a href="https://www.afma.gov.au/protected-species/endangered-and-threatened-species-reporting" target="_blank" rel="noopener">Protected-species reporting<small>AFMA · confirm physical contact and applicable fields</small></a></div></section>');

    add_line(l_html, q'~<script>
(function(){
  var shell=document.getElementById("cmShell"); if(!shell){return;} var trip=shell.getAttribute("data-trip-id");
  function val(id){var item=(globalThis.apex&&apex.item)?apex.item(id):null;if(item&&item.node){return item.getValue();}var el=document.getElementById(id);return el?el.value:"";}
  function reloadCommitted(){if(apex.page&&apex.page.cancelWarnOnUnsavedChanges){apex.page.cancelWarnOnUnsavedChanges();}window.location.reload();}
  function run(action,args){shell.classList.add("cm-loading");var payload={x01:action,x02:trip};Object.keys(args||{}).forEach(function(k){payload[k]=args[k];});apex.server.process("AFMA_CM_ACTION",payload,{dataType:"json"}).then(function(r){if(!r||!r.success){throw new Error((r&&r.message)||"Action failed");}reloadCommitted();}).catch(function(e){shell.classList.remove("cm-loading");apex.message.alert(e&&e.message?e.message:String(e));});}
  function runIntake(action,args){shell.classList.add("cm-loading");var payload={x01:action};Object.keys(args||{}).forEach(function(k){payload[k]=args[k];});apex.server.process("AFMA_CM_INTAKE_ACTION",payload,{dataType:"json"}).then(function(r){if(!r||!r.success){throw new Error((r&&r.message)||"Intake action failed");}reloadCommitted();}).catch(function(e){shell.classList.remove("cm-loading");apex.message.alert(e&&e.message?e.message:String(e));});}
  function runMetadata(args){shell.classList.add("cm-loading");apex.server.process("AFMA_CM_METADATA_ACTION",args,{dataType:"json"}).then(function(r){if(!r||!r.success){throw new Error((r&&r.message)||"Metadata action failed");}reloadCommitted();}).catch(function(e){shell.classList.remove("cm-loading");apex.message.alert(e&&e.message?e.message:String(e));});}
  function runPrompt(args){shell.classList.add("cm-loading");apex.server.process("AFMA_CM_PROMPT_ACTION",args,{dataType:"json"}).then(function(r){if(!r||!r.success){throw new Error((r&&r.message)||"Prompt action failed");}reloadCommitted();}).catch(function(e){shell.classList.remove("cm-loading");apex.message.alert(e&&e.message?e.message:String(e));});}
  function moveItem(itemId,slotId){var container=document.getElementById(itemId+"_CONTAINER"),slot=document.getElementById(slotId);if(container&&slot&&container.parentNode!==slot){slot.appendChild(container);}}
  function placeIntakeItems(){moveItem("P4_VIDEO_TITLE","cmVideoTitleSlot");moveItem("P4_VIDEO_DESCRIPTION","cmVideoDescriptionSlot");moveItem("P4_VIDEO_URL","cmVideoUrlSlot");moveItem("P4_VIDEO_FILE","cmVideoFileSlot");moveItem("P4_RIGHTS_ACK","cmRightsAckSlot");moveItem("P4_HANDLING_ACK","cmHandlingAckSlot");}
  placeIntakeItems();setTimeout(placeIntakeItems,50);setTimeout(placeIntakeItems,500);
  var intake=shell.querySelector(".cm-intake"),intakeToggle=intake&&intake.querySelector(".cm-intake__toggle");function setIntakeToggle(){if(intakeToggle){intakeToggle.textContent=intake.open?"Collapse":"Expand";}}if(intake){intake.addEventListener("toggle",setIntakeToggle);setIntakeToggle();}
  var refreshClearance=document.getElementById("cmRefreshClearance");if(refreshClearance){refreshClearance.addEventListener("click",reloadCommitted);}
  var registerUrl=document.getElementById("cmRegisterUrl");if(registerUrl){registerUrl.addEventListener("click",function(){var title=val("P4_VIDEO_TITLE").trim(),url=val("P4_VIDEO_URL").trim();if(!url){apex.message.alert("Enter an HTTPS video or video-page URL.");return;}runIntake("STAGE_URL",{x02:title,x03:url,x04:val("P4_VIDEO_DESCRIPTION"),x05:val("P4_RIGHTS_ACK"),x06:val("P4_HANDLING_ACK")});});}
  var uploadVideo=document.getElementById("cmUploadVideo");if(uploadVideo){uploadVideo.addEventListener("click",function(){if(!val("P4_VIDEO_FILE")){apex.message.alert("Choose a video file.");return;}if(val("P4_RIGHTS_ACK")!=="Y"||val("P4_HANDLING_ACK")!=="Y"){apex.message.alert("Confirm both authority and data-handling acknowledgements.");return;}var form=document.getElementById("wwvFlowForm");if(form){form.enctype="multipart/form-data";}apex.page.submit({request:"STAGE_UPLOAD",showWait:true});});}
  shell.querySelectorAll(".cm-delete-submission").forEach(function(button){button.addEventListener("click",function(){apex.message.confirm("Delete the stored video or URL payload? Audit metadata will remain.",function(ok){if(ok){runIntake("DELETE_SUBMISSION",{x02:button.getAttribute("data-submission-id")});}});});});
  shell.querySelectorAll(".cm-save-metadata").forEach(function(button){button.addEventListener("click",function(){var form=button.closest(".cm-metadata"),title=form.querySelector(".cm-meta-title").value.trim();if(!title){apex.message.alert("Enter a reviewer-approved title.");return;}runMetadata({x01:"SAVE_METADATA",x02:form.getAttribute("data-submission-id"),x03:title,x04:form.querySelector(".cm-meta-description").value,x05:form.querySelector(".cm-meta-region").value,x06:form.querySelector(".cm-meta-fishery").value,x07:form.querySelector(".cm-meta-gear").value});});});
  var approvePrompt=document.getElementById("cmApproveMetadataPrompt");if(approvePrompt){approvePrompt.addEventListener("click",function(){if(!document.getElementById("cmPromptAck").checked){apex.message.alert("Review the complete prompt contract and tick the approval acknowledgement first.");return;}apex.message.confirm("Approve and activate this metadata-only prompt for controlled internal testing? No videos will be processed automatically.",function(ok){if(ok){runPrompt({x01:"APPROVE",x02:approvePrompt.getAttribute("data-prompt-id"),x03:"Y"});}});});}
  shell.querySelectorAll(".cm-request-metadata").forEach(function(button){button.addEventListener("click",function(){var form=button.closest(".cm-metadata");apex.message.confirm("Send this uploaded video to Gemini Pro using the approved metadata prompt?",function(ok){if(ok){runPrompt({x01:"RUN_METADATA",x02:form.getAttribute("data-submission-id")});}});});});
  shell.querySelectorAll(".cm-apply-ai-metadata").forEach(function(button){button.addEventListener("click",function(){var form=button.closest(".cm-metadata");form.querySelector(".cm-meta-title").value=button.dataset.title||"";form.querySelector(".cm-meta-description").value=button.dataset.description||"";form.querySelector(".cm-meta-region").value=button.dataset.region||"";form.querySelector(".cm-meta-fishery").value=button.dataset.fishery||"";form.querySelector(".cm-meta-gear").value=button.dataset.gear||"";});});
  var scenario=document.getElementById("cmScenario");if(scenario){scenario.addEventListener("change",function(){var url=scenario.options[scenario.selectedIndex].getAttribute("data-url");if(url){window.location.href=new URL(url,document.baseURI).href;}});}
  var add=document.getElementById("cmAddCatch");if(add){add.addEventListener("click",function(){var taxon=val("cmTaxonText").trim();if(!taxon){apex.message.alert("Enter the reported species or taxon text.");return;}run("ADD_CATCH",{x03:taxon,x04:val("cmCount"),x05:val("cmWeight"),x06:val("cmState")});});}
  var addInteraction=document.getElementById("cmAddInteraction");if(addInteraction){addInteraction.addEventListener("click",function(){var taxon=val("cmInteractionTaxon").trim();if(!taxon){apex.message.alert("Enter the reported wildlife or taxon text.");return;}run("ADD_CATCH",{x03:taxon,x04:val("cmInteractionCount"),x05:"",x06:"INTERACTION:"+val("cmInteractionKind")});});}
  var freeze=document.getElementById("cmFreeze");if(freeze){freeze.addEventListener("click",function(){apex.message.confirm("Freeze this version for video review? It will become immutable.",function(ok){if(ok){run("FREEZE",{});}});});}
  var amend=document.getElementById("cmAmend");if(amend){amend.addEventListener("click",function(){var reason=window.prompt("Reason for creating an amended reported-data version:","Correct synthetic comparison data");if(reason){run("AMEND",{x03:reason});}});}
  shell.querySelectorAll(".cm-review-action").forEach(function(button){button.addEventListener("click",function(){var card=button.closest(".cm-event"),decision=button.getAttribute("data-decision"),note=window.prompt("Reviewer note (optional):","");run("REVIEW",{x03:card.getAttribute("data-observation-id"),x04:decision,x05:card.querySelector(".cm-review-spcode").value,x06:card.querySelector(".cm-review-count").value,x07:card.querySelector(".cm-review-interaction").value,x08:note||""});});});
  var complete=document.getElementById("cmComplete");if(complete&&!complete.disabled){complete.addEventListener("click",function(){apex.message.confirm("Complete this internal review?",function(ok){if(ok){run("COMPLETE",{});}});});}
})();
</script>~');
    add_line(l_html, '</div>');
    return l_html;
  exception
    when no_data_found then
      return '<div class="t-Alert t-Alert--warning"><strong>Catch Monitor is not ready.</strong><p>Run the foundation and demo scenario scripts, then reload this page.</p></div>';
  end workbench_html;
end afma_cm_page_api;
/

prompt AFMA 120 complete
