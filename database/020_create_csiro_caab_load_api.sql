set define off

prompt AFMA 020 - Create CSIRO CAAB load API

declare
  l_count number;
begin
  select count(*)
    into l_count
    from user_tables
   where table_name = 'CSIRO_CAAB_CSV_CHUNKS';

  if l_count = 0 then
    execute immediate q'[
      create table csiro_caab_csv_chunks (
        batch_key    varchar2(100 char) not null,
        chunk_no     number not null,
        encoding     varchar2(20 char) default 'BASE64' not null,
        chunk_text   clob not null,
        created_at   timestamp with local time zone default systimestamp not null,
        created_by   varchar2(255 char) default coalesce(sys_context('APEX$SESSION','APP_USER'), user) not null,
        constraint csiro_caab_csv_chunks_pk primary key (batch_key, chunk_no),
        constraint csiro_caab_csv_chunks_ck_encoding check (encoding in ('BASE64'))
      )
    ]';
  end if;
end;
/

create or replace package csiro_caab_load_api as
  procedure clear_base64_chunks(
    p_batch_key in varchar2
  );

  procedure append_base64_chunk(
    p_batch_key   in varchar2,
    p_chunk_no    in number,
    p_base64_text in clob
  );

  function load_csv_blob(
    p_content            in blob,
    p_file_name          in varchar2,
    p_source_url         in varchar2 default 'https://www.cmar.csiro.au/data/caab/create_caab_extract.cfm',
    p_source_file_sha256 in varchar2 default null,
    p_source_file_bytes  in number default null,
    p_data_as_at_text    in varchar2 default null,
    p_downloaded_at      in timestamp with local time zone default null,
    p_replace_existing   in varchar2 default 'Y',
    p_notes              in clob default null
  ) return number;

  function load_from_base64_chunks(
    p_batch_key          in varchar2,
    p_file_name          in varchar2,
    p_source_url         in varchar2 default 'https://www.cmar.csiro.au/data/caab/create_caab_extract.cfm',
    p_source_file_sha256 in varchar2 default null,
    p_source_file_bytes  in number default null,
    p_data_as_at_text    in varchar2 default null,
    p_downloaded_at      in timestamp with local time zone default null,
    p_replace_existing   in varchar2 default 'Y',
    p_notes              in clob default null
  ) return number;

  function load_from_apex_temp_file(
    p_temp_file_name     in varchar2,
    p_source_url         in varchar2 default 'https://www.cmar.csiro.au/data/caab/create_caab_extract.cfm',
    p_source_file_sha256 in varchar2 default null,
    p_data_as_at_text    in varchar2 default null,
    p_replace_existing   in varchar2 default 'Y',
    p_notes              in clob default null
  ) return number;
end csiro_caab_load_api;
/

create or replace package body csiro_caab_load_api as
  function clean_text(
    p_value in varchar2
  ) return varchar2 is
    l_value varchar2(32767) := trim(p_value);
  begin
    return nullif(l_value, '');
  end clean_text;

  function clean_number(
    p_value in varchar2
  ) return number is
    l_value varchar2(32767) := clean_text(p_value);
  begin
    if l_value is null then
      return null;
    end if;

    return to_number(l_value);
  exception
    when value_error then
      return null;
  end clean_number;

  function clean_timestamp(
    p_value in varchar2
  ) return timestamp is
    l_value varchar2(32767) := clean_text(p_value);
  begin
    if l_value is null then
      return null;
    end if;

    return to_timestamp(l_value, 'YYYY-MM-DD HH24:MI:SS');
  exception
    when others then
      return null;
  end clean_timestamp;

  procedure clear_base64_chunks(
    p_batch_key in varchar2
  ) is
  begin
    delete from csiro_caab_csv_chunks
     where batch_key = upper(trim(p_batch_key));
  end clear_base64_chunks;

  procedure append_base64_chunk(
    p_batch_key   in varchar2,
    p_chunk_no    in number,
    p_base64_text in clob
  ) is
  begin
    if p_batch_key is null then
      raise_application_error(-20102, 'CSV chunk batch key is required.');
    end if;

    if p_chunk_no is null or p_chunk_no < 1 then
      raise_application_error(-20103, 'CSV chunk number must be a positive integer.');
    end if;

    if p_base64_text is null or dbms_lob.getlength(p_base64_text) = 0 then
      raise_application_error(-20104, 'CSV chunk text is required.');
    end if;

    merge into csiro_caab_csv_chunks target
    using (
      select upper(trim(p_batch_key)) batch_key,
             p_chunk_no chunk_no,
             p_base64_text chunk_text
        from dual
    ) source
    on (
      target.batch_key = source.batch_key
      and target.chunk_no = source.chunk_no
    )
    when matched then
      update set chunk_text = source.chunk_text,
                 created_at = systimestamp,
                 created_by = coalesce(sys_context('APEX$SESSION','APP_USER'), user)
    when not matched then
      insert (batch_key, chunk_no, chunk_text)
      values (source.batch_key, source.chunk_no, source.chunk_text);
  end append_base64_chunk;

  procedure append_base64_to_blob(
    p_blob   in out nocopy blob,
    p_base64 in clob
  ) is
    l_pos pls_integer := 1;
    l_len pls_integer := dbms_lob.getlength(p_base64);
    l_chunk varchar2(32767);
    l_decoded raw(32767);
  begin
    while l_pos <= l_len loop
      l_chunk := dbms_lob.substr(p_base64, least(32000, l_len - l_pos + 1), l_pos);
      l_decoded := utl_encode.base64_decode(utl_raw.cast_to_raw(l_chunk));
      dbms_lob.writeappend(p_blob, utl_raw.length(l_decoded), l_decoded);
      l_pos := l_pos + length(l_chunk);
    end loop;
  end append_base64_to_blob;

  function load_csv_blob(
    p_content            in blob,
    p_file_name          in varchar2,
    p_source_url         in varchar2 default 'https://www.cmar.csiro.au/data/caab/create_caab_extract.cfm',
    p_source_file_sha256 in varchar2 default null,
    p_source_file_bytes  in number default null,
    p_data_as_at_text    in varchar2 default null,
    p_downloaded_at      in timestamp with local time zone default null,
    p_replace_existing   in varchar2 default 'Y',
    p_notes              in clob default null
  ) return number is
    l_load_id number;
    l_count number := 0;
    l_taxon csiro_caab_taxa%rowtype;
    l_error_message varchar2(1000);
  begin
    if p_content is null or dbms_lob.getlength(p_content) = 0 then
      raise_application_error(-20100, 'CSIRO CAAB load requires a CSV file.');
    end if;

    insert into csiro_caab_loads (
      source_url,
      source_file_name,
      source_file_sha256,
      source_file_bytes,
      data_as_at_text,
      downloaded_at,
      load_status,
      notes
    ) values (
      p_source_url,
      p_file_name,
      p_source_file_sha256,
      p_source_file_bytes,
      p_data_as_at_text,
      p_downloaded_at,
      'LOADED',
      p_notes
    )
    returning load_id into l_load_id;

    if upper(coalesce(p_replace_existing, 'Y')) = 'Y' then
      delete from csiro_caab_taxa;
    end if;

    for rec in (
      select line_number,
             col001 spcode,
             col002 scientific_name,
             col003 authority,
             col004 common_name,
             col005 family,
             col006 family_sequence,
             col007 assigned_family_code,
             col008 assigned_family_sequence,
             col009 recent_synonyms,
             col010 common_names_list,
             col011 kingdom,
             col012 phylum,
             col013 subphylum,
             col014 class_name,
             col015 subclass,
             col016 order_name,
             col017 suborder,
             col018 infraorder,
             col019 genus,
             col020 species,
             col021 sciname_informal,
             col022 subgenus,
             col023 subspecies,
             col024 variety,
             col025 date_last_modified,
             col026 undescribed_sp_flag,
             col027 habitat_code,
             col028 obis_classification_code,
             col029 date_extracted,
             col030 list_status_code,
             col031 itis_identifier,
             col032 parent_id,
             col033 display_name,
             col034 taxon_rank,
             col035 non_current_flag,
             col036 superseded_by,
             col037 taxon_www_notes
        from table(
          apex_data_parser.parse(
            p_content => p_content,
            p_file_name => p_file_name,
            p_skip_rows => 1
          )
        )
       where col001 is not null
    ) loop
      l_taxon.spcode := clean_text(rec.spcode);
      l_taxon.scientific_name := clean_text(rec.scientific_name);
      l_taxon.authority := clean_text(rec.authority);
      l_taxon.common_name := clean_text(rec.common_name);
      l_taxon.family := clean_text(rec.family);
      l_taxon.family_sequence := clean_number(rec.family_sequence);
      l_taxon.assigned_family_code := clean_text(rec.assigned_family_code);
      l_taxon.assigned_family_sequence := clean_number(rec.assigned_family_sequence);
      l_taxon.recent_synonyms := clean_text(rec.recent_synonyms);
      l_taxon.common_names_list := clean_text(rec.common_names_list);
      l_taxon.kingdom := clean_text(rec.kingdom);
      l_taxon.phylum := clean_text(rec.phylum);
      l_taxon.subphylum := clean_text(rec.subphylum);
      l_taxon.class_name := clean_text(rec.class_name);
      l_taxon.subclass := clean_text(rec.subclass);
      l_taxon.order_name := clean_text(rec.order_name);
      l_taxon.suborder := clean_text(rec.suborder);
      l_taxon.infraorder := clean_text(rec.infraorder);
      l_taxon.genus := clean_text(rec.genus);
      l_taxon.species := clean_text(rec.species);
      l_taxon.sciname_informal := clean_text(rec.sciname_informal);
      l_taxon.subgenus := clean_text(rec.subgenus);
      l_taxon.subspecies := clean_text(rec.subspecies);
      l_taxon.variety := clean_text(rec.variety);
      l_taxon.date_last_modified := clean_timestamp(rec.date_last_modified);
      l_taxon.undescribed_sp_flag := clean_text(rec.undescribed_sp_flag);
      l_taxon.habitat_code := clean_text(rec.habitat_code);
      l_taxon.obis_classification_code := clean_text(rec.obis_classification_code);
      l_taxon.date_extracted := clean_timestamp(rec.date_extracted);
      l_taxon.list_status_code := clean_text(rec.list_status_code);
      l_taxon.itis_identifier := clean_text(rec.itis_identifier);
      l_taxon.parent_id := clean_text(rec.parent_id);
      l_taxon.display_name := clean_text(rec.display_name);
      l_taxon.taxon_rank := clean_text(rec.taxon_rank);
      l_taxon.non_current_flag := clean_text(rec.non_current_flag);
      l_taxon.superseded_by := clean_text(rec.superseded_by);
      l_taxon.taxon_www_notes := clean_text(rec.taxon_www_notes);
      l_taxon.load_id := l_load_id;
      l_taxon.source_file_name := p_file_name;
      l_taxon.source_row_number := rec.line_number;

      if l_taxon.spcode is null then
        continue;
      end if;

      update csiro_caab_taxa
         set scientific_name = l_taxon.scientific_name,
             authority = l_taxon.authority,
             common_name = l_taxon.common_name,
             family = l_taxon.family,
             family_sequence = l_taxon.family_sequence,
             assigned_family_code = l_taxon.assigned_family_code,
             assigned_family_sequence = l_taxon.assigned_family_sequence,
             recent_synonyms = l_taxon.recent_synonyms,
             common_names_list = l_taxon.common_names_list,
             kingdom = l_taxon.kingdom,
             phylum = l_taxon.phylum,
             subphylum = l_taxon.subphylum,
             class_name = l_taxon.class_name,
             subclass = l_taxon.subclass,
             order_name = l_taxon.order_name,
             suborder = l_taxon.suborder,
             infraorder = l_taxon.infraorder,
             genus = l_taxon.genus,
             species = l_taxon.species,
             sciname_informal = l_taxon.sciname_informal,
             subgenus = l_taxon.subgenus,
             subspecies = l_taxon.subspecies,
             variety = l_taxon.variety,
             date_last_modified = l_taxon.date_last_modified,
             undescribed_sp_flag = l_taxon.undescribed_sp_flag,
             habitat_code = l_taxon.habitat_code,
             obis_classification_code = l_taxon.obis_classification_code,
             date_extracted = l_taxon.date_extracted,
             list_status_code = l_taxon.list_status_code,
             itis_identifier = l_taxon.itis_identifier,
             parent_id = l_taxon.parent_id,
             display_name = l_taxon.display_name,
             taxon_rank = l_taxon.taxon_rank,
             non_current_flag = l_taxon.non_current_flag,
             superseded_by = l_taxon.superseded_by,
             taxon_www_notes = l_taxon.taxon_www_notes,
             load_id = l_taxon.load_id,
             source_file_name = l_taxon.source_file_name,
             source_row_number = l_taxon.source_row_number,
             updated_at = systimestamp
       where spcode = l_taxon.spcode;

      if sql%rowcount = 0 then
        insert into csiro_caab_taxa (
          spcode,
          scientific_name,
          authority,
          common_name,
          family,
          family_sequence,
          assigned_family_code,
          assigned_family_sequence,
          recent_synonyms,
          common_names_list,
          kingdom,
          phylum,
          subphylum,
          class_name,
          subclass,
          order_name,
          suborder,
          infraorder,
          genus,
          species,
          sciname_informal,
          subgenus,
          subspecies,
          variety,
          date_last_modified,
          undescribed_sp_flag,
          habitat_code,
          obis_classification_code,
          date_extracted,
          list_status_code,
          itis_identifier,
          parent_id,
          display_name,
          taxon_rank,
          non_current_flag,
          superseded_by,
          taxon_www_notes,
          load_id,
          source_file_name,
          source_row_number
        ) values (
          l_taxon.spcode,
          l_taxon.scientific_name,
          l_taxon.authority,
          l_taxon.common_name,
          l_taxon.family,
          l_taxon.family_sequence,
          l_taxon.assigned_family_code,
          l_taxon.assigned_family_sequence,
          l_taxon.recent_synonyms,
          l_taxon.common_names_list,
          l_taxon.kingdom,
          l_taxon.phylum,
          l_taxon.subphylum,
          l_taxon.class_name,
          l_taxon.subclass,
          l_taxon.order_name,
          l_taxon.suborder,
          l_taxon.infraorder,
          l_taxon.genus,
          l_taxon.species,
          l_taxon.sciname_informal,
          l_taxon.subgenus,
          l_taxon.subspecies,
          l_taxon.variety,
          l_taxon.date_last_modified,
          l_taxon.undescribed_sp_flag,
          l_taxon.habitat_code,
          l_taxon.obis_classification_code,
          l_taxon.date_extracted,
          l_taxon.list_status_code,
          l_taxon.itis_identifier,
          l_taxon.parent_id,
          l_taxon.display_name,
          l_taxon.taxon_rank,
          l_taxon.non_current_flag,
          l_taxon.superseded_by,
          l_taxon.taxon_www_notes,
          l_taxon.load_id,
          l_taxon.source_file_name,
          l_taxon.source_row_number
        );
      end if;

      l_count := l_count + 1;
    end loop;

    update csiro_caab_loads
       set source_record_count = l_count,
           loaded_record_count = l_count,
           load_status = 'LOADED'
     where load_id = l_load_id;

    begin
      execute immediate q'[
        begin
          csiro_caab_common_name_api.rebuild_all;
        end;
      ]';
    exception
      when others then
        l_error_message := substr(sqlerrm, 1, 500);
        update csiro_caab_loads
           set notes = coalesce(notes, to_clob('')) || chr(10) ||
                       'Common-name rebuild skipped: ' || l_error_message
         where load_id = l_load_id;
    end;

    return l_load_id;
  exception
    when others then
      l_error_message := substr(sqlerrm, 1, 1000);

      if l_load_id is not null then
        update csiro_caab_loads
           set load_status = 'FAILED',
               notes = coalesce(notes, to_clob('')) || chr(10) || 'Load failed: ' || l_error_message
         where load_id = l_load_id;
      end if;

      raise;
  end load_csv_blob;

  function load_from_base64_chunks(
    p_batch_key          in varchar2,
    p_file_name          in varchar2,
    p_source_url         in varchar2 default 'https://www.cmar.csiro.au/data/caab/create_caab_extract.cfm',
    p_source_file_sha256 in varchar2 default null,
    p_source_file_bytes  in number default null,
    p_data_as_at_text    in varchar2 default null,
    p_downloaded_at      in timestamp with local time zone default null,
    p_replace_existing   in varchar2 default 'Y',
    p_notes              in clob default null
  ) return number is
    l_blob blob;
    l_chunk_count number := 0;
    l_load_id number;
  begin
    if p_batch_key is null then
      raise_application_error(-20105, 'CSV chunk batch key is required.');
    end if;

    dbms_lob.createtemporary(l_blob, true);

    for r in (
      select chunk_text
        from csiro_caab_csv_chunks
       where batch_key = upper(trim(p_batch_key))
       order by chunk_no
    ) loop
      l_chunk_count := l_chunk_count + 1;
      append_base64_to_blob(l_blob, r.chunk_text);
    end loop;

    if l_chunk_count = 0 then
      raise_application_error(-20106, 'No CSV chunks found for batch key ' || upper(trim(p_batch_key)) || '.');
    end if;

    l_load_id := load_csv_blob(
      p_content => l_blob,
      p_file_name => p_file_name,
      p_source_url => p_source_url,
      p_source_file_sha256 => p_source_file_sha256,
      p_source_file_bytes => coalesce(p_source_file_bytes, dbms_lob.getlength(l_blob)),
      p_data_as_at_text => p_data_as_at_text,
      p_downloaded_at => p_downloaded_at,
      p_replace_existing => p_replace_existing,
      p_notes => coalesce(p_notes, to_clob('')) || chr(10) ||
                 'Loaded from ' || to_char(l_chunk_count) || ' SQL base64 chunks.'
    );

    return l_load_id;
  end load_from_base64_chunks;

  function load_from_apex_temp_file(
    p_temp_file_name     in varchar2,
    p_source_url         in varchar2 default 'https://www.cmar.csiro.au/data/caab/create_caab_extract.cfm',
    p_source_file_sha256 in varchar2 default null,
    p_data_as_at_text    in varchar2 default null,
    p_replace_existing   in varchar2 default 'Y',
    p_notes              in clob default null
  ) return number is
    l_blob blob;
    l_file_name apex_application_temp_files.filename%type;
    l_bytes number;
  begin
    select blob_content,
           filename,
           dbms_lob.getlength(blob_content)
      into l_blob,
           l_file_name,
           l_bytes
      from apex_application_temp_files
     where name = p_temp_file_name
     order by created_on desc
     fetch first 1 row only;

    return load_csv_blob(
      p_content => l_blob,
      p_file_name => l_file_name,
      p_source_url => p_source_url,
      p_source_file_sha256 => p_source_file_sha256,
      p_source_file_bytes => l_bytes,
      p_data_as_at_text => p_data_as_at_text,
      p_replace_existing => p_replace_existing,
      p_notes => p_notes
    );
  exception
    when no_data_found then
      raise_application_error(-20101, 'Uploaded CAAB file was not found in APEX temporary files.');
  end load_from_apex_temp_file;
end csiro_caab_load_api;
/

prompt AFMA 020 complete
