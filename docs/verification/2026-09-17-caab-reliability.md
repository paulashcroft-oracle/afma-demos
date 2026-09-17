# CAAB reliability implementation evidence

Date: 17 September 2026. AI Hub task: `caab-015`. Owner: Codex task `01a0ad20-e77a-74a1-94db-8ac7063c5f86`.

## Scope and current state

Paul's “authorized” instruction and the AI Hub coordinator's subsequent implementation handoff authorize the September review recommendations R01–R10. The coordinator explicitly included the scoped AIDEMODB `caab` feedback migration and acknowledgement test. Human acceptance remains separate. Real source-data refresh, full application replacement, broader security changes and unrelated application work are excluded.

Target: AIDEMODB, AFMA workspace/schema, application 101 (`AFMA CAAB AI Demo`, alias `AFMA-CAAB-AI-DEMO`), AI Hub project `caab`, actor `codex-caab`.

**Implementation/deployment:** candidate source preparation; no application/package deployment yet.

**Verification:** live SQL identity and AI Hub discovery passed. Current deployed package-body/app reconciliation and browser tests pending the coordinated Chrome window. SQLcl `apex list -applicationid 101` returned no visible components in the CODEX connection; this does not prove app absence. No access grant was changed.

**Housekeeping:** task-owned lifecycle run initialized; export/test scratch is under the ignored run. No cleanup claimed. The saved checkout's modified `.gitignore` and untracked `_gitignore_for_mac_migration` remain untouched.

## Git and checkpoint

Worktree: `C:/Users/pashcrof/.codex/worktrees/1d21/AFMA Demos`. Branch: `codex/caab-reliability`, created from verified saved commit `3eb70349f93bf4e94abeb27ebd5e1d73b6adeddd`.

Configured remote: `https://github.com/paulashcroft-oracle/afma-demos.git`. A normal-user, read-only remote probe succeeded. Current pre-change and post-change APEX exports are pending; no live change may rely on the July export as a proven current baseline.

## Guidance

Manifest revision `2026-09-17.2`; topics: credentials, apex-source-control, ai-hub-workflow, aidemodb-bootstrap, apex-browser, github-delivery, artifact-hygiene. All required files were fully reread after context compaction; no reads were reused from the compacted summary.

Fully read paths:

- `C:/Users/pashcrof/Documents/Codex Projects/AGENTS.md`
- `C:/Users/pashcrof/Documents/Codex Projects/AFMA Demos/AGENTS.md`
- `C:/Users/pashcrof/Documents/Codex Projects/Demo Project Standards/shared-guidance-refresh-standard.md`
- `C:/Users/pashcrof/Documents/Codex Projects/Demo Project Standards/codex-authorization-and-follow-through-standard.md`
- `C:/Users/pashcrof/Documents/Codex Projects/Demo Project Standards/shared-credential-storage-standard.md`
- `C:/Users/pashcrof/Documents/Codex Projects/Demo Project Standards/apex-export-git-checkpoint-standard.md`
- `C:/Users/pashcrof/Documents/Codex Projects/Demo Project Standards/apex-26-1-lessons.md`
- `C:/Users/pashcrof/Documents/Codex Projects/Demo Project Standards/ai-hub-project-integration-standard.md`
- `C:/Users/pashcrof/Documents/Codex Projects/Demo Project Standards/ai-hub-project-onboarding-standard.md`
- `C:/Users/pashcrof/Documents/Codex Projects/Demo Project Standards/aidemodb-new-project-bootstrap-playbook.md`
- `C:/Users/pashcrof/Documents/Codex Projects/Demo Project Standards/apex-generative-ai-services-standard.md`
- `C:/Users/pashcrof/Documents/Codex Projects/Demo Project Standards/apex-visible-chrome-cdp-standard.md`
- `C:/Users/pashcrof/Documents/Codex Projects/Demo Project Standards/github-delivery-standard.md`
- `C:/Users/pashcrof/Documents/Codex Projects/Demo Project Standards/codex-artifact-hygiene-standard.md`
- `C:/Users/pashcrof/Documents/Codex Projects/Demo Project Standards/artifact-hygiene-operations.md`

Current shared guidance supersedes older skill wording about abandoning worktrees, dumping Git configuration and closing tabs by appearance. The current worktree is preserved, Git reads are narrow, and all browser interactions are paused until explicit ownership release. The provider's documented Grok alias remains a conflict with the shared catalogue's “obsolete shorthand” wording; no Grok service has been renamed or deleted on that assumption.

## Verified prerequisites

- SQLcl MCP saved connection `aidemodb` identifies session user CODEX and database `GE1C42BF10AE843_AIDEMODB`. AUTOCOMMIT is off. Schema discovery preceded SQL generation.
- AI Hub guarded profile resolves AIDEMODB / `caab` / `codex-caab` / `X-AI-Hub-API-Key`. Catalog, OpenAPI, bootstrap and deterministic triage returned HTTP 200.
- Task `caab-015` created through the API with an idempotency key, then full bundle read. Initial version had no previous version or approval records; current explicit user authority is retained. Scope clarification produced version 2. Build-start thread entry: 1869.
- Current browser discovery found the restored external Chrome extension. No CAAB tab was created or authenticated; ownership remains queued after GEO. Discovery is transport evidence only.
- Ignore-protection check: 22 checks, zero failures after adding missing protections in this worktree only.
- Lifecycle manifest: `.local/artifact-hygiene/manifests/5774199cb5614068b18d4e491d9d2f7a.json`; scratch: `.local/tasks/caab-015/5774199cb5614068b18d4e491d9d2f7a`.
- Lifecycle normal-user engine: bundled `pwsh.exe` 7.6.5 Core, host `PASHCROF-99QG4M`, culture `en-AG`, existing `RemoteSigned` policy. Sandbox culture differed (`en-AU`) and directory pinning failed with Windows error 5; supported scoped normal-user initialization succeeded. Cleanup must preserve the recorded engine/context and guards.

## Model request budget

Maximum: 40 application/provider requests across this implementation and verification. Used: **0**. Connection tests must be counted if they invoke a model. Token usage remains unknown unless the provider returns it; context characters are not billed tokens.

## Recommendation coverage and acceptance

| Recommendation | Implementation and required proof |
|---|---|
| R01 | Reconcile current services/bindings, exclude retired choices in the app, verify every offered model. Pending live reconciliation. |
| R02 | Exact code/name retrieval, separate regional qualification, useful token limit after stop words, provenance/status and sample counts. Candidate source in progress. |
| R03 | Conservative deterministic code/count/abundance routes, zero model attempt on those routes. Candidate source in progress. |
| R04 | One bounded evidence result reused for prompt and supporting output. No shared answer/conversation cache. Candidate source in progress. |
| R05 | Bounded context and measured candidate-model comparison without unverified output-token settings. Tests pending. |
| R06 | Honest result mode/resolved model/safe fallback/reference and stage timings; no automatic retries. Candidate source in progress. |
| R07 | Independent-question semantics explicitly described; no new conversation state. Candidate wording prepared. |
| R08 | Native APEX Markdown, maintained static assets, prompt label/status and safe response insertion. Candidate prepared; rendering/keyboard/mobile checks pending. |
| R09 | Scoped AIDEMODB `caab` bridge, validated acknowledgement, idempotency and per-item failures. Candidate prepared; distinct source-app service credential and live baseline pending. |
| R10 | Genuinely disabled, accurately labelled refresh control. No data load/scheduler added. Candidate wording prepared. |

Acceptance must include code `37354001`, an absent code, a non-current/superseded row, synthetic aliases, exact counts versus qualified-count rejection, tuna+NSW, long polite input, safe markup/links/images, unknown model selection, real AI success and visible fallback. Source-only checks do not certify deployment.

## Source-app feedback dependency

Fresh full bundles `caab-009` and `caab-014` do not establish installed service-credential or acknowledgement readiness. Only the Codex `caab` automation profile was found among named CAAB profiles. The coordinator has been asked to resolve an existing distinct project-scoped source-app client/reference or own its named provisioning gate. Never use the Codex automation key in the application or repoint a legacy ASHCROFT secret.

Expected minimal source-app scopes: `feedback.write`, `feedback.read`, `feedback.response.read`, `feedback.response.acknowledge`; no response-authoring or administrative scope. Canonical endpoint: `https://ge1c42bf10ae843-aidemodb.adb.ap-sydney-1.oraclecloudapps.com/ords/aihub/ai-hub-api/v1/projects/caab/feedback`.
