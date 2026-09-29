set define off

-- Execution authority: read-only AFMA parsing schema verification through APEX SQL Commands or the schema owner.
-- Target: AIDEMODB workspace/schema AFMA; verifies application 101 Catch Monitor dependencies.
prompt AFMA 130 - Verify Catch Monitor database and selectable video scenarios

select object_name,
       object_type,
       status
  from user_objects
 where object_name like 'AFMA_CM_%'
 order by object_type, object_name;

select 'TRIPS' metric_name, count(*) metric_value
  from afma_cm_trips
union all
select 'REPORT_VERSIONS', count(*)
  from afma_cm_report_versions
union all
select 'REPORTED_CATCH_LINES', count(*)
  from afma_cm_reported_catch
union all
select 'MEDIA_ASSETS', count(*)
  from afma_cm_media_assets
union all
select 'MEDIA_OBJECTS', count(*)
  from afma_cm_media_objects
union all
select 'ANALYSIS_RUNS', count(*)
  from afma_cm_analysis_runs
union all
select 'OBSERVATIONS', count(*)
  from afma_cm_observations
union all
select 'CURRENT_OBSERVATIONS', count(*)
  from afma_cm_observations
 where superseded_at is null
union all
select 'SUPERSEDED_OBSERVATIONS', count(*)
  from afma_cm_observations
 where superseded_at is not null
union all
select 'VIDEO_SUBMISSIONS', count(*)
  from afma_cm_video_submissions
union all
select 'PROMPT_CONTRACTS', count(*)
  from afma_cm_prompt_contracts
union all
select 'AUDIT_EVENTS', count(*)
  from afma_cm_audit_events
union all
select 'REVIEW_SESSIONS', count(*)
  from afma_cm_review_sessions
union all
select 'REVIEW_MESSAGES', count(*)
  from afma_cm_review_messages
union all
select 'REVIEW_TOOL_RUNS', count(*)
  from afma_cm_review_tool_runs
union all
select 'REVIEW_PROPOSALS', count(*)
  from afma_cm_review_proposals;

select trip_ref,
       source_type,
       fishery_name,
       status,
       version_no,
       report_status,
       reported_lines,
       observations,
       needs_review
  from afma_cm_trip_summary_v
 order by trip_ref;

select rc.original_taxon_text,
       rc.spcode,
       rc.mapping_status,
       t.scientific_name,
       t.common_name,
       rc.reported_count,
       rc.reported_weight_kg,
       rc.catch_state
  from afma_cm_reported_catch rc
  join afma_cm_operations op on op.operation_id = rc.operation_id
  join afma_cm_report_versions rv on rv.report_version_id = op.report_version_id
  left join csiro_caab_taxa t on t.spcode = rc.spcode
 where rv.trip_id = (select trip_id from afma_cm_trips where trip_ref = 'CM-QLD-001')
 order by rc.reported_catch_id;

select analysis_mode,
       model_version,
       media_manifest,
       run_status,
       count(o.observation_id) observation_count,
       count(case when o.reviewer_status = 'NEEDS_REVIEW' then 1 end) needs_review_count
  from afma_cm_analysis_runs ar
  left join afma_cm_observations o on o.analysis_run_id = ar.analysis_run_id
 where ar.trip_id = (select trip_id from afma_cm_trips where trip_ref = 'CM-QLD-001')
 group by analysis_mode, model_version, media_manifest, run_status;

select rights_status,
       coverage_status,
       count(*) asset_count
  from afma_cm_media_assets
 where trip_id = (select trip_id from afma_cm_trips where trip_ref = 'CM-QLD-001')
 group by rights_status, coverage_status
 order by rights_status, coverage_status;

select t.trip_ref,
       m.title video_title,
       m.source_system,
       m.australian_region,
       m.duration_seconds,
       ar.model_version annotation_mode,
       ar.media_manifest,
       count(o.observation_id) evidence_events,
       ar.run_notes
  from afma_cm_trips t
  join afma_cm_analysis_runs ar on ar.trip_id = t.trip_id
  join afma_cm_media_assets m on m.media_asset_id = ar.media_asset_id
  left join afma_cm_observations o on o.analysis_run_id = ar.analysis_run_id
 where m.asset_role = 'SOURCE_VIDEO'
 group by t.trip_ref, m.title, m.source_system, m.australian_region,
          m.duration_seconds, ar.model_version, ar.media_manifest, ar.run_notes
 order by case t.trip_ref
            when 'CM-QLD-002' then 1
            when 'CM-QLD-003' then 2
            when 'CM-QLD-004' then 3
            when 'CM-WA-001' then 4
            when 'CM-QLD-001' then 5
            else 9
          end,
          t.trip_ref;

select o.start_second,
       o.end_second,
       o.ai_taxon_text,
       o.ai_spcode,
       t.scientific_name,
       o.ai_count,
       o.ai_count_lower_bound,
       o.ai_count_upper_bound,
       o.ai_count_basis,
       o.ai_count_scope,
       o.ai_event_granularity,
       o.ai_confidence,
       o.ai_catch_state,
       o.ai_interaction_class,
       o.evidence_role,
       o.evidence_group_ref,
       o.reviewer_status
  from afma_cm_observations o
  join afma_cm_analysis_runs ar on ar.analysis_run_id = o.analysis_run_id
  left join csiro_caab_taxa t on t.spcode = o.ai_spcode
 where ar.trip_id = (select trip_id from afma_cm_trips where trip_ref = 'CM-WA-001')
 order by o.start_second, o.observation_id;

select coalesce(t.common_name, t.scientific_name, o.ai_taxon_text) species_name,
       o.ai_spcode,
       sum(o.ai_count) proposed_count
  from afma_cm_observations o
  join afma_cm_analysis_runs ar on ar.analysis_run_id = o.analysis_run_id
  left join csiro_caab_taxa t on t.spcode = o.ai_spcode
 where ar.trip_id = (select trip_id from afma_cm_trips where trip_ref = 'CM-WA-001')
   and o.observation_type = 'CATCH'
 group by coalesce(t.common_name, t.scientific_name, o.ai_taxon_text), o.ai_spcode
 order by species_name;

select submission_ref,
       input_method,
       display_title,
       original_filename,
       mime_type,
       file_bytes,
       processing_status,
       processing_stage,
       progress_percent,
       processing_message,
       processing_started_at,
       processing_completed_at,
       last_progress_at,
       worker_job_ref,
       storage_region,
       inference_entry_region,
       processor_location,
       handling_notice_version,
       rights_confirmed_yn,
       handling_acknowledged_yn,
       retention_review_at,
       case when video_blob is not null then 'BLOB_PRESENT' else 'NO_BLOB' end payload_state,
       case when source_url is not null then 'URL_PRESENT' else 'NO_URL' end url_state
  from afma_cm_video_submissions
 order by created_at desc;

select processing_status,
       processing_stage,
       count(*) submission_count,
       min(progress_percent) min_progress_percent,
       max(progress_percent) max_progress_percent,
       sum(case when analysis_run_id is not null then 1 else 0 end) linked_run_count
  from afma_cm_video_submissions
 where processing_status <> 'DELETED'
 group by processing_status, processing_stage
 order by processing_status, processing_stage;

select vs.submission_ref,
       vs.display_title,
       mo.object_key,
       mo.object_role,
       mo.original_filename,
       mo.mime_type,
       mo.file_bytes,
       dbms_lob.getlength(mo.content_blob) stored_blob_bytes,
       mo.sha256,
       mo.duration_seconds,
       mo.source_video_id,
       mo.acquisition_method,
       mo.audio_present_yn,
       mo.storage_region,
       mo.retention_review_at
  from afma_cm_media_objects mo
  join afma_cm_video_submissions vs on vs.submission_id = mo.submission_id
 order by mo.created_at desc;

select count(*) incomplete_submission_scenario_count
  from afma_cm_trips t
 where t.status <> 'ARCHIVED'
   and exists (
     select 1
       from afma_cm_video_submissions vs
       join afma_cm_analysis_runs ar on ar.analysis_run_id = vs.analysis_run_id
      where ar.trip_id = t.trip_id
        and (vs.processing_status <> 'ANALYSIS_COMPLETE'
             or coalesce(vs.processing_stage, '~') <> 'READY_FOR_REVIEW')
   );

select prompt_key,
       prompt_version,
       model_id,
       service_static_id,
       contract_status,
       approved_at,
       approved_by,
       activated_at,
       activated_by
  from afma_cm_prompt_contracts
 order by prompt_key, created_at desc;

select count(*) invalid_batch_count_contracts
  from afma_cm_observations o
 where (o.ai_event_granularity = 'INDIVIDUAL' and o.ai_count <> 1)
    or (o.ai_count_basis = 'EXACT_VISIBLE'
        and (o.ai_count_lower_bound <> o.ai_count
             or o.ai_count_upper_bound <> o.ai_count))
    or (o.ai_count_basis = 'MINIMUM_VISIBLE'
        and (o.ai_count_lower_bound <> o.ai_count
             or o.ai_count_upper_bound is not null))
    or (o.ai_count_basis = 'ESTIMATED_RANGE'
        and (o.ai_count_upper_bound < o.ai_count_lower_bound
             or o.ai_count not between o.ai_count_lower_bound and o.ai_count_upper_bound))
    or (o.observation_type = 'WILDLIFE' and o.ai_count_scope <> 'WILDLIFE')
    or (o.observation_type = 'CATCH' and o.ai_count_scope = 'WILDLIFE');

select count(*) model_published_non_review_rows
 from afma_cm_observations o
  join afma_cm_analysis_runs ar on ar.analysis_run_id = o.analysis_run_id
 where ar.analysis_mode = 'APEX_GEMINI_PRO'
   and o.superseded_at is null
   and o.reviewer_status <> 'NEEDS_REVIEW';

select er.evidence_run_id,
       er.replaces_evidence_run_id,
       vs.submission_ref,
       mo.object_key,
       er.run_purpose,
       er.prompt_version,
       er.run_status,
       er.validation_status,
       er.proposed_event_count,
       er.reviewer_instruction,
       er.started_at,
       er.completed_at
  from afma_cm_evidence_runs er
  join afma_cm_video_submissions vs on vs.submission_id = er.submission_id
  join afma_cm_media_objects mo on mo.media_object_id = er.media_object_id
 where er.run_purpose = 'SEGMENT_REANALYSIS'
    or er.replaces_evidence_run_id is not null
 order by er.evidence_run_id desc;

select count(*) invalid_supersession_links
  from afma_cm_observations o
 where (o.superseded_at is null and o.superseded_by_evidence_run_id is not null)
    or (o.superseded_at is not null and o.superseded_by_evidence_run_id is null)
    or (o.evidence_run_id is null and o.superseded_at is not null);

select vs.submission_ref,
       count(*) segment_count,
       min(mo.source_start_second) first_source_second,
       max(mo.source_end_second) last_source_second,
       sum(mo.source_end_second - mo.source_start_second) covered_seconds
  from afma_cm_video_submissions vs
  join afma_cm_media_objects mo on mo.submission_id = vs.submission_id
 where mo.object_key like 'ANALYSIS_SEG_%'
 group by vs.submission_ref
 order by vs.submission_ref;

select count(*) completed_submission_stale_description_count
  from afma_cm_trips t
  join afma_cm_analysis_runs ar on ar.trip_id = t.trip_id
  join afma_cm_video_submissions vs on vs.analysis_run_id = ar.analysis_run_id
 where vs.processing_status = 'ANALYSIS_COMPLETE'
   and lower(t.notes) like '%analysis has not started%';

select count(*) youtube_playback_package_line_count
  from user_source
 where name = 'AFMA_CM_PAGE_API'
   and type = 'PACKAGE BODY'
   and text like '%youtube-nocookie%';

select count(*) reviewer_guidance_prompt_line_count
  from user_source
 where name = 'AFMA_CM_EVIDENCE_API'
   and type = 'PACKAGE BODY'
   and text like '%AUTHORISED REVIEWER SUPPLEMENTAL GUIDANCE%';

select count(*) prompted_full_reanalysis_ui_line_count
  from user_source
 where name = 'AFMA_CM_PAGE_API'
   and type = 'PACKAGE BODY'
   and (text like '%cmRerunAllSegments%'
        or text like '%cmAiCorrectionAll%');

select count(*) review_studio_package_line_count
  from user_source
 where name = 'AFMA_CM_PAGE_API'
   and type = 'PACKAGE BODY'
   and text like '%cmReviewStudioDialog%';

select count(*) review_agent_tool_contract_count
  from user_source
 where name = 'AFMA_CM_REVIEW_AGENT_API'
   and type = 'PACKAGE BODY'
   and (text like '%get_review_context%'
        or text like '%inspect_stored_segment%'
        or text like '%lookup_caab_candidates%'
        or text like '%create_corrected_proposal%');

select count(*) review_studio_ajax_process_count
  from apex_application_page_proc
 where application_id = 101
   and page_id = 4
   and process_name = 'AFMA_CM_EVIDENCE_ACTION'
   and dbms_lob.instr(process_source, 'OPEN_REVIEW_SESSION') > 0
   and dbms_lob.instr(process_source, 'SEND_REVIEW_MESSAGE') > 0
   and dbms_lob.instr(process_source, 'ACCEPT_REVIEW_PROPOSAL') > 0;

select rs.review_session_id,
       rs.session_status,
       rs.observation_id,
       count(distinct rm.review_message_id) message_count,
       count(distinct tr.tool_run_id) tool_run_count,
       count(distinct rp.review_proposal_id) proposal_count
  from afma_cm_review_sessions rs
  left join afma_cm_review_messages rm on rm.review_session_id = rs.review_session_id
  left join afma_cm_review_tool_runs tr on tr.review_session_id = rs.review_session_id
  left join afma_cm_review_proposals rp on rp.review_session_id = rs.review_session_id
 group by rs.review_session_id, rs.session_status, rs.observation_id
 order by rs.review_session_id desc;

prompt AFMA 130 complete
