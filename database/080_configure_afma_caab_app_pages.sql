set define off

prompt AFMA 080 - Configure AFMA CAAB app pages

declare
  c_workspace_id constant number := 14392040298408914;
  c_app_id       constant number := 101;
  c_schema       constant varchar2(30) := 'AFMA';
  c_region_standard constant number := 4072358936313175081;
  c_region_blank    constant number := 4501440665235496320;
  c_report_standard constant number := 2538654340625403440;

  procedure create_report_column(
    p_id              in number,
    p_query_column_id in number,
    p_column_alias    in varchar2,
    p_sequence        in number,
    p_heading         in varchar2,
    p_hidden          in varchar2 default 'N'
  ) is
  begin
    wwv_flow_imp_page.create_report_columns(
      p_id => wwv_flow_imp.id(p_id),
      p_query_column_id => p_query_column_id,
      p_column_alias => p_column_alias,
      p_column_display_sequence => p_sequence,
      p_column_heading => p_heading,
      p_heading_alignment => 'LEFT',
      p_hidden_column => p_hidden,
      p_derived_column => 'N',
      p_include_in_export => 'Y'
    );
  end create_report_column;
begin
  apex_application_install.set_workspace_id(c_workspace_id);
  apex_application_install.set_application_id(c_app_id);
  apex_application_install.set_schema(c_schema);

  wwv_flow_imp.import_begin(
    p_version_yyyy_mm_dd => '2024.11.30',
    p_release => '24.2.16',
    p_default_workspace_id => c_workspace_id,
    p_default_application_id => c_app_id,
    p_default_id_offset => 0,
    p_default_owner => c_schema
  );

  for existing_page in (
    select page_id
      from apex_application_pages
     where application_id = c_app_id
       and page_id in (1, 2, 3)
     order by page_id desc
  ) loop
    wwv_flow_imp_page.remove_page(
      p_flow_id => c_app_id,
      p_page_id => existing_page.page_id
    );
  end loop;

  wwv_flow_imp_page.create_page(
    p_id => 1,
    p_name => 'Home',
    p_alias => 'HOME',
    p_step_title => 'AFMA CAAB AI Demo',
    p_autocomplete_on_off => 'OFF',
    p_page_template_options => '#DEFAULT#',
    p_protection_level => 'C',
    p_page_component_map => '24'
  );

  wwv_flow_imp_page.create_page_plug(
    p_id => wwv_flow_imp.id(1010800101),
    p_plug_name => 'AFMA CAAB Home',
    p_region_name => 'afma-caab-home',
    p_region_template_options => '#DEFAULT#',
    p_plug_template => c_region_blank,
    p_plug_display_sequence => 10,
    p_plug_display_point => 'BODY',
    p_plug_source => 'return csiro_caab_page_api.home_html;',
    p_function_body_language => 'PLSQL',
    p_plug_source_type => 'NATIVE_DYNAMIC_CONTENT',
    p_lazy_loading => false,
    p_plug_query_num_rows => 15
  );

  wwv_flow_imp_page.create_page(
    p_id => 2,
    p_name => 'CSIRO CAAB Agent',
    p_alias => 'CSIRO-CAAB-AGENT',
    p_step_title => 'CSIRO CAAB Agent',
    p_autocomplete_on_off => 'OFF',
    p_page_template_options => '#DEFAULT#',
    p_protection_level => 'C',
    p_page_component_map => '24'
  );

  wwv_flow_imp_page.create_page_plug(
    p_id => wwv_flow_imp.id(1010800201),
    p_plug_name => 'CSIRO CAAB Agent',
    p_region_name => 'afma-caab-agent',
    p_region_template_options => '#DEFAULT#',
    p_plug_template => c_region_blank,
    p_plug_display_sequence => 10,
    p_plug_display_point => 'BODY',
    p_plug_source => 'return csiro_caab_page_api.agent_html;',
    p_function_body_language => 'PLSQL',
    p_plug_source_type => 'NATIVE_DYNAMIC_CONTENT',
    p_lazy_loading => false,
    p_plug_query_num_rows => 15
  );

  wwv_flow_imp_page.create_page_process(
    p_id => wwv_flow_imp.id(1010800202),
    p_flow_id => c_app_id,
    p_flow_step_id => 2,
    p_process_sequence => 10,
    p_process_point => 'ON_DEMAND',
    p_process_type => 'NATIVE_PLSQL',
    p_process_name => 'CSIRO_CAAB_AGENT_ASK',
    p_process_sql_clob => q'~
begin
  htp.prn(
    csiro_caab_agent_api.ask_json(
      p_user_prompt => apex_application.g_x01,
      p_service_static_id => apex_application.g_x02
    )
  );
end;
~',
    p_process_clob_language => 'PLSQL',
    p_error_display_location => 'INLINE_IN_NOTIFICATION'
  );

  wwv_flow_imp_page.create_page(
    p_id => 3,
    p_name => 'Reports',
    p_alias => 'REPORTS',
    p_step_title => 'CAAB Reports',
    p_autocomplete_on_off => 'OFF',
    p_page_template_options => '#DEFAULT#',
    p_protection_level => 'C',
    p_page_component_map => '24'
  );

  wwv_flow_imp_page.create_page_plug(
    p_id => wwv_flow_imp.id(1010800301),
    p_plug_name => 'Reports Layout Styles',
    p_region_name => 'afma-caab-reports-styles',
    p_region_template_options => '#DEFAULT#:t-Region--hideHeader js-addHiddenHeadingRoleDesc',
    p_plug_template => c_region_blank,
    p_plug_display_sequence => 1,
    p_plug_display_point => 'BODY',
    p_plug_source => q'[
<style>
div.t-Region[aria-label="Reports Layout Styles"]{display:none!important;}
div.t-Region[aria-label="Summary"] .t-Report-wrap,
div.t-Region[aria-label="Summary"] .t-Report-tableWrap{width:100%;}
div.t-Region[aria-label="Summary"] .t-Report-report{display:block;width:100%;}
div.t-Region[aria-label="Summary"] .t-Report-report thead{display:none;}
div.t-Region[aria-label="Summary"] .t-Report-report tbody{display:grid;grid-template-columns:repeat(auto-fit,minmax(12rem,1fr));gap:.75rem;}
div.t-Region[aria-label="Summary"] .t-Report-report tr{display:flex;flex-direction:column;justify-content:space-between;border:1px solid var(--ut-component-border-color,#d5d9de);border-radius:.5rem;background:var(--ut-component-background-color,#fff);padding:.75rem;min-height:7.5rem;}
div.t-Region[aria-label="Summary"] .t-Report-report td{display:block;}
div.t-Region[aria-label="Summary"] .t-Report-cell{border:0!important;padding:0!important;background:transparent!important;}
div.t-Region[aria-label="Summary"] .t-Report-cell[headers="METRIC_NAME"]{color:var(--ut-component-text-muted-color,#4b5563);font-size:.75rem;font-weight:800;text-transform:uppercase;}
div.t-Region[aria-label="Summary"] .t-Report-cell[headers="METRIC_VALUE"]{font-size:2rem;font-weight:850;line-height:1.1;margin-block:.35rem;color:#183a54;}
div.t-Region[aria-label="Summary"] .t-Report-cell[headers="METRIC_CONTEXT"]{color:var(--ut-component-text-muted-color,#4b5563);font-size:.8125rem;}
div.t-Region[aria-label="Summary"] .t-Report-pagination{display:none!important;}
</style>
]',
    p_plug_source_type => 'NATIVE_STATIC',
    p_attributes => wwv_flow_t_plugin_attributes(wwv_flow_t_varchar2(
      'expand_shortcuts', 'N',
      'output_as', 'HTML',
      'show_line_breaks', 'Y'
    )).to_clob
  );

  wwv_flow_imp_page.create_report_region(
    p_id => wwv_flow_imp.id(1010800310),
    p_name => 'Summary',
    p_region_name => 'afma-caab-report-summary',
    p_template => c_region_standard,
    p_display_sequence => 10,
    p_region_template_options => '#DEFAULT#:t-Region--hideHeader js-addHiddenHeadingRoleDesc',
    p_component_template_options => '#DEFAULT#',
    p_source_type => 'NATIVE_SQL_REPORT',
    p_query_type => 'SQL',
    p_source => wwv_flow_string.join(wwv_flow_t_varchar2(
      'select metric_name,',
      '       metric_value,',
      '       metric_context',
      '  from csiro_caab_report_summary_metrics',
      ' order by metric_sequence'
    )),
    p_query_row_template => c_report_standard,
    p_query_num_rows => 20,
    p_query_options => 'DERIVED_REPORT_COLUMNS',
    p_query_show_nulls_as => '-',
    p_query_num_rows_type => 'ROWS_X_TO_Y',
    p_pagination_display_position => 'BOTTOM_RIGHT',
    p_csv_output => 'N',
    p_prn_output => 'N',
    p_sort_null => 'L',
    p_plug_query_strip_html => 'N'
  );

  create_report_column(1010800311, 1, 'METRIC_NAME', 10, 'Metric');
  create_report_column(1010800312, 2, 'METRIC_VALUE', 20, 'Value');
  create_report_column(1010800313, 3, 'METRIC_CONTEXT', 30, 'Context');

  wwv_flow_imp_page.create_page_plug(
    p_id => wwv_flow_imp.id(1010800320),
    p_plug_name => 'Largest Fish Classes',
    p_region_name => 'afma-caab-fish-classes-chart',
    p_region_template_options => '#DEFAULT#:t-Region--scrollBody',
    p_plug_template => c_region_standard,
    p_plug_display_sequence => 20,
    p_plug_display_point => 'BODY',
    p_plug_source_type => 'NATIVE_JET_CHART'
  );

  wwv_flow_imp_page.create_jet_chart(
    p_id => wwv_flow_imp.id(1010800321),
    p_region_id => wwv_flow_imp.id(1010800320),
    p_chart_type => 'bar',
    p_height => '320',
    p_orientation => 'horizontal',
    p_animation_on_display => 'auto',
    p_animation_on_data_change => 'auto',
    p_data_cursor => 'on',
    p_hover_behavior => 'dim',
    p_legend_rendered => 'on',
    p_show_value => true
  );

  wwv_flow_imp_page.create_jet_chart_series(
    p_id => wwv_flow_imp.id(1010800322),
    p_chart_id => wwv_flow_imp.id(1010800321),
    p_static_id => 'fish-taxa',
    p_seq => 10,
    p_name => 'Taxa',
    p_data_source_type => 'SQL',
    p_data_source => wwv_flow_string.join(wwv_flow_t_varchar2(
      'select class_name,',
      '       taxon_count',
      '  from csiro_caab_report_fish_classes',
      ' fetch first 10 rows only'
    )),
    p_series_type => 'bar',
    p_items_value_column_name => 'TAXON_COUNT',
    p_items_label_column_name => 'CLASS_NAME',
    p_items_label_rendered => true,
    p_color => '#007f7a'
  );

  wwv_flow_imp_page.create_jet_chart_series(
    p_id => wwv_flow_imp.id(1010800323),
    p_chart_id => wwv_flow_imp.id(1010800321),
    p_static_id => 'fish-species',
    p_seq => 20,
    p_name => 'Species',
    p_data_source_type => 'SQL',
    p_data_source => wwv_flow_string.join(wwv_flow_t_varchar2(
      'select class_name,',
      '       species_count',
      '  from csiro_caab_report_fish_classes',
      ' fetch first 10 rows only'
    )),
    p_series_type => 'bar',
    p_items_value_column_name => 'SPECIES_COUNT',
    p_items_label_column_name => 'CLASS_NAME',
    p_items_label_rendered => true,
    p_color => '#5c9f38'
  );

  wwv_flow_imp_page.create_jet_chart_axis(
    p_id => wwv_flow_imp.id(1010800324),
    p_chart_id => wwv_flow_imp.id(1010800321),
    p_axis => 'x',
    p_is_rendered => 'on',
    p_title => 'Rows',
    p_min => 0
  );

  wwv_flow_imp_page.create_jet_chart_axis(
    p_id => wwv_flow_imp.id(1010800325),
    p_chart_id => wwv_flow_imp.id(1010800321),
    p_axis => 'y',
    p_is_rendered => 'on'
  );

  wwv_flow_imp_page.create_page_plug(
    p_id => wwv_flow_imp.id(1010800330),
    p_plug_name => 'Taxonomic Rank Mix',
    p_region_name => 'afma-caab-rank-chart',
    p_region_template_options => '#DEFAULT#:t-Region--scrollBody',
    p_plug_template => c_region_standard,
    p_plug_display_sequence => 30,
    p_plug_display_point => 'BODY',
    p_plug_source_type => 'NATIVE_JET_CHART'
  );

  wwv_flow_imp_page.create_jet_chart(
    p_id => wwv_flow_imp.id(1010800331),
    p_region_id => wwv_flow_imp.id(1010800330),
    p_chart_type => 'bar',
    p_height => '300',
    p_animation_on_display => 'auto',
    p_animation_on_data_change => 'auto',
    p_data_cursor => 'on',
    p_hover_behavior => 'dim',
    p_legend_rendered => 'off',
    p_show_value => true
  );

  wwv_flow_imp_page.create_jet_chart_series(
    p_id => wwv_flow_imp.id(1010800332),
    p_chart_id => wwv_flow_imp.id(1010800331),
    p_static_id => 'rank-mix',
    p_seq => 10,
    p_name => 'Rows',
    p_data_source_type => 'SQL',
    p_data_source => wwv_flow_string.join(wwv_flow_t_varchar2(
      'select rank_name,',
      '       taxon_count',
      '  from csiro_caab_report_rank_mix',
      ' fetch first 12 rows only'
    )),
    p_series_type => 'bar',
    p_items_value_column_name => 'TAXON_COUNT',
    p_items_label_column_name => 'RANK_NAME',
    p_items_label_rendered => true,
    p_color => '#183a54'
  );

  wwv_flow_imp_page.create_jet_chart_axis(
    p_id => wwv_flow_imp.id(1010800333),
    p_chart_id => wwv_flow_imp.id(1010800331),
    p_axis => 'x',
    p_is_rendered => 'on'
  );

  wwv_flow_imp_page.create_jet_chart_axis(
    p_id => wwv_flow_imp.id(1010800334),
    p_chart_id => wwv_flow_imp.id(1010800331),
    p_axis => 'y',
    p_is_rendered => 'on',
    p_title => 'Rows',
    p_min => 0
  );

  wwv_flow_imp_page.create_page_plug(
    p_id => wwv_flow_imp.id(1010800340),
    p_plug_name => 'Current Status Mix',
    p_region_name => 'afma-caab-status-chart',
    p_region_template_options => '#DEFAULT#:t-Region--scrollBody',
    p_plug_template => c_region_standard,
    p_plug_display_sequence => 40,
    p_plug_display_point => 'BODY',
    p_plug_source_type => 'NATIVE_JET_CHART'
  );

  wwv_flow_imp_page.create_jet_chart(
    p_id => wwv_flow_imp.id(1010800341),
    p_region_id => wwv_flow_imp.id(1010800340),
    p_chart_type => 'pie',
    p_height => '300',
    p_animation_on_display => 'auto',
    p_animation_on_data_change => 'auto',
    p_data_cursor => 'on',
    p_hover_behavior => 'dim',
    p_legend_rendered => 'on',
    p_show_value => true
  );

  wwv_flow_imp_page.create_jet_chart_series(
    p_id => wwv_flow_imp.id(1010800342),
    p_chart_id => wwv_flow_imp.id(1010800341),
    p_static_id => 'status-mix',
    p_seq => 10,
    p_name => 'Status',
    p_data_source_type => 'SQL',
    p_data_source => wwv_flow_string.join(wwv_flow_t_varchar2(
      'select status_label,',
      '       taxon_count',
      '  from csiro_caab_report_status_mix'
    )),
    p_series_type => 'pie',
    p_items_value_column_name => 'TAXON_COUNT',
    p_items_label_column_name => 'STATUS_LABEL',
    p_items_label_rendered => true
  );

  wwv_flow_imp_page.create_page_plug(
    p_id => wwv_flow_imp.id(1010800350),
    p_plug_name => 'Habitat Code Mix',
    p_region_name => 'afma-caab-habitat-chart',
    p_region_template_options => '#DEFAULT#:t-Region--scrollBody',
    p_plug_template => c_region_standard,
    p_plug_display_sequence => 50,
    p_plug_display_point => 'BODY',
    p_plug_source_type => 'NATIVE_JET_CHART'
  );

  wwv_flow_imp_page.create_jet_chart(
    p_id => wwv_flow_imp.id(1010800351),
    p_region_id => wwv_flow_imp.id(1010800350),
    p_chart_type => 'bar',
    p_height => '300',
    p_orientation => 'horizontal',
    p_animation_on_display => 'auto',
    p_animation_on_data_change => 'auto',
    p_data_cursor => 'on',
    p_hover_behavior => 'dim',
    p_legend_rendered => 'off',
    p_show_value => true
  );

  wwv_flow_imp_page.create_jet_chart_series(
    p_id => wwv_flow_imp.id(1010800352),
    p_chart_id => wwv_flow_imp.id(1010800351),
    p_static_id => 'habitat-mix',
    p_seq => 10,
    p_name => 'Rows',
    p_data_source_type => 'SQL',
    p_data_source => wwv_flow_string.join(wwv_flow_t_varchar2(
      'select habitat_code,',
      '       taxon_count',
      '  from csiro_caab_report_habitat_mix',
      ' fetch first 10 rows only'
    )),
    p_series_type => 'bar',
    p_items_value_column_name => 'TAXON_COUNT',
    p_items_label_column_name => 'HABITAT_CODE',
    p_items_label_rendered => true,
    p_color => '#00a6c8'
  );

  wwv_flow_imp_page.create_jet_chart_axis(
    p_id => wwv_flow_imp.id(1010800353),
    p_chart_id => wwv_flow_imp.id(1010800351),
    p_axis => 'x',
    p_is_rendered => 'on',
    p_title => 'Rows',
    p_min => 0
  );

  wwv_flow_imp_page.create_jet_chart_axis(
    p_id => wwv_flow_imp.id(1010800354),
    p_chart_id => wwv_flow_imp.id(1010800351),
    p_axis => 'y',
    p_is_rendered => 'on'
  );

  wwv_flow_imp_page.create_page_plug(
    p_id => wwv_flow_imp.id(1010800360),
    p_plug_name => 'Curated Aliases by Jurisdiction',
    p_region_name => 'afma-caab-alias-jurisdiction-chart',
    p_region_template_options => '#DEFAULT#:t-Region--scrollBody',
    p_plug_template => c_region_standard,
    p_plug_display_sequence => 60,
    p_plug_display_point => 'BODY',
    p_plug_source_type => 'NATIVE_JET_CHART'
  );

  wwv_flow_imp_page.create_jet_chart(
    p_id => wwv_flow_imp.id(1010800361),
    p_region_id => wwv_flow_imp.id(1010800360),
    p_chart_type => 'bar',
    p_height => '300',
    p_animation_on_display => 'auto',
    p_animation_on_data_change => 'auto',
    p_data_cursor => 'on',
    p_hover_behavior => 'dim',
    p_legend_rendered => 'on',
    p_show_value => true
  );

  wwv_flow_imp_page.create_jet_chart_series(
    p_id => wwv_flow_imp.id(1010800362),
    p_chart_id => wwv_flow_imp.id(1010800361),
    p_static_id => 'alias-count',
    p_seq => 10,
    p_name => 'Aliases',
    p_data_source_type => 'SQL',
    p_data_source => wwv_flow_string.join(wwv_flow_t_varchar2(
      'select jurisdiction,',
      '       alias_count',
      '  from csiro_caab_report_alias_jurisdictions'
    )),
    p_series_type => 'bar',
    p_items_value_column_name => 'ALIAS_COUNT',
    p_items_label_column_name => 'JURISDICTION',
    p_items_label_rendered => true,
    p_color => '#007f7a'
  );

  wwv_flow_imp_page.create_jet_chart_series(
    p_id => wwv_flow_imp.id(1010800363),
    p_chart_id => wwv_flow_imp.id(1010800361),
    p_static_id => 'alias-species',
    p_seq => 20,
    p_name => 'Species',
    p_data_source_type => 'SQL',
    p_data_source => wwv_flow_string.join(wwv_flow_t_varchar2(
      'select jurisdiction,',
      '       species_count',
      '  from csiro_caab_report_alias_jurisdictions'
    )),
    p_series_type => 'bar',
    p_items_value_column_name => 'SPECIES_COUNT',
    p_items_label_column_name => 'JURISDICTION',
    p_items_label_rendered => true,
    p_color => '#5c9f38'
  );

  wwv_flow_imp_page.create_jet_chart_axis(
    p_id => wwv_flow_imp.id(1010800364),
    p_chart_id => wwv_flow_imp.id(1010800361),
    p_axis => 'x',
    p_is_rendered => 'on'
  );

  wwv_flow_imp_page.create_jet_chart_axis(
    p_id => wwv_flow_imp.id(1010800365),
    p_chart_id => wwv_flow_imp.id(1010800361),
    p_axis => 'y',
    p_is_rendered => 'on',
    p_title => 'Rows',
    p_min => 0
  );

  wwv_flow_imp_page.create_report_region(
    p_id => wwv_flow_imp.id(1010800370),
    p_name => 'Curated Regional Alias Detail',
    p_region_name => 'afma-caab-curated-aliases',
    p_template => c_region_standard,
    p_display_sequence => 70,
    p_region_template_options => '#DEFAULT#:t-Region--scrollBody',
    p_component_template_options => '#DEFAULT#:t-Report--stretch:t-Report--rowHighlight',
    p_source_type => 'NATIVE_SQL_REPORT',
    p_query_type => 'SQL',
    p_source => wwv_flow_string.join(wwv_flow_t_varchar2(
      'select common_name,',
      '       scientific_name,',
      '       caab_common_name,',
      '       replace(initcap(name_kind), ''_'', '' '') name_kind,',
      '       jurisdiction,',
      '       region_name,',
      '       locality,',
      '       first_observed_year,',
      '       last_observed_year,',
      '       source_confidence,',
      '       synthetic_flag',
      '  from csiro_caab_report_curated_aliases',
      ' order by scientific_name, common_name'
    )),
    p_query_row_template => c_report_standard,
    p_query_num_rows => 50,
    p_query_options => 'DERIVED_REPORT_COLUMNS',
    p_query_show_nulls_as => '-',
    p_query_num_rows_type => 'ROWS_X_TO_Y',
    p_pagination_display_position => 'BOTTOM_RIGHT',
    p_csv_output => 'Y',
    p_prn_output => 'N',
    p_sort_null => 'L',
    p_plug_query_strip_html => 'N'
  );

  create_report_column(1010800371, 1, 'COMMON_NAME', 10, 'Common Name');
  create_report_column(1010800372, 2, 'SCIENTIFIC_NAME', 20, 'Scientific Name');
  create_report_column(1010800373, 3, 'CAAB_COMMON_NAME', 30, 'CAAB Name');
  create_report_column(1010800374, 4, 'NAME_KIND', 40, 'Kind');
  create_report_column(1010800375, 5, 'JURISDICTION', 50, 'Jurisdiction');
  create_report_column(1010800376, 6, 'REGION_NAME', 60, 'Region');
  create_report_column(1010800377, 7, 'LOCALITY', 70, 'Locality');
  create_report_column(1010800378, 8, 'FIRST_OBSERVED_YEAR', 80, 'First Seen');
  create_report_column(1010800379, 9, 'LAST_OBSERVED_YEAR', 90, 'Last Seen');
  create_report_column(1010800380, 10, 'SOURCE_CONFIDENCE', 100, 'Source');
  create_report_column(1010800381, 11, 'SYNTHETIC_FLAG', 110, 'Demo');

  wwv_flow_imp.import_end(p_auto_install_sup_obj => false);
end;
/

prompt AFMA 080 complete
