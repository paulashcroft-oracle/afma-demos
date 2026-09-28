# Catch Monitor video-analysis options and benchmark

Status: **Gemini 2.5 Pro selected for the demo; production pipeline decision pending**
Prepared: 28 September 2026
Scope: options for AFMA CAAB AI Demo app 101, not a production model approval.

## Recommendation

Use **Gemini 2.5 Pro as the public/internal demo default**, but keep it as an evidence-proposal stage with deterministic validation and AFMA reviewer confirmation. The project owner accepts the Chicago/Google Americas processing path for this controlled capability demonstration. The benchmark proves APEX can send video to OCI Generative AI in Chicago and receive structured JSON in roughly 24–55 seconds per 13–32 MB clip. This demo decision does not determine the production topology: [Oracle documents](https://docs.oracle.com/en-us/iaas/Content/generative-ai/model-endpoint-regions.htm) Gemini as externally hosted by Google, with US-region requests machine-processed in a Google Americas location. AFMA's September 2026 privacy summary defines EM as video-only and says purpose-built AI should operate within AFMA's secure environment, with overseas sharing only when authorised. Production architecture must therefore retain an Australian/private deployment option—for example, a suitable GPU/container model in Sydney where capacity and service availability permit—alongside the managed-model benchmark.

Use this staged path:

1. APEX owns upload/URL intake, disclosure acknowledgement, resumable chunk transfer, AIDEMODB BLOB storage, CAAB candidate context, job state, model/prompt provenance, raw response, validation, reviewer decisions and audit. It also keeps submitter metadata, AI-proposed title/description/region/fishery/gear, and editable reviewer-approved metadata as separate values. URL records remain in the project-import queue until authorised video bytes are available; prompt contracts remain independently governed. Native uploads and controlled project imports converge on the same hash/length-validated media-object contract.
2. Split long videos into bounded, overlapping clips and run Gemini 2.5 Pro for authorised demo candidates. Production AFMA analysis is vision plus approved sensor/telemetry only; do not create transcripts or audio features because EM systems have no microphones. The West Moore transcript remains a labelled public-video exception.
3. Apply deterministic gates before an event can be proposed: timestamps within clip bounds, count/detail/summary agreement, CAAB code validity, preview/replay detection and provenance, duplicate/overlap linking, out-of-scope disposition/measurement claims and required evidence text. Preserve depicted candidates for reviewer adjudication rather than silently deleting them.
4. Reject invalid outputs and retry Pro idempotently with the same immutable clip/prompt context. Escalate persistent failures or ambiguous species to the reviewer; do not silently switch models or coerce the answer.
5. Publish validated candidates into `AFMA_CM_OBSERVATIONS` only as `NEEDS_REVIEW`. An authorised AFMA reviewer remains responsible for confirmation/correction/rejection/escalation.
6. Benchmark wildlife-interaction, crowded-deck and overlapping-camera videos. Because production footage must remain within AFMA's approved secure boundary unless cross-border processing is explicitly authorised, assess the private A10/container path now rather than treating it only as a later accuracy fallback.

An asynchronous job boundary should be designed now. One clip call took up to 55 seconds; a long trip video will require multiple calls, retries and resumable state. APEX can remain the application and system of record even if a later OCI Function performs media clipping or calls a private model endpoint.

## APEX-native Gemini benchmark

### Test arrangement

- Source: West Moore Island public episode, 19:15.
- Revised human ground truth: nine unique fish — Common Coral Trout 1, Chinamanfish 4, Red Emperor 1, Spanish Mackerel 3; no wildlife interaction. The edited episode also depicts the first Spanish Mackerel in a 07:09 Coming Up preview, producing ten reviewable depicted-catch observations before deduplication.
- Model context: the four known CAAB candidates and exact `SPCODE` values were supplied. This intentionally tests the intended CAAB-constrained workflow rather than open-world species discovery.
- Four MP4 clips (13–32 MB, 90–240 seconds, audio retained) were supplied as `APEX_AI` video attachments to workspace service `google_gemini_2_5_flash` in `us-chicago-1`.
- Flash responses used a strict JSON schema and were stored in `AFMA_CM_AI_TRIALS`, not in the reviewer queue.
- The failed double-hook-up clip was re-run with `google.gemini_2_5_pro`.

### Results

| Trial | Ground truth | Model result | Elapsed | Assessment |
| --- | --- | --- | ---: | --- |
| Flash, source 02:20–04:45 | Coral Trout 1; Chinamanfish 1; Red Emperor 1 | Exactly three events; all species and CAAB codes correct; usable timestamps | 29.27 s | Strong result. It correctly followed the narrator's correction from “red emperor” to Chinamanfish. Confidence `1.0` was over-certain. |
| Flash, source 06:00–07:30 | Chinamanfish 3 plus one depicted Spanish Mackerel preview | Aggregate `unique_catch_total` said 2, but detail contained duplicated coral-trout events plus a Spanish Mackerel outside the clip bounds; all Chinamanfish identification failed | 24.49 s | Failed. Detail, summary and clip bounds contradicted one another, and the result missed the three-fish sequence. |
| Flash, source 12:00–14:45 | Spanish Mackerel 1 | Count and CAAB species correct | 27.48 s | Partly successful. Event end time exceeded the 165-second clip boundary. |
| Flash, source 14:40–18:40 | Spanish Mackerel 2 | Count and CAAB species correct | 33.12 s | Partly successful. Time windows extended outside the clip and did not cleanly isolate the two landings. |
| Pro adjudication, source 06:00–07:30 | Chinamanfish 3 plus one depicted Spanish Mackerel preview | Returned two Chinamanfish on one rig, a third separate Chinamanfish held by another angler, and the Spanish Mackerel Coming Up preview with correct species and 06:45–07:16 windows | 37.39 s | Strong result. Subsequent frame-by-frame review corrected the original human label: Pro had accurately detected the third fish and explicitly recognised the teaser context. Its `1.0` confidence was still over-certain, and full-video evidence is required to link the teaser to the later landing. |

### Refinement comparison

Prompt v2 added one-row-per-individual rules, explicit teaser/replay exclusion, hard clip bounds, exact source-offset arithmetic, count/summary equality, final-correction handling and a confidence ceiling of `0.98`. APEX semantic validation independently enforced bounds, unit counts, totals and active CAAB codes. Prompt v3 also supplied an independent time-coded transcript as supporting evidence for the ambiguous double-hook-up.

| Trial | Result | Validator outcome | Meaning |
| --- | --- | --- | --- |
| Flash v2, three-fish/preview sequence | Excluded the teaser and returned two bounded fish rows, but identified both as Common Coral Trout | Structurally passed; ground-truth failed | Prompting fixed arithmetic and timing but missed the third Chinamanfish, missed the reviewable preview and failed the difficult species decision. |
| Pro v2, three-fish/preview sequence | Provider-side internal error | Failed trial retained for retry evidence | The app needs retries, idempotency and model fallback. |
| Flash v3 + transcript, three-fish/preview sequence | Provider-side internal error | Failed trial retained | Flash is not a dependable adjudicator for the ambiguous case. |
| Pro v3 + transcript, three-fish/preview sequence | Two Chinamanfish, count 1 each, correct CAAB code, bounded 06:45–06:57 source window; third fish missed and preview excluded by instruction | Structural validator `PASS`; revised ground-truth `FAIL` | The over-aggressive exclusion/dedup prompt degraded the stronger Pro v1 result. Schema validity cannot detect a missing individual, and teaser evidence should be tagged and linked rather than suppressed. |
| Flash v2, late two-mackerel sequence | Correct species/count, but second event ended 100 seconds outside the clip and asserted release | `REJECTED` | Fast discovery remains useful; semantic validator prevented publication. |
| Pro v2, late two-mackerel sequence | Exactly two Spanish Mackerel with bounded source windows about 15:04–16:32 and 16:38–18:11 | `PASS` | Refined Pro was materially more temporally reliable on this clip. |

The selected public-demo routing policy is: **Gemini 2.5 Pro → deterministic validator → AFMA reviewer**, with transcript assistance retained only for the historical West Moore experiment. The production AFMA policy is **video + sensor/telemetry, no audio → approved in-boundary model → deterministic validator → AFMA reviewer**. Invalid results are retried idempotently, then escalated. A response can be structurally valid yet semantically wrong, so out-of-scope size/weight/quota/disposition claims are rejected. Depicted previews/replays and cross-camera repeats are retained with provenance and linked to matching evidence; they are not silently removed. Flash comparison trials remain in the evidence record but are not the current runtime path.

No further prompt version is to be activated without human review of its exact system prompt, task prompt, response schema and benchmark diff. The current contracts and their status are recorded in [Catch Monitor prompt review register](catch-monitor-prompt-review.md); the planned in-app registry will enforce `DRAFT → APPROVED → ACTIVE → RETIRED` with immutable audit and rollback.

Across the four Flash clips, the aggregate `unique_catch_total` summed to eight against the revised nine-unique-fish ground truth, and six of the nine fish received the correct species in the usable event interpretation. Only one of four clips returned internally reliable event timing/detail. This is promising for candidate discovery, not sufficient for automatic catch logging or compliance use.

### What the test establishes

- The configured APEX 26.1 service can pass an MP4 attachment to OCI Gemini and obtain schema-shaped JSON without a separate application server.
- Audio helped the West Moore public-video benchmark, but AFMA EM footage contains no audio. That result must not shape production dependencies or confidence rules.
- JSON schema conformance does not guarantee semantic consistency. The model can return out-of-range times, duplicate displays, inconsistent totals and overconfident scores.
- Short clips are necessary for current OCI Gemini payload limits and are beneficial for localisation, but clip boundaries/overlaps create their own duplicate-count risk.
- Preview/title-card/replay detection, evidence grouping and deterministic temporal validation are required before model proposals reach reviewers. The revised policy preserves those depicted observations and explains the likely duplicate; production AFMA device footage should not normally contain editorial teasers.

Replayable trial assets:

- `database/135_create_afma_catch_monitor_video_ai_trial.sql` — isolated trial table and APEX AI API.
- `database/136_run_west_moore_gemini_flash_trial.sql` — first three-fish clip.
- `database/137_run_remaining_west_moore_gemini_flash_trials.sql` — double hook-up and mackerel clips.
- `database/138_run_west_moore_gemini_pro_adjudication.sql` — Pro re-run of the failed double hook-up.
- `database/139_verify_afma_catch_monitor_video_ai_trials.sql` — verification.
- `database/140_run_west_moore_gemini_v2_comparison.sql` — original combined v2 comparison (retained with its provider failure evidence).
- `database/141_run_west_moore_gemini_v3_transcript_comparison.sql` — transcript-assisted Flash/Pro comparison.
- `database/142_run_west_moore_gemini_v2_late_sequence_comparison.sql` — refined late-sequence Flash/Pro comparison.

The benchmark clips are controlled internal demo derivatives and are not source-controlled. In a real workflow, private object storage or an authorised database BLOB store replaces APEX static application files.

## Current OCI and private-model options

| Option | Fit | Advantages | Limitations / risks | Timing decision |
| --- | --- | --- | --- | --- |
| **APEX 26.1 + OCI Gemini 2.5 Pro, Chicago entry region** | Direct proposal generation from authorised demo video | Already configured; best result in the public-video comparison; APEX attachments, structured output and agent tools; minimal new infrastructure; CAAB context can be supplied; on-demand pricing | Video API payload is limited to 50 MB encoded for inline data or 100 MB by URI; [Oracle documents](https://docs.oracle.com/en-us/iaas/Content/generative-ai/model-endpoint-regions.htm) Gemini as externally hosted by Google and US requests as processed in a Google Americas location. That constraint needs a separate production decision. Pro still needs validators/retries. | **Use now for this controlled demo.** Do not treat the demo decision as approval to send production AFMA EM footage across the same boundary. |
| **APEX AI Agent with PL/SQL/JavaScript tools** | Orchestrates CAAB lookup, job status, validation and proposal persistence | Keeps application logic/audit in APEX; tool calls can retrieve candidate taxa and run deterministic checks | An agent loop is not a video tracker; long-running media work still needs asynchronous execution and strict tool permissions | **Design now** as the control plane, after the direct attachment prototype. |
| **OCI Vision Stored Video Analysis** | Frame labels/object detection using pretrained or custom models | Accepts MOV/MP4/H264/MKV/WEBM up to 20 GB/10 hours; supports custom object models | Hosted only in Ashburn, London and Phoenix, not Chicago or Sydney; pretrained labels are not a fish-species/unique-individual solution; custom training and cross-region data handling add work | Keep as a secondary experiment, particularly if a custom object detector is trained. Not first choice for this demo. |
| **OCI Functions** | Media probing, clipping, callback/orchestration | Serverless operational boundary; can keep APEX responsive and invoke OCI APIs | Not a GPU inference service; execution/resource limits make it unsuitable as the primary video model; introduces another deployment artifact | Add only when asynchronous clipping/callback is needed. APEX remains system of record. |
| **OCI Data Science GPU Model Deployment on A10, BYOC/Triton** | Private specialist detector/tracker/classifier endpoint in an approved region/environment | Supports GPU inference, custom containers, Triton, private endpoints and deterministic boxes/tracks/count lines; better alignment with AFMA's secure-control requirement | Requires labelled operational footage, model lifecycle/MLOps, endpoint capacity and GPU cost; A10 has 24 GB per GPU and will constrain larger video-language models | **Assess now for production boundary fit**, even if Gemini remains the faster demo benchmark. |
| **Private A10 detector + tracker + CAAB classifier** | YOLO/RT-DETR-style detector, ByteTrack/BoT-SORT tracking, separate fish classifier | Best control of unique-individual counting, bounding boxes and reproducibility; models can be optimised with ONNX/TensorRT | Species accuracy depends on representative labels; occlusion and deck-domain shift are hard; Ultralytics licensing and all training-data rights need recording before production | Most credible fallback for deterministic counting. Do not train until a broader labelled set exists. |
| **Private A10 vision-language model over sampled frames** | Quantised Qwen2.5-VL-class 7B model or similar, optionally with a tracker | Flexible descriptions and CAAB-constrained reasoning; a 7B quantised model is more plausible on A10 than large imported multimodal models | Frame sampling can miss short events; VLMs still duplicate/hallucinate and do not replace tracking; exact model/container/licence must be validated | Useful research branch after Gemini prompt/validator tuning, not the first production counter. |
| **SAM 2 + classifier** | Segmentation/track annotation accelerator | Strong for interactive mask propagation and dataset annotation | Does not identify species or determine unique catch by itself; still requires detector/classifier and adjudication | Consider for media-library annotation tooling, not the first runtime pipeline. |
| **Whisper/audio transcription** | Historical public-video benchmark only | Helped explain the West Moore narration/correction anomaly | AFMA EM footage has no microphones or audio; adding transcription would create an irrelevant production dependency and misleading confidence signal | **Exclude from the AFMA EM production pipeline.** Retain only as labelled West Moore experiment provenance. |

## Why this work belongs now

The choice changes the data contract. Regardless of model, the application needs immutable source/clip identifiers, offsets, model and prompt versions, raw output, validator findings, retry state, CAAB candidate sets, evidence frames, track/dedup identifiers and reviewer decisions. Implementing those only after building the UI would create rework.

Full private-model training can wait, but the secure Australian/private deployment decision cannot. Continue the low-cost Gemini demo benchmark while defining and testing the private A10/container interface, multi-camera/sensor contract and deployment region now. The West Moore result is strong enough to continue as a demo benchmark and weak enough to justify the safeguards.

AFMA source references for this boundary:

- [Electronic monitoring program](https://www.afma.gov.au/fisheries-management/monitoring-tools/electronic-monitoring-program)
- [Electronic monitoring on board AFMA managed vessels](https://www.youtube.com/watch?v=1jrKBK1JPZE)
- [E-monitoring Summary Privacy Impact Assessment — September 2026](https://www.afma.gov.au/sites/default/files/2026-09/E-monitoring%20Summary%20Privacy%20Impact%20Assessment%20(Sept%202026).pdf)

## Primary references

- [OCI Generative AI models by region](https://docs.oracle.com/en-us/iaas/Content/generative-ai/model-endpoint-regions.htm)
- [OCI Gemini 2.5 Flash](https://docs.oracle.com/en-us/iaas/Content/generative-ai/google-gemini-2-5-flash.htm)
- [OCI Gemini 2.5 Pro](https://docs.oracle.com/en-us/iaas/Content/generative-ai/google-gemini-2-5-pro.htm)
- [APEX 26.1 `APEX_AI.GENERATE` with attachments and JSON schema](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_AI.GENERATE-Function-Signature-2.html)
- [APEX 26.1 attachment data types](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_AI.Data-Types.html)
- [OCI Vision stored video analysis](https://docs.oracle.com/en-us/iaas/Content/vision/using/stored_video_analysis.htm)
- [OCI Vision limits](https://docs.oracle.com/en-us/iaas/Content/vision/using/limits.htm)
- [OCI Data Science GPU inference](https://docs.oracle.com/en-us/iaas/Content/data-science/using/mod-dep-gpu-inference.htm)
- [OCI Data Science bring your own container](https://docs.oracle.com/en-us/iaas/Content/data-science/using/mod-dep-byoc.htm)
- [OCI Data Science A10 capacity-reservation shapes](https://docs.oracle.com/en-us/iaas/Content/data-science/using/bring-your-own-reservations.htm)
