set define off

prompt AFMA 045 - Create CSIRO CAAB report views

create or replace view csiro_caab_report_summary_metrics as
select 10 metric_sequence,
       'CAAB records' metric_name,
       to_char(count(*), 'FM999G999G999') metric_value,
       'Rows loaded from the CSIRO CAAB extract' metric_context
  from csiro_caab_taxa
union all
select 20,
       'Current records',
       to_char(count(*), 'FM999G999G999'),
       'Rows with active list status and no current/non-current flag'
  from csiro_caab_taxa_active_v
union all
select 30,
       'Species rows',
       to_char(count(*), 'FM999G999G999'),
       'Rows where CAAB rank is SPECIES'
  from csiro_caab_taxa
 where upper(taxon_rank) = 'SPECIES'
union all
select 40,
       'Fish rows',
       to_char(count(*), 'FM999G999G999'),
       'Chordata fish-like classes used for common-name coverage'
  from csiro_caab_fish_taxa_v
union all
select 50,
       'Common names',
       to_char(count(*), 'FM999G999G999'),
       'CSIRO names plus curated Australian aliases'
  from csiro_caab_common_names
union all
select 60,
       'Alias regions',
       to_char(count(distinct region_code), 'FM999G999G999'),
       'Australian regions represented by curated common-name rows'
  from csiro_caab_common_names
 where region_code is not null
union all
select 70,
       'AI models',
       to_char(count(*), 'FM999G999G999'),
       'Workspace OCI Generative AI Services available to the Agent page'
  from apex_workspace_ai_services
 where provider_type_code = 'OCI_GENAI';
/

create or replace view csiro_caab_report_classes as
select coalesce(class_name, '(not supplied)') class_name,
       count(*) taxon_count,
       count(case when upper(taxon_rank) = 'SPECIES' then 1 end) species_count
  from csiro_caab_taxa
 group by coalesce(class_name, '(not supplied)')
 order by count(*) desc;
/

create or replace view csiro_caab_report_fish_classes as
select coalesce(class_name, '(not supplied)') class_name,
       count(*) taxon_count,
       count(case when upper(taxon_rank) = 'SPECIES' then 1 end) species_count
  from csiro_caab_fish_taxa_v
 group by coalesce(class_name, '(not supplied)')
 order by count(*) desc;
/

create or replace view csiro_caab_report_rank_mix as
select coalesce(taxon_rank, '(not supplied)') rank_name,
       count(*) taxon_count,
       count(case when coalesce(non_current_flag, 'N') not in ('Y', 'T') and coalesce(list_status_code, 'A') = 'A' then 1 end) current_count,
       count(case when coalesce(non_current_flag, 'N') in ('Y', 'T') or coalesce(list_status_code, 'A') <> 'A' then 1 end) non_current_count
  from csiro_caab_taxa
 group by coalesce(taxon_rank, '(not supplied)')
 order by count(*) desc;
/

create or replace view csiro_caab_report_status_mix as
select case
         when coalesce(non_current_flag, 'N') in ('Y', 'T') then 'Non-current'
         when coalesce(list_status_code, 'A') = 'A' then 'Active'
         when list_status_code is null then 'Unspecified'
         else 'Status ' || list_status_code
       end status_label,
       count(*) taxon_count
  from csiro_caab_taxa
 group by case
            when coalesce(non_current_flag, 'N') in ('Y', 'T') then 'Non-current'
            when coalesce(list_status_code, 'A') = 'A' then 'Active'
            when list_status_code is null then 'Unspecified'
            else 'Status ' || list_status_code
          end
 order by count(*) desc;
/

create or replace view csiro_caab_report_habitat_mix as
select coalesce(habitat_code, '(not supplied)') habitat_code,
       count(*) taxon_count,
       count(case when upper(taxon_rank) = 'SPECIES' then 1 end) species_count
  from csiro_caab_taxa
 group by coalesce(habitat_code, '(not supplied)')
 order by count(*) desc;
/

create or replace view csiro_caab_report_family_leaders as
select family,
       class_name,
       count(*) taxon_count,
       count(case when upper(taxon_rank) = 'SPECIES' then 1 end) species_count
  from csiro_caab_taxa
 where family is not null
 group by family, class_name
 order by count(*) desc;
/

create or replace view csiro_caab_report_common_name_kinds as
select replace(initcap(name_kind), '_', ' ') name_kind_label,
       name_kind,
       count(*) alias_count,
       count(distinct spcode) species_count,
       count(case when synthetic_flag = 'Y' then 1 end) demo_curated_count
  from csiro_caab_common_names
 group by name_kind
 order by count(*) desc;
/

create or replace view csiro_caab_report_alias_jurisdictions as
select coalesce(jurisdiction, 'AU') jurisdiction,
       count(*) alias_count,
       count(distinct spcode) species_count,
       count(case when synthetic_flag = 'Y' then 1 end) demo_curated_count
  from csiro_caab_common_names
 where name_kind not in ('CSIRO_PRIMARY', 'CSIRO_ALT')
 group by coalesce(jurisdiction, 'AU')
 order by count(*) desc;
/

create or replace view csiro_caab_report_alias_regions as
select r.region_group,
       r.region_name,
       coalesce(cn.jurisdiction, r.jurisdiction) jurisdiction,
       count(*) alias_count,
       count(distinct cn.spcode) species_count,
       max(cn.updated_at) latest_update_at
  from csiro_caab_common_names cn
  join csiro_caab_fishing_regions r
    on r.region_code = cn.region_code
 where cn.name_kind not in ('CSIRO_PRIMARY', 'CSIRO_ALT')
 group by r.region_group,
          r.region_name,
          coalesce(cn.jurisdiction, r.jurisdiction)
 order by count(*) desc, r.region_name;
/

create or replace view csiro_caab_report_curated_aliases as
select cn.common_name,
       cn.name_kind,
       cn.jurisdiction,
       cn.region_code,
       r.region_name,
       cn.locality,
       cn.first_observed_year,
       cn.last_observed_year,
       cn.source_confidence,
       cn.synthetic_flag,
       t.scientific_name,
       t.common_name caab_common_name,
       t.family,
       t.class_name,
       cn.notes
  from csiro_caab_common_names cn
  join csiro_caab_taxa t
    on t.spcode = cn.spcode
  left join csiro_caab_fishing_regions r
    on r.region_code = cn.region_code
 where cn.name_kind not in ('CSIRO_PRIMARY', 'CSIRO_ALT')
 order by t.scientific_name,
          cn.region_code,
          cn.common_name;
/

prompt AFMA 045 complete
