set define off

-- Execution authority: AFMA parsing schema owner through the verified AFMA APEX SQL Commands session.
-- Target: AIDEMODB workspace/schema AFMA; source-traced selectable video cases for application 101.
prompt AFMA 125 - Seed selectable Catch Monitor video library

declare
  l_coral_spcode varchar2(20);

  function exact_spcode(p_scientific_name in varchar2) return varchar2 is
    l_spcode varchar2(20);
  begin
    select min(spcode) into l_spcode
      from csiro_caab_taxa_active_v
     where lower(scientific_name) = lower(p_scientific_name);
    return l_spcode;
  end;

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
    'CM-WA-001', 'West Moore Island — multi-species candidate',
    'Charter / recreational line fishing', 'West Moore Island, Western Australia',
    'Long-form fishing episode whose source description names coral trout, red emperor, Chinaman fish and Spanish mackerel. It is a promising multi-species candidate, but no event queue is shown until time-coded species labels are reviewed.',
    'West Moore Island fishing episode', 'YouTube',
    'https://www.youtube.com/watch?v=b4KcVC11KVI',
    'https://www.youtube-nocookie.com/embed/b4KcVC11KVI',
    'Original uploader via YouTube', null,
    'annotation-pending', 'AFMA-CM-CANDIDATE-2026.09',
    'Candidate source only. No review events have been created because time-coded ground truth is pending.'
  );

  commit;
end;
/

prompt AFMA 125 complete
