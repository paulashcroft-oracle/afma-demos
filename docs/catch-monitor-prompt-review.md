# Catch Monitor prompt review register

Status: **human approval required before the next prompt activation**
Prepared: 28 September 2026
Executable sources: `database/116_add_afma_catch_monitor_prompt_governance.sql` and `database/135_create_afma_catch_monitor_video_ai_trial.sql`

This register makes the current experimental prompt contracts reviewable. It does not approve them for production or autonomous publication. Until an in-app registry exists, any prompt change must update this document and the executable package together and must not be activated until Paul has reviewed the exact contract and benchmark diff.

## Version status

| Prompt version | Package status | Human approval | Result |
| --- | --- | --- | --- |
| `west-moore-caab-events-v1` | Current package default for controlled trials | Not production-approved | Pro correctly detected three Chinamanfish plus the Spanish Mackerel Coming Up preview. Confidence `1.0` was excessive and the event total did not distinguish depicted observations from cross-video unique catches. |
| `west-moore-caab-events-v2` | Experimental comparison only | Not approved; do not activate | Added hard bounds, unit rows and teaser/replay exclusion. Improved arithmetic but introduced evidence suppression. |
| `west-moore-caab-events-v3` | Experimental comparison only | Not approved; do not activate | Added transcript context. Pro returned valid JSON and two correctly identified Chinamanfish but missed the third fish and excluded the reviewable preview by instruction. |
| `catch-monitor-metadata-v1` | In-app governed public-demo contract | Previously approved for controlled demo use; not a production AFMA EM prompt | Proposes title, description, region, fishery and gear from uploaded video/audio. AFMA EM footage has no audio, so a reviewed vision/sensor-only successor is required before production use. It cannot create evidence events or compliance findings. |

No v4 prompt is proposed or active. Its wording will be drafted only after review of the desired depicted-event, evidence-linking and unique-catch semantics.

## Production AFMA EM prompt invariant

AFMA's [September 2026 privacy-impact summary](https://www.afma.gov.au/sites/default/files/2026-09/E-monitoring%20Summary%20Privacy%20Impact%20Assessment%20(Sept%202026).pdf) states that EM footage is fixed-camera video only, with no microphones or audio recordings. Therefore every production AFMA EM prompt and schema must:

- analyse vision, on-screen text and separately supplied authorised sensor/telemetry only;
- never request, infer or claim evidence from speech, narration, ambient sound or audio tracks;
- represent `audio_present=false` or an equivalent provenance fact when useful, rather than treating silence as missing evidence;
- use gear-sensor/GPS/time/camera identifiers to bound and align events;
- support cross-camera evidence grouping so the same fish is not counted once per view; and
- keep the West Moore audio/transcript behaviour explicitly isolated as public-video benchmark history.

The current executable metadata v1 and West Moore trial prompts are not being silently rewritten. Any successor will be shown verbatim with its schema and benchmark diff for Paul's approval before activation.

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
