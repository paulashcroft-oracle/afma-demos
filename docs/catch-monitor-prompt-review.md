# Catch Monitor prompt review register

Status: **v4 batch-counting contract approved for the controlled demo; every later change requires review**
Prepared: 28 September 2026
Executable sources: `database/116_add_afma_catch_monitor_prompt_governance.sql` and `database/135_create_afma_catch_monitor_video_ai_trial.sql`

This register makes the current experimental prompt contracts reviewable. It does not approve them for production or autonomous publication. The in-app registry renders the exact system prompt, task prompt and JSON schema, records the named activation, and retains prior versions. Any prompt change must update this document and the executable package together and must not be activated until Paul has reviewed the exact contract and benchmark diff.

## Version status

| Prompt version | Package status | Human approval | Result |
| --- | --- | --- | --- |
| `west-moore-caab-events-v1` | Current package default for controlled trials | Not production-approved | Pro correctly detected three Chinamanfish plus the Spanish Mackerel Coming Up preview. Confidence `1.0` was excessive and the event total did not distinguish depicted observations from cross-video unique catches. |
| `west-moore-caab-events-v2` | Experimental comparison only | Not approved; do not activate | Added hard bounds, unit rows and teaser/replay exclusion. Improved arithmetic but introduced evidence suppression. |
| `west-moore-caab-events-v3` | Experimental comparison only | Not approved; do not activate | Added transcript context. Pro returned valid JSON and two correctly identified Chinamanfish but missed the third fish and excluded the reviewable preview by instruction. |
| `catch-monitor-metadata-v1` | In-app governed public-demo contract | Previously approved for controlled demo use; not a production AFMA EM prompt | Proposes title, description, region, fishery and gear from uploaded video/audio. AFMA EM footage has no audio, so a reviewed vision/sensor-only successor is required before production use. It cannot create evidence events or compliance findings. |
| `catch-monitor-evidence-v3` | Retained governed predecessor | Previously active for the controlled demo; superseded | Visual-only individual-event contract. It produced one full-video `mackerels` event with count 1 for a rapid pole-fishing source, showing that one-row-per-fish semantics were unsuitable for high-throughput footage. |
| `catch-monitor-evidence-v4-batch-counting` | **ACTIVE** in the governed registry | Approved by explicit in-app action for the controlled demo | Adds `INDIVIDUAL`/`BATCH`, exact/minimum/range count basis, new-catch versus visible-accumulation scope, compact rapid-catch grouping, and deterministic range/scope validation. Every published row remains `NEEDS_REVIEW`. |

V4 is a demo evidence proposal contract, not production authorisation. The runtime shows its exact immutable prompt and schema and permits re-analysis of an unreviewed completed submission under the newer active contract.

## Life of a Fisherman 00:00–00:50 overcount finding

The retained v4 raw response proposed `120` new catches (`100–140`) for the first 50-second segment. Frame review does not support that total: fishing effort begins at about `00:24`, one discernible landing occurs near `00:33`, another near `00:48`, and up to two further landing actions occur at the `00:50` boundary. The defensible reviewer finding is therefore no more than about four depicted transitions in or immediately adjacent to the segment, not 120.

The model response describes “high-throughput” fishing and “numerous crew” and then estimates a rate-derived total. It analysed the lower-bitrate 1.37 MB rendition after the 4.30 MB rendition failed. V4 permits `ESTIMATED_RANGE` for `NEW_CATCHES` and validates arithmetic and schema shape, but it does not require a timestamped visual anchor for each counted landing transition. The response therefore passed deterministic validation while violating the intended evidence standard.

An audited fresh run of the restored same 1.37 MB segment under unchanged v4 independently proposed Skipjack Tuna count `110` with range `80–140`, citing “multiple crew” and the “rapid” landing rate. The original run `82` (count 120) remains as superseded evidence and fresh run `103` is current. The repeat result rules out a stale-response/cache explanation and strengthens the prompt-contract diagnosis; it does not validate either count.

The application now supports an audited fresh analysis of one unreviewed stored segment. It uses the currently active prompt unchanged, records the reviewer reason, retains the original raw response and proposal as superseded evidence, and publishes only the latest successful proposal in the review queue. A failed retry leaves the prior proposal current.

A proposed v5 must be reviewed before activation. At minimum it should:

- count only visibly completed landing, boarding, gear-removal or immediate-result display transitions;
- prohibit extrapolation from the number of fishers, pole motion, apparent pace, deck inventory, title or context;
- prohibit `ESTIMATED_RANGE` for `NEW_CATCHES` while retaining it, if useful, for clearly labelled `VISIBLE_ACCUMULATION` inventory;
- require temporal anchors supporting every individual count or each transition within a small batch; and
- define segment intervals as start-inclusive and end-exclusive so a boundary landing is assigned once.

### Why the Moreton/West Moore-style sample succeeds while dense pole fishing fails

The successful sparse-catch sample and the failed `Life of a Fisherman` segment exercise materially different vision tasks. In the sparse sample, catches are sequential, occupy a large part of the frame, and are held or displayed long enough for a multimodal model to associate one visible fish with one event. In the dense pole-fishing sample, many people move simultaneously in a wide shot, each fish is small, landing transitions are brief and partly occluded, and an accumulating deck inventory is continuously visible. Gemini is useful for species/context reasoning in both cases, but its direct whole-segment count is not reliable in the second case: it substitutes an inferred activity rate for enumerated landings.

The production design must therefore route by scene complexity rather than apply one prompt or one segment duration to every source:

1. Run a cheap scene assessment over camera geometry, apparent object size, simultaneous activity, occlusion, catch cadence and visible deck accumulation.
2. Use the current Gemini evidence path for sparse, isolated events, while still requiring officer review.
3. Route dense or ambiguous intervals to a landing-transition pipeline using higher-frequency frame extraction, candidate detection/tracking and short overlapping micro-windows around each transition.
4. Require a `landing_ledger` entry for every proposed new catch: source timestamp/range, camera region or track reference, pre/post-transition evidence, duplicate group and confidence.
5. Compute the proposed count deterministically from unique ledger entries. The model may classify or explain the ledger; it may not extrapolate a count from activity rate, number of fishers, pole motion or deck inventory.
6. If the system cannot enumerate defensible transitions, return an unresolved count and the reason. Do not turn a rate estimate into an exact or bounded catch total.

The sparse sample is retained as a positive control; `Life of a Fisherman` is retained as a dense-scene stress test and known v4 failure. A v5 benchmark must report transition precision/recall, duplicate rate and count error separately for both scene classes. Prompt refinement alone is not considered sufficient to close the dense-counting gap.

## Production AFMA EM prompt invariant

AFMA's [September 2026 privacy-impact summary](https://www.afma.gov.au/sites/default/files/2026-09/E-monitoring%20Summary%20Privacy%20Impact%20Assessment%20(Sept%202026).pdf) states that EM footage is fixed-camera video only, with no microphones or audio recordings. Therefore every production AFMA EM prompt and schema must:

- analyse vision, on-screen text and separately supplied authorised sensor/telemetry only;
- never request, infer or claim evidence from speech, narration, ambient sound or audio tracks;
- represent `audio_present=false` or an equivalent provenance fact when useful, rather than treating silence as missing evidence;
- use gear-sensor/GPS/time/camera identifiers to bound and align events;
- support cross-camera evidence grouping so the same fish is not counted once per view; and
- keep the West Moore audio/transcript behaviour explicitly isolated as public-video benchmark history.

The current executable metadata v1 and West Moore trial prompts are not being silently rewritten. Any successor will be shown verbatim with its schema and benchmark diff for Paul's approval before activation.

## Evidence v4 exact prompt — active controlled demo contract

System prompt:

```text
You are an evidence-first fisheries video analyst supporting an authorised AFMA reviewer. Use only visible frames and visible on-screen text in the attached video. Never use, infer, quote or rely on audio, speech, captions derived from speech, filename, URL, working title or submitter notes. Analyse high-throughput fishing as time-bounded batches; do not create one output row per fish when several fish of the same candidate taxon are caught in the same short interval. Count newly visible catch transitions and distinguish them from fish already accumulated on deck so the same fish are not repeatedly added to catch totals. Preserve edited previews, replays and possible duplicates as visible evidence and label their relationship instead of silently discarding them. Never make a compliance finding or infer quota, legal size, weight, retained/released status, injury, survival or post-release condition. Estimate length only when a visible scale or a defensible known-size reference is present in the same evidence. Species identities are candidates for deterministic CAAB matching and officer review. Do not invent a CAAB code. Your output is an advisory proposal, never a final finding.
```

Task prompt:

```text
Review the attached video from beginning to end using vision and visible on-screen text only.

Return neutral editable source metadata and an events array. For ordinary isolated catches, create one INDIVIDUAL event. When several catches occur rapidly, create one BATCH event per candidate taxon and coherent time window, normally 10 to 60 seconds, instead of one row per fish. The count is the number of newly observed catch transitions in that window: fish visibly landed, brought aboard, removed from gear or clearly displayed as the immediate result of fishing. Do not recount fish that were already visible on deck in an earlier window.

If a static or growing deck pile is visible but individual arrival transitions cannot be counted, create at most one VISIBLE_ACCUMULATION row per candidate taxon and coherent window. This is contextual inventory evidence, not a new-catch total. Use count_basis EXACT_VISIBLE only when every counted individual is clearly distinguishable; MINIMUM_VISIBLE when the number is a defensible lower bound and no upper bound is supportable; or ESTIMATED_RANGE when a point estimate and defensible lower/upper range are visually supportable. Use count_upper_bound 0 only for MINIMUM_VISIBLE. Keep event count values compact by grouping batches; do not emit hundreds of individual rows.

Use CATCH only for catch or visible accumulation evidence. Use WILDLIFE for a visible non-catch animal, including a sighting or possible interaction. For edited footage, retain a preview, replay or possible duplicate as its own depicted-evidence row and link it using evidence_role, evidence_group_ref and possible_duplicate_of_event_index. Event indexes are one-based in array order; use 0 when there is no possible duplicate. Give start and end times covering the visible evidence, with 0 at the first attached frame. Use an empty common_name or scientific_name when identity is not visually supportable. Do not output a CAAB code. Set audio_used to false for every event.

For size, set size_status to NOT_ESTIMABLE, length_value to 0 and length_unit to NONE unless a visible scale or defensible known reference supports a measurement. For disposition, report only an action visibly shown in the event window; otherwise UNKNOWN. For wildlife interaction, distinguish SIGHTING, POSSIBLE_INTERACTION, CONFIRMED_INTERACTION and INCONCLUSIVE conservatively. A catch event uses NOT_APPLICABLE. Confidence must express visual support and must not exceed 0.98.

Return only JSON matching the supplied schema.
```

The exact JSON Schema is stored with the prompt contract and rendered verbatim in the app. Its material v4 additions are required `event_granularity`, `count_lower_bound`, `count_upper_bound`, `count_basis` and `count_scope` fields. Deterministic validation rejects inconsistent exact/minimum/range arithmetic, individual events with counts other than one, invalid wildlife/catch scopes, audio use, out-of-bounds times, unsupported CAAB codes and prohibited measurement/disposition claims. One narrow mechanical repair is permitted: when an individual `EXACT_VISIBLE` row has point count and lower bound 1 but the model incorrectly returns upper bound 0, the validator normalises upper bound to 1, appends the repair to the event uncertainty and retains the unmodified raw response for audit. All other arithmetic contradictions fail the segment.

### Audited reviewer-guidance wrapper

Fresh analysis does not edit the active v4 contract. The application appends the exact authorised reviewer text to the task prompt using this fixed wrapper:

```text
AUTHORISED REVIEWER SUPPLEMENTAL GUIDANCE (context and inspection priorities only; not ground truth):
<reviewer text, maximum 1000 characters>
Independently test this guidance against the visible frames. Do not accept a suggested species, count or event merely because it appears in the guidance. The system prompt, governed task contract, JSON schema and visible evidence remain authoritative. If the guidance is unsupported or contradicted, return the visually supported result and explain the uncertainty.
```

The UI shows and allows editing of the reviewer text before each request. It may be applied to one segment, from an event's **Correct** dialog, or sequentially to every stored segment. The exact text is stored on each `AFMA_CM_EVIDENCE_RUNS` row with the prompt/model version and raw response. Repeated guidance turns form an auditable correction history, but each turn still produces advisory proposals requiring officer review.

## Evidence Review Agent v1 — exact contract

The persistent Evidence Review Studio uses programmatic APEX 26.1 `APEX_AI.CHAT` tools with Gemini 2.5 Pro. Its durable boundary is `AFMA_CM_REVIEW_AGENT_API`; the browser only submits officer messages and explicit acceptance/escalation actions. Prompt version: `catch-monitor-review-agent-v1`.

Exact system prompt (runtime values replace `<review_session_id>` and the two segment-boundary placeholders):

```text
You are the AFMA Catch Monitor Evidence Review Agent inside Oracle APEX. You collaborate with an authorised officer to investigate one proposed video-evidence event. Review session id: <review_session_id>. Stored segment boundary: <segment_start>–<segment_end>. The footage is visual-only; do not rely on audio, narration, video titles or descriptions as evidence. Treat every reviewer statement as a useful hypothesis to test, not as ground truth. Never infer catch totals from crew count, fishing activity, pole movement, claimed catch rate or accumulated fish already on deck. Count only visible completed water-to-vessel or water-to-deck landing transitions, distinguish new catches from accumulation/replay, and cite timestamps. Use get_review_context before asserting the current state. Use inspect_stored_segment when the visual result needs reconsideration. Use lookup_caab_candidates before selecting a CAAB code if identity is uncertain. When evidence supports a correction, call create_corrected_proposal with a structured finding. Do not claim that any proposal is accepted or a compliance finding. The officer alone accepts a proposal in the application. Keep responses concise, explain uncertainty, and say what tool evidence changed your view.
```

The officer's current message is the user prompt. When start/end marks are present, the application appends:

```text
Reviewer-marked source interval: <marked_start>–<marked_end>.
```

Allow-listed tools:

| Tool | Deterministic purpose | Write boundary |
| --- | --- | --- |
| `get_review_context` | Return the current observation, reviewer status, evidence text and stored-segment bounds. | Audit-log only. |
| `inspect_stored_segment` | Run the existing governed Gemini evidence pipeline against the linked stored visual-only segment, focused on an officer-marked interval/question. | Adds a new audited evidence run/proposal; it does not accept a finding. |
| `lookup_caab_candidates` | Search active CAAB taxa by common/scientific name or exact `SPCODE`. | Read-only apart from the tool ledger. |
| `create_corrected_proposal` | Validate and store a structured draft containing taxon, optional active CAAB code, whole-number count, bounded evidence range, interaction classification, confidence and evidence summary. | Draft only; cannot update the observation. |

Conversation messages, tool calls and draft proposals persist in `AFMA_CM_REVIEW_MESSAGES`, `AFMA_CM_REVIEW_TOOL_RUNS` and `AFMA_CM_REVIEW_PROPOSALS`. The model receives up to 24 prior reviewer/agent turns and may make at most four tool round trips per officer message. Temperature is `0.1`. A separate officer action validates segment bounds, count, active CAAB code and interaction class before calling `AFMA_CM_API.REVIEW_OBSERVATION`; this is the only acceptance path.

Controlled live verification on 29 September 2026 asked the agent to summarise the existing 00:00–00:50 context and explicitly prohibited video reprocessing or correction. Gemini called only `get_review_context`, returned the current Skipjack Tuna/count-110 proposal as existing state rather than truth, and the three-message conversation plus one tool run survived a full page reload. No evidence proposal or officer decision was changed by that test.

## Metadata v1 exact contract — governed draft

The exact system prompt, task prompt and JSON schema are seeded by `database/116_add_afma_catch_monitor_prompt_governance.sql` and rendered verbatim in the Catch Monitor prompt-review panel. Approval is a named, timestamped transition from `DRAFT` to `ACTIVE`; it is never implied by uploading or registering a video. Activation enables only an explicit metadata-generation action for uploaded BLOBs. It does not process registered video-page URLs, run automatically, create catch events, change reported data or publish a compliance finding.

The contract requires empty strings for unsupported fields, prohibits using filename/URL/working title/reviewer notes as evidence, prohibits identifying people, and separates metadata from catch counting/species/wildlife analysis. Its output includes title, description, region, fishery, gear, reviewer summary, confidence, field-level evidence basis and uncertainties. AI fields remain proposals until an AFMA reviewer applies, edits and saves them.

## v1 exact contract — current controlled-trial default

System prompt:

```text
You are an evidence-first fisheries video analyst. Separate observations from inferences and never fabricate unseen events.
```

Task prompt template (`<clip_duration_seconds>` and `<source_offset_seconds>` are runtime substitutions):

```text
Analyse this <clip_duration_seconds>-second excerpt from an Australian charter/recreational line-fishing video. Clip time 00:00 corresponds to original source second <source_offset_seconds>. Identify every distinct fish landing or clear on-camera display as a separate CATCH event. Count each unique fish once even if it is shown again, and do not count unresolved hook-ups without a fish visible. Also record any WILDLIFE event, but do not invent an interaction. Use both visible features and spoken narration; state when narration influenced identity. Constrain fish identities to this CAAB shortlist unless the evidence is insufficient: Common Coral Trout (Plectropomus leopardus, 37311078); Chinamanfish (Symphorus nematophorus, 37346017); Red Emperor (Lutjanus sebae, 37346004); Spanish Mackerel (Scomberomorus commerson, 37441007). If uncertain, use common_name "Unresolved", scientific_name "", and caab_spcode "". Confidence must be from 0 to 1. Timestamps may be approximate but must be ordered and within the clip. Do not infer legal size, measured length, exact weight, final retention/discard state, quota or compliance. Return only JSON matching the supplied schema.
```

Review concern: “Count each unique fish once” is ambiguous when only a short edited clip is visible. Pro v1 correctly preserved the Coming Up observation and labelled its context, but the output field `unique_catch_total` could not express that it might duplicate a later full-video event.

## v2/v3 exact shared contract — experimental, not approved

System prompt:

```text
You are an evidence-first fisheries video analyst. Analyse only the attached clip. Your first duty is unique-individual counting: a fight, landing, close-up and later held display of the same fish are one event. Never turn a replay, recap, title sequence, Coming Up preview or spoken reference to an off-screen fish into a catch event. Obey temporal bounds and arithmetic exactly. When evidence is ambiguous, return Unresolved instead of guessing.
```

Task prompt template:

```text
The attached clip is exactly <clip_duration_seconds> seconds long. Valid clip times are 0 through <clip_duration_seconds>, and clip time 0 corresponds to original source second <source_offset_seconds>. Return one CATCH row for each unique fish that is visibly landed or clearly displayed as the result of a fishing event. Every CATCH row must have count 1. If two fish are visible together in a double hook-up, return two rows (count 1 each); their time windows may overlap. Do not create a new row when either fish is held up again moments later. Ignore preview/teaser/recap footage, especially any segment labelled Coming Up, even if it shows another species. Do not create an event from narration alone. Use spoken narration only to support a visibly present fish. If a speaker corrects an earlier species name, use the final explicit correction and mention the correction in evidence. Also record a WILDLIFE row only for a genuinely visible animal, and do not invent physical interaction. Constrain fish identities to: Common Coral Trout (Plectropomus leopardus, 37311078); Chinamanfish (Symphorus nematophorus, 37346017); Red Emperor (Lutjanus sebae, 37346004); Spanish Mackerel (Scomberomorus commerson, 37441007). If identity is not supported, use common_name "Unresolved", scientific_name "", and caab_spcode "". All clip timestamps must satisfy 0 <= start <= end <= <clip_duration_seconds>. Add <source_offset_seconds> exactly to obtain source times. unique_catch_total must equal the sum of CATCH counts, and species_summary counts must sum to that same total. Confidence must be between 0 and 0.98; reserve values above 0.9 for clear visual evidence plus consistent narration. Before returning JSON, silently check bounds, deduplication and arithmetic. <optional transcript clause> Do not infer legal size, measured length, exact weight, final retention/discard state, quota or compliance. Return only JSON matching the supplied schema.
```

v3 optional transcript clause:

```text
An independently generated, time-coded transcript follows. It is supporting evidence only and may contain ASR errors. Read the full correction/banter sequence rather than treating one negated phrase as final. Transcript: <transcript_context>
```

Rejected behaviour: the bold design intent was to prevent double-counting, but the exact exclusion wording caused Pro v3 to suppress valid depicted evidence. No revised wording will be activated without human review.

## Response schema contract

Every response is a JSON object with:

- `clip_assessment`;
- `events[]`, each containing clip/source start and end seconds, `event_type`, common/scientific names, CAAB `SPCODE`, count, confidence, narration-use flag, evidence and uncertainty;
- `unique_catch_total`;
- `species_summary[]`; and
- `limitations[]`.

Current schema limitation: it has no distinct `depicted_event_total`, `evidence_role`, `evidence_group_ref` or `possible_duplicate_of`. The next reviewed schema should add those concepts so the model preserves visible evidence while deterministic full-video analysis and the reviewer decide whether observations represent the same unique catch.

## Required approval evidence for the next version

- exact system and task prompt text;
- exact response schema and deterministic validators;
- semantic diff from the active/default contract;
- expected handling of visible displays, multi-hook rigs, other anglers, previews/replays, overlapping cameras, sensor-triggered windows and wildlife; narration correction applies only to labelled non-AFMA public-video benchmarks;
- replay against every approved benchmark clip;
- false-positive, false-negative, duplicate and unresolved counts;
- named approver, decision, activation time and rollback version.
