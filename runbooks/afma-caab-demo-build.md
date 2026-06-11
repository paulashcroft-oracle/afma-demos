# AFMA CAAB Demo Build Runbook

This runbook tracks the first AFMA demo application slice for AI Hub tasks `afma-001` through `afma-008`.

Live target:

- AIDEMODB workspace/schema: `AFMA`
- APEX application: `101`, `AFMA CAAB AI Demo`
- Runtime URL: <https://ge1c42bf10ae843-aidemodb.adb.ap-sydney-1.oraclecloudapps.com/ords/r/afma/afma-caab-ai-demo/home>
- Login URL: <https://ge1c42bf10ae843-aidemodb.adb.ap-sydney-1.oraclecloudapps.com/ords/r/afma/afma-caab-ai-demo/login?session=0>
- Builder home URL: <https://ge1c42bf10ae843-aidemodb.adb.ap-sydney-1.oraclecloudapps.com/ords/r/apex/app-builder/home?fb_flow_id=101&f4000_p1_flow=101>

## Source Data

1. Download the CAAB dump from CSIRO:
   <https://www.cmar.csiro.au/data/caab/create_caab_extract.cfm>
2. Save the workbook as `Data/caab_species_YYYYMMDD.xls`.
3. Convert the Excel 97 workbook to CSV:

```powershell
.\tools\export_caab_workbook.ps1 -SourcePath Data\caab_species_20260611.xls -CsvPath .local\caab_species_20260611.csv
```

4. Profile the converted CSV:

```powershell
& "C:\Users\pashcrof\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe" tools\profile_caab_csv.py
```

## Database Install

Run these scripts in the `AFMA` APEX workspace SQL Commands session or as the `AFMA` schema owner:

1. `database/010_create_csiro_caab_foundation.sql`
2. `database/020_create_csiro_caab_load_api.sql`
3. `database/025_create_csiro_fish_common_names.sql`
4. `database/030_create_csiro_caab_agent_api.sql`
5. `database/040_create_csiro_caab_page_api.sql`
6. `database/045_create_csiro_caab_report_views.sql`
7. `database/050_add_demo_user_login.sql`
8. `database/080_configure_afma_caab_app_pages.sql`

The loader expects a CSV version of the CAAB workbook because the source workbook is Excel 97 `.xls`.

Repeatable large-load path:

1. Generate base64 chunk SQL files from the CSV:

```powershell
node tools\create_caab_chunk_sql_batches.mjs .local\caab_species_20260611.csv .local\caab_chunk_batches
```

2. In APEX SQL Commands, run every generated `.local/caab_chunk_batches/caab_chunk_*.sql` file in order.
3. Run `.local/caab_chunk_batches/caab_finalize_load.sql`, which calls `CSIRO_CAAB_LOAD_API.LOAD_FROM_BASE64_CHUNKS`.
4. Rebuild common-name seed/search rows after the CAAB rows exist:

```sql
begin
  csiro_caab_common_name_api.rebuild_all;
end;
/
```

5. Verify `CSIRO_CAAB_TAXA` row count is `63,191`, `CSIRO_CAAB_COMMON_NAMES` count is `10,376`, and `CSIRO_CAAB_FISHING_REGIONS` count is `17`.

## APEX App Shell

App `101` is already confirmed in workspace `AFMA`.

`database/080_configure_afma_caab_app_pages.sql` surgically configures pages `1`, `2`, and `3` in AIDEMODB. Do not full import/replace the application in AIDEMODB while it is being used for collaborative development.

Page layout:

- Page 1: Home
  - Dynamic Content source: `return csiro_caab_page_api.home_html;`
  - Visual buttons to Agent and Reports.
  - Dataset count tiles.
- Page 2: CSIRO CAAB Agent
  - Dynamic Content source: `return csiro_caab_page_api.agent_html;`
  - Ajax Callback process name: `CSIRO_CAAB_AGENT_ASK`
  - Ajax Callback source:

```sql
begin
  htp.prn(csiro_caab_agent_api.ask_json(apex_application.g_x01, apex_application.g_x02));
end;
```

- Page 3: Reports
  - Summary cards and chart/report regions backed by `database/045_create_csiro_caab_report_views.sql`.
  - Current report set includes largest fish classes, taxonomic rank mix, status mix, habitat mix, curated aliases by jurisdiction, and curated regional alias detail.

## AI Service Hook

AFMA workspace web credential: `genai_credentials`.

The Agent page model dropdown reads workspace Generative AI Services directly. The standard AFMA catalog currently contains:

- `google.gemini-2.5-pro`
- `google.gemini-2.5-flash`
- `google.gemini-2.5-flash-lite`
- `xai.grok-4.20-reasoning`
- `cohere.command-latest`
- `cohere.command-plus-latest`
- `openai.gpt-oss-120b`
- `openai.gpt-oss-20b`
- `xai.grok-4.3`

If the default model needs to change, update `CSIRO_CAAB_CONFIG`:

```sql
update csiro_caab_config
   set config_value = '<confirmed APEX AI service static id>'
 where config_key = 'AI_SERVICE_STATIC_ID';
```

If a native APEX AI Agent is configured in the app, use static id `CSIRO_CAAB_AGENT` or update `CSIRO_CAAB_CONFIG.AI_AGENT_STATIC_ID` to the confirmed static id.

If `APEX_AI.CHAT` cannot return a model answer for the selected service, `CSIRO_CAAB_AGENT_API.ASK_JSON` returns a deterministic rich CAAB table/search/chart response so the page remains demoable and grounded in the loaded CAAB tables.

## Demo Access

`database/050_add_demo_user_login.sql` adds the Comcare-style passwordless demo access pattern to app 101:

- Page 9999 remains public and keeps the normal username/password login form for `CODEX` and administrator users.
- A `Demo User Login` static region is added above the normal login form with a `Continue as Demo User` button.
- The button submits request `DEMO_LOGIN`.
- The page process `Demo User Login` calls `apex_authentication.post_login` as `DEMO_USER`, then redirects to page 1.

Runtime smoke test:

1. Open `https://ge1c42bf10ae843-aidemodb.adb.ap-sydney-1.oraclecloudapps.com/ords/r/afma/afma-caab-ai-demo/login?session=0`.
2. Click `Continue as Demo User`.
3. Confirm the browser redirects to `/home` and `apex.env.APP_USER` is `DEMO_USER`.

## Verification

Minimum checks before moving the build tasks to Test:

- `select count(*) from csiro_caab_taxa;` returns `63191`.
- `select count(*) from csiro_caab_taxa where spcode is null;` returns `0`.
- `select count(*) from csiro_caab_taxa_active_v;` returns `51213`.
- `select count(*) from csiro_caab_common_names;` returns `10376`.
- `select count(*) from csiro_caab_fishing_regions;` returns `17`.
- Invalid object probe returns `AFMA_APP pages=1:Home, 2:CSIRO CAAB Agent, 3:Reports, 9999:Login Page invalid=none`.
- Home page renders the AFMA CAAB AI Demo visual button and dataset counts.
- Page 2 accepts a prompt such as `Show me jewfish and mulloway names used around NSW and include any local nicknames.` and returns rich output with `jewfish`, `jewie`, and `mulla` near the top of the common-name table.
- Page 2 model dropdown lists the nine workspace OCI Generative AI Services.
- Page 2 displays the CSIRO source refresh/download component.
- Page 3 renders summary cards and visual reports; live smoke test observed `15` chart/SVG elements.
- Login page 9999 displays `Continue as Demo User` and still displays the normal login fields.
- Clicking `Continue as Demo User` signs in as `DEMO_USER` without entering a password and redirects to page 1.
- AI Hub project metadata is updated with confirmed app ID, runtime URL, and builder URL.

## Live Verification On 2026-06-11

- Schema/app probe: pages `1`, `2`, `3`, `9999`; `CSIRO_CAAB%` invalid objects: `none`.
- Home page as `DEMO_USER`: rendered counts `63,191`, `51,213`, `46,731`.
- Reports page as `DEMO_USER`: rendered summary cards and `15` chart/SVG elements.
- Agent page as `DEMO_USER`: model dropdown displayed all nine services; NSW prompt returned `jewfish`, `jewie`, and `mulla` without passworded access.

## Captured Exports

Captured from AIDEMODB workspace `AFMA` on 2026-06-11:

- APEX application export: `exports/f101_afma_caab_ai_demo_20260611.sql`
- APEX SQL Scripts export: `exports/afma_caab_sql_scripts_20260611.sql`
