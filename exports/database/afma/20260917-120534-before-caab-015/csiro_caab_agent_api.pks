package csiro_caab_agent_api as 
  function dataset_summary_markdown return clob; 
 
  function deterministic_answer_html( 
    p_user_prompt in clob 
  ) return clob; 
 
  function build_ai_context( 
    p_user_prompt in clob 
  ) return clob; 
 
  function ask_json( 
    p_user_prompt        in clob, 
    p_service_static_id  in varchar2 default null 
  ) return clob; 
end csiro_caab_agent_api;