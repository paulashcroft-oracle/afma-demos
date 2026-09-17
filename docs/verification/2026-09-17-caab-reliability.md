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

Manifest revision `2026-09-17.3`; topics: credentials, apex-source-control, ai-hub-workflow, aidemodb-bootstrap, apex-browser, github-delivery, artifact-hygiene. All required files were fully reread after context compaction; no reads were reused from the compacted summary.

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

## Read-only candidate verification

SQLcl CLI 26.2.0.0, saved connection `aidemodb`, verified session `CODEX` / `GE1C42BF10AE843_AIDEMODB`, executed the candidate 030 declarations as an anonymous block with AFMA table references qualified for this existing account. No package was created or replaced. A deliberately absent service prevented provider calls. The canonical tests are `database/apex-workspace/tests/caab_reliability_readonly.sql`; the temporary qualified wrapper is registered in the owned lifecycle run.

The final expanded suite passed **121 retrieval assertions**, including exact/absent codes, scientific name, superseded code and flag, synthetic alias provenance, ambiguous names and alias caveats, exact raw habitat/rank/order filters and intersections, unsupported filter syntax, catalogue counts versus SQL, grouped class chart, qualified-count rejection, tuna/NSW exclusion, useful terms after a polite prefix, mixed-status clarification, context bounds/status, abundance limitation, independent follow-up clarification, unknown-model fallback, safe error output and prompt length. **8 native Markdown checks** passed for escaped HTML, omitted images, unsafe/unapproved schemes, retained HTTPS, safe link attributes, pipe tables and Mermaid code fences. **16 pure feedback acknowledgement checks** passed for valid task/response-only contracts and rejected missing/mismatched/invalid identities, statuses and content. No model, feedback, or other external business request was made. Candidate 040 declarations also compiled; its rendering/asset delivery was not exercised.

Final run's server-reported total timings (10 ms resolution): exact codes 30–140 ms; code excluded by a typed filter 30 ms; scientific name 1,130 ms; local aliases 820 ms; raw habitat filters 60–310 ms; species rank 380 ms; order 110 ms; intersected filters 70 ms; catalogue counts 40 ms; class chart 50 ms; tuna/NSW 110 ms; polite scientific-name query 1,030 ms; broad shark explanation with unavailable-service fallback 1,100 ms. These are candidate anonymous-routine database timings, not deployed browser/AI latency, a benchmark distribution or provider tokens.

Corrections found before deployment: five unsupported JSON array object calls changed to `TREAT(array.get(index) AS JSON_OBJECT_T)`; chart intent grammar restored; missing typed filters/alias caveats restored; the synthetic-provenance test now decodes JSON before checking HTML so JSON slash escaping cannot create a false failure. Native APEX escapes HTTPS slashes as `&#x2F;`, so the server link guard explicitly accepts native escaped slashes while rejecting encoded/unsafe schemes. Earlier `WITH FUNCTION` output-wrapper experimentation failed to parse and changed no database object. SQLcl MCP omitted DBMS_OUTPUT, so the final recorded test used the installed CLI. A transient CURRENT_SCHEMA test was restored to CODEX after the MCP audit logger reported insufficient privileges under AFMA; no audit or access grant was changed.

Final peer review corrected two contract edges: a code excluded by typed filters now reports the combined mismatch, and feedback identity validation accepts only the positive decimal IDs emitted by the AI Hub contract. Boolean, nonnumeric and zero-ID fixtures reject them. A local JavaScript replacement-token mistake temporarily corrupted the validator wrapper; the exact duplicated suffix was removed, source/wrapper identity checked, and the complete final read-only suite rerun successfully. This did not deploy any object.

JavaScript syntax and focused offline DOM-adapter checks passed for the pinned Mermaid 11.17.2 enhancement, source limits, forbidden features/resources and readable fallback/cleanup. It relies on Mermaid's maintained strict-mode sanitizer and a compact inert-DOM resource guard. Actual Mermaid layout, browser keyboard/mobile behavior and app static-file delivery remain unverified under the browser hold.

A separate attempt to compile the complete 085 body as uncalled anonymous declarations under CODEX failed with `ORA-01031` at its four AFMA ledger DML statements. No DML was executed. The pure acknowledgement function passed independently, but this is not a full-package compile pass. Complete compilation and ledger behavior require the authorized AFMA parsing-schema SQL Workshop context; no account switch, grant expansion or permission bypass was performed.

Documentation checkpoint `5bc4c99d555949e1c160f7b803dc09d1552cab7f` is pushed and verified at `origin/codex/caab-reliability`; Task Thread entry 1876 records it. The next checkpoint contains undeployed source candidates; live baseline/post-change exports remain pending. Coordinator operation `approval-completion-20260917/v2` reinforces Paul's existing R01–R10 completion authority; it does not record human acceptance. Browser queue v12 places CAAB after GovernMate, GEO and AI Hub's bounded administration inspection. All browser interaction remains held until explicit release.

## Recommendation coverage and acceptance

| Recommendation | Implementation and required proof |
|---|---|
| R01 | Reconcile current services/bindings, exclude retired choices in the app, verify every offered model. Pending live reconciliation. |
| R02 | Exact code/name retrieval, separate regional qualification, useful token limit after stop words, provenance/status and sample counts. Candidate read-only assertions passed; installed-package verification pending. |
| R03 | Conservative deterministic code/count/abundance routes, zero model attempt on those routes. Candidate read-only assertions passed; runtime verification pending. |
| R04 | One bounded evidence result reused for prompt and supporting output. No shared answer/conversation cache. Candidate bounds/status assertions passed; live AI alignment pending. |
| R05 | Bounded context and measured candidate-model comparison without unverified output-token settings. Tests pending. |
| R06 | Honest result mode/resolved model/safe fallback/reference and stage timings; no automatic retries. Candidate unavailable-service and timing assertions passed; live AI/runtime checks pending. |
| R07 | Independent-question semantics explicitly described; no new conversation state. Candidate wording prepared. |
| R08 | Native APEX Markdown, maintained static assets, prompt label/status and safe response insertion. Candidate prepared; rendering/keyboard/mobile checks pending. |
| R09 | Scoped AIDEMODB `caab` bridge, validated acknowledgement, idempotency and per-item failures. Candidate prepared; distinct source-app service credential and live baseline pending. |
| R10 | Genuinely disabled, accurately labelled refresh control. No data load/scheduler added. Candidate wording prepared. |

Acceptance must include code `37354001`, an absent code, a non-current/superseded row, synthetic aliases, exact counts versus qualified-count rejection, tuna+NSW, long polite input, safe markup/links/images, unknown model selection, real AI success and visible fallback. Source-only checks do not certify deployment.

## Source-app feedback dependency

Fresh full bundles `caab-009` and `caab-014` do not establish installed service-credential or acknowledgement readiness. Only the Codex `caab` automation profile was found among named CAAB profiles. The coordinator has been asked to resolve an existing distinct project-scoped source-app client/reference or own its named provisioning gate. Never use the Codex automation key in the application or repoint a legacy ASHCROFT secret.

Expected minimal source-app scopes: `feedback.write`, `feedback.read`, `feedback.response.read`, `feedback.response.acknowledge`; no response-authoring or administrative scope. Canonical endpoint: `https://ge1c42bf10ae843-aidemodb.adb.ap-sydney-1.oraclecloudapps.com/ords/aihub/ai-hub-api/v1/projects/caab/feedback`.
