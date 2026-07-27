# CAAB AI Hub migration manifest

## Scope and boundary

This is a deterministic, source-side handoff for the **AFMA CAAB application**.
It authorizes no target call or write. ASHCROFT evidence is read-only; AIDEMODB
records below are expected values until the AI Hub master task reports its
control-plane API healthy.

The application boundary is deliberate:

- Repository and APEX workspace/schema: `AFMA`.
- APEX application: `101`, **AFMA CAAB AI Demo**, alias `AFMA-CAAB-AI-DEMO`.
- AIDEMODB AI Hub project: `caab` (not `afma`).
- Future target API identity/profile: `codex-caab` /
  `codex-caab-aidemodb.local.json`. This manifest never contains its value.

## Source evidence inventory

| Evidence | Source path | SHA-256 | Use |
|---|---|---|---|
| ASHCROFT project context snapshot | `.local/ashcroft-afma-project-context-20260727.json` | `5369eb3c23de4a982cbc5e1735d447be8f82ea6e416ff2d40fdf48ab3fead318` | Source project fields, lane counts and directives. |
| ASHCROFT Kanban snapshot | `.local/ashcroft-afma-tasks-20260727.json` | `ecdeffe63e18c6642db2d7bc19aee0424f0639030d702645cb1e0eaec86bbf30` | Fourteen cards and current versions/lanes. |
| ASHCROFT project-design query result | `.local/ashcroft-afma-design-specs-20260727.json` | `c34d53fc96bbd771705a53a973e623848f0a4c09c36e2df8b63dbf0ea391bff8` | Records the source client `403 grant_denied` for `design.read`; it is not evidence of no design documents. |
| Application definition | `exports/apex/afma/101/20260715-apexlang-standard-export/application.apx` | `99d5eb9954360715f303f6df39e1d72f18dfefdbfaabcc1a17d79cdb3b2a862c` | App name, alias, authentication and APEXlang checkpoint. |
| CAAB data profile | `.local/caab-profile.json` | Profiled source CSV hash `793afa2ac0252aca8147537bba667ea67f886ecce0df7388c182c6ffc91b5515` | 63,191 taxonomy rows and load characteristics. |

The source browser-export helper requires a CDP endpoint at `127.0.0.1:9333`.
On 2026-07-27 it returned `ECONNREFUSED`; therefore no newer ASHCROFT export
was captured. The dated APEXlang export above is provisional evidence. Its
tracked copy deliberately excludes `workspace-components/credentials/**` and
`workspace-components/generative-ai-services/**`; target prerequisites must be
provisioned separately.

## Field-by-field reconciliation

| Field | ASHCROFT source evidence | Expected AIDEMODB CAAB value | Transformation / verification |
|---|---|---|---|
| Project key | `afma` | `caab` | Deliberate application-project split; must not be literal equality. Assert `PROJECT_KEY='caab'` and no CAAB task is owned by `afma`. |
| Project name | `AFMA Demos` | `AFMA CAAB AI Demo` | Replace workspace/repository-oriented name with the application name. |
| Project status | `ACTIVE` | `ACTIVE` | Preserve. |
| Display sequence | Source snapshot has no confirmed display-sequence field | Master seed-controlled CAAB application position | Assign by target seed; verify it is present and unique, not inferred from source. |
| Summary | AFMA onboarding summary | CAAB application summary grounded in taxonomy, search, reporting and AI-agent capabilities | Deliberate rewrite to application scope. |
| Local folder | `C:\\Users\\pashcrof\\Documents\\Codex Projects\\AFMA Demos` | Same | Preserve repository ownership. |
| GitHub owner/repository/URL | `paulashcroft-oracle` / `afma-demos` / `https://github.com/paulashcroft-oracle/afma-demos` | Same | Preserve; account context `Paul Ashcroft Oracle GitHub`, status `ACTIVE`. |
| Migration target | `AIDEMODB` | `AIDEMODB` | Preserve. |
| Public-domain target | `ashcroftcloud.com` | `ashcroftcloud.com` where a CAAB route is approved | Preserve target domain; do not carry ASHCROFT session or feedback endpoints. |
| APEX workspace/schema | `AFMA` / `AFMA` | `AFMA` / `AFMA` | Preserve: app remains in its existing target workspace. |
| Application ID/name/alias | Source context stale; APEXlang/runbook prove `101` / `AFMA CAAB AI Demo` / `AFMA-CAAB-AI-DEMO` | Same | Correct the stale source project record during target creation. |
| Runtime URL | Source project record says pending; runbook records AIDEMODB runtime `/ords/r/afma/afma-caab-ai-demo/home` | Same runtime URL | Deliberate correction from stale ASHCROFT metadata to confirmed AIDEMODB app route. |
| Builder URL | Source project record says pending; runbook records app-builder URL with `fb_flow_id=101` | Same builder location, without a reusable `session=` value | Deliberate correction; verify URL pattern only. |
| Notes | AFMA workspace bootstrapping notes, stale "app pending" statement | CAAB-specific provenance, app 101 source checkpoint, target API activation prerequisite and data-load notes | Do not copy stale status or raw endpoints/keys. |
| System-design linkage | Project-scoped source design query is denied by the captured AFMA key | Link/import only designs returned by the target `caab` discovery/bootstrap and applicable AI Hub design APIs | Deliberate deferred linkage; source response is an authorization limitation, not a negative assertion. |

## Kanban migration inventory

The source snapshot contains **14** cards: `DESIGN=1`, `TEST=10`,
`COMPLETE=2`, `BLOCKED=1`. Preserve source task keys in a migration reference
field; create target cards with deterministic idempotency key
`caab:migration:<source-task-key>:v<source-version>`. A rerun must update the
same target card rather than create a duplicate. Preserve lane/status only when
the target workflow permits it; retain the source lane and reason in the task
details when target policy requires a review handoff.

| Source key | Version | Lane | Title | Best captured full bundle |
|---|---:|---|---|---|
| `afma-001` | 4 | TEST | Load CSIRO CAAB taxonomy data into AFMA schema | `.local/afma-001-bundle-refresh.json` |
| `afma-002` | 2 | TEST | Create AFMA CAAB demo APEX app shell and home page | `.local/afma-002-bundle-refresh.json` |
| `afma-003` | 2 | TEST | Add CAAB AI Agent exploration page | `.local/afma-003-bundle-refresh.json` |
| `afma-004` | 1 | DESIGN | Add CAAB source refresh component shell | `.local/afma-004-bundle-after-012.json` |
| `afma-005` | 2 | TEST | Verify, export, and document AFMA CAAB demo | `.local/afma-005-bundle.json` |
| `afma-006` | 3 | TEST | Fishes Common Names | `.local/afma-006-bundle.json` |
| `afma-007` | 2 | TEST | Allow passwordless demo user access to AFMA CAAB app | `.local/afma-007-bundle.json` |
| `afma-008` | 2 | TEST | Add visual CAAB reports page to AFMA demo app | `.local/afma-008-bundle.json` |
| `afma-009` | 2 | TEST | Enable AI Hub feedback model for AFMA demo app | `.local/afma-009-bundle-after-move.json` |
| `afma-010` | 2 | TEST | Wire CAAB Agent page to live APEX AI responses | `.local/afma-010-bundle-refresh.json` |
| `afma-011` | 2 | COMPLETE | Design rich AI response contract for CAAB Agent visuals | `.local/afma-011-bundle-after-012.json` |
| `afma-012` | 2 | TEST | Fix CAAB Agent responsive chat layout and Mermaid stretch rendering | `.local/afma-012-bundle-refresh.json` |
| `afma-013` | 6 | COMPLETE | Add AFMA ashcroftcloud DNS and path shortcut | Card snapshot only; no local full-bundle capture. |
| `afma-014` | 2 | BLOCKED | Add CAAB Agent feedback submission | Card snapshot only; no local full-bundle capture. |

Captured bundles include current/previous version, latest diff, task thread,
artifacts and approvals where present. The captured cards report no attached
artifact, approval, or source-feedback records. Do not infer that the original
service has none beyond this capture; retrieve target-side references only after
the control plane is available.

## System and application inventory

- APEX pages: `1` Home, `2` CSIRO CAAB Agent, `3` Reports, `9999` Login,
  `10030` Feedback, `10031` Feedback submitted.
- Canonical database/data scripts: `010`, `020`, `025`, `030`, `040`, `045`,
  `085`, `086` under `database/`.
- Data acceptance values: `CSIRO_CAAB_TAXA=63191`, active taxa `51213`,
  `CSIRO_CAAB_COMMON_NAMES=10376`, `CSIRO_CAAB_FISHING_REGIONS=17`.
- Application metadata - including AI agents, login/feedback UI, navigation and
  static files - comes from the APEXlang checkpoint. Secrets and workspace GenAI
  service definitions are provisioned only in the target workspace.

## Target activation and deterministic verification

Do not execute these checks until the AI Hub master task confirms AIDEMODB API
discovery, `caab` bootstrap and triage return HTTP `200`.

1. `GET /api-catalog` returns `200` using only
   `codex-caab-aidemodb.local.json`; its base URL must be AIDEMODB.
2. `GET /projects/caab/codex-bootstrap` returns `200` and identifies
   `caab`/`codex-caab`, not `afma`/`codex-afma`.
3. `POST /projects/caab/task-triage` with model use disabled returns `200`.
4. Target SQL/API inspection proves exactly one `HUB_PROJECTS` row for `caab`,
   `ACTIVE` status, configured display sequence, correct Git/APEX fields, and
   a `codex-caab` client with normalized Deep-Sec grants. The superseded
   `codex-afma` client must not be active for this application project.
5. Reconcile all 14 source keys against target migration references and the
   idempotency keys above; assert 14 target cards, zero duplicate source-key
   references, and the expected lane counts after any policy-required handoff.
6. Retrieve target task bundles and compare version/thread/artifact/approval/
   source-feedback references against this captured evidence; record missing
   source bundles for `afma-013` and `afma-014` explicitly.
7. Run target design discovery and attach/create CAAB-relevant System Designs
   through the design mutation API; record returned document keys and versions.

Target readiness is intentionally **not claimed** by this document.
