set define off

prompt AFMA 090 - Configure AFMA CAAB AI Configs

declare
  c_workspace_id constant number := 14392040298408914;
  c_app_id       constant number := 101;
  c_schema       constant varchar2(30) := 'AFMA';

  function caab_system_prompt return varchar2 is
  begin
    return 'You are the AFMA CSIRO CAAB Agent in an Oracle APEX demo. Answer the user question from the supplied CAAB context only. CAAB is a taxonomy and code catalogue, not a population abundance survey. If the data cannot answer a question directly, say so clearly and offer the nearest data-backed interpretation. Return concise GitHub-flavoured Markdown with headings, bullets, numbered lists, and standard pipe tables when useful. When a simple chart or relationship diagram would help, include a fenced ```mermaid code block using Mermaid syntax such as xychart-beta, pie, flowchart, or timeline; do not provide unlabeled chart pseudo-code. Do not invent species, abundance, locations, URLs, images, load dates, or AFMA production claims.';
  end caab_system_prompt;

  procedure ensure_ai_config(
    p_id        in number,
    p_static_id in varchar2,
    p_name      in varchar2
  ) is
    l_remote_server_id number;
    l_count number;
  begin
    select remote_server_id
      into l_remote_server_id
      from apex_workspace_ai_services
     where provider_type_code = 'OCI_GENAI'
       and remote_server_static_id = p_static_id
       fetch first 1 row only;

    select count(*)
      into l_count
      from apex_appl_ai_configs
     where application_id = c_app_id
       and upper(config_static_id) = upper(p_static_id);

    if l_count = 0 then
      wwv_flow_imp_shared.create_ai_config(
        p_id => wwv_flow_imp.id(p_id),
        p_flow_id => c_app_id,
        p_name => p_name,
        p_static_id => p_static_id,
        p_remote_server_id => l_remote_server_id,
        p_system_prompt => caab_system_prompt,
        p_welcome_message => 'Ask about Australian aquatic biota, taxonomy, common names, habitat codes, and current/non-current CAAB records.',
        p_temperature => .2,
        p_config_comment => 'AFMA CAAB demo AI Config aligned to the workspace OCI Generative AI Service ' || p_name || '.'
      );
    end if;
  exception
    when no_data_found then
      null;
  end ensure_ai_config;
begin
  apex_application_install.set_workspace_id(c_workspace_id);
  apex_application_install.set_application_id(c_app_id);
  apex_application_install.set_schema(c_schema);

  wwv_flow_imp.import_begin(
    p_version_yyyy_mm_dd => '2024.11.30',
    p_release => '24.2.16',
    p_default_workspace_id => c_workspace_id,
    p_default_application_id => c_app_id,
    p_default_id_offset => 0,
    p_default_owner => c_schema
  );

  ensure_ai_config(1010900101, 'google_gemini_2_5_pro', 'google.gemini-2.5-pro');
  ensure_ai_config(1010900102, 'google_gemini_2_5_flash', 'google.gemini-2.5-flash');
  ensure_ai_config(1010900103, 'google_gemini_2_5_flash_lite', 'google.gemini-2.5-flash-lite');
  ensure_ai_config(1010900104, 'cohere_command_plus_latest', 'cohere.command-plus-latest');
  ensure_ai_config(1010900105, 'cohere_command_latest', 'cohere.command-latest');
  ensure_ai_config(1010900106, 'openai_gpt_oss_120b', 'openai.gpt-oss-120b');
  ensure_ai_config(1010900107, 'openai_gpt_oss_20b', 'openai.gpt-oss-20b');
  ensure_ai_config(1010900108, 'xai_grok_4_20_reasoning', 'xai.grok-4.20-reasoning');
  ensure_ai_config(1010900109, 'xai_grok_4_3', 'xai.grok-4.3');

  wwv_flow_imp.import_end(p_auto_install_sup_obj => false);
end;
/

merge into csiro_caab_config target
using (
  select 'AI_CONFIG_STATIC_ID' as config_key,
         'google_gemini_2_5_pro' as config_value,
         'Default APEX AI Config static id for the AFMA CAAB Agent page. Users can override per question from the model dropdown.' as notes
    from dual
) source
on (target.config_key = source.config_key)
when matched then
  update set target.config_value = source.config_value,
             target.notes = source.notes
when not matched then
  insert (config_key, config_value, notes)
  values (source.config_key, source.config_value, source.notes);
/

prompt AFMA 090 complete
