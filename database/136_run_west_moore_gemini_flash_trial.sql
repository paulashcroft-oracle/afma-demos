set define off

-- Historical benchmark only; the current demo default is Gemini 2.5 Pro.
-- Replay requires the private APEX application static file benchmarks/afma-west-moore-clip-a.mp4.
-- The trial result is stored separately from AFMA_CM_OBSERVATIONS and cannot appear in the review queue.
prompt AFMA 136 - Run West Moore Gemini Flash trial

declare
  l_trial_id number;
begin
  l_trial_id := afma_cm_video_ai_api.run_trial(
    p_trip_ref              => 'CM-WA-001',
    p_source_file_name      => 'benchmarks/afma-west-moore-clip-a.mp4',
    p_source_offset_seconds => 140,
    p_clip_duration_seconds => 145,
    p_service_static_id     => 'google_gemini_2_5_flash',
    p_model_name            => 'google.gemini-2.5-flash',
    p_prompt_version        => 'west-moore-caab-events-v1'
  );
  dbms_output.put_line('AFMA_CM_AI_TRIAL_ID=' || l_trial_id);
end;
/

prompt AFMA 136 complete
