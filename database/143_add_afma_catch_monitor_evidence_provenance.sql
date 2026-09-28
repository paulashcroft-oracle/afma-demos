set define off

-- Execution authority: AFMA parsing schema owner through the verified AFMA APEX SQL Commands session.
-- Target: AIDEMODB workspace/schema AFMA; adds source-edit and evidence-group provenance to review observations.
prompt AFMA 143 - Add Catch Monitor evidence provenance

declare
  l_count number;
begin
  select count(*) into l_count
    from user_tab_columns
   where table_name = 'AFMA_CM_OBSERVATIONS'
     and column_name = 'EVIDENCE_ROLE';
  if l_count = 0 then
    execute immediate q'[alter table afma_cm_observations add evidence_role varchar2(30 char) default 'PRIMARY' not null]';
  end if;

  select count(*) into l_count
    from user_tab_columns
   where table_name = 'AFMA_CM_OBSERVATIONS'
     and column_name = 'EVIDENCE_GROUP_REF';
  if l_count = 0 then
    execute immediate 'alter table afma_cm_observations add evidence_group_ref varchar2(100 char)';
  end if;

  select count(*) into l_count
    from user_constraints
   where table_name = 'AFMA_CM_OBSERVATIONS'
     and constraint_name = 'AFMA_CM_OBS_CK_EVIDENCE_ROLE';
  if l_count = 0 then
    execute immediate q'[alter table afma_cm_observations add constraint afma_cm_obs_ck_evidence_role check (evidence_role in ('PRIMARY','PREVIEW_OR_REPLAY'))]';
  end if;
end;
/

comment on column afma_cm_observations.evidence_role is 'PRIMARY or PREVIEW_OR_REPLAY; preserves visibly depicted edited-source evidence for reviewer adjudication.';
comment on column afma_cm_observations.evidence_group_ref is 'Stable reference linking individual catches in one sequence or duplicate preview/full-sequence evidence.';

prompt AFMA 143 complete
