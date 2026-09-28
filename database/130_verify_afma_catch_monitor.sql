set define off

-- Execution authority: read-only AFMA parsing schema verification through APEX SQL Commands or the schema owner.
-- Target: AIDEMODB workspace/schema AFMA; verifies application 101 Catch Monitor dependencies.
prompt AFMA 130 - Verify Catch Monitor database and demo scenario

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
select 'ANALYSIS_RUNS', count(*)
  from afma_cm_analysis_runs
union all
select 'OBSERVATIONS', count(*)
  from afma_cm_observations
union all
select 'AUDIT_EVENTS', count(*)
  from afma_cm_audit_events;

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

prompt AFMA 130 complete
