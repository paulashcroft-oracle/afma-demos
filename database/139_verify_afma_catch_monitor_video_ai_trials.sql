set define off

-- Execution authority: read-only AFMA parsing schema verification through APEX SQL Commands or the schema owner.
prompt AFMA 139 - Verify Catch Monitor video AI trials

select object_name, object_type, status
  from user_objects
 where object_name in ('AFMA_CM_AI_TRIALS', 'AFMA_CM_VIDEO_AI_API')
 order by object_type, object_name;

select trial_id,
       model_name,
       prompt_version,
       source_offset_seconds,
       clip_duration_seconds,
       run_status,
       validation_status,
       validation_issues,
       source_bytes,
       case when response_json is not null then 'Y' else 'N' end has_response,
       error_text
  from afma_cm_ai_trials
 order by trial_id;

prompt AFMA 139 complete
