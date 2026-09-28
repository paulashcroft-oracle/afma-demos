# AFMA Catch Monitor — review specification

Status: **MVP implemented in AIDEMODB app 101; product and operating decisions remain for review**  
Prepared: 26 September 2026  
Implemented: 28 September 2026 under AI Hub task `caab-016`  
Scope: AIDEMODB app 101 demonstrator, not a production reporting system.

Implemented slice: reviewer-only page 4, versioned reported-data API, freeze/amend rules, CAAB-linked identities, selectable source-traced video cases, evidence-provenance labels, catch/wildlife review controls, reconciliation, audit events, governed media metadata, the hybrid-incremental library plan, West Moore ground truth and isolated APEX-to-Gemini trials. Publishing model output into the queue, structured per-fish measurements, private-object ingestion, bulk media discovery, import templates and production authorisation/retention controls remain later delivery gates.

## Implemented selectable video set

The selector changes the source video, description, synthetic/received comparison record, evidence run and review queue together. It defaults to grounded Queensland handline footage; it never carries observations from one video into another.

| Case | What the footage shows | Evidence status |
| --- | --- | --- |
| `CM-QLD-002` — [ABC Great Barrier Reef handline](https://www.abc.net.au/news/2024-06-07/sharks-take-handline-fishermens-catch/103948396) | One hooked reef fish and sharks sighting/contacting or taking the catch. Useful for catch plus depredation; fish and shark species remain unresolved. | Three human-curated, time-coded demo events grounded in the reviewed clip; not live model output. |
| `CM-QLD-003` — [AMCS Mackay turtle gillnet](https://www.marineconservation.org.au/marine-conservationists-uncover-footage-of-turtle-death-traps-in-our-reef/) | Multiple marine turtles visibly entangled in gillnet. The publisher reports at least seven animals. | One source-described aggregate/minimum; species-level and individual time coding remain pending. |
| `CM-QLD-004` — [ABC Bundaberg prawn trawler](https://www.abc.net.au/news/2024-03-02/video-sharks-dolphins-maul-prawn-trawler-catch/103534252) | A dolphin and multiple sharks around a trawler, including sharks contacting the caught mass. Useful as a crowded interaction/counting stress test. | Three human-curated, time-coded demo events; minimum counts and unresolved species are explicit. |
| `CM-WA-001` — [West Moore Island episode](https://www.youtube.com/watch?v=b4KcVC11KVI) | Nine unique fish: Common Coral Trout x1, Chinamanfish x4, Red Emperor x1 and Spanish Mackerel x3. The edited source also contains a 07:09 Coming Up preview of the first Spanish Mackerel landing. No wildlife interaction is evidenced. | Ten time-coded depicted-catch observations: nine unique fish plus the linked preview. All remain reviewer-visible; the preview is labelled as a possible duplicate rather than silently discarded. |
| `CM-QLD-001` — original workflow fixture | The original public coral-trout-themed source used to exercise the first UI slice. | Explicitly labelled synthetic UI fixture; its four deterministic events are not claims about the video. |

Each selected case displays its region, fishing context, duration where known, source link, rights status, annotation/evidence status and a plain-language description. Source narration may inform a note, but species-level CAAB identity remains unresolved unless the visual evidence and reference material support that precision. The current “AI” queue is therefore a deterministic evaluation fixture assembled from manual/source review, not the output of a connected computer-vision model.

The first APEX-native Gemini experiment is documented in [Catch Monitor video-analysis options and benchmark](catch-monitor-video-analysis-options.md). Raw trial results remain in `AFMA_CM_AI_TRIALS`, isolated from `AFMA_CM_OBSERVATIONS`; no model response is automatically published to the review queue.

Current model decision: use OCI Gemini 2.5 Pro in Chicago as the demonstrator's default video-analysis model. Flash comparison results remain recorded, but Flash is deferred unless later volume, latency or cost warrants a second tier.

Edited-source policy for this public demo: retain every visibly depicted catch as a reviewable observation, tag previews/replays explicitly, and link matching observations into an evidence group. The West Moore 07:09 preview is linked to the full 12:28–14:20 Spanish Mackerel sequence. This deliberately exposes the deduplication anomaly to viewers. Production AFMA recording-device footage is expected to be continuous and should not contain editorial Coming Up segments, but the provenance fields remain useful for repeated views, camera overlap and genuine duplicate detections.

## Decision requested

Approve a staged Catch Monitor demonstrator for authorised AFMA review officers. It analyses fishing-operation video and helps the officer identify species, count catch, classify retained or discarded catch where visible, and detect wildlife sightings or possible protected-species interactions.

The demonstrator must always say **AI-assisted review — reviewer confirmation required**. It must not make an autonomous compliance finding or alter a fisher's logbook/e-log/CDR. An authorised AFMA officer confirms every proposed result. Fishers are not Catch Monitor users in the MVP; they continue to operate the vessel system and meet their existing reporting obligations through approved channels.

Catch Monitor is an additive capability inside the existing AFMA CAAB AI Demo. The current Home, CSIRO CAAB Agent, Reports, CAAB loading APIs, taxonomy data, common-name/alias data and reporting views must remain operational. CAAB supplies the canonical taxonomic identity used to identify, reconcile and log Catch Monitor output.

## AFMA basis and product boundary

AFMA describes electronic monitoring as cameras and sensors whose footage can be reviewed to verify logbook reporting. AFMA's current program says footage review is being performed in-house by AFMA and includes AI/ML as a way to speed analysis and event detection. E-monitoring does **not** change catch, discard, or protected-species reporting obligations.

In Commonwealth fisheries, the concession holder is responsible for a complete/correct logbook and the skipper submits it during the trip. Logbooks cover time/location, gear, catch composition, and protected-species interactions. Requirements vary by fishery, concession, gear, area, vessel-monitoring plan, current direction, and logbook form. Catch Monitor therefore gives the AFMA reviewer contextual guidance and an evidence-backed reconciliation workspace, never an autonomous legal conclusion.

AFMA defines a protected-species interaction as physical contact involving a person, nominated boat, boat equipment, or something onboard/attached, of a kind that could distress the organism. Wildlife merely visible near a vessel is not necessarily a reportable interaction. Actual protected-species interactions in Commonwealth fisheries must be reported in the AFMA logbook.

Every compliance prompt must show source title, URL, review/effective date, and fishery/gear applicability:

- [AFMA electronic monitoring program](https://www.afma.gov.au/fisheries-management/monitoring-tools/electronic-monitoring-program)
- [AFMA logbooks and e-logs](https://www.afma.gov.au/logbooks-and-elogs)
- [AFMA protected-species management](https://www.afma.gov.au/protected-species/protected-species-management)
- [AFMA protected-species reporting](https://www.afma.gov.au/protected-species/endangered-and-threatened-species-reporting)
- [AFMA reducing bycatch](https://www.afma.gov.au/protected-species/reducing-bycatch)
- [AFMA e-monitoring FAQ — June 2026](https://www.afma.gov.au/sites/default/files/2026-06/afma_e-monitoring_program_-_frequently_asked_questions.pdf)
- [AFMA e-monitoring privacy-impact summary — September 2026](https://www.afma.gov.au/sites/default/files/2026-09/E-monitoring%20Summary%20Privacy%20Impact%20Assessment%20(Sept%202026).pdf)

## Users and outcomes

| User | Outcome |
| --- | --- |
| AFMA electronic-monitoring review officer | Find catch and wildlife events on a timeline, correct AI suggestions, reconcile footage with reported information, and create a traceable review result. |
| AFMA fisheries manager or authorised compliance analyst | Inspect discrepancies, protected-species findings, reviewer evidence and aggregate catch patterns within their authority. |
| AFMA demo data operator | Create, import and amend a clearly identified synthetic or received fisher report for comparison; freeze a version before video review begins. |
| AFMA system administrator/demo operator | Manage authorised users, source footage, model/rule versions and test-data permissions; cannot silently change a frozen report or completed review. |

Fishers, concession holders, vessel crew and receivers are external subjects or recipients of existing AFMA processes, not application users in the MVP. Any later fisher-facing feedback view is a separately authorised scope.

## MVP scope

- Upload one source-traced MP4/MOV approved for the controlled internal demo and record fishery, gear, broad coastal region, date, camera/view, known rights status, and checksum.
- Create, import or edit the corresponding normal fisher-reported trip, operation, catch, discard and protected-species information, with synthetic/received provenance and version history.
- Select among governed video cases and show a description of what each source demonstrates before review begins.
- Provide a governed CAAB-linked media library containing source-traced reference images and labelled video examples for the selected demo species.
- Detect fishing-operation segments, catch observations, counts, species candidates, and wildlife observations.
- Allow confirm, edit, merge, split, reject, and escalate decisions for every event.
- Reconcile human-reviewed video observations against supplied logbook/e-log information and produce an internal review result or draft feedback report.
- Provide contextual AFMA ID, handling, mitigation, and video-quality guidance.
- Preserve clip/frame evidence, model/version, confidence, reviewer, and decision history.

Explicitly out of scope: a fisher portal; changing or submitting GoFish/e-log/CDR records; type approval or vessel-monitoring-plan claims; autonomous compliance decisions or enforcement action; verified weight/quota/legal-size/post-release-condition from video; and model training from internet video without written rights.

## CAAB preservation and integration contract

### Preserve the current application

Catch Monitor shall add pages, navigation and database objects without replacing or repurposing the current CAAB capabilities. In particular:

- retain the existing Home, CSIRO CAAB Agent and Reports pages and their current navigation entry points;
- retain `CSIRO_CAAB_TAXA`, `CSIRO_CAAB_TAXA_ACTIVE_V`, `CSIRO_CAAB_COMMON_NAMES`, `CSIRO_CAAB_COMMON_NAME_SEARCH_V`, the CAAB load/common-name APIs and existing report views as the owned CAAB source layer;
- do not copy CAAB taxa into a second editable species master;
- keep existing CAAB source provenance, current/non-current status and synthetic-alias indicators visible; and
- add Catch Monitor-specific tables and APIs separately, referring to CAAB by `SPCODE` where a mapping is available.

### Use CAAB throughout Catch Monitor

CAAB shall drive both AI suggestions and human data entry:

- resolve a fisher-entered common name, local alias, market name or scientific name through `CSIRO_CAAB_COMMON_NAME_SEARCH_V` and `CSIRO_CAAB_TAXA_ACTIVE_V`;
- constrain/rank AI species candidates using CAAB taxonomy plus available region, fishery, gear and alias context;
- show `SPCODE`, scientific name, preferred CAAB common name, relevant alternative names, taxonomic rank and current-status indicator in the reviewer decision panel;
- retain the source-reported species text exactly as entered, alongside the nullable reviewed CAAB `SPCODE` mapping;
- save the AI-proposed `SPCODE` candidates separately from the officer-confirmed `SPCODE`; and
- use the officer-confirmed CAAB identity in reconciliations, review results and aggregate Catch Monitor reports.

Every species mapping shall record `mapping_status`, `mapping_method`, confidence where applicable, mapped-by identity, mapped-at time and the CAAB load/version provenance used. Supported statuses are `MATCHED`, `MULTIPLE_CANDIDATES`, `HIGHER_TAXON`, `NOT_IN_CAAB` and `UNRESOLVED`. The application must never invent an `SPCODE` or force a match.

CAAB is the taxonomic catalogue, not the source of legal protected-species status or abundance. Protected-species/reporting rules must remain a separately versioned AFMA/EPBC overlay linked to the CAAB taxon when possible. Wildlife that cannot be resolved to CAAB remains reviewable and reportable using its original description and the applicable protected-species reference.

### Connected experience

From a reported catch line, AI detection or confirmed review finding, the officer shall be able to open a CAAB detail view showing taxonomy, names/aliases, provenance and current status. Catch Monitor aggregate reports may add reviewed counts and discrepancies by `SPCODE`, but the existing CAAB Reports page must continue to describe the catalogue itself and must not present Catch Monitor counts as CAAB population-abundance data.

## CAAB-linked media library requirement

The loaded 63,191-row CAAB extract contains taxonomy and names but no image assets or image URLs. The wider CSIRO CAAB service separately exposes collection images keyed by CAAB code, including an [Australian National Fish Collection Fishmap catalogue](https://www.cmar.csiro.au/caab/collection_images.cfm?image_set=FISHMAP) currently returning approximately 4,093 images. Catch Monitor shall introduce a governed media library that links these and other approved visual assets to the existing CAAB `SPCODE` records without adding media columns to `CSIRO_CAAB_TAXA`.

### Media purposes must remain separate

Each asset shall have one or more explicitly approved purposes:

- `REFERENCE_DISPLAY`: show an AFMA reviewer trusted comparison images and identification features;
- `MODEL_CONTEXT`: provide an approved retrieval/reference set to a vision workflow;
- `TRAINING`: permit the asset and approved derivatives to train or fine-tune a model;
- `VALIDATION`: permit use in a held-out performance test set; or
- `DEMO_PLAYBACK`: permit showing a source clip in the Catch Monitor demonstration.

Permission for display does not imply permission for model training, derivative annotations or redistribution. For this controlled internal demo, incomplete licence information is recorded and risk-scoped rather than treated as an automatic blocker. Public/customer distribution, external publication, redistribution and custom model training remain separate approval gates.

Rights status shall be one of `CONFIRMED`, `UNCONFIRMED_INTERNAL_ONLY`, `RESTRICTED`, `PROHIBITED` or `TAKEDOWN`. `UNCONFIRMED_INTERNAL_ONLY` permits limited use in the access-controlled demo after a reasonable source check, with source/creator recorded and no public export. It does not permit bypassing access controls, ignoring an explicit prohibition, using confidential/private material without authority, or continuing after a rights-holder objection.

### Required media metadata

Store the media catalogue separately from the binary object. A media asset record shall include:

| Area | Required metadata |
| --- | --- |
| Identity | Media ID, nullable CAAB `SPCODE`, original taxon text, asset type, view type, life stage/sex where known and identification status. |
| Source | Source system, stable source record URL/identifier, creator, provider, capture date, Australian region/habitat and specimen/observation identifier where applicable. |
| Rights | Rights status, copyright holder where known, available licence and URL/version, attribution text, approved purposes, restrictions, permission evidence where available, date checked and internal-demo rationale when unconfirmed. |
| File integrity | Private object-storage URI, MIME type, dimensions/duration, file size, SHA-256 checksum and derivative-of media ID. |
| Quality | Deck/underwater/specimen context, orientation, occlusion, image-quality rating, expert-review status and reviewer notes. |
| Dataset control | Dataset split (`REFERENCE`, `TRAIN`, `VALIDATION`, `TEST`), annotation version, duplicate/near-duplicate group and leakage-control group such as trip/vessel/source. |

An asset may be linked to more than one candidate taxon during curation, but only an expert-confirmed mapping becomes an approved species reference. `UNRESOLVED` and `NOT_IN_CAAB` assets remain available for review without a fabricated `SPCODE`.

### Source priority and licensing rules

Populate the library in this order:

1. **CSIRO CAAB Image Catalogue and Australian National Fish Collection.** Prefer these because images can be associated directly with CAAB codes and specimen provenance. CSIRO reports a much larger ANFC digital collection beyond the CAAB Fishmap subset. Capture the displayed licence where readily available: example CAAB/ANFC records use CC BY-NC-SA and current CSIRO Data Access Portal image collections may use [CC BY-NC 4.0](https://data.csiro.au/collection/csiro%3A66002). If the exact internal-demo position remains unclear after a reasonable check, mark the asset `UNCONFIRMED_INTERNAL_ONLY` and continue with restricted internal evaluation; obtain confirmation before public/customer reuse or custom training.
2. **[Atlas of Living Australia](https://www.ala.org.au/terms-of-use/).** Use Australian occurrence/specimen images and retain record-level provider/licence information when available. ALA pages can combine content from providers under different terms, so do not assign one ALA-wide licence; unresolved records may remain internal-only.
3. **[iNaturalist licensed datasets/API](https://www.inaturalist.org/pages/developers).** Prefer research-grade Australian observations with CC0 or CC BY photos, while allowing other source-traced records to be evaluated internally under the recorded rights status. Use supported datasets/API and rate limits, not scraping or access-control circumvention.
4. **[Wikimedia Commons](https://commons.wikimedia.org/wiki/Commons:Reusing_content_outside_Wikimedia/en).** Prefer files with clear per-file creator/licence information and retain attribution/share-alike details. Do not let a difficult edge case block the internal demo; use another asset or mark it internal-only.
5. **AFMA identification guides and operational footage.** Link to published guidance for reviewer assistance. Record known source and terms for any extracted frames or clips. Real non-public AFMA/vessel footage still requires task authority and privacy/security approval; public/customer distribution or model training requires a separate rights decision.

Search-engine results and unverified social-media images are discovery leads rather than authoritative species records. Prefer the original source; if an asset is temporarily used in the internal demo, mark it `UNCONFIRMED_INTERNAL_ONLY`, exclude it from training/export and replace it when a better source is found.

### Population plan

1. **Select the first fishery and target list.** After the demo fishery/gear is chosen, define a versioned priority list of target catch, expected bycatch, look-alike taxa and protected wildlife. Resolve each entry to CAAB `SPCODE` where possible and include explicit higher-taxon/unresolved slots.
2. **Audit existing visual coverage.** Query the CAAB/ANFC catalogue first, then ALA, iNaturalist and Commons. Produce a coverage report by `SPCODE`, view type, rights status and intended purpose. Perform a reasonable source/licence check during ingestion; missing or ambiguous terms produce `UNCONFIRMED_INTERNAL_ONLY` rather than blocking the controlled demo.
3. **Establish the reference set.** For every priority species, seek multiple expert-verified views showing relevant identification characteristics and, where available, live colouration, lateral/dorsal/ventral views, juveniles/adults and likely deck condition. A small reference set supports reviewer display; it must not be described as sufficient model-training data.
4. **Acquire operational examples.** Obtain source-traced Australian fishing footage approved for the internal demo and extract labelled frames/clips showing real deck lighting, occlusion, handling, crowding and camera angles. These operational examples are essential because clean specimen images alone do not represent e-monitoring footage.
5. **Annotate and validate.** Two suitably qualified annotators independently label taxon, bounding box/track, unique individual, fate, view quality and interaction status. Record disagreement and expert adjudication. Retain the original label and every annotation revision.
6. **Create leakage-safe datasets.** Keep reference, training, validation and test purposes separate. Place all frames from the same trip, clip, vessel or near-duplicate sequence in one split so the test results cannot be inflated by duplicated imagery.
7. **Approve and publish internally.** A media curator verifies taxonomy, source, recorded rights status, attribution, file integrity and purposes before an asset becomes available. `UNCONFIRMED_INTERNAL_ONLY` assets remain visibly restricted and cannot enter public exports or custom-training datasets.
8. **Monitor coverage and expiry.** Dashboard coverage by priority species and view type, re-check expiring/changed permissions, quarantine disputed assets, and version every released dataset manifest.

The MVP should use a pretrained vision capability plus the CAAB-constrained candidate list and internal reference retrieval. Custom training/fine-tuning is a later gate requiring adequate operational footage, an explicit data-use decision, expert labels, leakage-safe splits and an approved evaluation baseline.

### Incremental versus full population strategy

The media library shall use a **hybrid incremental** strategy for the demo:

- keep the full CAAB taxonomy and names locally as already implemented;
- build a lightweight searchable metadata/coverage index for eligible external media collections where their APIs and terms permit it;
- store media binaries locally only for approved target taxa and actual demo/test needs; and
- expand the approved asset set through a repeatable curation workflow whenever a new video introduces missing or ambiguous taxa.

This avoids pretending that a full visual library is achievable merely because the full taxonomy is loaded. Current scale illustrates the difference:

| Layer | Known scale | Design implication |
| --- | ---: | --- |
| [Loaded CAAB catalogue](caab-data-profile.md) | 63,191 taxon rows; 46,731 case-normalised species rows; 51,213 active/current rows | Suitable as the complete local naming/taxonomy layer, but most taxa are irrelevant to a selected fishery and have no image in the extract. |
| CAAB/ANFC Fishmap image catalogue | Approximately 4,093 images | Manageable for metadata discovery, but it does not cover all CAAB species and each asset still needs a rights/purpose check. |
| [Broader Australian National Fish Collection](https://www.csiro.au/en/about/facilities-collections/collections/anfc/what-our-collection-holds) | More than 92,000 fish images representing about 3,700 species, according to CSIRO | Potentially valuable but large, specimen-heavy and subject to collection/record licensing; full binary ingestion is not an MVP requirement. |
| Operational e-monitoring footage | Volume depends on trips, cameras, resolution, duty cycle and retention | Likely to dominate storage and curation cost; retain only authorised footage and derived evidence needed for the demo/review policy. |

Before choosing a full or incremental acquisition for any source, record:

- number of target taxa and percentage covered by the source;
- assets per taxon, view diversity and whether imagery resembles deck footage;
- original and derivative byte volume, object-storage cost, backup/retention multiplier and expected network egress;
- API rate limits, bulk-download terms and refresh/change frequency;
- proportion of assets whose licences permit each intended purpose;
- curator and taxonomic-expert effort per asset/taxon;
- duplicate rate and the cost of checksum/perceptual-hash processing;
- expected frequency of new videos, fisheries and unseen species;
- reviewer latency requirements and whether external retrieval can be tolerated during a review;
- whether the model uses retrieval/reference images or requires a statistically adequate training set; and
- reproducibility requirements for re-running a historical review against the exact same media and model versions.

Use this capacity calculation for each proposed ingestion rather than a guessed total:

```text
stored bytes = approved originals
             + generated display/model derivatives
             + annotation/embedding/index overhead
             + required backup or replica copies
```

For illustration only, 4,093 originals averaging 5 MB would be about 20 GB before derivatives and backups; 92,000 at the same average would be about 460 GB. Actual source file sizes must be measured during the coverage audit, and video will use a separate duration/bitrate calculation. Storage volume is only one constraint—rights review and expert curation are likely to be the stronger limits.

Adopt the following tiers:

| Tier | Contents | Population mode |
| --- | --- | --- |
| 0 — Taxonomy | All existing CAAB taxa, names and aliases | Full and versioned, already loaded. |
| 1 — Discovery index | Remote media identifiers, CAAB/name mapping candidates, source, licence metadata and availability; no assumed usage permission | Broad metadata indexing where permitted, refreshed incrementally. |
| 2 — Internal reference library | Source-traced images for selected fishery taxa, look-alikes, likely bycatch and protected wildlife, including visibly restricted internal-only assets | Curated incrementally, stored privately and versioned. |
| 3 — Operational dataset | Authorised, annotated deck-video frames/tracks and interaction examples | Added per approved video/trip; split by trip/vessel/source for evaluation safety. |

A full binary ingest is justified only for a bounded source when coverage value is high, its terms and access method do not clearly prohibit the proposed ingest, measured storage/processing costs are acceptable, and expert curation capacity exists. Mixed or incomplete rights metadata can be retained for internal-only assets but makes a source unsuitable for unreviewed public export or training. “All CAAB species” is not a useful full-ingest target because media coverage is incomplete and the majority of taxa are outside any one demo fishery.

### New-video expansion workflow

New videos shall not require a schema change, hard-coded species list or complete library rebuild:

1. Register the video, fishery/gear/region context and rights.
2. Run a discovery pass using the pretrained vision capability and the applicable CAAB/fishery candidate set.
3. Compare proposed/observed taxa with the current approved-media coverage manifest.
4. Mark missing coverage as `MEDIA_GAP`, ambiguous mapping as `NEEDS_TAXON_REVIEW`, and unclear terms as `UNCONFIRMED_INTERNAL_ONLY`; continue to support `HIGHER_TAXON` and `UNRESOLVED` review outcomes without blocking the internal demo.
5. Queue only the affected taxa for source discovery, licence review, ingestion and expert validation.
6. Publish a new immutable media-library version after approval, without changing earlier review evidence.
7. Re-run only the affected analysis/review candidates when useful, recording both the original and new model/library versions.

Each analysis run shall be pinned to a media-library manifest. A later asset addition may improve a new or explicitly re-run analysis, but it must never silently rewrite a completed AFMA review.

## Functional requirements

### FR-1 — Reported fisher data capture

Provide a separate **Reported Data** workflow for an AFMA demo data operator to create the comparison baseline. This is not a fisher portal and does not submit data to AFMA. It represents either:

- `SYNTHETIC_DEMO`: deliberately created test data that resembles normal fisher reporting; or
- `RECEIVED_RECORD`: information transcribed or imported from an authorised source for the demo.

The operator shall be able to use a guided form, load a pre-approved sample, or import a documented CSV/JSON template. The minimum comparison model is:

| Section | Captured fields |
| --- | --- |
| Trip/report header | Report ID, source type, fishery, concession/test vessel reference, skipper or authorised-agent display reference, trip start/end, reporting status, submitted/recorded time and source provenance. |
| Fishing operation/shot | Operation number, set and haul date/time, broad location or authorised coordinates, gear/method and effort fields applicable to the selected fishery. |
| Catch line | Reported species/taxon, number where reported, weight where reported, retained/discarded/unknown state, discard reason and processing state where applicable. |
| Protected-species interaction | Reported species/taxon, count, time/location, fishing stage, life/injury status, contact/entanglement, release/mitigation action and notes where applicable. |
| Certification/version | `DRAFT`, `RECORDED`, `FROZEN_FOR_REVIEW` or `AMENDED`; recorded-by identity, timestamp, version number and amendment reason. |

Required behaviour:

- validate fields using the selected fishery/logbook profile while still allowing `unknown` or `not supplied` where the source record lacks information;
- clearly label synthetic values so they cannot be mistaken for a real fisher declaration;
- allow editing while the report version is `DRAFT` or `RECORDED`;
- freeze an immutable version when video review begins;
- represent later corrections as a new amended version linked to the original, never overwrite the frozen comparison baseline; and
- let reviewers view reported data but not edit it from the video-review workbench.

### FR-2 — Evidence-first intake and analysis

Require review context before analysis: fishery, gear/method, broad region, date, camera view, source profile, and rights/consent status. Permit `unknown` when evidence is inadequate. Create time-bounded observations with thumbnails, clip link, camera/view, and available GPS/sensor context. A detection is never a record until a reviewer decides. Preserve every depicted catch candidate, link repeated/overlapping evidence rather than silently deleting it, and support reviewer-controlled merge/split. Edited public demo footage must label previews/replays; continuous AFMA device footage should normally use primary evidence only.

### FR-3 — Catch identification and count

Show scientific name, CSIRO/AFMA common name where available, alternatives, confidence, count, and state: `retained`, `discarded alive`, `discarded dead`, `unknown`, or `not catch`. The reviewer may choose higher taxon or `unknown`; do not force false precision. Weight is a manual field headed “not estimated by video”.

The species selector and AI candidate list shall use CAAB `SPCODE` records and CAAB-backed common names/aliases. The interface shall show whether the identity is an exact taxon match, a higher-taxon decision, ambiguous, unresolved or outside the available CAAB catalogue.

### FR-4 — Wildlife workflow

| Outcome | Meaning | Reviewer action |
| --- | --- | --- |
| Wildlife sighting | Animal present; no physical contact evidenced. | Confirm or dismiss; no report claim. |
| Possible interaction | Evidence is incomplete or ambiguous. | Classify as sighting, confirmed interaction, or inconclusive. |
| Confirmed reportable interaction | Reviewer confirms physical-contact threshold and context. | Complete applicable review fields, reconcile against the reported record, and route the finding under AFMA procedure. |

For confirmed candidates, prompt for species/taxon, count, event time/location, fishing stage, life status/injury, contact/entanglement location, release method, tag/band where relevant, and free-text evidence. This is a configurable current-form superset, not a claim that every field applies to every fishery.

### FR-5 — Reconciliation, reviewer guidance, and quality

Compare confirmed observations with the selected frozen report version, grouped by operation/shot where known. Show field-level outcomes of `MATCH`, `VIDEO_HIGHER`, `REPORTED_HIGHER`, `SPECIES_DIFFERENCE`, `UNREPORTED_VIDEO_EVENT`, `REPORTED_NOT_OBSERVED`, `INCONCLUSIVE` and `NOT_COMPARABLE`. Flag low-confidence items, incomplete fate/count, duplicates, discrepancies, and incomplete interaction fields. Preserve the reported information unchanged. Export an **AFMA internal review result** or clearly labelled **draft feedback report**; do not imitate an e-log acknowledgement or alter the source report.

The guidance drawer provides AFMA reviewer sources for species ID, interaction definitions, bycatch handling, sharks/rays, turtles, and seabirds. Warn about obstruction, poor light, missing deck view, and timecode loss. Equipment-failure and mid-trip obligations remain fishery/VMP specific and are contextual evidence for the reviewer, not operating instructions issued by Catch Monitor.

### FR-6 — Audit, privacy, and retention

Record immutable decision history, model version, confidence, evidence hashes, and reviewer identity. Use least-privilege roles, encryption in transit/at rest, access logging, working-area/active-fishing capture only, and no audio. Default to a six-month footage deletion baseline aligned to AFMA’s PIA unless a stricter approved demo policy is chosen. Internal analysis/reference use follows the recorded rights status; custom model training requires an explicit recorded data-use decision.

### FR-7 — Prompt governance and human approval

Treat system prompts, task prompts, response schemas, CAAB candidate context and deterministic validation rules as governed application configuration. Every version must preserve its exact text, author, rationale, model/service, test set, comparison results, approval status, approver, activation time and rollback target. The lifecycle is `DRAFT → APPROVED → ACTIVE → RETIRED`; only an explicitly approved version may become active. Activation creates a new immutable version and audit event rather than overwriting prompt text.

The application shall provide an authorised prompt-review page showing the exact rendered system/task prompts and response schema before approval, including a highlighted semantic diff from the active version and replay results against the benchmark set. A prompt change that adds exclusion, deduplication, compliance, species or counting behaviour requires human review even when its JSON schema is unchanged. The West Moore regression demonstrates why: the v2/v3 teaser-exclusion instruction suppressed a correctly detected third Chinamanfish and reviewable preview that Pro v1 had identified.

Until that page exists, no new prompt version may be activated without Paul reviewing the exact prompt contract in [Catch Monitor prompt review register](catch-monitor-prompt-review.md). The PL/SQL package remains the executable source; the register and package must change together in the same reviewed commit.

## Proposed UI

### Reported Data page

```text
┌ Reported Data · Trip CM-0007 ─────────────────────────────────────────────────┐
│ Source [Synthetic demo ▼]  Fishery [ETBF ▼]  Status [Draft]  Version 1       │
│ [Load sample] [Import CSV/JSON] [Add operation]             [Freeze for review]│
├───────────────────────────────────────────────────────────────────────────────┤
│ OP 01 · 24 Sep · Set 06:15 · Haul 12:05 · Longline                         │
│ Reported catch                                                               │
│  Yellowfin tuna       Count 4   Weight 188 kg   Retained            [Edit]   │
│  Blue shark           Count 1   Weight —        Discarded alive     [Edit]   │
│ Reported protected-species interactions                                      │
│  None reported                                                   [Add event] │
└───────────────────────────────────────────────────────────────────────────────┘
```

`Freeze for review` creates the immutable version used by the analysis. Any subsequent correction uses `Create amendment`, records a reason, and creates a new version. Synthetic records carry a persistent `DEMO DATA` marker in the header, tables and exports.

Application navigation for the MVP is: **Trips → Reported Data → Video Review → Reconciliation → Review Result**.

### Video-review workbench

```text
┌ Catch Monitor · Trip CM-0007 · Authorised AFMA review ────────────────────────┐
│ Fishery [ETBF ▼]  Gear [Longline ▼]  Region [NSW coast ▼]  Source [cleared]  │
├───────────────────────────────┬──────────────────────────────────────────────┤
│ VIDEO + TIMELINE              │ REVIEW QUEUE                                 │
│ [video frame / evidence boxes]│ 12:14–12:32 Catch · Coral trout?    [Review] │
│                               │ 12:31–12:42 Wildlife · seabird      [Review] │
│ ───●─────●───────●────●──     │ 12:48–13:06 Interaction · turtle   [Review] │
│ Blue=catch Amber=possible     │ Filters: All · Needs review · Catch · Wildlife│
├───────────────────────────────┴──────────────────────────────────────────────┤
│ AI-assisted · reviewer confirmation required · 4 unresolved                   │
└──────────────────────────────────────────────────────────────────────────────┘
```

Selecting an event opens evidence, species candidates and traits, count/fate controls, interaction status, confidence explanation, source guidance, reviewer decision, and `Confirm`, `Correct`, `Merge`, `Not an interaction`, `Escalate`. Use colour plus text/icon; low-confidence items default to review rather than silent inclusion.

Every review card displays its complete evidence window as `MM:SS–MM:SS`, not just the first timestamp. The start is the earliest relevant hook-up or appearance used by the observation; the end is the last useful evidence frame or scene transition. These are evidence boundaries, not claims about exact capture, death, retention or release time.

The reconciliation page is an operation register with filters and three columns: **frozen reported information**, **video evidence**, and **AFMA reviewer finding/action**. Each row shows a comparison outcome and links back to both the source report version and supporting clip. A footer enables `Complete review` only when critical alerts have a reviewed state. A guidance drawer provides source, applicability, review date, current concession conditions and relevant logbook instructions.

## Data and technical design

Persist trip, versioned reported-data header, reported operation, reported catch line, reported interaction, media asset, media rights/purpose, media annotation, dataset manifest/split, source-video asset, frame/clip evidence, detected observation, reconciliation result, review decision, rule-source version, and generated result separately. Use CAAB `SPCODE` as the canonical taxonomic reference when resolved; retain the fisher-supplied text, AI candidate values and reviewed mapping independently without destroying original values. Catch Monitor tables shall reference the existing CAAB source layer rather than duplicate it. Keep imagery and footage in private object storage with short-lived authorised playback URLs.

Pipeline: record source/rights status and validate checksum/media quality; segment fishing activity; detect/track fish, gear, people, wildlife; classify using region/gear candidates; aggregate evidence-backed counts; require authorised officer review; reconcile against reported information; generate an internal review result and audit trail. Vision output must be structured and schema-validated. An LLM may explain evidence or retrieve approved reviewer guidance, never become the source of record for count or compliance status.

## Test-video acquisition plan

For this access-controlled internal demo, record the original source, creator and readily available licence/terms, then proceed using an appropriate rights status. Do not let unavailable or ambiguous licence detail stall the prototype: use `UNCONFIRMED_INTERNAL_ONLY`, keep the asset private, attribute it, and exclude it from public export and custom training. Stop only for an explicit prohibition, access-control bypass, confidential/private material without authority, a rights-holder objection, or unresolved privacy/security risk. Written permission becomes a gate before customer/public distribution or broader model-training reuse.

| Priority | Real video candidate | Initial use | Rights action |
| --- | --- | --- | --- |
| 1 | [AFMA Best Practice Bycatch Handling education video](https://www.youtube.com/watch?v=kY-bN9Wn1eI) — official AFMA, 5:58 | Wildlife/bycatch and training UX. | Record AFMA source; use internally while checking any readily available terms. Seek confirmation before external reuse/training. |
| 2 | [AFMA electronic monitoring on board AFMA managed vessels](https://www.youtube.com/watch?v=1jrKBK1JPZE) — official AFMA, 1:35 | Intake, camera-health and e-monitoring explanatory UI. | Record AFMA source; suitable as an internal explanatory sample, not a labelled catch-count dataset. |
| 3 | [Queensland Coral Trout Fishery](https://www.youtube.com/watch?v=IrbFHTr4G3Y) — Queensland reef line fishery, 5:55 | Fish/deck/line scenes and species-ID UX. | Record uploader/original source and use as internal-only if terms remain unclear; replace or seek confirmation before external reuse. |
| 4 | [Commercial hand net fishing in remote Australia](https://www.youtube.com/watch?v=S1orSxsFc24) — ABC Australia, Shark Bay WA, 2:46 | Net-haul timeline and Australian coastal operations. | Record ABC/source attribution; restrict to internal evaluation unless broader permission is confirmed. |
| 5 | [Raptis — The Australian Fishing Company](https://www.youtube.com/watch?v=LdVA9-2wWIM) — Australian commercial operations, 7:28 | Deck/processing scenes and count review. | Record Raptis/source attribution and restrict to internal evaluation unless broader permission is confirmed. |

These are source-traced internal UI-test leads, not a balanced validation dataset. A credible validation set needs controlled Australian coastal footage spanning fisheries, gear, seasons, lighting/weather, camera views, catch densities, and protected-species groups. Two qualified annotators should independently label taxon, unique-individual count, fate, time bounds, and interaction status; record adjudication. Broader publication of the dataset or its media remains a separate rights review.

## Quality gates

- A human reviewer, evidence link, and interaction-field checklist are mandatory before an item can be confirmed reportable.
- Wildlife presence alone never creates a confirmed interaction or “report to AFMA” message.
- Video review cannot begin without a selected `FROZEN_FOR_REVIEW` reported-data version; a deliberately empty “no report supplied” version is permitted and auditable.
- Reviewers cannot edit frozen reported data from the review or reconciliation pages; amendments create new versions and do not silently change completed comparisons.
- Every review result carries model/evidence/reviewer provenance and preserves the source-reported record unchanged.
- Every resolved catch or wildlife taxon in an output carries its reviewed CAAB `SPCODE`, scientific/common-name display snapshot and CAAB source-version provenance; unresolved taxa remain explicit.
- Existing CAAB Home, Agent and Reports functions pass regression checks after Catch Monitor is added, and CAAB catalogue reports remain semantically separate from video-derived catch counts.
- Every media asset has a source and rights status. `UNCONFIRMED_INTERNAL_ONLY` assets may support the access-controlled internal demo and internal evaluation, but are excluded from public/customer export and custom-training datasets until an explicit decision is recorded.
- `PROHIBITED` or `TAKEDOWN` assets, material obtained by bypassing access controls, and non-public footage lacking task/privacy authority are never used.
- Every priority demo taxon has a visible media-coverage status; missing visual coverage produces an explicit gap rather than an unlicensed substitute.
- Dataset manifests are reproducible from immutable asset checksums, CAAB mappings, annotation versions and split assignments, with trip/vessel/source leakage checks passing before evaluation.
- Unknown/higher-taxon and zero-count corrections are supported.
- Report precision/recall separately for detection, taxon ID, counting, and interaction classification; break results down by fishery/gear/region/species group.
- Establish performance targets only after a held-out, annotated, source-controlled Australian-coastal baseline; never invent demo accuracy claims.
- Privacy/security review must confirm task authority for non-public footage, private storage, access, retention/deletion and no audio before crew footage is loaded. Do not turn routine licence ambiguity for public source material into an MVP blocker.

## Review questions

1. Which AFMA reviewer roles may complete a review, view aggregate results, or access potentially compliance-relevant footage?
2. Which first fishery/gear drives vocabulary and test-set acquisition: ETBF longline, SESSF trawl/gillnet-hook-trap, or another Commonwealth fishery?
3. Which internal-demo assets, if any, are intended later for customer/public presentation or custom model training and therefore need formal rights confirmation?
4. Should the next deliverable be a clickable APEX reviewer mock-up with cleared sample clips, or the evidence/review data model?
