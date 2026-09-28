set define off

-- Historical benchmark only; the current demo default is Gemini 2.5 Pro.
-- Replay requires private APEX application static files for clips b, c and d.
-- Trial results remain separate from AFMA_CM_OBSERVATIONS and cannot appear in the review queue.
prompt AFMA 137 - Run remaining West Moore Gemini Flash trials

declare
  l_trial_id number;
begin
  l_trial_id := afma_cm_video_ai_api.run_trial(
    p_trip_ref              => 'CM-WA-001',
    p_source_file_name      => 'benchmarks/afma-west-moore-clip-b.mp4',
    p_source_offset_seconds => 360,
    p_clip_duration_seconds => 90,
    p_service_static_id     => 'google_gemini_2_5_flash',
    p_model_name            => 'google.gemini-2.5-flash',
    p_prompt_version        => 'west-moore-caab-events-v1'
  );
  dbms_output.put_line('AFMA_CM_AI_TRIAL_ID=' || l_trial_id);
end;
/

declare
  l_trial_id number;
begin
  l_trial_id := afma_cm_video_ai_api.run_trial(
    p_trip_ref              => 'CM-WA-001',
    p_source_file_name      => 'benchmarks/afma-west-moore-clip-c.mp4',
    p_source_offset_seconds => 720,
    p_clip_duration_seconds => 165,
    p_service_static_id     => 'google_gemini_2_5_flash',
    p_model_name            => 'google.gemini-2.5-flash',
    p_prompt_version        => 'west-moore-caab-events-v1'
  );
  dbms_output.put_line('AFMA_CM_AI_TRIAL_ID=' || l_trial_id);
end;
/

declare
  l_trial_id number;
begin
  l_trial_id := afma_cm_video_ai_api.run_trial(
    p_trip_ref              => 'CM-WA-001',
    p_source_file_name      => 'benchmarks/afma-west-moore-clip-d.mp4',
    p_source_offset_seconds => 880,
    p_clip_duration_seconds => 240,
    p_service_static_id     => 'google_gemini_2_5_flash',
    p_model_name            => 'google.gemini-2.5-flash',
    p_prompt_version        => 'west-moore-caab-events-v1'
  );
  dbms_output.put_line('AFMA_CM_AI_TRIAL_ID=' || l_trial_id);
end;
/

prompt AFMA 137 complete
