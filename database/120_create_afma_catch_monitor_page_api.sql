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
  begin
    dbms_lob.createtemporary(l_html, true);

    if apex_application.g_request like 'SCENARIO-%' then
      l_requested_ref := substr(apex_application.g_request, length('SCENARIO-') + 1);
    end if;

    begin
      select trip_id
        into l_trip_id
        from afma_cm_trips
       where trip_ref = coalesce(l_requested_ref, 'CM-QLD-002');
    exception
      when no_data_found then
        select min(trip_id) keep (dense_rank first order by created_at desc)
          into l_trip_id
          from afma_cm_trips;
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
      when l_model_version = 'annotation-pending' then 'Annotation pending'
      when l_model_version = 'source-described-minimum-v1' then 'Source-described summary'
      when l_model_version = 'synthetic-ui-fixture-v1' then 'Synthetic UI fixture'
      when l_model_version like 'human-ground-truth%' then 'Human-reviewed ground truth'
      when l_model_version like 'manual-video-annotation%' then 'Time-coded manual annotation'
      else 'Demo evidence run'
    end;

    add_line(l_html, '<div class="cm-shell" id="cmShell" data-trip-id="' || l_trip_id || '">');
    add_line(l_html, q'~<style>
.cm-shell{display:grid;gap:1rem;color:#1d2935}
.cm-selector{display:grid;grid-template-columns:minmax(18rem,.7fr) minmax(0,1.3fr);gap:1rem;align-items:end;background:#fff;border:1px solid #cbdbe3;border-radius:10px;padding:1rem;box-shadow:0 8px 24px rgba(18,54,76,.06)}.cm-selector label{display:block;font-size:.72rem;font-weight:850;text-transform:uppercase;letter-spacing:.045em;color:#5d6c76;margin-bottom:.3rem}.cm-selector select{width:100%;border:1px solid #9fb8c5;border-radius:7px;background:#fff;padding:.62rem;color:#12364c;font-weight:750}.cm-selector h2{margin:0 0 .25rem;color:#12364c;font-size:1.05rem}.cm-selector p{margin:0;color:#526672;line-height:1.45}.cm-selector__meta{display:flex;gap:.4rem;flex-wrap:wrap;margin-top:.55rem}
.cm-hero{background:linear-gradient(128deg,#12364c 0%,#075c72 58%,#007d78 100%);color:white;border-radius:12px;padding:clamp(1rem,3vw,2rem);box-shadow:0 18px 40px rgba(18,54,76,.18)}.cm-hero__top{display:flex;align-items:flex-start;justify-content:space-between;gap:1rem;flex-wrap:wrap}.cm-kicker{font-size:.75rem;font-weight:850;text-transform:uppercase;letter-spacing:.11em;color:#9ce8e0}.cm-hero h1{margin:.25rem 0 .45rem;font-size:clamp(1.65rem,3.4vw,2.8rem);line-height:1.08}.cm-hero p{margin:0;max-width:68rem;color:#e6f4f5;line-height:1.5}.cm-demo{display:inline-flex;align-items:center;gap:.45rem;border:1px solid rgba(255,255,255,.45);background:rgba(255,255,255,.12);border-radius:999px;padding:.4rem .7rem;font-size:.78rem;font-weight:800}.cm-stats{display:grid;grid-template-columns:repeat(4,minmax(0,1fr));gap:.7rem;margin-top:1.15rem}.cm-stat{background:rgba(255,255,255,.1);border:1px solid rgba(255,255,255,.22);border-radius:9px;padding:.7rem}.cm-stat span{display:block;font-size:.7rem;text-transform:uppercase;letter-spacing:.06em;color:#c7e8e9}.cm-stat strong{display:block;font-size:1.35rem;margin-top:.15rem}
.cm-alert{display:flex;gap:.65rem;align-items:flex-start;border-radius:9px;padding:.75rem .9rem;border:1px solid #f1c36c;background:#fff8e7;color:#6e4900}.cm-alert strong{display:block}.cm-alert p{margin:.2rem 0 0;line-height:1.45}.cm-grid{display:grid;grid-template-columns:minmax(0,1.05fr) minmax(22rem,.95fr);gap:1rem}.cm-card{background:#fff;border:1px solid #d7e1e7;border-radius:10px;box-shadow:0 8px 24px rgba(18,54,76,.06);overflow:hidden}.cm-card__head{display:flex;justify-content:space-between;align-items:flex-start;gap:.8rem;padding:.9rem 1rem;border-bottom:1px solid #d7e1e7;background:#fbfdfe}.cm-card__head h2{margin:0;color:#12364c;font-size:1.08rem}.cm-card__head p{margin:.2rem 0 0;color:#5d6c76;font-size:.83rem}.cm-card__body{padding:1rem}.cm-video{aspect-ratio:16/9;width:100%;border:0;background:#071924}.cm-meta{display:flex;gap:.45rem;flex-wrap:wrap;margin-top:.7rem}.cm-badge{display:inline-flex;align-items:center;border-radius:999px;padding:.18rem .5rem;font-size:.72rem;font-weight:850;text-transform:uppercase;letter-spacing:.025em}.cm-badge-ok{background:#e6f4e8;color:#27642c}.cm-badge-warn{background:#fff0cd;color:#795000}.cm-badge-risk{background:#fde8e8;color:#8f2020}.cm-badge-neutral{background:#eaf1f5;color:#3b5668}.cm-table-wrap{overflow:auto}.cm-table{width:100%;border-collapse:collapse}.cm-table th,.cm-table td{padding:.65rem .7rem;border-bottom:1px solid #d7e1e7;text-align:left;vertical-align:top}.cm-table th{background:#f5f8fa;color:#5d6c76;font-size:.7rem;text-transform:uppercase;letter-spacing:.045em}.cm-table td{font-size:.88rem}.cm-table small{display:block;color:#5d6c76;margin-top:.18rem;line-height:1.35}.cm-spcode{font-family:ui-monospace,SFMono-Regular,Menlo,monospace;font-size:.76rem;color:#0c6e9d}
.cm-btn{border:1px solid #b8cbd4;background:white;color:#12364c;border-radius:7px;padding:.48rem .68rem;font-weight:800;cursor:pointer}.cm-btn:hover{background:#f1f7f9}.cm-btn-primary{background:#007d78;border-color:#007d78;color:white}.cm-btn-danger{border-color:#e1b1b1;color:#a32929}.cm-btn:disabled{opacity:.48;cursor:not-allowed}.cm-actions{display:flex;gap:.45rem;flex-wrap:wrap}.cm-form{display:grid;grid-template-columns:2fr .7fr .8fr 1fr auto;gap:.55rem;align-items:end;margin-top:.8rem;padding:.8rem;background:#f4f8fa;border:1px solid #d7e1e7;border-radius:8px}.cm-field label{display:block;font-size:.7rem;font-weight:850;text-transform:uppercase;color:#5d6c76;margin-bottom:.25rem}.cm-field input,.cm-field select,.cm-review select,.cm-review input{width:100%;border:1px solid #b9cbd4;border-radius:6px;padding:.48rem;background:white}.cm-events{display:grid;gap:.65rem}.cm-event{border:1px solid #d7e1e7;border-left:5px solid #0c6e9d;border-radius:8px;padding:.75rem}.cm-event-wildlife{border-left-color:#9a6200}.cm-event__top{display:flex;justify-content:space-between;gap:.7rem}.cm-event h3{margin:0;font-size:.95rem;color:#12364c}.cm-event p{margin:.35rem 0;color:#5d6c76;font-size:.84rem;line-height:1.4}.cm-review{display:grid;grid-template-columns:1.2fr .55fr 1fr auto;gap:.45rem;margin-top:.6rem;align-items:end}.cm-review label{font-size:.68rem;color:#5d6c76;text-transform:uppercase;font-weight:800}.cm-section-title{display:flex;justify-content:space-between;align-items:center;gap:.7rem;margin:.1rem 0 .7rem}.cm-section-title h2{margin:0;color:#12364c;font-size:1.25rem}.cm-media-grid{display:grid;grid-template-columns:repeat(3,minmax(0,1fr));gap:.75rem}.cm-media{border:1px solid #d7e1e7;border-radius:8px;padding:.75rem}.cm-media h3{margin:.2rem 0 .3rem;font-size:.92rem;color:#12364c}.cm-media p{margin:.25rem 0;color:#5d6c76;font-size:.8rem;line-height:1.4}.cm-link{color:#0c6e9d;font-weight:750}.cm-guidance{display:grid;grid-template-columns:repeat(3,minmax(0,1fr));gap:.65rem}.cm-guidance a{display:block;border:1px solid #d7e1e7;border-radius:8px;padding:.7rem;text-decoration:none;color:#12364c;font-weight:800;background:#fff}.cm-guidance small{display:block;color:#5d6c76;font-weight:400;margin-top:.2rem}.cm-footnote{font-size:.78rem;color:#5d6c76;line-height:1.45}.cm-loading{opacity:.56;pointer-events:none}
@media(max-width:920px){.cm-selector,.cm-grid{grid-template-columns:1fr}.cm-stats{grid-template-columns:repeat(2,1fr)}.cm-media-grid,.cm-guidance{grid-template-columns:1fr}.cm-form,.cm-review{grid-template-columns:1fr 1fr}.cm-form .cm-field:first-child,.cm-review .cm-field:first-child{grid-column:1/-1}}
@media(max-width:560px){.cm-stats{grid-template-columns:1fr 1fr}.cm-form,.cm-review{grid-template-columns:1fr}.cm-form .cm-field:first-child,.cm-review .cm-field:first-child{grid-column:auto}.cm-actions{width:100%}.cm-btn{flex:1}}
</style>~');

    add_line(l_html, '<section class="cm-selector"><div><label for="cmScenario">Video scenario</label><select id="cmScenario">');
    for s in (
      select t.trip_ref, t.fishery_name, t.region_name
        from afma_cm_trips t
       where exists (
         select 1 from afma_cm_media_assets m
          where m.trip_id = t.trip_id and m.asset_role = 'SOURCE_VIDEO'
       )
       order by case t.trip_ref
                  when 'CM-QLD-002' then 1
                  when 'CM-QLD-003' then 2
                  when 'CM-QLD-004' then 3
                  when 'CM-WA-001' then 4
                  when 'CM-QLD-001' then 5
                  else 9
                end,
                t.trip_ref
    ) loop
      add_line(l_html, '<option value="' || a(s.trip_ref) || '" data-url="' || a(apex_page.get_url(p_page => 4, p_request => 'SCENARIO-' || s.trip_ref)) || '"' || case when s.trip_ref = l_trip.trip_ref then ' selected' end || '>' || h(s.fishery_name) || ' — ' || h(s.region_name) || '</option>');
    end loop;
    add_line(l_html, '</select></div><div><h2>What this footage shows</h2><p>' || h(l_trip.notes) || '</p><div class="cm-selector__meta"><span class="cm-badge cm-badge-neutral">' || h(l_annotation_status) || '</span><span class="cm-badge cm-badge-neutral">' || h(l_trip.region_name) || '</span><span class="cm-badge cm-badge-neutral">' || h(l_trip.gear_method) || '</span></div></div></section>');

    add_line(l_html, '<section class="cm-hero"><div class="cm-hero__top"><div><div class="cm-kicker">Authorised AFMA reviewer workspace</div><h1>Catch Monitor · ' || h(l_trip.trip_ref) || '</h1><p>' || h(l_trip.fishery_name) || ' · ' || h(l_trip.gear_method) || ' · ' || h(l_trip.region_name) || '</p></div><span class="cm-demo">DEMO DATA · ' || h(l_trip.source_type) || '</span></div>');
    add_line(l_html, '<div class="cm-stats"><div class="cm-stat"><span>Reported version</span><strong>v' || l_version_no || '</strong></div><div class="cm-stat"><span>Reported catch lines</span><strong>' || l_reported_count || '</strong></div><div class="cm-stat"><span>Evidence events</span><strong>' || l_video_count || '</strong></div><div class="cm-stat"><span>Needs review</span><strong>' || l_open_count || '</strong></div></div></section>');

    add_line(l_html, '<div class="cm-alert"><span aria-hidden="true">&#9888;</span><div><strong>AI-assisted review — reviewer confirmation required</strong><p>This demonstration proposes evidence events; it does not make a compliance finding, alter a logbook/e-log, or infer quota, legal size, weight or post-release condition from video.</p></div></div>');

    add_line(l_html, '<div class="cm-grid"><section class="cm-card"><div class="cm-card__head"><div><h2>Source video &amp; evidence timeline</h2><p>' || h(l_media_title) || ' · ' || h(l_media_source) || case when l_duration_seconds is not null then ' · ' || h(to_char(l_duration_seconds)) || ' seconds' end || '</p></div><span class="cm-badge cm-badge-warn">Internal demo source</span></div><div class="cm-card__body">');
    if lower(l_embed_url) like '%.mp4%' then
      add_line(l_html, '<video class="cm-video" src="' || a(l_embed_url) || '" title="' || a(l_media_title) || '" controls preload="metadata" playsinline></video>');
    else
      add_line(l_html, '<iframe class="cm-video" src="' || a(l_embed_url) || '" title="' || a(l_media_title) || '" loading="lazy" allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture" allowfullscreen></iframe>');
    end if;
    add_line(l_html, '<div class="cm-meta"><span class="cm-badge cm-badge-neutral">' || h(l_annotation_status) || '</span><span class="cm-badge cm-badge-neutral">' || h(l_model_version) || '</span><span class="cm-badge cm-badge-neutral">Manifest ' || h(l_manifest) || '</span><a class="cm-link" href="' || a(l_source_url) || '" target="_blank" rel="noopener">Open original source</a></div>');
    add_line(l_html, '<p class="cm-footnote"><strong>Evidence status:</strong> ' || h(l_run_notes) || '</p></div></section>');

    add_line(l_html, '<section class="cm-card"><div class="cm-card__head"><div><h2>Review queue</h2><p>Confirm, correct, reject or escalate each proposed event.</p></div><span class="cm-badge ' || badge_class(case when l_open_count = 0 then 'CONFIRMED' else 'NEEDS_REVIEW' end) || '">' || l_open_count || ' unresolved</span></div><div class="cm-card__body"><div class="cm-events">');
    if l_video_count = 0 then
      add_line(l_html, '<div class="cm-alert"><span aria-hidden="true">&#9432;</span><div><strong>No evidence events published</strong><p>This candidate remains selectable for playback and assessment, but its review queue stays empty until time-coded ground truth is approved.</p></div></div>');
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
      add_line(l_html, '<article class="cm-media"><span class="cm-badge ' || badge_class(m.rights_status) || '">' || h(m.rights_status) || '</span><h3>' || h(m.title) || '</h3><p><strong>' || h(m.taxon_name) || '</strong>' || case when m.spcode is not null then ' · <span class="cm-spcode">' || h(m.spcode) || '</span>' end || '</p><p>' || h(m.approved_purposes) || '</p><p>' || h(m.restrictions) || '</p><a class="cm-link" href="' || a(m.source_record_url) || '" target="_blank" rel="noopener">Open source record</a></article>');
    end loop;
    add_line(l_html, '</div><p class="cm-footnote">Hybrid incremental population: CAAB taxonomy remains complete, while approved visual assets are added for the selected fishery and expanded only when new footage introduces a media gap or ambiguous taxon.</p></section>');

    add_line(l_html, '<section><div class="cm-section-title"><h2>Reviewer guidance</h2></div><div class="cm-guidance"><a href="https://www.afma.gov.au/fisheries-management/monitoring-tools/electronic-monitoring-program" target="_blank" rel="noopener">Electronic monitoring program<small>AFMA · program and in-house footage review context</small></a><a href="https://www.afma.gov.au/logbooks-and-elogs" target="_blank" rel="noopener">Logbooks and e-logs<small>AFMA · existing reporting obligations remain unchanged</small></a><a href="https://www.afma.gov.au/protected-species/endangered-and-threatened-species-reporting" target="_blank" rel="noopener">Protected-species reporting<small>AFMA · confirm physical contact and applicable fields</small></a></div></section>');

    add_line(l_html, q'~<script>
(function(){
  var shell=document.getElementById("cmShell"); if(!shell){return;} var trip=shell.getAttribute("data-trip-id");
  function val(id){var el=document.getElementById(id);return el?el.value:"";}
  function run(action,args){shell.classList.add("cm-loading");var payload={x01:action,x02:trip};Object.keys(args||{}).forEach(function(k){payload[k]=args[k];});apex.server.process("AFMA_CM_ACTION",payload,{dataType:"json"}).then(function(r){if(!r||!r.success){throw new Error((r&&r.message)||"Action failed");}window.location.reload();}).catch(function(e){shell.classList.remove("cm-loading");apex.message.alert(e&&e.message?e.message:String(e));});}
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
