# AFMA Demos

AFMA Demos is the AFMA project shell under the shared Codex Projects workspace.

## Purpose

This repository holds the replayable source assets for the first AFMA APEX demo application: a CSIRO CAAB-backed exploration app using Oracle Autonomous Database 26ai, APEX, and workspace-level Generative AI Services.

## Initial Scope

- establish the AFMA project registration in AI Hub
- create and verify the `AFMA` APEX workspace in AIDEMODB
- add the shared `CODEX` workspace user for build verification
- add numbered database/APEX scripts, exports, and runbooks as the demo takes shape
- build the first CSIRO CAAB-backed APEX demo application with AI exploration, visual reports, and demo-user access

## Working Rules

- Read [`AGENTS.md`](AGENTS.md) and the shared parent [`../AGENTS.md`](../AGENTS.md) first.
- Keep secrets, credentials, wallets, and local browser profiles out of git.
- Prefer numbered, replayable scripts for database and APEX setup.

## Current Demo Slice

- Data profile: [`docs/caab-data-profile.md`](docs/caab-data-profile.md)
- Fish-name research trail: [`docs/australian-fish-common-name-research.md`](docs/australian-fish-common-name-research.md)
- Build runbook: [`runbooks/afma-caab-demo-build.md`](runbooks/afma-caab-demo-build.md)
- Database scripts: [`database/`](database/)
- Local data helpers: [`tools/`](tools/)
- Demo access: `database/050_add_demo_user_login.sql` adds the passwordless `DEMO_USER` login button on the AFMA app login page.
- Feedback model: `database/085_enable_ai_hub_feedback_model.sql` adds native APEX Feedback capture and the controlled AI Hub source-feedback bridge.

Live AIDEMODB target:

- Workspace/schema: `AFMA`
- Application: `101`, `AFMA CAAB AI Demo`
- Runtime: <https://ge1c42bf10ae843-aidemodb.adb.ap-sydney-1.oraclecloudapps.com/ords/r/afma/afma-caab-ai-demo/home>
- Pages: Home, CSIRO CAAB Agent, Reports, Login
- Loaded CAAB rows: `63,191`
- Common names and regional aliases: `10,376`
- Workspace AI services available to the Agent page: `9`
- Feedback capture: native APEX Feedback bubble/modal verified for `DEMO_USER`; AI Hub forwarding objects installed and controlled/dormant pending the live source-feedback API key and endpoint reachability check
