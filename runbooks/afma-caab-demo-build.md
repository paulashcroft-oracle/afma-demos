# AFMA CAAB Demo Build Runbook

This runbook tracks the first AFMA demo application slice for AI Hub tasks `afma-001` through `afma-009`.

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

```bash
./tools/export_caab_workbook.sh Data/caab_species_20260611.xls .local/caab_species_20260611.csv
```

4. Profile the converted CSV:

```bash
"$HOME/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/bin/python3" tools/profile_caab_csv.py
```

## Database Install

Run these scripts in the `AFMA` APEX workspace SQL Commands session or as the `AFMA` schema owner:

1. `database/010_create_csiro_caab_foundation.sql`
2. `database/020_create_csiro_caab_load_api.sql`
3. `database/025_create_csiro_fish_common_names.sql`
4. `database/030_create_csiro_caab_agent_api.sql`
5. `database/040_create_csiro_caab_page_api.sql`
6. `database/045_create_csiro_caab_report_views.sql`
7. `database/085_create_ai_hub_feedback_model.sql`
8. `database/086_verify_ai_hub_feedback_model.sql`

Numbered SQL is the canonical source only for database/data evolution: tables, views, packages, report views, reference/config rows, and explicit data loads. APEX pages, navigation, feedback UI, page processes, AI Configs, Web Credential metadata, and application/static-file behavior are owned by APEXlang/application source. Legacy mixed scripts `050`, `080`, `085_enable`, and `090` are not retained as canonical install scripts.

The loader expects a CSV version of the CAAB workbook because the source workbook is Excel 97 `.xls`.

Repeatable large-load path:

1. Generate base64 chunk SQL files from the CSV:

```bash
"$HOME/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/bin/node" tools/create_caab_chunk_sql_batches.mjs .local/caab_species_20260611.csv .local/caab_chunk_batches
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

Pages `1`, `2`, `3`, and `9999` are application components and must be carried by APEXlang/application source or dated application exports, not numbered SQL. Do not full import/replace the application in AIDEMODB while it is being used for collaborative development.

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

The Agent page model dropdown reads workspace Generative AI Services directly. The app-level AI Configs and any native AI Agent shared components are APEX application metadata and must be represented by APEXlang/application source. The standard AFMA catalog currently contains:

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

If a native APEX AI Agent is configured in the app, use static id `CSIRO_CAAB_AGENT` or update `CSIRO_CAAB_CONFIG.AI_AGENT_STATIC_ID` to the confirmed static id through database config data while keeping the app AI Agent component in APEXlang/application source.

If `APEX_AI.CHAT` cannot return a model answer for the selected service, `CSIRO_CAAB_AGENT_API.ASK_JSON` returns a deterministic rich CAAB table/search/chart response so the page remains demoable and grounded in the loaded CAAB tables.

## Demo Access

The Comcare-style passwordless demo access pattern is an app-login component and is represented by application source/export, not a numbered SQL script:

- Page 9999 remains public and keeps the normal username/password login form for `CODEX` and administrator users.
- A `Demo User Login` static region is added above the normal login form with a `Continue as Demo User` button.
- The button submits request `DEMO_LOGIN`.
- The page process `Demo User Login` calls `apex_authentication.post_login` as `DEMO_USER`, then redirects to page 1.

No separate operational database/security provisioning script is retained for the current demo-user pattern. The retired `database/050_add_demo_user_login.sql` script contained APEX page/login metadata (`apex_application_install` and `wwv_flow_imp_page` calls), so it belongs in APEXlang/application source rather than numbered SQL.

Runtime smoke test:

1. Open `https://ge1c42bf10ae843-aidemodb.adb.ap-sydney-1.oraclecloudapps.com/ords/r/afma/afma-caab-ai-demo/login?session=0`.
2. Click `Continue as Demo User`.
3. Confirm the browser redirects to `/home` and `apex.env.APP_USER` is `DEMO_USER`.

## AI Hub Feedback Model

`database/085_create_ai_hub_feedback_model.sql` preserves the database/data part of the shared AI Hub/GovernMate feedback pattern for AFMA:

- adds `AI_HUB_FEEDBACK_FORWARDS` as the local AFMA forwarding ledger;
- adds `AI_HUB_FEEDBACK_CANDIDATES_V` over native `APEX_TEAM_FEEDBACK` for app `101`;
- adds package `AFMA_AI_HUB_FORWARDER` to build the AI Hub source-feedback payload and call `POST /projects/afma/feedback`;
- stores the project Kanban URL, public board URL, feedback endpoint URL, and credential static id in `CSIRO_CAAB_CONFIG`.

The visible `Feedback` navigation entry, modal pages `10030` and `10031`, feedback LOV, page process calling `APEX_UTIL.SUBMIT_FEEDBACK`, Web Credential metadata `AI_HUB_AFMA_FEEDBACK_API`, and any static/application behavior are APEX application metadata. They must be verified from APEXlang/application source or dated application export evidence, not recreated by numbered SQL.

Important deployment boundary:

- The raw `afma-apex-feedback` API key must be set only in the live APEX Web Credential or another approved secret store.
- The current endpoint is `https://apex.oraclecorp.com/pls/apex/ashcroft/ai-hub-api/v1/projects/afma/feedback`.
- As seen in the GovernMate proof, AIDEMODB server-side PL/SQL may not be able to reach the ASHCROFT `apex.oraclecorp.com` endpoint. Treat `AFMA_AI_HUB_FORWARDER` as installed and ready but controlled/dormant until the credential and database-reachable endpoint are verified.
- Do not schedule automatic forwarding until `database/086_verify_ai_hub_feedback_model.sql`, a read-only endpoint health check, and one idempotent `AFMA_AI_HUB_FORWARDER.FORWARD_FEEDBACK` smoke test pass without exposing secrets.

## Verification

Minimum checks before moving the build tasks to Test:

- `select count(*) from csiro_caab_taxa;` returns `63191`.
- `select count(*) from csiro_caab_taxa where spcode is null;` returns `0`.
- `select count(*) from csiro_caab_taxa_active_v;` returns `51213`.
- `select count(*) from csiro_caab_common_names;` returns `10376`.
- `select count(*) from csiro_caab_fishing_regions;` returns `17`.
- Database invalid object probe returns no invalid `CSIRO_CAAB%`, `AFMA_AI_HUB_FORWARDER`, or `AI_HUB_FEEDBACK%` objects.
- Application source/export evidence represents pages `1:Home`, `2:CSIRO CAAB Agent`, `3:Reports`, and `9999:Login Page`.
- Home page renders the AFMA CAAB AI Demo visual button and dataset counts.
- Page 2 accepts a prompt such as `Show me jewfish and mulloway names used around NSW and include any local nicknames.` and returns rich output with `jewfish`, `jewie`, and `mulla` near the top of the common-name table.
- Page 2 model dropdown lists the nine workspace OCI Generative AI Services.
- Page 2 displays the CSIRO source refresh/download component.
- Page 2 keeps the agent title/model selector pinned at the top of the agent viewport, keeps the prompt composer pinned at the bottom, and lets the chat thread scroll in the remaining space on desktop and mobile.
- Page 2 submits the prompt when the user presses `Enter`; `Shift+Enter` inserts a new line.
- Page 2 renders supported fenced Mermaid diagrams to SVG, with escaped source fallback if the Mermaid runtime cannot load.
- Page 3 renders summary cards and visual reports; live smoke test observed `15` chart/SVG elements.
- Login page 9999 displays `Continue as Demo User` and still displays the normal login fields.
- Clicking `Continue as Demo User` signs in as `DEMO_USER` without entering a password and redirects to page 1.
- Navigation bar displays `Feedback` for authenticated users when APEX feedback is enabled.
- Page `10030` submits native APEX feedback and page `10031` confirms capture.
- `AFMA_AI_HUB_FORWARDER`, `AI_HUB_FEEDBACK_FORWARDS`, and `AI_HUB_FEEDBACK_CANDIDATES_V` are valid.
- APEX Web Credential metadata `AI_HUB_AFMA_FEEDBACK_API` exists in the live workspace or APEX application/source evidence; the raw key is not stored in the repository.
- AI Hub project metadata is updated with confirmed app ID, runtime URL, and builder URL.

## Live Verification On 2026-06-11

- Schema/app probe: pages `1`, `2`, `3`, `9999`; `CSIRO_CAAB%` invalid objects: `none`.
- Home page as `DEMO_USER`: rendered counts `63,191`, `51,213`, `46,731`.
- Reports page as `DEMO_USER`: rendered summary cards and `15` chart/SVG elements.
- Agent page as `DEMO_USER`: model dropdown displayed all nine services; NSW prompt returned `jewfish`, `jewie`, and `mulla` without passworded access.

## Feedback Verification On 2026-06-12

- Historical note: this verification was originally delivered with the legacy mixed `database/085_enable_ai_hub_feedback_model.sql`.
- Current source-control boundary keeps only the database/data portion as `database/085_create_ai_hub_feedback_model.sql`. APEX pages/navigation/feedback UI/Web Credential metadata are application metadata and must be represented by APEXlang/application source.
- `database/086_verify_ai_hub_feedback_model.sql` verified:
  - `AFMA_AI_HUB_FORWARDER` package/body, `AI_HUB_FEEDBACK_FORWARDS`, and `AI_HUB_FEEDBACK_CANDIDATES_V` are valid.
  - Config rows exist for the AFMA AI Hub Kanban URL, public board URL, feedback endpoint URL, and credential static id.
- Runtime verified as `demo_user`: the feedback bubble appears in the top-right navigation beside the current user, opens the `Feedback` modal, and submits native APEX feedback through `APEX_UTIL.SUBMIT_FEEDBACK`.
- `AI_HUB_FEEDBACK_CANDIDATES_V` reported `1` pending feedback candidate after the verification submission.
- Do not mark the AFMA feedback bridge as automatically forwarding until the `AI_HUB_AFMA_FEEDBACK_API` raw key and AIDEMODB-to-AI-Hub endpoint reachability are verified.

## AI Agent Verification On 2026-06-12

- Historical note: live AI wiring originally used `database/090_configure_afma_caab_ai_configs.sql` as a surgical delivery script. Current source-control boundary keeps AI Configs as APEX application metadata, not numbered SQL.
- Replayed `database/030_create_csiro_caab_agent_api.sql` and `database/040_create_csiro_caab_page_api.sql` in workspace `AFMA` for database package/API behavior.
- Page 2 now calls live `APEX_AI.CHAT` via app AI Config static IDs instead of always returning the deterministic fallback.
- Runtime prompt `What is the most populous species?` returned a live model answer that correctly explained CAAB is a taxonomy/code catalogue, not an abundance survey.
- Runtime prompt requesting shark records as a Markdown table rendered an HTML table in the answer area; verification observed `answerOnlyTableCount = 1` and `rawPipeTableVisible = false`.
- Markdown rendering supports headings, lists, blockquotes, horizontal rules, fenced code, inline code, bold, italics, HTTP links, images, standard pipe tables, and loose pipe tables. Parser failures fall back to escaped preformatted text.
- Human chat messages are right-aligned at roughly 80 percent of the thread width to visually separate user prompts from agent responses. Runtime layout verification observed `widthRatio = 0.776` and `leftOffsetRatio = 0.209` in the live page.

## Responsive Agent Verification On 2026-06-12

- Replayed `database/030_create_csiro_caab_agent_api.sql` and `database/040_create_csiro_caab_page_api.sql` in workspace `AFMA` for database package/API behavior. Responsive page behavior is application/static behavior and belongs in APEXlang/application source.
- Page 2 keeps the title/actions/model selector pinned above the chat flow and the prompt composer pinned at the bottom of the agent viewport.
- Desktop verification at `1280x900` observed `headAboveThread = true`, `threadAboveComposer = true`, `composerNearViewportBottom = true`, `threadScrollableSpace = true`, and `promptVisible = true`.
- Mobile verification at `390x844` observed the same layout checks as `true`.
- Runtime keyboard verification observed `enterFired = true`; `Shift+Enter` remains reserved for multi-line prompts.
- Runtime rendering verification observed `tableCount = 1` and Mermaid `status = Y`, `hasSvg = true` for a fenced `mermaid` response block.

## APEXlang And SQL Source Cleanup On 2026-07-15

- Shared guidance revision `2026-07-15.3` applied the source-control boundary: APEXlang/application static assets own application behavior; numbered SQL owns database/data evolution only.
- Captured an APEXlang Standard Export for app `101` at `exports/apex/afma/101/20260715-apexlang-standard-export/`. The export contains pages `1`, `2`, `3`, `9999`, `10030`, `10031`, shared navigation/LOVs/static files, AI agents, workspace Generative AI Services, and `genai_credentials` metadata.
- Retained the database/data portion of the legacy mixed feedback script as `database/085_create_ai_hub_feedback_model.sql`.
- Updated `database/086_verify_ai_hub_feedback_model.sql` so it verifies only database/data objects and config rows. APEX pages, navigation, feedback UI, Web Credentials, AI Configs, and static assets are verified from APEXlang/application source.
- Live APEX SQL Scripts catalog cleanup was completed by save/delete only; no SQL Script was run.
- Live catalog retained these rows after cleanup: `010_create_csiro_caab_foundation.sql`, `020_create_csiro_caab_load_api.sql`, `025_create_csiro_fish_common_names.sql`, `030_create_csiro_caab_agent_api.sql`, `040_create_csiro_caab_page_api.sql`, `045_create_csiro_caab_report_views.sql`, `085_create_ai_hub_feedback_model.sql`, and `086_verify_ai_hub_feedback_model.sql`.
- Live catalog no longer retained `050_add_demo_user_login.sql`, `080_configure_afma_caab_app_pages.sql`, `090_configure_afma_caab_ai_configs.sql`, or the mixed `085_enable_ai_hub_feedback_model.sql`.
- Live editor verification for `085_create_ai_hub_feedback_model.sql` reported file id `15343385457047155`, source length `20724`, `620` lines, and no forbidden application-metadata patterns (`wwv_flow_imp`, `apex_application_install`, APEX credential creation, page/navigation/LOV, or AI config creation calls).
- Live editor verification for `086_verify_ai_hub_feedback_model.sql` reported file id `15444330100052227`, source length `1410`, `41` lines, and no forbidden application-metadata patterns.
- The SQL Scripts export helper was attempted after cleanup but did not produce a completed download. The row-level catalog inspection and live source-pattern verification above are the retained live evidence for this cleanup slice.

## Captured Exports

Captured from AIDEMODB workspace `AFMA` on 2026-06-11:

- APEX application export: `exports/f101_afma_caab_ai_demo_20260611.sql`
- APEX SQL Scripts export: `exports/afma_caab_sql_scripts_20260611.sql`

Captured from AIDEMODB workspace `AFMA` on 2026-06-12 after feedback-model verification:

- APEX application export: `exports/f101_afma_caab_ai_demo_20260612.sql`
- APEX SQL Scripts export: `exports/afma_caab_sql_scripts_20260612.sql`

Captured from AIDEMODB workspace `AFMA` on 2026-06-12 after live AI and rendering verification:

- APEX application export: `exports/f101_afma_caab_ai_demo_20260612_ai_agent_rendering_fix.sql`
- APEX SQL Scripts export: `exports/afma_caab_sql_scripts_20260612_ai_agent_rendering_fix.sql`

Captured from AIDEMODB workspace `AFMA` on 2026-06-12 after responsive layout and Mermaid verification:

- APEX application export: `exports/f101_afma_caab_ai_demo_20260612_responsive_mermaid.sql`
- APEX SQL Scripts export: `exports/afma_caab_sql_scripts_20260612_responsive_mermaid.sql`

Captured from AIDEMODB workspace `AFMA` on 2026-07-15 after APEXlang/source-control cleanup:

- APEXlang Standard Export: `exports/apex/afma/101/20260715-apexlang-standard-export/`
- APEX SQL Scripts export: not captured; the export helper did not produce a completed download. Live catalog rows and source-pattern verification are recorded in `APEXlang And SQL Source Cleanup On 2026-07-15`.
