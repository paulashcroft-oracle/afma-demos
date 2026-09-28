set define off

-- Historical comparison only; the current demo default is Gemini 2.5 Pro.
-- Compares Flash and Pro on the ambiguous double-hook-up with an independent transcript supplied as supporting evidence.
prompt AFMA 141 - Run West Moore Gemini v3 transcript comparison

declare
  l_trial_id number;
  l_transcript clob := q'~
[00:27.38] Oh, you've got a Chinaman.
[00:37.96] These Chinaman go like Broncos.
[00:43.74] No, it's not a Chinaman.
[00:44.92] Another Chinaman.
[00:46.82] Look at that, twins.
[00:47.86] Exactly the same size.
[00:50.46] [unclear] Chinaman.
[00:52.46] That's not a Chinaman.
[00:54.84] It's a Chinaman.
[01:02.40] It's a Chinaman.
~';
begin
  begin
    l_trial_id := afma_cm_video_ai_api.run_trial(
      p_trip_ref              => 'CM-WA-001',
      p_source_file_name      => 'benchmarks/afma-west-moore-clip-b.mp4',
      p_source_offset_seconds => 360,
      p_clip_duration_seconds => 90,
      p_service_static_id     => 'google_gemini_2_5_flash',
      p_model_name            => 'google.gemini-2.5-flash',
      p_prompt_version        => 'west-moore-caab-events-v3',
      p_transcript_context    => l_transcript
    );
    dbms_output.put_line('FLASH_B_V3_TRIAL_ID=' || l_trial_id);
  exception
    when others then
      dbms_output.put_line('FLASH_B_V3_FAILED');
  end;

  begin
    l_trial_id := afma_cm_video_ai_api.run_trial(
      p_trip_ref              => 'CM-WA-001',
      p_source_file_name      => 'benchmarks/afma-west-moore-clip-b.mp4',
      p_source_offset_seconds => 360,
      p_clip_duration_seconds => 90,
      p_service_static_id     => 'google_gemini_2_5_pro',
      p_model_name            => 'google.gemini-2.5-pro',
      p_prompt_version        => 'west-moore-caab-events-v3',
      p_transcript_context    => l_transcript
    );
    dbms_output.put_line('PRO_B_V3_TRIAL_ID=' || l_trial_id);
  exception
    when others then
      dbms_output.put_line('PRO_B_V3_FAILED');
  end;
end;
/

prompt AFMA 141 complete
