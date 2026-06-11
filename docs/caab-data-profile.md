# CSIRO CAAB Data Profile

Source: CSIRO Codes for Australian Aquatic Biota (CAAB)

Downloaded file: `Data/caab_species_20260611.xls`

Converted working CSV: `.local/caab_species_20260611.csv`

CSIRO dump endpoint: <https://www.cmar.csiro.au/data/caab/create_caab_extract.cfm>

## Local Profile

- Workbook format: Excel 97-2003 OLE/BIFF `.xls`
- Sheet count: 1
- Header columns: 37
- Data rows: 63,191
- Unique `SPCODE` values: 63,191
- Blank `SPCODE` values: 0
- Duplicate `SPCODE` values: 0
- Converted CSV SHA-256: `793afa2ac0252aca8147537bba667ea67f886ecce0df7388c182c6ffc91b5515`

## Main Target Table

The AFMA table prefix requested in AI Hub task `afma-001` is `CSIRO_`.

Primary table: `CSIRO_CAAB_TAXA`

Natural primary key: `SPCODE`

Load ledger: `CSIRO_CAAB_LOADS`

Configuration table: `CSIRO_CAAB_CONFIG`

Common-name tables:

- `CSIRO_CAAB_FISHING_REGIONS`
- `CSIRO_CAAB_COMMON_NAMES`
- `CSIRO_CAAB_COMMON_NAME_SEARCH_V`

Report views:

- `CSIRO_CAAB_REPORT_SUMMARY_V`
- `CSIRO_CAAB_REPORT_CLASSES_V`
- `CSIRO_CAAB_REPORT_FISH_CLASSES_V`
- `CSIRO_CAAB_REPORT_RANKS_V`
- `CSIRO_CAAB_REPORT_STATUS_V`
- `CSIRO_CAAB_REPORT_HABITAT_V`
- `CSIRO_CAAB_REPORT_NAME_KINDS_V`
- `CSIRO_CAAB_REPORT_ALIAS_REGION_V`
- `CSIRO_CAAB_REPORT_REGION_DETAIL_V`

## Notable Columns

- `RECENT_SYNONYMS` and `TAXON_WWW_NOTES` can exceed 1,000 characters and are stored as CLOBs.
- Spreadsheet `CLASS` is stored as `CLASS_NAME` to avoid awkward SQL naming.
- Spreadsheet `RANK` is stored as `TAXON_RANK`.
- `DATE_EXTRACTED` was blank in the downloaded workbook; source file, source URL, load timestamp, and optional source page `data_as_at_text` are captured in `CSIRO_CAAB_LOADS`.

## Top-Level Counts From Local CSV

- Kingdom `Animalia`: 57,813 rows
- Kingdom `Chromista`: 2,715 rows
- Kingdom `Plantae`: 2,269 rows
- Rank `Species`: 46,722 rows
- Rank `species`: 9 rows
- Rank `Genus`: 12,986 rows
- Rank `Family`: 3,064 rows
- Habitat `M`: 36,243 rows
- List status `A`: 54,869 rows
- Non-current flag `Y`: 3,973 rows

## Live AFMA Load Counts

Verified in AIDEMODB workspace/schema `AFMA` on 2026-06-11:

- `CSIRO_CAAB_LOADS.LOAD_ID`: `1`
- `CSIRO_CAAB_TAXA`: `63,191`
- Active/current rows: `51,213`
- Species rows using case-insensitive rank: `46,731`
- Null `SPCODE`: `0`
- `CSIRO_CAAB_COMMON_NAMES`: `10,376`
- Demo-curated aliases: `55`
- `CSIRO_CAAB_FISHING_REGIONS`: `17`
