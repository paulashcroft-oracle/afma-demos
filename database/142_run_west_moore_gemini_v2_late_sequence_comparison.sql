set define off

-- Historical comparison only; the current demo default is Gemini 2.5 Pro.
-- Compares Flash and Pro on the two-Spanish-Mackerel late sequence under the refined temporal/deduplication prompt.
prompt AFMA 142 - Run West Moore Gemini v2 late-sequence comparison

declare
  l_trial_id number;
begin
  begin
    l_trial_id := afma_cm_video_ai_api.run_trial(
      p_trip_ref              => 'CM-WA-001',
      p_source_file_name      => 'benchmarks/afma-west-moore-clip-d.mp4',
      p_source_offset_seconds => 880,
      p_clip_duration_seconds => 240,
      p_service_static_id     => 'google_gemini_2_5_flash',
      p_model_name            => 'google.gemini-2.5-flash',
      p_prompt_version        => 'west-moore-caab-events-v2'
    );
    dbms_output.put_line('FLASH_D_V2_TRIAL_ID=' || l_trial_id);
  exception
    when others then
      dbms_output.put_line('FLASH_D_V2_FAILED');
  end;

  begin
    l_trial_id := afma_cm_video_ai_api.run_trial(
      p_trip_ref              => 'CM-WA-001',
      p_source_file_name      => 'benchmarks/afma-west-moore-clip-d.mp4',
      p_source_offset_seconds => 880,
      p_clip_duration_seconds => 240,
      p_service_static_id     => 'google_gemini_2_5_pro',
      p_model_name            => 'google.gemini-2.5-pro',
      p_prompt_version        => 'west-moore-caab-events-v2'
    );
    dbms_output.put_line('PRO_D_V2_TRIAL_ID=' || l_trial_id);
  exception
    when others then
      dbms_output.put_line('PRO_D_V2_FAILED');
  end;
end;
/

prompt AFMA 142 complete
