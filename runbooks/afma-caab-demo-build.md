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
9. `database/100_create_afma_catch_monitor_foundation.sql`
10. `database/110_create_afma_catch_monitor_api.sql`
11. `database/120_create_afma_catch_monitor_page_api.sql`
12. `database/125_seed_afma_catch_monitor_video_library.sql`
13. `database/130_verify_afma_catch_monitor.sql`

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
- Page 4: Catch Monitor
  - Dynamic Content source: `return afma_cm_page_api.workbench_html;`
  - Ajax Callback process name: `AFMA_CM_ACTION`.
  - Intake Ajax Callback process name: `AFMA_CM_INTAKE_ACTION`; controlled project imports use `AFMA_CM_MEDIA_IMPORT_ACTION`; native browser uploads use `AFMA_CM_NATIVE_UPLOAD_ACTION`.
  - Native items: `P4_VIDEO_TITLE`, `P4_VIDEO_DESCRIPTION`, `P4_VIDEO_URL`, `P4_VIDEO_FILE`, `P4_RIGHTS_ACK`, `P4_HANDLING_ACK`. The upload control hashes the file and sends sequential chunks without a page submit, avoiding the unreliable `APEX_APPLICATION_TEMP_FILES` handoff that previously raised `ORA-20066`.
  - Uploads are limited to 35 MiB. URL registration initially stores metadata only. Both routes require authority and data-handling acknowledgement. URL rows enter `AWAITING_IMPORT` / `AWAITING_PROJECT_IMPORT`; stored native/imported BLOBs reach `READY_FOR_ANALYSIS` / `AWAITING_ANALYSIS_PROMPT_REVIEW` at 30% after byte-length/hash verification.
  - Working title and reviewer notes are optional. The submission ledger separates untouched submitter input, Gemini-proposed title/description/region/fishery/gear with provenance, and reviewer-approved editable values. The Generate control remains disabled until its prompt contract is approved; reviewer metadata editing is active.
  - Expand **Prompt contract review**, read the verbatim system/task prompts and JSON schema, tick the acknowledgement, then use **Approve and activate metadata prompt**. This records the authenticated reviewer and activation time; it does not start analysis automatically.
  - **Generate with Gemini Pro** is available only when stored video reaches the governed model action. Registered page URLs wait for a controlled project import because the current APEX attachment path requires video bytes. Jake Unger and The Life of a Fisherman currently have exact video-only BLOBs stored at the prompt-review gate; neither has proposed events or a model call yet.
  - The prior per-submission approval button is removed. The persistent disclosure and acknowledgements are sufficient for this controlled demo; prompt-contract approval remains separate.
  - The visible **Video processing & clearance** table shows stage, progress, proposed-event count and last update. Only `ANALYSIS_COMPLETE` / `READY_FOR_REVIEW` records appear in the scenario selector.
  - The UI states the full boundary: storage in AIDEMODB Sydney; OCI Generative AI entry in Chicago; external Google Americas Gemini processing; Oracle non-retention claims; Google no-training commitment plus documented transient-cache/abuse-monitoring caveats.
  - Authorised AFMA reviewer workflow; fishers are represented by a versioned `SYNTHETIC_DEMO` or `RECEIVED_RECORD`, not given an MVP portal.
  - The seeded `CM-QLD-001` scenario uses the source-traced Queensland Coral Trout Fishery video and four `SIMULATED_DEMO` observations. The observations are deterministic workflow fixtures and are not asserted to have been measured from the linked video.
  - Reported data can be amended only by creating a new version. `FROZEN_FOR_REVIEW` versions remain immutable.
  - AI identity/count/interaction proposals remain separate from officer decisions; `Confirm`, `Correct`, `Reject`, and `Escalate` actions are audited.
  - Catch and reviewed identities reference existing `CSIRO_CAAB_TAXA.SPCODE`; no second species master is created.
  - The media library records source, rights status, approved purposes, restrictions and coverage. `UNCONFIRMED_INTERNAL_ONLY` is usable only inside the controlled demo and is excluded from public redistribution or custom training.

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
- Application source/export evidence also represents page `4:Catch Monitor` and Ajax process `AFMA_CM_ACTION`.
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
- `database/130_verify_afma_catch_monitor.sql` reports all `AFMA_CM_%` objects valid, the video-intake table/package valid, and the five selectable supplied cases with their current evidence counts.
- Page 4 stages an HTTPS URL only after both acknowledgements, lists it as `AWAITING_PROJECT_IMPORT`, excludes it from the scenario selector until clearance, and clears the URL on the authorised delete action while retaining audit metadata.
- Page 4 hashes and transfers a supported upload through `AFMA_CM_NATIVE_UPLOAD_ACTION`, records byte/mime/file/checksum metadata in AIDEMODB, rejects empty/oversized/unsupported files, exposes chunk progress without leaving the page, and clears both submission/media-object BLOBs on deletion.
- Catch Monitor visibly labels `AI-assisted review — reviewer confirmation required`, `DEMO DATA`, source/region/context, annotation status, model/evidence version and media manifest.
- The video selector changes source, description, reported comparison data and review queue together through server-generated checksum-protected page URLs.
- Frozen reported data can be cloned as an amendment; the editable version provides audited entry for catch lines and wildlife interactions before it is re-frozen for review.
- The invalid-observation Ajax guard returns a controlled `ORA-20008` JSON response without mutating data, confirming the page/process/package boundary.
- Existing Home, CSIRO CAAB Agent and Reports pages still render without an APEX or database error after Catch Monitor deployment.

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

Captured from AIDEMODB workspace `AFMA` on 2026-09-28 for AI Hub task `caab-016`:

- Pre-change APEXlang Standard Export: `exports/apex/afma/101/20260928-before-caab-016-apexlang-standard-export/`
- Post-verification APEXlang Standard Export: `exports/apex/afma/101/20260928-after-caab-016-apexlang-standard-export/`
- Intake-clearance checkpoint: `exports/apex/afma/101/20260928-after-caab-016-video-intake-apexlang-standard-export/`
- Current media-import/native-upload checkpoint: `exports/apex/afma/101/20260928-after-caab-016-media-import-apexlang-standard-export/`
- The repository-safe copies exclude `workspace-components/credentials/**` and `workspace-components/generative-ai-services/**`.
- Runtime verification as `DEMO_USER` observed page 4 with four event cards, two reported catch lines, three media cards, CAAB codes `37311078` and `37346004`, full Catch Monitor styling, a controlled Ajax validation response, and passing Home/Agent/Reports regressions.
- Follow-up runtime verification on 2026-09-28 observed all five selector paths, per-video descriptions and queue counts, an empty pending-annotation queue for `CM-WA-001`, explicit non-grounded wording for `CM-QLD-001`, and passing Home/Agent/Reports regressions.
- Media-import verification on 2026-09-28 stored exact video-only BLOBs for Jake Unger and The Life of a Fisherman at the 30% prompt-review gate, with matching byte counts/SHA-256 values, zero events and zero model calls. A 193,091-byte native upload exercised the visible chunked browser path end to end, reached the same gate, and was then deleted; the test BLOB/media object were cleared and no import rows remained.
