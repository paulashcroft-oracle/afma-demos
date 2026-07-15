set define off

prompt AFMA 085 - Create AI Hub feedback database model
prompt Database/data only. APEX feedback pages, navigation, Web Credential metadata, and AI configs are owned by APEXlang/application source.

declare
  l_count number;

  procedure create_index_if_missing(
    p_index_name in varchar2,
    p_sql        in varchar2
  ) is
    l_index_count number;
  begin
    select count(*)
      into l_index_count
      from user_indexes
     where index_name = upper(p_index_name);

    if l_index_count = 0 then
      execute immediate p_sql;
    end if;
  end create_index_if_missing;
begin
  select count(*)
    into l_count
    from user_tables
   where table_name = 'AI_HUB_FEEDBACK_FORWARDS';

  if l_count = 0 then
    execute immediate q'[
      create table ai_hub_feedback_forwards (
        feedback_id            number not null,
        ai_hub_task_key        varchar2(128 char),
        ai_hub_feedback_key    varchar2(128 char),
        forward_status         varchar2(30 char) default 'PENDING' not null,
        decision_code          varchar2(80 char),
        public_response        varchar2(4000 char),
        payload_json           clob,
        response_json          clob,
        error_message          varchar2(4000 char),
        source_application_id  number,
        source_page_id         number,
        source_created_by      varchar2(255 char),
        source_created_on      timestamp with time zone,
        created_at             timestamp with time zone default systimestamp not null,
        updated_at             timestamp with time zone default systimestamp not null,
        constraint ai_hub_feedback_forwards_pk primary key (feedback_id),
        constraint ai_hub_feedback_forwards_status_ck check (
          forward_status in ('PENDING', 'FORWARDED', 'RESPONSE_ONLY', 'FAILED', 'SKIPPED')
        ),
        constraint ai_hub_feedback_forwards_payload_ck check (payload_json is json),
        constraint ai_hub_feedback_forwards_resp_ck check (response_json is json)
      )
    ]';
  end if;

  create_index_if_missing(
    'AI_HUB_FEEDBACK_FORWARDS_IX1',
    'create index ai_hub_feedback_forwards_ix1 on ai_hub_feedback_forwards (forward_status, updated_at)'
  );
end;
/

comment on table ai_hub_feedback_forwards is
  'AFMA ledger for native APEX feedback forwarded or prepared for forwarding into AI Hub source feedback.';
/
comment on column ai_hub_feedback_forwards.feedback_id is
  'APEX_TEAM_FEEDBACK.FEEDBACK_ID from AFMA application 101.';
/
comment on column ai_hub_feedback_forwards.ai_hub_task_key is
  'AI Hub task key returned for actionable feedback, for example afma-010.';
/
comment on column ai_hub_feedback_forwards.ai_hub_feedback_key is
  'AI Hub source-feedback key returned for response-only or task-backed feedback.';
/
comment on column ai_hub_feedback_forwards.forward_status is
  'Local bridge status: PENDING, FORWARDED, RESPONSE_ONLY, FAILED, or SKIPPED.';
/

create or replace view ai_hub_feedback_candidates_v as
select f.feedback_id,
       f.feedback_number,
       f.application_id,
       f.application_name,
       f.page_id,
       f.page_name,
       f.feedback,
       f.feedback_rating,
       f.feedback_status,
       f.created_by,
       f.created_on,
       f.screen_width,
       f.screen_height,
       f.http_user_agent,
       f.logging_session_id
  from apex_team_feedback f
 where f.application_id = 101
   and f.feedback is not null
   and not exists (
         select 1
           from ai_hub_feedback_forwards x
          where x.feedback_id = f.feedback_id
            and x.forward_status in ('FORWARDED', 'RESPONSE_ONLY')
       );
/

create or replace package afma_ai_hub_forwarder authid definer as
  c_project_key constant varchar2(30) := 'afma';
  c_credential_static_id constant varchar2(128) := 'AI_HUB_AFMA_FEEDBACK_API';
  c_default_feedback_url constant varchar2(1000) :=
    'https://apex.oraclecorp.com/pls/apex/ashcroft/ai-hub-api/v1/projects/afma/feedback';

  function feedback_url return varchar2;

  function idempotency_key(
    p_feedback_id in number
  ) return varchar2;

  function build_endpoint_payload(
    p_feedback_id in number
  ) return clob;

  procedure mark_pending(
    p_feedback_id in number
  );

  procedure mark_failed(
    p_feedback_id   in number,
    p_error_message in varchar2
  );

  function forward_feedback(
    p_feedback_id in number,
    p_force_yn    in varchar2 default 'N'
  ) return varchar2;

  function forward_pending(
    p_limit in number default 10
  ) return number;
end afma_ai_hub_forwarder;
/

create or replace package body afma_ai_hub_forwarder as
  function config_value(
    p_key     in varchar2,
    p_default in varchar2
  ) return varchar2 is
    l_value csiro_caab_config.config_value%type;
  begin
    select config_value
      into l_value
      from csiro_caab_config
     where config_key = upper(trim(p_key));

    return coalesce(l_value, p_default);
  exception
    when no_data_found then
      return p_default;
  end config_value;

  function feedback_url return varchar2 is
  begin
    return config_value('AI_HUB_FEEDBACK_ENDPOINT_URL', c_default_feedback_url);
  end feedback_url;

  procedure ensure_workspace is
  begin
    apex_util.set_workspace('AFMA');
  exception
    when others then
      null;
  end ensure_workspace;

  function normalized_text(
    p_text in varchar2
  ) return varchar2 is
  begin
    return trim(regexp_replace(replace(replace(nvl(p_text, ''), chr(13), ' '), chr(10), ' '), '\s+', ' '));
  end normalized_text;

  function short_text(
    p_text   in varchar2,
    p_length in pls_integer
  ) return varchar2 is
    l_text varchar2(4000) := normalized_text(p_text);
  begin
    if length(l_text) <= p_length then
      return l_text;
    end if;

    return substr(l_text, 1, greatest(1, p_length - 3)) || '...';
  end short_text;

  function idempotency_key(
    p_feedback_id in number
  ) return varchar2 is
  begin
    return 'afma-apex-feedback-' || to_char(p_feedback_id);
  end idempotency_key;

  function build_endpoint_payload(
    p_feedback_id in number
  ) return clob is
    l_feedback_id        apex_team_feedback.feedback_id%type;
    l_application_id     apex_team_feedback.application_id%type;
    l_application_name   apex_team_feedback.application_name%type;
    l_page_id            apex_team_feedback.page_id%type;
    l_page_name          apex_team_feedback.page_name%type;
    l_feedback           apex_team_feedback.feedback%type;
    l_feedback_rating    apex_team_feedback.feedback_rating%type;
    l_screen_width       apex_team_feedback.screen_width%type;
    l_screen_height      apex_team_feedback.screen_height%type;
    l_http_user_agent    apex_team_feedback.http_user_agent%type;
    l_logging_session_id apex_team_feedback.logging_session_id%type;
    l_created_by         apex_team_feedback.created_by%type;
    l_created_on         apex_team_feedback.created_on%type;
    l_payload            clob;
    l_details            clob;
  begin
    select feedback_id,
           application_id,
           application_name,
           page_id,
           page_name,
           feedback,
           feedback_rating,
           screen_width,
           screen_height,
           http_user_agent,
           logging_session_id,
           created_by,
           created_on
      into l_feedback_id,
           l_application_id,
           l_application_name,
           l_page_id,
           l_page_name,
           l_feedback,
           l_feedback_rating,
           l_screen_width,
           l_screen_height,
           l_http_user_agent,
           l_logging_session_id,
           l_created_by,
           l_created_on
      from apex_team_feedback
     where feedback_id = p_feedback_id
       and application_id = 101;

    l_details :=
      'Source: AFMA native APEX Feedback' || chr(10) ||
      'Feedback ID: ' || l_feedback_id || chr(10) ||
      'Application: ' || l_application_name || ' (' || l_application_id || ')' || chr(10) ||
      'Page: ' || nvl(l_page_name, 'Unknown') || ' (' || l_page_id || ')' || chr(10) ||
      'Submitted by: ' || nvl(l_created_by, 'Unknown') || chr(10) ||
      'Submitted on: ' || to_char(l_created_on, 'YYYY-MM-DD"T"HH24:MI:SS TZH:TZM') || chr(10) ||
      'Rating: ' || nvl(to_char(l_feedback_rating), 'Not supplied') || chr(10) ||
      'Screen: ' || nvl(l_screen_width, '?') || ' x ' || nvl(l_screen_height, '?') || chr(10) ||
      'Logging session: ' || nvl(l_logging_session_id, 'Not captured') || chr(10) ||
      'User agent: ' || nvl(short_text(l_http_user_agent, 500), 'Not captured') || chr(10) ||
      chr(10) ||
      'Feedback:' || chr(10) ||
      l_feedback || chr(10) ||
      chr(10) ||
      'Suggested handling:' || chr(10) ||
      '- Review the reported behaviour in the AFMA CAAB demo runtime.' || chr(10) ||
      '- Preserve source page, user, and feedback id when creating or updating an AI Hub task.' || chr(10) ||
      '- Fix through normal AFMA Build/Test workflow, then record verification evidence.';

    apex_json.initialize_clob_output;
    apex_json.open_object;
    apex_json.write('idempotencyKey', idempotency_key(l_feedback_id));
    apex_json.write('title', short_text(nvl(l_page_name, 'AFMA CAAB Demo') || ': ' || l_feedback, 160));
    apex_json.write('description', short_text('User feedback from ' || nvl(l_page_name, 'AFMA CAAB Demo') || ': ' || l_feedback, 360));
    apex_json.write('priority', 'MEDIUM');
    apex_json.write('feedbackType', 'APEX_FEEDBACK');
    apex_json.write('feedback', l_feedback);
    apex_json.write('details', l_details);
    apex_json.open_object('source');
    apex_json.write('system', 'AFMA');
    apex_json.write('application', nvl(l_application_name, 'AFMA CAAB AI Demo'));
    apex_json.write('applicationId', to_char(l_application_id));
    apex_json.write('pageId', to_char(l_page_id));
    apex_json.write('pageName', l_page_name);
    apex_json.write('recordType', 'APEX_TEAM_FEEDBACK');
    apex_json.write('recordId', to_char(l_feedback_id));
    apex_json.write('feedbackId', to_char(l_feedback_id));
    apex_json.write('feedbackNumber', to_char(l_feedback_id));
    apex_json.write('user', l_created_by);
    apex_json.write('submittedAt', to_char(l_created_on, 'YYYY-MM-DD"T"HH24:MI:SS TZH:TZM'));
    apex_json.close_object;
    apex_json.close_object;
    l_payload := apex_json.get_clob_output;
    apex_json.free_output;

    return l_payload;
  exception
    when no_data_found then
      apex_json.free_output;
      raise_application_error(-20000, 'AFMA APEX feedback not found: ' || p_feedback_id);
    when others then
      apex_json.free_output;
      raise;
  end build_endpoint_payload;

  procedure upsert_result(
    p_feedback_id         in number,
    p_ai_hub_task_key     in varchar2,
    p_ai_hub_feedback_key in varchar2,
    p_forward_status      in varchar2,
    p_decision_code       in varchar2,
    p_public_response     in varchar2,
    p_payload_json        in clob,
    p_response_json       in clob
  ) is
    l_source_application_id apex_team_feedback.application_id%type;
    l_source_page_id        apex_team_feedback.page_id%type;
    l_source_created_by     apex_team_feedback.created_by%type;
    l_source_created_on     apex_team_feedback.created_on%type;
  begin
    select application_id,
           page_id,
           created_by,
           created_on
      into l_source_application_id,
           l_source_page_id,
           l_source_created_by,
           l_source_created_on
      from apex_team_feedback
     where feedback_id = p_feedback_id
       and application_id = 101;

    update ai_hub_feedback_forwards
       set ai_hub_task_key = p_ai_hub_task_key,
           ai_hub_feedback_key = p_ai_hub_feedback_key,
           forward_status = p_forward_status,
           decision_code = p_decision_code,
           public_response = substr(p_public_response, 1, 4000),
           payload_json = p_payload_json,
           response_json = p_response_json,
           error_message = null,
           source_application_id = l_source_application_id,
           source_page_id = l_source_page_id,
           source_created_by = l_source_created_by,
           source_created_on = l_source_created_on,
           updated_at = systimestamp
     where feedback_id = p_feedback_id;

    if sql%rowcount = 0 then
      insert into ai_hub_feedback_forwards (
        feedback_id,
        ai_hub_task_key,
        ai_hub_feedback_key,
        forward_status,
        decision_code,
        public_response,
        payload_json,
        response_json,
        source_application_id,
        source_page_id,
        source_created_by,
        source_created_on
      ) values (
        p_feedback_id,
        p_ai_hub_task_key,
        p_ai_hub_feedback_key,
        p_forward_status,
        p_decision_code,
        substr(p_public_response, 1, 4000),
        p_payload_json,
        p_response_json,
        l_source_application_id,
        l_source_page_id,
        l_source_created_by,
        l_source_created_on
      );
    end if;
  end upsert_result;

  procedure mark_pending(
    p_feedback_id in number
  ) is
  begin
    merge into ai_hub_feedback_forwards target
    using (
      select feedback_id,
             application_id,
             page_id,
             created_by,
             created_on
        from apex_team_feedback
       where feedback_id = p_feedback_id
         and application_id = 101
    ) source
    on (target.feedback_id = source.feedback_id)
    when matched then update set
      target.forward_status = case
        when target.forward_status in ('FORWARDED', 'RESPONSE_ONLY') then target.forward_status
        else 'PENDING'
      end,
      target.updated_at = systimestamp
    when not matched then insert (
      feedback_id,
      forward_status,
      source_application_id,
      source_page_id,
      source_created_by,
      source_created_on
    ) values (
      source.feedback_id,
      'PENDING',
      source.application_id,
      source.page_id,
      source.created_by,
      source.created_on
    );
  end mark_pending;

  procedure mark_failed(
    p_feedback_id   in number,
    p_error_message in varchar2
  ) is
  begin
    merge into ai_hub_feedback_forwards target
    using (
      select feedback_id,
             application_id,
             page_id,
             created_by,
             created_on
        from apex_team_feedback
       where feedback_id = p_feedback_id
         and application_id = 101
    ) source
    on (target.feedback_id = source.feedback_id)
    when matched then update set
      target.forward_status = 'FAILED',
      target.error_message = substr(p_error_message, 1, 4000),
      target.source_application_id = source.application_id,
      target.source_page_id = source.page_id,
      target.source_created_by = source.created_by,
      target.source_created_on = source.created_on,
      target.updated_at = systimestamp
    when not matched then insert (
      feedback_id,
      forward_status,
      error_message,
      source_application_id,
      source_page_id,
      source_created_by,
      source_created_on
    ) values (
      source.feedback_id,
      'FAILED',
      substr(p_error_message, 1, 4000),
      source.application_id,
      source.page_id,
      source.created_by,
      source.created_on
    );
  end mark_failed;

  function forward_feedback(
    p_feedback_id in number,
    p_force_yn    in varchar2 default 'N'
  ) return varchar2 is
    l_existing_key ai_hub_feedback_forwards.ai_hub_task_key%type;
    l_payload clob;
    l_response clob;
    l_status_code number;
    l_task_key varchar2(128);
    l_feedback_key varchar2(128);
    l_decision_code varchar2(80);
    l_public_response varchar2(4000);
    l_forward_status varchar2(30);
    l_force_yn varchar2(1) := upper(nvl(substr(trim(p_force_yn), 1, 1), 'N'));
  begin
    begin
      select coalesce(ai_hub_task_key, ai_hub_feedback_key)
        into l_existing_key
        from ai_hub_feedback_forwards
       where feedback_id = p_feedback_id
         and forward_status in ('FORWARDED', 'RESPONSE_ONLY')
         and coalesce(ai_hub_task_key, ai_hub_feedback_key) is not null;

      if l_force_yn <> 'Y' then
        return l_existing_key;
      end if;
    exception
      when no_data_found then
        null;
    end;

    ensure_workspace;
    l_payload := build_endpoint_payload(p_feedback_id);

    apex_web_service.g_request_headers.delete;
    apex_web_service.g_request_headers(1).name := 'Content-Type';
    apex_web_service.g_request_headers(1).value := 'application/json';
    apex_web_service.g_request_headers(2).name := 'Idempotency-Key';
    apex_web_service.g_request_headers(2).value := idempotency_key(p_feedback_id);

    l_response := apex_web_service.make_rest_request(
      p_url                  => feedback_url,
      p_http_method          => 'POST',
      p_body                 => l_payload,
      p_transfer_timeout     => 30,
      p_credential_static_id => c_credential_static_id
    );

    l_status_code := apex_web_service.g_status_code;

    if l_status_code not in (200, 201) then
      mark_failed(
        p_feedback_id   => p_feedback_id,
        p_error_message => 'AI Hub returned HTTP ' || l_status_code || ': ' || dbms_lob.substr(l_response, 2000, 1)
      );
      commit;
      raise_application_error(-20002, 'AI Hub returned HTTP ' || l_status_code || '.');
    end if;

    select json_value(l_response, '$.taskKey' returning varchar2(128) null on error),
           json_value(l_response, '$.feedbackKey' returning varchar2(128) null on error),
           json_value(l_response, '$.decisionCode' returning varchar2(80) null on error),
           json_value(l_response, '$.publicResponse' returning varchar2(4000) null on error)
      into l_task_key,
           l_feedback_key,
           l_decision_code,
           l_public_response
      from dual;

    l_forward_status := case
      when l_task_key is not null then 'FORWARDED'
      else 'RESPONSE_ONLY'
    end;

    upsert_result(
      p_feedback_id         => p_feedback_id,
      p_ai_hub_task_key     => l_task_key,
      p_ai_hub_feedback_key => l_feedback_key,
      p_forward_status      => l_forward_status,
      p_decision_code       => l_decision_code,
      p_public_response     => l_public_response,
      p_payload_json        => l_payload,
      p_response_json       => l_response
    );
    commit;

    return coalesce(l_task_key, l_feedback_key);
  exception
    when others then
      rollback;
      begin
        mark_failed(p_feedback_id, sqlerrm);
        commit;
      exception
        when others then
          rollback;
      end;
      raise;
  end forward_feedback;

  function forward_pending(
    p_limit in number default 10
  ) return number is
    l_count number := 0;
    l_result_key varchar2(128);
  begin
    for r in (
      select feedback_id
        from (
          select feedback_id
            from ai_hub_feedback_candidates_v
           order by created_on
        )
       where rownum <= greatest(1, nvl(p_limit, 10))
    ) loop
      l_result_key := forward_feedback(r.feedback_id);
      l_count := l_count + case when l_result_key is not null then 1 else 0 end;
    end loop;

    return l_count;
  end forward_pending;
end afma_ai_hub_forwarder;
/

merge into csiro_caab_config target
using (
  select 'AI_HUB_PROJECT_KANBAN_URL' as config_key,
         'https://apex.oraclecorp.com/pls/apex/r/ashcroft/ai-hub/project-kanban?request=PROJECT-afma' as config_value,
         'Stable AI Hub project-filtered Kanban landing URL. Do not store session URLs.' as notes
    from dual
  union all
  select 'AI_HUB_PUBLIC_BOARD_URL',
         'https://apex.oraclecorp.com/pls/apex/ashcroft/ai-hub-api/v1/projects/afma/board',
         'Public compact AI Hub board endpoint for AFMA.'
    from dual
  union all
  select 'AI_HUB_FEEDBACK_ENDPOINT_URL',
         'https://apex.oraclecorp.com/pls/apex/ashcroft/ai-hub-api/v1/projects/afma/feedback',
         'Project-scoped AI Hub source feedback endpoint. Retarget when AI Hub is database-reachable from AIDEMODB.'
    from dual
  union all
  select 'AI_HUB_FEEDBACK_CREDENTIAL_STATIC_ID',
         'AI_HUB_AFMA_FEEDBACK_API',
         'APEX Web Credential static id for the AFMA source feedback API key. Raw key is stored only in the live credential.'
    from dual
) source
on (target.config_key = source.config_key)
when matched then update set
  target.config_value = source.config_value,
  target.notes = source.notes
when not matched then
  insert (config_key, config_value, notes)
  values (source.config_key, source.config_value, source.notes);
/

prompt AFMA 085 complete
