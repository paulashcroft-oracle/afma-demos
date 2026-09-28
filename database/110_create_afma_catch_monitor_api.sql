set define off

-- Execution authority: AFMA parsing schema owner through the verified AFMA APEX SQL Commands session.
-- Target: AIDEMODB workspace/schema AFMA; additive database API and controlled demo records for application 101.
prompt AFMA 110 - Create Catch Monitor API and demo scenario

create or replace package afma_cm_api as
  procedure ensure_demo_scenario;

  procedure save_reported_catch(
    p_trip_id             in number,
    p_reported_catch_id   in number default null,
    p_original_taxon_text in varchar2,
    p_spcode              in varchar2 default null,
    p_reported_count      in number default null,
    p_reported_weight_kg  in number default null,
    p_catch_state         in varchar2 default 'UNKNOWN',
    p_notes               in varchar2 default null
  );

  procedure delete_reported_catch(
    p_trip_id           in number,
    p_reported_catch_id in number
  );

  procedure save_reported_interaction(
    p_trip_id             in number,
    p_original_taxon_text in varchar2,
    p_spcode              in varchar2 default null,
    p_reported_count      in number default null,
    p_interaction_kind    in varchar2 default null,
    p_notes               in varchar2 default null
  );

  procedure freeze_report(
    p_trip_id in number
  );

  procedure create_amendment(
    p_trip_id          in number,
    p_amendment_reason in varchar2
  );

  procedure review_observation(
    p_trip_id                    in number,
    p_observation_id             in number,
    p_reviewer_status            in varchar2,
    p_reviewed_spcode            in varchar2 default null,
    p_reviewed_count             in number default null,
    p_reviewed_interaction_class in varchar2 default null,
    p_reviewer_notes             in varchar2 default null
  );

  procedure complete_review(
    p_trip_id in number
  );
end afma_cm_api;
/

create or replace package body afma_cm_api as
  function caab_spcode(
    p_name in varchar2
  ) return varchar2 is
    l_spcode csiro_caab_taxa.spcode%type;
  begin
    select spcode
      into l_spcode
      from (
        select spcode,
               row_number() over (
                 order by case
                            when lower(scientific_name) = lower(trim(p_name)) then 1
                            when lower(common_name) = lower(trim(p_name)) then 2
                            else 3
                          end,
                          spcode
               ) rn
          from csiro_caab_taxa_active_v
         where lower(scientific_name) = lower(trim(p_name))
            or lower(common_name) = lower(trim(p_name))
            or lower(common_names_list) like '%' || lower(trim(p_name)) || '%'
      )
     where rn = 1;
    return l_spcode;
  exception
    when no_data_found then
      return null;
  end caab_spcode;

  procedure audit(
    p_trip_id     in number,
    p_entity_type in varchar2,
    p_entity_id   in number,
    p_action      in varchar2,
    p_detail      in varchar2 default null
  ) is
  begin
    insert into afma_cm_audit_events (
      trip_id, entity_type, entity_id, action_name, detail_text
    ) values (
      p_trip_id, upper(p_entity_type), p_entity_id, upper(p_action), substr(p_detail, 1, 2000)
    );
  end audit;

  procedure editable_context(
    p_trip_id          in number,
    p_report_version_id out number,
    p_operation_id      out number
  ) is
    l_status afma_cm_report_versions.report_status%type;
    l_region afma_cm_trips.region_name%type;
    l_gear afma_cm_trips.gear_method%type;
  begin
    select report_version_id, report_status
      into p_report_version_id, l_status
      from afma_cm_report_versions
     where trip_id = p_trip_id
       and version_no = (select max(version_no) from afma_cm_report_versions where trip_id = p_trip_id);

    if l_status not in ('DRAFT','RECORDED') then
      raise_application_error(-20001, 'The selected reported-data version is frozen. Create an amendment before editing.');
    end if;

    begin
      select min(operation_id)
        into p_operation_id
        from afma_cm_operations
       where report_version_id = p_report_version_id;
    exception
      when no_data_found then
        p_operation_id := null;
    end;

    if p_operation_id is null then
      select region_name, gear_method
        into l_region, l_gear
        from afma_cm_trips
       where trip_id = p_trip_id;

      insert into afma_cm_operations (
        report_version_id, operation_no, location_text, gear_method
      ) values (
        p_report_version_id, 1, l_region, l_gear
      )
      returning operation_id into p_operation_id;
    end if;
  end editable_context;

  procedure ensure_demo_scenario is
    l_trip_id number;
    l_report_id number;
    l_operation_id number;
    l_media_id number;
    l_run_id number;
    l_coral_spcode varchar2(20);
    l_emperor_spcode varchar2(20);
    l_existing number;
  begin
    select count(*) into l_existing from afma_cm_trips where trip_ref = 'CM-QLD-001';
    if l_existing > 0 then
      return;
    end if;

    l_coral_spcode := caab_spcode('Plectropomus leopardus');
    l_emperor_spcode := caab_spcode('Lutjanus sebae');
    if l_emperor_spcode is null then
      l_emperor_spcode := caab_spcode('Red emperor');
    end if;

    insert into afma_cm_trips (
      trip_ref, source_type, fishery_name, gear_method, region_name,
      vessel_ref, trip_start_at, trip_end_at, status, retention_review_at, notes
    ) values (
      'CM-QLD-001', 'SYNTHETIC_DEMO', 'Queensland reef line — internal UX sample',
      'Line fishing', 'Great Barrier Reef, Queensland coast', 'DEMO-VESSEL-07',
      to_timestamp_tz('2026-09-24 06:00:00 Australia/Brisbane', 'YYYY-MM-DD HH24:MI:SS TZR'),
      to_timestamp_tz('2026-09-24 15:30:00 Australia/Brisbane', 'YYYY-MM-DD HH24:MI:SS TZR'),
      'IN_REVIEW', trunc(sysdate) + 180,
      'Synthetic comparison record paired with public Australian coastal footage for an access-controlled product demonstration.'
    ) returning trip_id into l_trip_id;

    insert into afma_cm_report_versions (
      trip_id, version_no, report_status, source_type, source_provenance,
      recorded_at, frozen_at, frozen_by
    ) values (
      l_trip_id, 1, 'FROZEN_FOR_REVIEW', 'SYNTHETIC_DEMO',
      'Created inside Catch Monitor to demonstrate comparison with normal fisher-reported fields; not an actual declaration.',
      systimestamp - interval '4' day, systimestamp - interval '3' day,
      coalesce(sys_context('APEX$SESSION','APP_USER'), user)
    ) returning report_version_id into l_report_id;

    insert into afma_cm_operations (
      report_version_id, operation_no, set_at, haul_at, location_text, gear_method, effort_text
    ) values (
      l_report_id, 1,
      to_timestamp_tz('2026-09-24 06:15:00 Australia/Brisbane', 'YYYY-MM-DD HH24:MI:SS TZR'),
      to_timestamp_tz('2026-09-24 12:05:00 Australia/Brisbane', 'YYYY-MM-DD HH24:MI:SS TZR'),
      'Great Barrier Reef — broad demo region', 'Line fishing', 'Synthetic: 6 hours observed effort'
    ) returning operation_id into l_operation_id;

    insert into afma_cm_reported_catch (
      operation_id, original_taxon_text, spcode, mapping_status, mapping_method,
      mapping_confidence, reported_count, reported_weight_kg, catch_state, notes
    ) values (
      l_operation_id, 'Common coral trout', l_coral_spcode,
      case when l_coral_spcode is null then 'UNRESOLVED' else 'MATCHED' end,
      case when l_coral_spcode is null then null else 'CAAB_EXACT_SCIENTIFIC_NAME' end,
      case when l_coral_spcode is null then null else 1 end,
      4, 21.8, 'RETAINED', 'Synthetic fisher input for comparison.'
    );

    insert into afma_cm_reported_catch (
      operation_id, original_taxon_text, spcode, mapping_status, mapping_method,
      mapping_confidence, reported_count, reported_weight_kg, catch_state, notes
    ) values (
      l_operation_id, 'Red emperor', l_emperor_spcode,
      case when l_emperor_spcode is null then 'UNRESOLVED' else 'MATCHED' end,
      case when l_emperor_spcode is null then null else 'CAAB_NAME_LOOKUP' end,
      case when l_emperor_spcode is null then null else 1 end,
      1, 6.4, 'RETAINED', 'Synthetic fisher input for comparison.'
    );

    insert into afma_cm_media_assets (
      trip_id, asset_type, asset_role, title, source_system, source_record_url,
      embed_url, creator_provider, australian_region, rights_status, attribution_text,
      approved_purposes, restrictions, rights_checked_at, duration_seconds,
      view_type, quality_rating, expert_review_status, dataset_split, coverage_status
    ) values (
      l_trip_id, 'VIDEO', 'SOURCE_VIDEO', 'Queensland Coral Trout Fishery', 'YouTube',
      'https://www.youtube.com/watch?v=IrbFHTr4G3Y',
      'https://www.youtube-nocookie.com/embed/IrbFHTr4G3Y',
      'Original uploader via YouTube', 'Queensland coast', 'UNCONFIRMED_INTERNAL_ONLY',
      'Queensland Coral Trout Fishery; original uploader and YouTube source retained.',
      'DEMO_PLAYBACK,VALIDATION',
      'Access-controlled internal demo only; no redistribution or custom training until rights are confirmed.',
      trunc(sysdate), 355, 'Operational/deck and fishing scenes', 'DEMO_REVIEW',
      'PENDING', 'DEMO', 'UNCONFIRMED_INTERNAL_ONLY'
    ) returning media_asset_id into l_media_id;

    insert into afma_cm_media_assets (
      trip_id, spcode, original_taxon_text, asset_type, asset_role, title, source_system,
      source_record_url, creator_provider, australian_region, rights_status,
      attribution_text, approved_purposes, restrictions, rights_checked_at,
      view_type, quality_rating, expert_review_status, dataset_split, coverage_status
    ) values (
      l_trip_id, l_coral_spcode, 'Common coral trout', 'GUIDE', 'REFERENCE_DISPLAY',
      'CAAB / Australian National Fish Collection image catalogue', 'CSIRO CAAB',
      'https://www.cmar.csiro.au/caab/collection_images.cfm?image_set=FISHMAP',
      'CSIRO Australian National Fish Collection', 'Australia', 'UNCONFIRMED_INTERNAL_ONLY',
      'CSIRO CAAB / Australian National Fish Collection', 'REFERENCE_DISPLAY,MODEL_CONTEXT',
      'Record-level image and licence must be curated before external use or training.',
      trunc(sysdate), 'Specimen/reference catalogue', 'SOURCE_TRACED', 'PENDING',
      'REFERENCE', case when l_coral_spcode is null then 'NEEDS_TAXON_REVIEW' else 'COVERED' end
    );

    insert into afma_cm_media_assets (
      trip_id, asset_type, asset_role, title, source_system, source_record_url,
      embed_url, creator_provider, australian_region, rights_status, attribution_text,
      approved_purposes, restrictions, rights_checked_at, duration_seconds,
      view_type, quality_rating, expert_review_status, dataset_split, coverage_status
    ) values (
      l_trip_id, 'VIDEO', 'GUIDANCE', 'Best Practice Bycatch Handling', 'AFMA YouTube',
      'https://www.youtube.com/watch?v=kY-bN9Wn1eI',
      'https://www.youtube-nocookie.com/embed/kY-bN9Wn1eI', 'Australian Fisheries Management Authority',
      'Australia', 'UNCONFIRMED_INTERNAL_ONLY', 'Australian Fisheries Management Authority',
      'REFERENCE_DISPLAY,DEMO_PLAYBACK',
      'Official guidance link retained; internal demonstrator playback only pending confirmation for reuse.',
      trunc(sysdate), 358, 'Operational wildlife/bycatch guidance', 'SOURCE_TRACED',
      'PENDING', 'REFERENCE', 'UNCONFIRMED_INTERNAL_ONLY'
    );

    insert into afma_cm_analysis_runs (
      trip_id, report_version_id, media_asset_id, analysis_mode, model_version,
      media_manifest, run_status, completed_at, run_notes
    ) values (
      l_trip_id, l_report_id, l_media_id, 'SIMULATED_DEMO', 'deterministic-sample-v1',
      'AFMA-CM-DEMO-2026.09', 'COMPLETE', systimestamp,
      'Deterministic observations exercise the product workflow. They are not claims about the linked public video.'
    ) returning analysis_run_id into l_run_id;

    insert into afma_cm_observations (
      analysis_run_id, observation_type, start_second, end_second, ai_taxon_text,
      ai_spcode, ai_count, ai_confidence, ai_catch_state, ai_interaction_class, evidence_text
    ) values (
      l_run_id, 'CATCH', 74, 86, 'Common coral trout', l_coral_spcode,
      5, .86, 'RETAINED', 'NOT_APPLICABLE', 'Five track IDs cross the synthetic count line; one fish is partly occluded.'
    );

    insert into afma_cm_observations (
      analysis_run_id, observation_type, start_second, end_second, ai_taxon_text,
      ai_spcode, ai_count, ai_confidence, ai_catch_state, ai_interaction_class, evidence_text
    ) values (
      l_run_id, 'CATCH', 112, 119, 'Red emperor', l_emperor_spcode,
      1, .78, 'RETAINED', 'NOT_APPLICABLE', 'Single fish track; colour and profile support the proposed candidate.'
    );

    insert into afma_cm_observations (
      analysis_run_id, observation_type, start_second, end_second, ai_taxon_text,
      ai_count, ai_confidence, ai_interaction_class, evidence_text
    ) values (
      l_run_id, 'WILDLIFE', 168, 176, 'Marine turtle',
      1, .72, 'POSSIBLE_INTERACTION', 'Animal and line overlap in frame; physical contact cannot be established from the sample view.'
    );

    insert into afma_cm_observations (
      analysis_run_id, observation_type, start_second, end_second, ai_taxon_text,
      ai_count, ai_confidence, ai_interaction_class, evidence_text
    ) values (
      l_run_id, 'WILDLIFE', 203, 211, 'Seabird',
      1, .81, 'SIGHTING', 'Bird visible near the vessel; no physical contact is evidenced.'
    );

    audit(l_trip_id, 'TRIP', l_trip_id, 'DEMO_SCENARIO_CREATED',
      'Synthetic reported data, source-traced media catalogue entries and deterministic analysis observations created.');
    commit;
  end ensure_demo_scenario;

  procedure save_reported_catch(
    p_trip_id             in number,
    p_reported_catch_id   in number default null,
    p_original_taxon_text in varchar2,
    p_spcode              in varchar2 default null,
    p_reported_count      in number default null,
    p_reported_weight_kg  in number default null,
    p_catch_state         in varchar2 default 'UNKNOWN',
    p_notes               in varchar2 default null
  ) is
    l_report_id number;
    l_operation_id number;
    l_spcode varchar2(20) := trim(p_spcode);
    l_id number;
  begin
    if upper(coalesce(p_catch_state, 'UNKNOWN')) like 'INTERACTION:%' then
      afma_cm_api.save_reported_interaction(
        p_trip_id             => p_trip_id,
        p_original_taxon_text => p_original_taxon_text,
        p_spcode              => p_spcode,
        p_reported_count      => p_reported_count,
        p_interaction_kind    => substr(p_catch_state, length('INTERACTION:') + 1),
        p_notes               => p_notes
      );
      return;
    end if;

    if trim(p_original_taxon_text) is null then
      raise_application_error(-20002, 'Reported species or taxon text is required.');
    end if;
    editable_context(p_trip_id, l_report_id, l_operation_id);
    if l_spcode is null then
      l_spcode := caab_spcode(p_original_taxon_text);
    end if;

    if p_reported_catch_id is null then
      insert into afma_cm_reported_catch (
        operation_id, original_taxon_text, spcode, mapping_status, mapping_method,
        mapping_confidence, reported_count, reported_weight_kg, catch_state, notes
      ) values (
        l_operation_id, trim(p_original_taxon_text), l_spcode,
        case when l_spcode is null then 'UNRESOLVED' else 'MATCHED' end,
        case when l_spcode is null then null else 'CAAB_OPERATOR_LOOKUP' end,
        case when l_spcode is null then null else 1 end,
        p_reported_count, p_reported_weight_kg, upper(coalesce(p_catch_state, 'UNKNOWN')), p_notes
      ) returning reported_catch_id into l_id;
      audit(p_trip_id, 'REPORTED_CATCH', l_id, 'CREATED', trim(p_original_taxon_text));
    else
      update afma_cm_reported_catch
         set original_taxon_text = trim(p_original_taxon_text),
             spcode = l_spcode,
             mapping_status = case when l_spcode is null then 'UNRESOLVED' else 'MATCHED' end,
             mapping_method = case when l_spcode is null then null else 'CAAB_OPERATOR_LOOKUP' end,
             mapping_confidence = case when l_spcode is null then null else 1 end,
             reported_count = p_reported_count,
             reported_weight_kg = p_reported_weight_kg,
             catch_state = upper(coalesce(p_catch_state, 'UNKNOWN')),
             notes = p_notes
       where reported_catch_id = p_reported_catch_id
         and operation_id = l_operation_id;
      if sql%rowcount = 0 then
        raise_application_error(-20003, 'Reported catch line was not found in the editable version.');
      end if;
      l_id := p_reported_catch_id;
      audit(p_trip_id, 'REPORTED_CATCH', l_id, 'UPDATED', trim(p_original_taxon_text));
    end if;
    commit;
  end save_reported_catch;

  procedure save_reported_interaction(
    p_trip_id             in number,
    p_original_taxon_text in varchar2,
    p_spcode              in varchar2 default null,
    p_reported_count      in number default null,
    p_interaction_kind    in varchar2 default null,
    p_notes               in varchar2 default null
  ) is
    l_report_id number;
    l_operation_id number;
    l_spcode varchar2(20) := trim(p_spcode);
    l_id number;
  begin
    if trim(p_original_taxon_text) is null then
      raise_application_error(-20011, 'Reported wildlife or taxon text is required.');
    end if;
    editable_context(p_trip_id, l_report_id, l_operation_id);
    if l_spcode is null then
      l_spcode := caab_spcode(p_original_taxon_text);
    end if;

    insert into afma_cm_reported_interactions (
      operation_id, original_taxon_text, spcode, reported_count,
      interaction_kind, notes
    ) values (
      l_operation_id, trim(p_original_taxon_text), l_spcode, p_reported_count,
      trim(p_interaction_kind), p_notes
    ) returning reported_interaction_id into l_id;

    audit(p_trip_id, 'REPORTED_INTERACTION', l_id, 'CREATED', trim(p_original_taxon_text));
    commit;
  end save_reported_interaction;

  procedure delete_reported_catch(
    p_trip_id           in number,
    p_reported_catch_id in number
  ) is
    l_report_id number;
    l_operation_id number;
  begin
    editable_context(p_trip_id, l_report_id, l_operation_id);
    delete from afma_cm_reported_catch
     where reported_catch_id = p_reported_catch_id
       and operation_id = l_operation_id;
    if sql%rowcount = 0 then
      raise_application_error(-20004, 'Reported catch line was not found in the editable version.');
    end if;
    audit(p_trip_id, 'REPORTED_CATCH', p_reported_catch_id, 'DELETED');
    commit;
  end delete_reported_catch;

  procedure freeze_report(
    p_trip_id in number
  ) is
    l_report_id number;
    l_operation_id number;
  begin
    editable_context(p_trip_id, l_report_id, l_operation_id);
    update afma_cm_report_versions
       set report_status = 'FROZEN_FOR_REVIEW',
           frozen_at = systimestamp,
           frozen_by = coalesce(sys_context('APEX$SESSION','APP_USER'), user)
     where report_version_id = l_report_id;
    update afma_cm_trips set status = 'IN_REVIEW' where trip_id = p_trip_id;
    audit(p_trip_id, 'REPORT_VERSION', l_report_id, 'FROZEN_FOR_REVIEW');
    commit;
  end freeze_report;

  procedure create_amendment(
    p_trip_id          in number,
    p_amendment_reason in varchar2
  ) is
    l_source_id number;
    l_new_report_id number;
    l_new_operation_id number;
    l_version_no number;
    l_source_type afma_cm_report_versions.source_type%type;
    l_source_provenance afma_cm_report_versions.source_provenance%type;
  begin
    if trim(p_amendment_reason) is null then
      raise_application_error(-20005, 'An amendment reason is required.');
    end if;
    select report_version_id, version_no + 1, source_type, source_provenance
      into l_source_id, l_version_no, l_source_type, l_source_provenance
      from afma_cm_report_versions
     where trip_id = p_trip_id
       and version_no = (select max(version_no) from afma_cm_report_versions where trip_id = p_trip_id)
       and report_status = 'FROZEN_FOR_REVIEW';

    insert into afma_cm_report_versions (
      trip_id, version_no, report_status, source_type, source_provenance,
      amendment_reason, parent_version_id, recorded_at
    ) values (
      p_trip_id, l_version_no, 'DRAFT', l_source_type, l_source_provenance,
      trim(p_amendment_reason), l_source_id, systimestamp
    )
    returning report_version_id into l_new_report_id;

    for op in (select * from afma_cm_operations where report_version_id = l_source_id order by operation_no) loop
      insert into afma_cm_operations (
        report_version_id, operation_no, set_at, haul_at, location_text, gear_method, effort_text
      ) values (
        l_new_report_id, op.operation_no, op.set_at, op.haul_at, op.location_text, op.gear_method, op.effort_text
      ) returning operation_id into l_new_operation_id;

      insert into afma_cm_reported_catch (
        operation_id, original_taxon_text, spcode, mapping_status, mapping_method,
        mapping_confidence, reported_count, reported_weight_kg, catch_state,
        discard_reason, processing_state, notes
      )
      select l_new_operation_id, original_taxon_text, spcode, mapping_status, mapping_method,
             mapping_confidence, reported_count, reported_weight_kg, catch_state,
             discard_reason, processing_state, notes
        from afma_cm_reported_catch
       where operation_id = op.operation_id;

      insert into afma_cm_reported_interactions (
        operation_id, original_taxon_text, spcode, reported_count, event_at,
        fishing_stage, interaction_kind, life_injury_status, release_action, notes
      )
      select l_new_operation_id, original_taxon_text, spcode, reported_count, event_at,
             fishing_stage, interaction_kind, life_injury_status, release_action, notes
        from afma_cm_reported_interactions
       where operation_id = op.operation_id;
    end loop;
    update afma_cm_trips set status = 'DRAFT' where trip_id = p_trip_id;
    audit(p_trip_id, 'REPORT_VERSION', l_new_report_id, 'AMENDMENT_CREATED', trim(p_amendment_reason));
    commit;
  exception
    when no_data_found then
      raise_application_error(-20006, 'The latest version is not a frozen report that can be amended.');
  end create_amendment;

  procedure review_observation(
    p_trip_id                    in number,
    p_observation_id             in number,
    p_reviewer_status            in varchar2,
    p_reviewed_spcode            in varchar2 default null,
    p_reviewed_count             in number default null,
    p_reviewed_interaction_class in varchar2 default null,
    p_reviewer_notes             in varchar2 default null
  ) is
    l_status varchar2(30) := upper(trim(p_reviewer_status));
  begin
    if l_status not in ('CONFIRMED','CORRECTED','REJECTED','ESCALATED') then
      raise_application_error(-20007, 'Unsupported reviewer decision.');
    end if;
    update afma_cm_observations o
       set reviewer_status = l_status,
           reviewed_spcode = case when l_status = 'REJECTED' then null else coalesce(trim(p_reviewed_spcode), o.ai_spcode) end,
           reviewed_count = case when l_status = 'REJECTED' then null else coalesce(p_reviewed_count, o.ai_count) end,
           reviewed_interaction_class = case when l_status = 'REJECTED' then null else coalesce(upper(trim(p_reviewed_interaction_class)), o.ai_interaction_class) end,
           reviewer_notes = p_reviewer_notes,
           reviewed_at = systimestamp,
           reviewed_by = coalesce(sys_context('APEX$SESSION','APP_USER'), user)
     where o.observation_id = p_observation_id
       and exists (
         select 1
           from afma_cm_analysis_runs ar
          where ar.analysis_run_id = o.analysis_run_id
            and ar.trip_id = p_trip_id
       );
    if sql%rowcount = 0 then
      raise_application_error(-20008, 'Observation not found for this trip.');
    end if;
    audit(p_trip_id, 'OBSERVATION', p_observation_id, l_status, p_reviewer_notes);
    commit;
  end review_observation;

  procedure complete_review(
    p_trip_id in number
  ) is
    l_open number;
  begin
    select count(*)
      into l_open
      from afma_cm_observations o
      join afma_cm_analysis_runs ar on ar.analysis_run_id = o.analysis_run_id
     where ar.trip_id = p_trip_id
       and o.reviewer_status = 'NEEDS_REVIEW';
    if l_open > 0 then
      raise_application_error(-20009, 'Review cannot be completed while observations still need review.');
    end if;
    update afma_cm_trips set status = 'REVIEW_COMPLETE' where trip_id = p_trip_id;
    audit(p_trip_id, 'TRIP', p_trip_id, 'REVIEW_COMPLETED');
    commit;
  end complete_review;
end afma_cm_api;
/

begin
  afma_cm_api.ensure_demo_scenario;
end;
/

prompt AFMA 110 complete
