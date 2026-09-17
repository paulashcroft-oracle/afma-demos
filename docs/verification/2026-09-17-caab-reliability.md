# CAAB reliability implementation evidence

Date: 17 September 2026. AI Hub task: `caab-015`. Owner: Codex task `01a0ad20-e77a-74a1-94db-8ac7063c5f86`.

## Scope and current state

Paul's “authorized” instruction and the AI Hub coordinator's subsequent implementation handoff authorize the September review recommendations R01–R10. The coordinator explicitly included the scoped AIDEMODB `caab` feedback migration and acknowledgement test. Human acceptance remains separate. Real source-data refresh, full application replacement, broader security changes and unrelated application work are excluded.

Target: AIDEMODB, AFMA workspace/schema, application 101 (`AFMA CAAB AI Demo`, alias `AFMA-CAAB-AI-DEMO`), AI Hub project `caab`, actor `codex-caab`.

**Implementation/deployment:** candidate source preparation; no application/package deployment yet.

**Verification:** 145 candidate read-only checks passed. CODEX/AFMA Builder identity, agent inventory, package validity and the current native APEXlang baseline are verified. The current application export matches July's component content; actual deployed package-body reconciliation and runtime tests remain pending. The SQLcl export route stopped on `ORA-20987`; native Builder export succeeded without changing access grants.

**Housekeeping:** task-owned lifecycle run initialized; export/test scratch is under the ignored run. No cleanup claimed. The saved checkout's modified `.gitignore` and untracked `_gitignore_for_mac_migration` remain untouched.

## Git and checkpoint

Worktree: `C:/Users/pashcrof/.codex/worktrees/1d21/AFMA Demos`. Branch: `codex/caab-reliability`, created from verified saved commit `3eb70349f93bf4e94abeb27ebd5e1d73b6adeddd`.

Configured remote: `https://github.com/paulashcroft-oracle/afma-demos.git`. A normal-user, read-only remote probe succeeded. Current pre-change application baseline: `exports/apex/afma/101/20260917-110915-before-caab-015/`. Post-change export is pending deployment and verification. The July export is historical comparison evidence; the newly captured export supplies current application state.

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

Documentation checkpoint `5bc4c99d555949e1c160f7b803dc09d1552cab7f` is pushed and verified at `origin/codex/caab-reliability`; Task Thread entry 1876 records it. Undeployed candidate checkpoint `61f0c5f8d1aedfae86db501de97d946013b23981` is committed, pushed and remote-verified; Task Thread 1882 records its 145 passing checks. Live baseline/post-change exports remain pending. Coordinator operation `approval-completion-20260917/v2` reinforces Paul's existing R01–R10 completion authority; it does not record human acceptance. Browser queue v12 places CAAB after GovernMate, GEO and AI Hub's bounded administration inspection. All browser interaction remains held until explicit release.

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

Required source-app scope for the current consumer: `feedback.write` only; no response-authoring or administrative scope. The earlier four-scope proposal included reads and a subsequent response ACK introduced by test planning, not an implemented CAAB consumer. Canonical endpoint: `https://ge1c42bf10ae843-aidemodb.adb.ap-sydney-1.oraclecloudapps.com/ords/aihub/ai-hub-api/v1/projects/caab/feedback`.

Scope audit, 17 September 2026: original review R09 requires validating the intake POST acknowledgement, idempotent replay and per-item failure isolation. Current 085 has one outbound request (`POST`, lines 572–578); `acknowledgement_is_valid` validates that immediate result. No later response GET, poller, display or `/acknowledge` consumer exists in the candidate source or captured app components. Extra scope wording first entered planning commit `5bc4c99`; the separate GET/ACK test was added in `61f0c5f`. The delivery runbook and 086 acceptance wording now remove that test-only expansion. Deployed package bodies still require capture, so this is source evidence, not proof of their equality. The coordinator's current authorization audit confirms ordinary appropriate credential issuance through an existing authorized administration route was already covered; the remaining issue is the actual executor/secure-install capability, with a direct-SQL security-table fallback separately gated. This supersedes earlier blanket credential-approval and four-scope prerequisite wording; no key, grant or credential has been created.

## Live read-only inspection and browser release

During the coordinator's explicit v12 CAAB browser slice, native Chrome autofill signed CODEX into AFMA without exposing credential values. Live APEX reports version 26.1.4. App 101 is AFMA CAAB AI Demo, alias afma-caab-ai-demo, owner AFMA, seven pages. SQL Workshop's selected schema is AFMA. No app, package, grant or credential mutation occurred.

The app has nine native AI Agents, all reporting zero tools and Text response format: the two retired Cohere aliases, Gemini 2.5 Pro/Flash/Flash-Lite, GPT OSS 120b/20b, Grok 4.20 reasoning and Grok 4.3. The inspected Pro agent has static ID google_gemini_2_5_pro, service google.gemini-2.5-pro, temperature .2, and no augmentation or on-demand tools. This is metadata evidence, not connection or model-quality verification.

Read-only config results: AI_CONFIG_STATIC_ID=google_gemini_2_5_pro; AI_AGENT_STATIC_ID=CSIRO_CAAB_AGENT; AI_HUB_FEEDBACK_CREDENTIAL_STATIC_ID=AI_HUB_AFMA_FEEDBACK_API; the endpoint still points to historical ASHCROFT /projects/afma/feedback; no AI_HUB_PROJECT_KEY row was returned. The coordinator confirmed that the distinct AIDEMODB source-app SERVICE credential remains unissued/unverified; its proposed filename is not a usable credential reference.

All three affected package specifications and bodies are VALID. Recorded body LAST_DDL values are 2026-07-13 04:35:01 for CSIRO_CAAB_AGENT_API and CSIRO_CAAB_PAGE_API, and 2026-07-13 04:35:02 for AFMA_AI_HUB_FORWARDER. Validity/timestamps do not establish source equality.

One app 101 APEXlang Standard Export action emitted the supported download event, but the tool returned an opaque object without a file path. Page.setDownloadBehavior was unsupported and directed use of the download event. Opening Chrome's internal downloads URL was policy-rejected; that UI was not retried or bypassed. The coordinator supplied its previously verified native-download-to-filesystem handoff: narrow local artifact metadata inspection, exact identity verification, and exact-file relocation to owned scratch. No new file appeared in the normal user's Downloads by creation or write timestamp after the verified 10:05:29 UTC source-checkpoint note; host UTC agrees with the task clock. No archive was opened, moved, staged, registered or claimed as captured. No repeat export was attempted. The current baseline remains a concrete artifact-handoff dependency; deployment stopped before mutation.

At about 10:15 UTC CAAB explicitly released ALL-browser ownership directly to Policing and copied the coordinator; subsequent queue is Policing, GovernMate, GEO continuation. CAAB root and children are HOLD. Own tab 61491459 is marked for continuation at SQL Commands showing the completed read-only validity result. There is no pending CUA, chooser, dialog, SQL write or unsaved component edit. The export location is unresolved, not an in-flight browser action. Preserve all existing tabs/profile.

Next owners/actions: the coordinator resolves the baseline artifact handoff and distinct SERVICE-client provisioning dependency; CAAB retains remaining source reconciliation, surgical deployment, live tests, exports and PR in BUILD. No Test/Complete or human acceptance claim. Model usage remains 0/40. The owned artifact lease remains active with its one registered anonymous test wrapper; no housekeeping completion is claimed.

## Official SQLcl export check and credential proposal

At the coordinator's request, the installed SQLcl 26.2 help was inspected offline. It explicitly supports `apex export -applicationid 101 -exptype APEXLANG -dir <path>`. Independent source review found no prior native export attempt; the earlier record was an empty component listing. This check is separate from the rejected internal Chrome downloads-page navigation.

Fresh saved `aidemodb` CLI discovery verified SESSION_USER, CURRENT_USER and CURRENT_SCHEMA all `CODEX`, database `GE1C42BF10AE843_AIDEMODB`. The app 101 list again returned no data. One export attempt used the unchanged identity, an explicit target guard and the new output path `.local/tasks/caab-015/5774199cb5614068b18d4e491d9d2f7a/sqlcl-before-r09`, without force/overwrite. It reported `Exporting Workspace null - application 101:null`, then `ORA-20987: APEX - Security Group ID (your workspace identity) is invalid`, with WWV_FLOW_SECURITY / WWV_FLOW_EXPORT_INT / WWV_FLOW_EXPORT_API in the stack. SQLcl exited 1 and rolled back. The resulting directory is empty: no archive or export files were produced. The existing-rights SQLcl export route stops here; no identity, schema/workspace-context or privilege change was attempted. No live deployment or provider call occurred.

The artifact runner was rechecked as the same bundled PowerShell 7.6.5 Core / PASHCROF-99QG4M / en-AG / RemoteSigned. The ignore checker initially rejected the worktree against its default saved-workspace root; its documented explicit WorkspaceRoot parameter resolved that validation mismatch. All 22 checks passed for this owning worktree. The original failure did not change files, permissions or policy. The existing active lease and registered test wrapper remain; the failed export added only the empty directory. A concise secret-free `sqlcl-export-attempt.txt` is retained in the owned run with the original error and command; this section preserves the durable result. Cleanup is not claimed complete.

The AI Hub coordinator's source-only provisioning proposal is `AI Hub/docs/implementation/2026-09-17-caab-feedback-service-provisioning.md`, commit `f406bc6fd9f890a04afff44835edc5af2b9fc757` on `codex/ai-hub-knowledge-repo-api`; the coordinator reports remote equality verified. CAAB fully reviewed the proposal and recorded it in Task Thread 1887. It proposes a distinct `caab-apex-feedback` SERVICE client, existing project-9 actor 33, and four narrow feedback scopes, initially PAUSED. No client, key or grants have been provisioned. The coordinator owns the precise security decision presented to Paul; no repeat generic implementation approval is required.

The coordinator subsequently named the proposed new AFMA Web Credential static ID `AI_HUB_CAAB_FEEDBACK_AIDEMODB`, subject to a fresh absence check. Its proposed valid-URL prefix is `https://ge1c42bf10ae843-aidemodb.adb.ap-sydney-1.oraclecloudapps.com/ords/aihub/ai-hub-api/v1/projects/caab/feedback`. This is a design choice, not live metadata or installation evidence. Preserve the verified legacy `AI_HUB_AFMA_FEEDBACK_API` and its current config pairing. No secret-preserving automated installation mechanism or named credential custodian has yet been verified; CAAB owns installation coordination and subsequent end-to-end proof, while the coordinator resolves that dependency.

Fresh full task bundle at 10:36:11 UTC remains `caab-015` v2 / BUILD with pending human review. The coordinator subsequently confirmed the explicit browser handoff from GovernMate to GEO; CAAB root and children remain ALL-browser HOLD. No task-owned browser action is pending.

For this continuation, guidance revision `2026-09-17.3` was refreshed and the full required set reread: parent/project AGENTS plus the paths listed above for shared-guidance-refresh, codex-authorization-and-follow-through, shared-credential-storage, apex-export-git-checkpoint, apex-26-1-lessons, ai-hub-project-integration, ai-hub-project-onboarding, apex-visible-chrome-cdp, github-delivery, codex-artifact-hygiene and artifact-hygiene-operations. The newly routed source `C:/Users/pashcrof/Documents/Codex Projects/Demo Project Standards/python-tool-dependency-resilience.md` was also fully read. Selected topics were credentials, apex-source-control, ai-hub-workflow, apex-browser, github-delivery, artifact-hygiene and python-dependencies. No compacted-summary read was reused; prior bootstrap/service reads above retain their earlier provenance.

## Native baseline captured; timestamp diagnosis corrected

After Policing's explicit release and CAAB's acknowledgement, one coordinator-approved instrumented native export began at `2026-09-17T11:09:15.682Z`. The earlier CAAB tab was absent from fresh inventory, so this slice used new owned tab 61491471. Native autofill reauthenticated CODEX into AFMA without reading or supplying the password. Live UI verified APEX 26.1.4, application 101, AFMA CAAB AI Demo, owner AFMA, seven pages, and selected APEXlang / Standard Export.

Documented passive `cdp.readEvents` anchored cursor 173 before the one Export click; `waitForEvent('download', {timeoutMs:30000})` was armed first. Cursor 189 contained Page.downloadWillBegin and progress events for owned tab 61491471, frame `441DE039B552F3FDD5E5D05E25368A29`, GUID `8838e2bb-50ea-4e31-8695-bf979b4ab3b7`, suggested filename `afma-caab-ai-demo.zip`, and completed received/total bytes 68,545. Events had no filePath; the high-level download remained opaque. No CDP command, browser setting/profile change, internal-page fallback or further export was used.

The concrete native file was `C:/Users/pashcrof/Downloads/afma-caab-ai-demo (1).zip`, created 11:09:21.494 UTC and written 11:09:22.732 UTC. Its 44 entries had no unsafe paths. Application identity and `.apex/apexlang.json` version `26.1.0+3102` matched the verified UI. SHA-256 `6649FD6CE852FBD68D2ED00E76764E83145B2B671E6E5FC298CC34F4799CD847` was verified before and after the exact-file move into the owned run as `app101-20260917T110915-standard.zip`. This retained private operational archive includes workspace prerequisite metadata; its retention review is 17 October 2026.

The original native export also existed: `afma-caab-ai-demo.zip`, created 10:09:10.602 UTC and written 10:09:12.192 UTC, 68,545 bytes, SHA-256 `415EB28801251A8C2276DD055BD2373946A6638B62FBF7B3B7147A5CCE0709A2`. Its 44-entry archive and application identity were verified before exact-file relocation to the owned run as `app101-20260917T100910-standard-initial.zip`. It is temporarily retained as original correction evidence, with redundancy review on 18 September. No other Downloads file was moved or removed.

**Correction to the earlier missing-file diagnosis:** casting a `Z` timestamp directly to PowerShell `[datetime]` produced a local-time comparison against `CreationTimeUtc`/`LastWriteTimeUtc`. The filter therefore incorrectly reported no files. Filename-led discovery found both exports; parsing the cutoff as `[datetimeoffset]` and comparing `.UtcDateTime` correctly selected the new file. The earlier no-file claims above and in Task Threads 1885/1891 are superseded. This was a local inspection error; the evidence does not establish a browser download failure. The separate SQLcl `ORA-20987` result remains valid.

The canonical current baseline has **34 files**: 29 text sources and five PNG assets. Ten `workspace-components/credentials/**` and `workspace-components/generative-ai-services/**` archive entries were excluded before extraction into Git source. The manifest, application, pages, native agents and static assets remain. Path/content checks found no excluded private paths or credential/session patterns. Independent comparison found no added/removed files and no text differences after CRLF/LF normalization versus July; all five PNGs are byte-identical. The unchanged native application checksum-salt metadata is preserved as exported application state; its value is omitted from this evidence. Page 2 still renders `CSIRO_CAAB_PAGE_API.AGENT_HTML` and its `CSIRO_CAAB_AGENT_ASK` callback calls `CSIRO_CAAB_AGENT_API.ASK_JSON` with `g_x01`/`g_x02`. This does not establish deployed package-body equality.

The initial baseline commit check stopped on 36 native-export whitespace findings (blank final lines and whitespace-only embedded-code lines), with no other findings. They are unchanged from the historical export's content. The captured application source is preserved without a formatting rewrite; the edited verification document passes its separate whitespace check. This is a reviewed exporter-format exception, not a source-validation or application-runtime pass.

CAAB marked tab 61491471 for handoff at Export Application, then explicitly released ALL-browser ownership to GEO; GEO acknowledged acquisition. No browser operation, chooser, dialog or unsaved edit remained. CAAB root/children are HOLD. The artifact manifest is generation 10 with an active lease, two registered disposable records and two retained private archives; housekeeping is not complete.

Paul reaffirmed all projects' current update-completion authority through the coordinator. Ordinary implementation, schema-local repairs, approved agent/UI changes, verification and Git delivery remain authorized; pending SERVICE security/installation decisions and enforced access restrictions remain separate. CAAB continues deployed package reconciliation and surgical implementation on its next coordinated browser slice. The current application baseline dependency is resolved; model usage remains 0/40.

## Actual package baseline and static asset delivery

After Policing explicitly released ALL-browser ownership, CAAB acknowledged and
reused owned tab 61491471. An expired shared Builder session was restored through
one authorized CODEX/AFMA native-autofill sign-in; APEX 26.1.4 and selected schema
AFMA were verified. Guidance revision 2026-09-17.4 was refreshed and all 13 routed
sources listed above fully reread after compaction. Topics: credentials,
apex-source-control, ai-hub-workflow, apex-browser, github-delivery and
artifact-hygiene. Fresh full bundle at 12:02:30 UTC and remaining early thread
entries at 12:02:57 UTC confirmed caab-015 v3 / BUILD, pending human review and
the intake-only R09 scope.

Native SQL Commands captured all 1,112 source rows for the agent/page package
specifications and bodies. Separate row/line/character aggregates match the
concrete native CSV and exact reconstructed files. The database checkpoint is
`exports/database/afma/20260917-120534-before-caab-015`; its README records source
counts, hashes, download provenance and the rollback wrapper. Independent review
found no semantic drift from candidate parent 61f0c5f^ and no detected forbidden
secrets/session URLs. Each non-final captured source line has one extra trailing
space; exact native source is preserved. Both specs match the candidate interfaces,
allowing body-only replacement. Package replacement has not occurred at this
checkpoint. The source CSV is registered retained in artifact generation 11.

App 101 Shared Components initially contained five icon files and neither new
asset. Native chooser uploads of canonical `apex/static/caab.css` (8,993 bytes)
and `apex/static/caab-agent.js` (12,037 bytes) each returned `File(s) created`.
The JS editor shows `#APP_FILES#caab-agent.js`, text/javascript and UTF-8, with
the intended renderer source. This establishes asset creation, not runtime
loading or application acceptance. No catalogue data, feedback configuration,
credential or model call was changed. Model requests remain 0/40.
