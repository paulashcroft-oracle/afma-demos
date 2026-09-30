# AFMA Demos

AFMA Demos is the AFMA project shell under the shared Codex Projects workspace.

## Purpose

This repository holds the replayable source assets for the AFMA APEX demo application: a CSIRO CAAB-backed exploration app and an AFMA-reviewer Catch Monitor using Oracle Autonomous Database 26ai and APEX.

## Initial Scope

- establish the AFMA project registration in AI Hub
- create and verify the `AFMA` APEX workspace in AIDEMODB
- add the shared `CODEX` workspace user for build verification
- add numbered database/data scripts, APEX application exports, and runbooks as the demo takes shape
- build the first CSIRO CAAB-backed APEX demo application with AI exploration, visual reports, and demo-user access
- compare versioned fisher-reported inputs with AI-assisted catch and wildlife observations in an authorised-officer review workflow

## Working Rules

- Read [`AGENTS.md`](AGENTS.md) and the shared parent [`../AGENTS.md`](../AGENTS.md) first.
- Keep secrets, credentials, wallets, and local browser profiles out of git.
- Use numbered, replayable scripts for database/data evolution only.
- Use APEXlang Standard Export as the canonical source for APEX pages, navigation, feedback UI, shared components, and application AI configuration once available.

## Current Demo Slice

- Data profile: [`docs/caab-data-profile.md`](docs/caab-data-profile.md)
- Fish-name research trail: [`docs/australian-fish-common-name-research.md`](docs/australian-fish-common-name-research.md)
- Build runbook: [`runbooks/afma-caab-demo-build.md`](runbooks/afma-caab-demo-build.md)
- Catch Monitor specification, selectable video set and AFMA/source research: [`docs/catch-monitor-specification.md`](docs/catch-monitor-specification.md)
- Database scripts: [`database/`](database/)
- Local data helpers: [`tools/`](tools/)
- Current APEXlang Standard Export: [`exports/apex/afma/101/20260929-after-caab-016-evidence-review-studio-apexlang-standard-export/`](exports/apex/afma/101/20260929-after-caab-016-evidence-review-studio-apexlang-standard-export/)
- Demo access: app page/login components are represented by the APEXlang application export; do not recreate them through numbered SQL. The retired `050_add_demo_user_login.sql` script was app-login metadata, not operational database/security provisioning.
- Feedback model: `database/085_create_ai_hub_feedback_model.sql` keeps only the database/data bridge for native APEX Feedback to AI Hub. Feedback pages, navigation, workspace credentials, and AI configs are application metadata owned by APEXlang/application source.
- Live SQL Scripts catalog cleanup on 2026-07-15: retained database/data scripts are `010`, `020`, `025`, `030`, `040`, `045`, `085_create_ai_hub_feedback_model.sql`, and `086_verify_ai_hub_feedback_model.sql`. Legacy app-metadata catalog scripts `050`, `080`, `090`, and the mixed `085_enable_ai_hub_feedback_model.sql` are no longer retained.

Live AIDEMODB target:

- Workspace/schema: `AFMA`
- Application: `101`, `AFMA CAAB AI Demo`
- Runtime: <https://ge1c42bf10ae843-aidemodb.adb.ap-sydney-1.oraclecloudapps.com/ords/r/afma/afma-caab-ai-demo/home>
- `ashcroftcloud.com` DNS: `afma.ashcroftcloud.com A 149.118.66.213`, TTL `60`, added on 2026-06-12 through AI Hub task `afma-013`
- Domain routing status: path shortcut verified. `https://aidemos.ashcroftcloud.com/afma` redirects to the AFMA CAAB AI Demo login page. `https://afma.ashcroftcloud.com/` remains DNS-only until host-aware root routing is deliberately designed and verified through the `AIDEMOS Domain Routing Standard`.
- Pages: Home, CSIRO CAAB Agent, Reports, Catch Monitor, Feedback, Login
- Loaded CAAB rows: `63,191`
- Common names and regional aliases: `10,376`
- Workspace AI services available to the Agent page: `9`
- Feedback capture: native APEX Feedback bubble/modal verified for `DEMO_USER`; AI Hub forwarding objects installed and controlled/dormant pending the live source-feedback API key and endpoint reachability check
- Catch Monitor: page 4 is live with selectable Australian footage, CAAB-backed reported/AI/reviewer identities, review decisions, reconciliation, report freeze/amend controls, audit events, a hybrid-incremental media library, and authorised test-video upload/HTTPS URL intake with explicit Sydney/Chicago/Google processing disclosures. Its Evidence Review Studio uses the AI Hub chat pattern, plays the exact stored visual-only segment when retained, supports optional timestamp attachments, preserves the officer/Gemini conversation, audits visual reinspection and CAAB lookup tools, and keeps structured corrections behind explicit officer acceptance. Native files use a resumable, SHA-256-checked in-page transfer; authorised URL imports store provenance-linked video-only BLOBs in AIDEMODB. Intake metadata keeps submitter input, AI proposals and editable reviewer-approved values separate. A visible processing-and-clearance queue keeps incomplete submissions out of the scenario selector; it is an internal demonstrator, not a fisher portal or autonomous compliance system.
