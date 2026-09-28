set define off

-- Execution authority: AFMA parsing schema owner through the verified AFMA APEX SQL Commands session.
-- Target: AIDEMODB workspace/schema AFMA; source-traced selectable video cases for application 101.
prompt AFMA 125 - Seed selectable Catch Monitor video library

declare
  l_coral_spcode    varchar2(20);
  l_chinaman_spcode varchar2(20);
  l_emperor_spcode  varchar2(20);
  l_mackerel_spcode varchar2(20);
  l_west_trip_id    number;
  l_west_run_id     number;

  function exact_spcode(p_scientific_name in varchar2) return varchar2 is
    l_spcode varchar2(20);
  begin
    select min(spcode) into l_spcode
      from csiro_caab_taxa_active_v
     where lower(scientific_name) = lower(p_scientific_name);
    return l_spcode;
  end;

  procedure upsert_observation(
    p_run_id             in number,
    p_start_second       in number,
    p_end_second         in number,
    p_taxon_text         in varchar2,
    p_spcode             in varchar2,
    p_confidence         in number,
    p_evidence_text      in varchar2,
    p_evidence_role      in varchar2 default 'PRIMARY',
    p_evidence_group_ref in varchar2 default null
  ) is
  begin
    merge into afma_cm_observations target
    using (
      select p_run_id analysis_run_id,
             p_start_second start_second,
             p_end_second end_second
        from dual
    ) source
       on (target.analysis_run_id = source.analysis_run_id
       and target.observation_type = 'CATCH'
       and target.start_second = source.start_second
       and target.end_second = source.end_second)
     when matched then update set
       target.ai_taxon_text = p_taxon_text,
       target.ai_spcode = p_spcode,
       target.ai_count = 1,
       target.ai_confidence = p_confidence,
       target.ai_catch_state = 'UNKNOWN',
       target.ai_interaction_class = 'NOT_APPLICABLE',
       target.evidence_role = p_evidence_role,
       target.evidence_group_ref = p_evidence_group_ref,
       target.evidence_text = p_evidence_text
     when not matched then insert (
       analysis_run_id, observation_type, start_second, end_second,
       ai_taxon_text, ai_spcode, ai_count, ai_confidence,
       ai_catch_state, ai_interaction_class, evidence_role,
       evidence_group_ref, evidence_text
     ) values (
       p_run_id, 'CATCH', p_start_second, p_end_second,
       p_taxon_text, p_spcode, 1, p_confidence,
       'UNKNOWN', 'NOT_APPLICABLE', p_evidence_role,
       p_evidence_group_ref, p_evidence_text
     );
  end upsert_observation;

  procedure create_case(
    p_trip_ref          in varchar2,
    p_fishery_name      in varchar2,
    p_gear_method       in varchar2,
    p_region_name       in varchar2,
    p_notes             in varchar2,
    p_media_title       in varchar2,
    p_source_system     in varchar2,
    p_source_url        in varchar2,
    p_embed_url         in varchar2,
    p_provider          in varchar2,
    p_duration          in number,
    p_model_version     in varchar2,
    p_manifest          in varchar2,
    p_run_notes         in varchar2,
    p_reported_taxon    in varchar2 default null,
    p_reported_spcode   in varchar2 default null,
    p_reported_count    in number default null
  ) is
    l_trip_id number;
    l_report_id number;
    l_operation_id number;
    l_media_id number;
    l_run_id number;
  begin
    begin
      select trip_id into l_trip_id from afma_cm_trips where trip_ref = p_trip_ref;
      update afma_cm_trips
         set fishery_name = p_fishery_name,
             gear_method = p_gear_method,
             region_name = p_region_name,
             notes = p_notes
       where trip_id = l_trip_id;
      update afma_cm_media_assets
         set title = p_media_title,
             source_system = p_source_system,
             source_record_url = p_source_url,
             embed_url = p_embed_url,
             creator_provider = p_provider,
             australian_region = p_region_name,
             duration_seconds = p_duration
       where trip_id = l_trip_id
         and asset_role = 'SOURCE_VIDEO';
      update afma_cm_analysis_runs
         set model_version = p_model_version,
             media_manifest = p_manifest,
             run_notes = p_run_notes
       where trip_id = l_trip_id
         and media_asset_id in (
           select media_asset_id
             from afma_cm_media_assets
            where trip_id = l_trip_id
              and asset_role = 'SOURCE_VIDEO'
         );
      return;
    exception
      when no_data_found then null;
    end;

    insert into afma_cm_trips (
      trip_ref, source_type, fishery_name, gear_method, region_name,
      vessel_ref, status, retention_review_at, notes
    ) values (
      p_trip_ref, 'SYNTHETIC_DEMO', p_fishery_name, p_gear_method, p_region_name,
      'PUBLIC-SOURCE-DEMO', 'IN_REVIEW', trunc(sysdate) + 180, p_notes
    ) returning trip_id into l_trip_id;

    insert into afma_cm_report_versions (
      trip_id, version_no, report_status, source_type, source_provenance,
      recorded_at, frozen_at, frozen_by
    ) values (
      l_trip_id, 1, 'FROZEN_FOR_REVIEW', 'SYNTHETIC_DEMO',
      'Demo-operator comparison input; not an actual fisher declaration.',
      systimestamp, systimestamp, coalesce(sys_context('APEX$SESSION','APP_USER'), user)
    ) returning report_version_id into l_report_id;

    insert into afma_cm_operations (
      report_version_id, operation_no, location_text, gear_method, effort_text
    ) values (
      l_report_id, 1, p_region_name, p_gear_method,
      'Synthetic comparison operation paired to public source footage.'
    ) returning operation_id into l_operation_id;

    if p_reported_taxon is not null then
      insert into afma_cm_reported_catch (
        operation_id, original_taxon_text, spcode, mapping_status, mapping_method,
        mapping_confidence, reported_count, catch_state, notes
      ) values (
        l_operation_id, p_reported_taxon, p_reported_spcode,
        case when p_reported_spcode is null then 'UNRESOLVED' else 'MATCHED' end,
        case when p_reported_spcode is null then null else 'CAAB_EXACT_SCIENTIFIC_NAME' end,
        case when p_reported_spcode is null then null else 1 end,
        p_reported_count, 'RETAINED', 'Synthetic fisher input for reviewer comparison.'
      );
    end if;

    insert into afma_cm_media_assets (
      trip_id, asset_type, asset_role, title, source_system, source_record_url,
      embed_url, creator_provider, australian_region, rights_status, attribution_text,
      approved_purposes, restrictions, rights_checked_at, duration_seconds,
      view_type, quality_rating, expert_review_status, dataset_split, coverage_status
    ) values (
      l_trip_id, 'VIDEO', 'SOURCE_VIDEO', p_media_title, p_source_system, p_source_url,
      p_embed_url, p_provider, p_region_name, 'UNCONFIRMED_INTERNAL_ONLY',
      p_provider || '; original source record retained.', 'DEMO_PLAYBACK,VALIDATION',
      'Access-controlled internal demo only; no redistribution or custom training until rights are confirmed.',
      trunc(sysdate), p_duration, 'Operational fishing footage', 'DEMO_REVIEW',
      'PENDING', 'DEMO', 'UNCONFIRMED_INTERNAL_ONLY'
    ) returning media_asset_id into l_media_id;

    insert into afma_cm_analysis_runs (
      trip_id, report_version_id, media_asset_id, analysis_mode, model_version,
      media_manifest, run_status, completed_at, run_notes
    ) values (
      l_trip_id, l_report_id, l_media_id, 'SIMULATED_DEMO', p_model_version,
      p_manifest, 'COMPLETE', systimestamp, p_run_notes
    ) returning analysis_run_id into l_run_id;

    if p_trip_ref = 'CM-QLD-002' then
      insert into afma_cm_observations (
        analysis_run_id, observation_type, start_second, end_second, ai_taxon_text,
        ai_count, ai_confidence, ai_catch_state, ai_interaction_class, evidence_text
      ) values (
        l_run_id, 'WILDLIFE', 28, 35, 'Shark — species unresolved',
        1, .90, null, 'SIGHTING',
        'At least one shark is visible. Species and unique-individual count are not resolved from the public footage.'
      );
      insert into afma_cm_observations (
        analysis_run_id, observation_type, start_second, end_second, ai_taxon_text,
        ai_count, ai_confidence, ai_catch_state, ai_interaction_class, evidence_text
      ) values (
        l_run_id, 'CATCH', 64, 80, 'Hooked reef fish — species unresolved',
        1, .70, 'UNKNOWN', 'NOT_APPLICABLE',
        'One hooked reef fish is visible near the surface; the exact species is not established by this source.'
      );
      insert into afma_cm_observations (
        analysis_run_id, observation_type, start_second, end_second, ai_taxon_text,
        ai_count, ai_confidence, ai_interaction_class, evidence_text
      ) values (
        l_run_id, 'WILDLIFE', 65, 80, 'Shark — species unresolved',
        1, .92, 'CONFIRMED_INTERACTION',
        'Shark contact/depredation of the hooked catch is visible; count is a minimum and shark species remains unresolved.'
      );
    elsif p_trip_ref = 'CM-QLD-003' then
      insert into afma_cm_observations (
        analysis_run_id, observation_type, start_second, end_second, ai_taxon_text,
        ai_count, ai_confidence, ai_interaction_class, evidence_text
      ) values (
        l_run_id, 'WILDLIFE', 0, 73, 'Marine turtles — species unresolved',
        7, .65, 'CONFIRMED_INTERACTION',
        'The publisher reports at least seven turtles visibly entangled. This is a source-reported minimum; species-level and individual time coding await expert annotation.'
      );
    elsif p_trip_ref = 'CM-QLD-004' then
      insert into afma_cm_observations (
        analysis_run_id, observation_type, start_second, end_second, ai_taxon_text,
        ai_count, ai_confidence, ai_interaction_class, evidence_text
      ) values (
        l_run_id, 'WILDLIFE', 8, 14, 'Dolphin — species unresolved',
        1, .85, 'SIGHTING',
        'A dolphin is visible near the trawler. No physical contact is established in this event.'
      );
      insert into afma_cm_observations (
        analysis_run_id, observation_type, start_second, end_second, ai_taxon_text,
        ai_count, ai_confidence, ai_interaction_class, evidence_text
      ) values (
        l_run_id, 'WILDLIFE', 14, 46, 'Sharks — species unresolved',
        1, .88, 'SIGHTING',
        'Multiple sharks are visible around the gear; proposed count 1 is deliberately a minimum because individuals cannot be tracked reliably.'
      );
      insert into afma_cm_observations (
        analysis_run_id, observation_type, start_second, end_second, ai_taxon_text,
        ai_count, ai_confidence, ai_interaction_class, evidence_text
      ) values (
        l_run_id, 'WILDLIFE', 25, 38, 'Sharks — species unresolved',
        1, .90, 'CONFIRMED_INTERACTION',
        'Sharks visibly contact/feed on the caught mass. The source mentions bronze whalers and bull sharks, but species is not assigned to this visual event.'
      );
    end if;

    insert into afma_cm_audit_events (
      trip_id, entity_type, entity_id, action_name, detail_text
    ) values (
      l_trip_id, 'TRIP', l_trip_id, 'VIDEO_LIBRARY_CASE_CREATED',
      'Selectable source-traced video case created; evidence provenance is recorded in the analysis run.'
    );
  end create_case;

begin
  l_coral_spcode := exact_spcode('Plectropomus leopardus');
  l_chinaman_spcode := exact_spcode('Symphorus nematophorus');
  l_emperor_spcode := exact_spcode('Lutjanus sebae');
  l_mackerel_spcode := exact_spcode('Scomberomorus commerson');

  update afma_cm_trips
     set fishery_name = 'Synthetic workflow fixture — UI controls only',
         notes = 'Original workflow fixture. Its four deterministic observations do not correspond to events in the linked video; retain only for testing controls.'
   where trip_ref = 'CM-QLD-001';
  update afma_cm_analysis_runs
     set model_version = 'synthetic-ui-fixture-v1',
         media_manifest = 'AFMA-CM-SYNTHETIC-FIXTURE-2026.09',
         run_notes = 'Synthetic UI fixture only. Observation identities, counts and timestamps are not grounded in the linked video.'
   where trip_id = (select trip_id from afma_cm_trips where trip_ref = 'CM-QLD-001');

  create_case(
    'CM-QLD-002', 'Great Barrier Reef commercial handline — shark depredation',
    'Commercial handline', 'Great Barrier Reef, Queensland',
    'ABC footage shows a hooked reef fish at the surface and sharks taking/contacting the catch. Useful for a one-fish catch event plus wildlife sighting and depredation; exact fish and shark species remain unresolved.',
    'Sharks take handline fishermen''s catch', 'ABC News',
    'https://www.abc.net.au/news/2024-06-07/sharks-take-handline-fishermens-catch/103948396',
    'https://mediacore-live-production.akamaized.net/video/01/ue/Z/r5.mp4',
    'Australian Broadcasting Corporation', 84,
    'manual-video-annotation-v1', 'AFMA-CM-GROUNDED-2026.09',
    'Human-curated time-coded demo annotations grounded in reviewed public footage; not live model output.',
    'Common coral trout', l_coral_spcode, 1
  );

  create_case(
    'CM-QLD-003', 'Mackay gillnet — turtle entanglement',
    'Gillnet', 'Mackay / Louisa Creek, Queensland',
    'AMCS footage shows multiple marine turtles entangled in gillnet. The publisher reports at least seven animals; it is strong physical-interaction footage but does not support a catch-species count.',
    'Turtles trapped in gillnets near Mackay', 'Australian Marine Conservation Society',
    'https://www.marineconservation.org.au/marine-conservationists-uncover-footage-of-turtle-death-traps-in-our-reef/',
    'https://www.marineconservation.org.au/wp-content/uploads/2021/02/Sequence-01.mp4',
    'Australian Marine Conservation Society', 74,
    'source-described-minimum-v1', 'AFMA-CM-SOURCE-SUMMARY-2026.09',
    'Aggregated source-described minimum. Species-level and individual time-coded annotation remain pending.'
  );

  create_case(
    'CM-QLD-004', 'Bundaberg prawn trawler — sharks and dolphin',
    'Prawn trawl', 'Bundaberg, Queensland',
    'ABC footage shows a dolphin and multiple sharks around a prawn trawler, including sharks contacting the caught mass. Useful as a crowded, high-volume wildlife-interaction stress test; exact animal and catch counts are not reliable.',
    'Sharks and dolphins maul prawn trawler catch', 'ABC News',
    'https://www.abc.net.au/news/2024-03-02/video-sharks-dolphins-maul-prawn-trawler-catch/103534252',
    'https://mediacore-live-production.akamaized.net/video/01/r9/Z/pu.mp4',
    'Australian Broadcasting Corporation', 52,
    'manual-video-annotation-v1', 'AFMA-CM-GROUNDED-2026.09',
    'Human-curated time-coded demo annotations grounded in reviewed public footage; not live model output.',
    'Prawns', null, null
  );

  create_case(
    'CM-WA-001', 'West Moore Island — multi-species catch review',
    'Charter / recreational line fishing', 'West Moore Island, Western Australia',
    'Long-form fishing episode with ten reviewable depicted-catch observations: nine unique fish plus one edited Coming Up preview of a later Spanish Mackerel landing. The preview is retained and explicitly linked so the deduplication anomaly is visible; no wildlife interaction is evidenced.',
    'West Moore Island fishing episode', 'YouTube',
    'https://www.youtube.com/watch?v=b4KcVC11KVI',
    'https://www.youtube-nocookie.com/embed/b4KcVC11KVI',
    'Original uploader via YouTube', 1155,
    'human-ground-truth-v2', 'AFMA-CM-WEST-MOORE-GROUND-TRUTH-V2-2026.09',
    'Ten human-curated depicted-catch observations represent nine unique fish plus one edited preview linked to the later full landing. Continuous AFMA device footage is not expected to contain editorial previews.'
  );

  select t.trip_id, ar.analysis_run_id
    into l_west_trip_id, l_west_run_id
    from afma_cm_trips t
    join afma_cm_analysis_runs ar
      on ar.trip_id = t.trip_id
    join afma_cm_media_assets m
      on m.media_asset_id = ar.media_asset_id
     and m.asset_role = 'SOURCE_VIDEO'
   where t.trip_ref = 'CM-WA-001';

  upsert_observation(
    l_west_run_id, 158, 177, 'Common Coral Trout', l_coral_spcode, .99,
    'One fish is landed and displayed. Its spotted red/orange profile and repeated spoken identification as coral trout support the CAAB candidate; final retention and size are not inferred.'
  );
  upsert_observation(
    l_west_run_id, 202, 243, 'Chinamanfish', l_chinaman_spcode, .99,
    'One banded red/orange fish is landed and displayed. The speaker first says red emperor, then explicitly corrects the identification to Chinamanfish; the correction and visible pattern support the CAAB candidate.'
  );
  upsert_observation(
    l_west_run_id, 249, 270, 'Red Emperor', l_emperor_spcode, .99,
    'One fish is landed and displayed and is repeatedly identified in the footage as red emperor. The event is distinct from the preceding corrected Chinamanfish catch.'
  );
  upsert_observation(
    l_west_run_id, 387, 428, 'Chinamanfish', l_chinaman_spcode, .96,
    'First of two Chinamanfish simultaneously visible on the multi-hook rig. It is one of three distinct Chinamanfish depicted in this catch sequence.',
    p_evidence_group_ref => 'WM-CHINAMAN-0627'
  );
  upsert_observation(
    l_west_run_id, 402, 428, 'Chinamanfish', l_chinaman_spcode, .96,
    'Second Chinamanfish simultaneously visible on the same multi-hook rig. The two-fish frame supports a separate individual rather than a replay of the first.',
    p_evidence_group_ref => 'WM-CHINAMAN-0627'
  );
  upsert_observation(
    l_west_run_id, 418, 427, 'Chinamanfish', l_chinaman_spcode, .98,
    'A third, separate Chinamanfish is held by a different angler after the camera pans from the two-fish rig. Visual continuity and the “Chinaman love-in” narration support three individuals in this sequence.',
    p_evidence_group_ref => 'WM-CHINAMAN-0627'
  );
  upsert_observation(
    l_west_run_id, 429, 436, 'Spanish Mackerel', l_mackerel_spcode, .99,
    'Edited-source anomaly: a Coming Up preview visibly depicts a Spanish Mackerel landing. Gemini Pro identified the species, the preview context and its exact 07:09–07:16 window. Full-video frame comparison links it to the later 12:28–14:20 landing; it remains reviewable rather than being silently discarded. Continuous AFMA device footage is not expected to contain editorial previews.',
    p_evidence_role => 'PREVIEW_OR_REPLAY',
    p_evidence_group_ref => 'WM-MACKEREL-1228'
  );
  upsert_observation(
    l_west_run_id, 748, 860, 'Spanish Mackerel', l_mackerel_spcode, .99,
    'One Spanish Mackerel is fought, brought alongside, landed and displayed. This is the full sequence previewed at 07:09; matching landing, holder and deck frames link the two observations. Narration identifies the species; spoken weight estimates are not measurements.',
    p_evidence_group_ref => 'WM-MACKEREL-1228'
  );
  upsert_observation(
    l_west_run_id, 904, 990, 'Spanish Mackerel', l_mackerel_spcode, .99,
    'A second distinct Spanish Mackerel is fought, landed and displayed. The separate hook-up and landing establish a new individual.'
  );
  upsert_observation(
    l_west_run_id, 1010, 1101, 'Spanish Mackerel', l_mackerel_spcode, .98,
    'A third distinct Spanish Mackerel is brought to the boat and displayed after becoming entangled in two lures. The exact hooking mechanism does not change the unique-fish count; size and final disposition remain unknown.'
  );

  insert into afma_cm_audit_events (
    trip_id, entity_type, entity_id, action_name, detail_text
  )
  select l_west_trip_id, 'TRIP', l_west_trip_id,
         'WEST_MOORE_GROUND_TRUTH_V2_PUBLISHED',
         'Ten depicted-catch observations published: nine unique fish (Common Coral Trout 1, Chinamanfish 4, Red Emperor 1, Spanish Mackerel 3) plus one linked Coming Up preview of the first Spanish Mackerel; no wildlife interaction claimed.'
    from dual
   where not exists (
     select 1
       from afma_cm_audit_events
      where trip_id = l_west_trip_id
        and action_name = 'WEST_MOORE_GROUND_TRUTH_V2_PUBLISHED'
   );

  commit;
end;
/

prompt AFMA 125 complete
