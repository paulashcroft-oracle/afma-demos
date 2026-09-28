set define off

-- Re-runs the failed double-hook-up clip with Gemini Pro for comparison with Flash.
-- The result remains isolated in AFMA_CM_AI_TRIALS and cannot enter the review queue.
prompt AFMA 138 - Run West Moore Gemini Pro adjudication trial

declare
  l_trial_id number;
begin
  l_trial_id := afma_cm_video_ai_api.run_trial(
    p_trip_ref              => 'CM-WA-001',
    p_source_file_name      => 'benchmarks/afma-west-moore-clip-b.mp4',
    p_source_offset_seconds => 360,
    p_clip_duration_seconds => 90,
    p_service_static_id     => 'google_gemini_2_5_pro',
    p_model_name            => 'google.gemini-2.5-pro',
    p_prompt_version        => 'west-moore-caab-events-v1'
  );
  dbms_output.put_line('AFMA_CM_AI_TRIAL_ID=' || l_trial_id);
end;
/

prompt AFMA 138 complete
