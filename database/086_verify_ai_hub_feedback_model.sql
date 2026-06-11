set define off

prompt AFMA 086 - Verify AI Hub feedback model

select owner,
       object_name,
       object_type,
       status
  from all_objects
 where owner = 'AFMA'
   and object_name in (
       'AI_HUB_FEEDBACK_FORWARDS',
       'AI_HUB_FEEDBACK_CANDIDATES_V',
       'AFMA_AI_HUB_FORWARDER'
       )
 order by object_name,
          object_type
/

select workspace,
       static_id,
       name,
       credential_type_code,
       valid_for_urls
  from apex_workspace_credentials
 where static_id = 'AI_HUB_AFMA_FEEDBACK_API'
/

select config_key,
       config_value,
       notes
  from csiro_caab_config
 where config_key in (
       'AI_HUB_PROJECT_KANBAN_URL',
       'AI_HUB_PUBLIC_BOARD_URL',
       'AI_HUB_FEEDBACK_ENDPOINT_URL',
       'AI_HUB_FEEDBACK_CREDENTIAL_STATIC_ID'
       )
 order by config_key
/

select application_id,
       page_id,
       page_name,
       page_mode
  from apex_application_pages
 where application_id = 101
   and page_id in (10030, 10031)
 order by page_id
/

select list_name,
       entry_text,
       entry_target,
       entry_image,
       entry_attribute_02 as display_hint,
       condition_type,
       condition_expression1
  from apex_application_list_entries
 where application_id = 101
   and list_name = 'Navigation Bar'
   and entry_text = 'Feedback'
/

select count(*) as pending_feedback_count
  from ai_hub_feedback_candidates_v
/

select feedback_id,
       ai_hub_task_key,
       ai_hub_feedback_key,
       forward_status,
       decision_code,
       source_application_id,
       source_page_id,
       source_created_by,
       replace(error_message, 'ORA-', 'ORACLE-') as failure_message,
       updated_at
  from ai_hub_feedback_forwards
 order by updated_at desc
 fetch first 10 rows only
/

prompt AFMA 086 complete
