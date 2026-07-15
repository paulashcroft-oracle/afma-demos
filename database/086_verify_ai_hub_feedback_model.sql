set define off

prompt AFMA 086 - Verify AI Hub feedback database model
prompt Database/data verification only. APEX feedback pages, navigation, Web Credentials, AI configs, and static assets are verified from APEXlang/application source.

select owner, object_name, object_type, status
  from all_objects
 where owner = 'AFMA'
   and object_name in ('AI_HUB_FEEDBACK_FORWARDS', 'AI_HUB_FEEDBACK_CANDIDATES_V', 'AFMA_AI_HUB_FORWARDER')
 order by object_name, object_type
/

select object_type, count(*) as valid_object_count
  from all_objects
 where owner = 'AFMA'
   and object_name in ('AI_HUB_FEEDBACK_FORWARDS', 'AI_HUB_FEEDBACK_CANDIDATES_V', 'AFMA_AI_HUB_FORWARDER')
   and status = 'VALID'
 group by object_type
 order by object_type
/

select config_key, config_value, notes
  from csiro_caab_config
 where config_key in ('AI_HUB_PROJECT_KANBAN_URL', 'AI_HUB_PUBLIC_BOARD_URL', 'AI_HUB_FEEDBACK_ENDPOINT_URL', 'AI_HUB_FEEDBACK_CREDENTIAL_STATIC_ID')
 order by config_key
/

select count(*) as pending_feedback_count
  from ai_hub_feedback_candidates_v
/

select feedback_id, ai_hub_task_key, ai_hub_feedback_key, forward_status, decision_code,
       source_application_id, source_page_id, source_created_by,
       replace(error_message, 'ORA-', 'ORACLE-') as failure_message, updated_at
  from ai_hub_feedback_forwards
 order by updated_at desc
 fetch first 10 rows only
/

prompt AFMA 086 complete
