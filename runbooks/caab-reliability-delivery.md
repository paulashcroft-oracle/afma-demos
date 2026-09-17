# CAAB reliability delivery

Task `caab-015`, approved recommendations R01–R10. Target: AIDEMODB, workspace/schema `AFMA`, app `101` (`AFMA CAAB AI Demo`). This runbook describes the candidate delivery; the dated [verification record](../docs/verification/2026-09-17-caab-reliability.md) determines what is actually deployed and verified.

## Source and prerequisites

- `database/030_create_csiro_caab_agent_api.sql`: schema-local retrieval, deterministic routes, bounded shared evidence, native Markdown and honest response diagnostics.
- `database/040_create_csiro_caab_page_api.sql`: existing page-package boundary, static-asset registration and accessible controls.
- `apex/static/caab-agent.js` and `apex/static/caab.css`: editable application static assets. Upload these exact files to app 101 before deploying 040; capture their installed form in the post-change APEXlang export. Never keep a conflicting inline copy.
- `database/085_create_ai_hub_feedback_model.sql`: schema-local feedback ledger/view/package and insert-only bootstrap defaults. Existing config is not overwritten by replay.
- `database/086_verify_ai_hub_feedback_model.sql` and `database/apex-workspace/tests/caab_*_readonly.sql`: database, retrieval and pure feedback-contract verification; these are not deployment authority or credential certification.

Run schema-local scripts as AFMA through authorized CODEX SQL Workshop. Do not use ADMIN for these objects. The current CODEX SQLcl connection can inspect data but has not established app 101 metadata visibility and lacks AFMA feedback-ledger DML privileges; it is not the app deployment path. No additional database grants are required by this delivery procedure.

## Surgical sequence

1. Obtain the coordinated exclusive Chrome handoff; verify CODEX, AFMA, app 101, parsing schema and live APEX release from fresh state. Preserve all other tasks' tabs.
2. Capture and commit a current repository-safe APEXlang Standard baseline plus actual affected package bodies/config and relevant SQL Scripts. The July export does not establish today's baseline. Exclude workspace credential and service-definition paths from Git.
3. Compare current deployed components with the candidate. Resolve drift before replacing any package. Inspect current native agent/service bindings and offered models; preserve shared services. Record safe metadata only, never headers or credential values.
4. Upload the two application static files and deploy the reconciled 030/040 package scripts. Verify valid objects, asset loading, the Ajax contract and existing Home/Reports behavior. Do not full import or replace the application.
5. Verify every offered model through a bounded explanation request, excluding retired Cohere aliases. Count all provider attempts toward the 40-request cap. Compare the existing Pro choice with Flash or Flash-Lite and at most one existing OSS candidate on the same small grounding suite. Change defaults only if measured quality and latency justify it.
6. Complete the separately included feedback migration below. Keep forwarding scheduling unactivated.
7. Run the acceptance suite, capture current post-change APEXlang/static assets and relevant package/SQL Script evidence, commit and push, then open the review PR. Move to review-ready Test only when all agent-owned acceptance is verified; Paul owns human review.

## Retrieval and response contract

Each question is independent. Exact code/name, catalogue counts, largest-class charts, abundance limitations and clarification can answer without a provider. Search explanations use one request-local evidence set for both model input and displayed grounding. There is no conversation, answer or summary cache.

The request limit is 3,000 characters; evidence is capped at 24 taxa and 24 aliases plus character budgets, and total context at 24,000 characters. Counts distinguish all matching taxa from the displayed sample; alias totals apply only to displayed taxa. Regional aliases describe recorded name usage, not distribution.

Typed filters use raw stored values: `habitat code M,E`, `rank species`, and `order Perciformes`. Habitat equality preserves compound values; `M`, `M,E` and `PM` are distinct. No marine/freshwater labels are inferred. Family/class/genus matching remains lexical. Names, status, supersession, alias caveats and synthetic provenance remain visible.

JSON reports `mode`, `route`, `requestId`, `aiAttempted`, the resolved service/model/agent, safe fallback reason, context characters, sample/total counts and retrieval/resolution/model/render/total timings. Usage fields remain null unless actual provider usage becomes available. There are no automatic model retries or silent model substitutions.

Native APEX Markdown escapes embedded HTML. Model-created images are omitted; links are constrained to HTTP(S) in the browser. Optional, bounded Mermaid diagrams use a pinned release and readable source fallback. The refresh control is disabled and labelled unavailable; this task performs no data load or scheduling change.

## Feedback migration and proof

Resolve a distinct AIDEMODB source-app service client with only `feedback.write`, `feedback.read`, `feedback.response.read`, and `feedback.response.acknowledge`. The AI Hub coordinator owns discovery/provisioning of that dependency. Never install the `codex-caab` automation key or a legacy ASHCROFT key in the app.

Verify the target Web Credential and its allowed URL before pairing it with these AFMA config values:

- `AI_HUB_PROJECT_KEY = caab`
- `AI_HUB_FEEDBACK_ENDPOINT_URL = https://ge1c42bf10ae843-aidemodb.adb.ap-sydney-1.oraclecloudapps.com/ords/aihub/ai-hub-api/v1/projects/caab/feedback`
- `AI_HUB_FEEDBACK_CREDENTIAL_STATIC_ID =` the verified source-app Web Credential reference

Preserve the previous config and credential until the paired target is verified. The forwarder fails closed for a historical project/endpoint and validates accepted status, project, idempotency and a returned identifier before terminal status. Its source idempotency key remains `afma-apex-feedback-<feedback_id>` across retries. One failed item must not stop the rest of a bounded batch.

Submit one approved test through native feedback, forward it server-side, and replay the same source record. Confirm identical returned identity and no duplicate source feedback/task. Test malformed-response handling without sending fabricated responses to the live external API. No request may reach ASHCROFT.

Use one positive acknowledgement/praise intake for the controlled round trip. AI Hub's canonical `2030_harden_feedback_defect_classification.sql` creates a structured response for its response-only branch; the `1390` latest-response read joins the feedback/project rather than requiring a task. This is source evidence, not deployed proof. Fetch the actual resource; never synthesize it from intake text or create a dummy task.

For a task-backed intake that omits `feedbackKey`, resolve it through `/tasks/{taskKey}/source-feedback` and match the original source record. Read `/projects/caab/feedback/{feedbackKey}/responses/latest`; verify project, feedback and response identity before acknowledging `/projects/caab/feedback/{feedbackKey}/responses/{responseKey}/acknowledge`. Use `RECEIVED` for receipt-only proof and a precise `sourceDeliveryReference`. Use `APPLIED` only after actual application/display. Reread the acknowledgement and its client identity. A missing structured response remains a live contract failure; the source client must never self-author or self-grant. Reconcile an uncertain ACK from fresh state before retrying because its idempotency behavior is not certified.

## Acceptance and recovery

Run the read-only SQL fixtures against the installed package, then verify actual AI success and visible fallback, two successive requests, failure cleanup, keyboard and small-screen behavior, inert HTML, safe links, no model image requests, and diagram success/failure. Verify app pages 1/2/3 and feedback capture remain usable.

If a package or asset fails, restore only that affected component from the committed current baseline, then recheck it. Preserve successful unrelated changes. Full app replacement is not an automatic rollback. Keep current exports and concise evidence; release and clean only registered disposable test/download artifacts through the shared lifecycle.
