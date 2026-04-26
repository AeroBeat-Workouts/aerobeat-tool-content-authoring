# AeroBeat Content Authoring Tool Definition

**Date:** 2026-04-25  
**Status:** Proposed definition  
**Repo:** `aerobeat-tool-content-authoring`

---

## Goal

Make the day-one job of `aerobeat-tool-content-authoring` explicit now that the v1 workout package contract is locked.

This document defines:

- what this repo owns
- what it explicitly does not own
- the minimum day-one creator workflows
- the required CLI / shared-service / editor split
- the concrete contract between this tool, the demo package, and `aerobeat-content-core`

---

## 1. Product stance

`aerobeat-tool-content-authoring` is **the package authoring and package-operations tool for canonical AeroBeat content**.

It is not the source of truth for content meaning. It is the source of truth for **how creators and automation safely work with that content**.

In plain terms:

- `aerobeat-content-core` defines what a valid `Song`, `Routine`, `Chart`, `Workout`, `Coach Config`, `Environment`, and `Asset` record means.
- `aerobeat-tool-content-authoring` defines how a creator or CI job can create, inspect, validate, scaffold, migrate, package, and normalize a workout package that uses those records.

If `content-core` is the language, this repo is the authoring toolbox.

---

## 2. Crisp responsibility boundary

### This repo owns

`aerobeat-tool-content-authoring` owns **workflow orchestration over authored workout packages**.

That includes:

1. **Package scaffolding**
   - create a new package folder from the locked v1 shape
   - create starter YAML records with required shared fields
   - create domain folders in the canonical package layout

2. **Record authoring helpers**
   - create/add/update package records through explicit tool operations
   - help creators add songs, routines, charts, environments, assets, and coach config entries
   - keep package manifests and cross-file references coherent when the user chooses a tool-driven operation

3. **Validation orchestration**
   - run shared structural validation from `aerobeat-content-core`
   - run tool-layer package checks such as missing files, bad paths, duplicate ids, illegal asset selections, and submission-cleanliness rules
   - produce human-usable reports for CLI, editor, and CI

4. **Inspection and reporting**
   - print package summaries, dependency/reference summaries, and validation summaries
   - surface what records exist and how they connect
   - explain invalid states instead of just failing generically

5. **Migration workflows**
   - detect schema/tool-version mismatches
   - preview explicit migrations
   - apply deliberate migrations with reports
   - preserve traceability of what changed

6. **Packaging and submission preparation**
   - build a canonical export/submission payload from authored package contents
   - strip or ignore disposable runtime artifacts such as `cache/`
   - verify that the package is self-contained for v1 rules

7. **Import/export adapters**
   - translate approved external sources into canonical package records
   - export canonical content into approved interchange/report forms
   - keep adapters outside the durable schema definitions

8. **Shared services for multiple surfaces**
   - expose the same package operations to CLI, editor UI, and future automation surfaces

### This repo does not own

1. **Canonical record/schema definitions**
   - not `Song`, `Routine`, `Chart`, `Workout`, `Coach Config`, `Environment`, `Asset` field ownership
   - not schema ids/versions
   - not the shared chart envelope contract
   - those live in `aerobeat-content-core`

2. **Mode-specific gameplay semantics**
   - not boxing event legality
   - not scoring rules
   - not hit windows
   - not runtime visual interpretation
   - those live in feature repos plus shared feature/runtime layers

3. **Install/discovery persistence as a product concern**
   - this repo may build or refresh local indexes as a workflow step
   - it does not own the long-term installed-library runtime/catalog system contract

4. **Remote distribution/catalog/service behavior**
   - not publication systems
   - not remote moderation state
   - not download hosting
   - not entitlement, trust, or signatures
   - those belong to future service/distribution layers

5. **Silent repair of authored content**
   - this repo may detect, suggest, preview, and apply requested changes
   - it must not quietly rewrite creator-authored meaning behind their back

---

## 3. Repo split by layer

### `aerobeat-content-core`

Owns:

- durable content contracts
- schema ids and versioning rules
- shared structural validation contracts
- canonical migration interfaces/results
- reference integrity rules

### `aerobeat-tool-content-authoring`

Owns:

- package-scaffold workflows
- record-creation/editing helpers
- package validation execution and reporting
- migrations as user-facing operations
- package export/submission prep
- inspection/reporting UX

### feature repos / feature core

Own:

- mode payload legality beyond shared structure
- runtime scoring and interpretation
- concrete visuals, spawning, and presentation
- mode-specific compatibility behavior

### future service/distribution layers

Own:

- remote catalog metadata
- upload/review/publication flows
- moderation state
- signing/integrity/trust policy
- remote leaderboard authority

---

## 4. Day-one creator workflows

The honest day-one scope should stay tight and package-centric.

### Must-have day-one workflows

### A. Scaffold a new workout package

Goal:

- create a valid starter package matching the locked v1 folder shape

Minimum output:

- `workout.yaml`
- `songs/`, `routines/`, `charts/`, `coaches/`, `environments/`, `assets/`, `media/`
- one coach config file
- starter metadata fields (`schemaId`, `schemaVersion`, `recordVersion`, `createdByTool`, timestamps)

### B. Inspect a package

Goal:

- answer “what is in this package?” quickly

Minimum output:

- package summary
- counts by domain
- record ids and names
- cross-reference summary
- unresolved references / warnings

### C. Validate a package

Goal:

- prove whether a package is structurally valid and submission-clean

Minimum checks:

- required folders/files exist
- YAML parses
- ids are unique
- references resolve
- exactly one coach-config exists
- `assetSelections` only use allowed entry-selectable asset types
- coach avatar/voice assets are referenced only through coach config
- package-local media paths exist when required
- `cache/` is ignored or flagged appropriately for export/submission

### D. Add or scaffold individual records

Goal:

- help creators add canonical record files without hand-writing every boilerplate field

Day-one record actions:

- add song
- add routine for a song/mode
- add chart for a routine
- add environment
- add asset
- add coach overlay / coach support asset references
- add workout session entry referencing exact ids

Important limit:

- this is not a rich chart editor yet
- day one should create/edit the record shell and small explicit fields safely, not promise a full choreography authoring UX

### E. Prepare a package for export/submission

Goal:

- produce a canonical package payload suitable for transfer/review

Minimum behavior:

- validate before build
- omit/strip disposable cache artifacts
- ensure package-local references remain self-contained
- generate a clear report of what was included/excluded

### F. Preview/apply migrations

Goal:

- move older package records forward explicitly

Minimum behavior:

- detect old schema/tool versions
- preview changes before writing
- write migration reports

### Not day-one

- full visual chart editing UX
- waveform/timeline choreography tooling
- live scene preview/editor integration beyond thin scaffolding
- remote publishing workflows
- online catalog sync
- installer/storefront UX
- collaborative multi-user editing
- signature/trust workflows
- automatic mode-specific correctness beyond what shared/feature validators can actually prove

---

## 5. Required surfaces: CLI vs shared services vs editor

### Shared service layer = required and authoritative

The service layer is the actual product core.

It should expose operations like:

- scaffold package
- inspect package
- validate package
- add/update record
- add/update workout entry
- prepare export/submission payload
- preview/apply migration

Rules:

- services return structured results, not UI strings only
- services are usable from CLI, editor, tests, and CI
- services may call into `aerobeat-content-core` validators/migrators, but do not redefine them

### CLI = required on day one

The CLI is the first-class day-one surface because it unlocks:

- CI validation
- fixture generation
- automation
- deterministic repro steps
- low-cost early product usage before building rich UI

Minimum day-one command families:

- `scaffold`
- `inspect`
- `validate`
- `add-record` / targeted add commands
- `add-entry`
- `migrate`
- `build-package`

The CLI should stay thin and route into services.

### Editor/UI = optional day-one scaffold only

An editor surface is justified only as a thin layer over the same services.

Day-one editor scope, if any:

- package open/browse shell
- validation results panel
- simple forms for metadata and record scaffolding
- package summary inspector

It is intentionally **not** a promise of a full immersive authoring suite on day one.

---

## 6. Contract against the demo package and content core

The demo package is not just docs wallpaper. It should act as the **teaching fixture and behavioral baseline** for this repo.

### The tool must read

From package contents:

- `workout.yaml`
- all domain YAML files under `songs/`, `routines/`, `charts/`, `coaches/`, `environments/`, `assets/`
- package-local media/resource paths when validating or exporting
- optional `cache/` only for ignore/strip/report behavior, not as authored truth

From `aerobeat-content-core`:

- canonical record contracts
- shared validators for structure/reference legality where they exist
- schema identifiers/version compatibility rules
- migration interfaces/result contracts

### The tool may write

Only through explicit workflow actions:

- new scaffolded package files/folders
- new or updated canonical YAML records
- derived export/submission payloads
- human-readable validation/migration reports
- optional refreshed local index artifacts when the chosen workflow explicitly asks for them

### The tool validates

1. **Package shape**
   - required files/folders
   - exactly one `workout.yaml`
   - exactly one coach-config YAML under `coaches/`

2. **Record coherence**
   - ids exist and are unique
   - `workout.yaml` references resolve to package records
   - chart -> routine -> song links are coherent
   - environment and asset ids resolve correctly

3. **Locked v1 package rules**
   - entry-selectable asset types are only `gloves`, `targets`, `obstacles`, `trails`
   - `coach_avatar` and `coach_voice` are only used via coach config
   - each session entry has exactly one environment
   - at most one asset per asset type per entry
   - unknown asset types fail validation

4. **Submission cleanliness**
   - `cache/` is omitted/ignored for submission payloads
   - no authored package depends on non-package-local files for v1 self-contained validation

### The tool scaffolds

Day one should scaffold:

- package root and domain folders
- package metadata boilerplate
- starter `workout.yaml`
- starter `coach-config.yaml`
- starter song/routine/chart/environment/asset records
- entry stubs wired to exact ids

The scaffold should aim for **valid boring correctness**, not maximal convenience magic.

### The tool migrates

The tool is the user-facing place to:

- detect outdated schema/tool versions
- preview migration changes
- apply migrations intentionally
- emit migration reports

But the migration rules themselves should come from shared contracts/interfaces, not be invented ad hoc inside CLI code.

### The tool must not silently mutate

This is the most important contract line.

The tool must not silently:

- rename ids
- move authored records between domains
- rewrite chart events for style reasons
- change `assetType` values
- reassign workout references to “closest match” ids
- strip authored optional metadata because it looks unused
- upgrade schema versions without an explicit migration path/report
- remove cache files from the working package folder unless the user requested a build/export/clean operation that declares that behavior

Allowed behavior:

- fail
- warn
- suggest
- preview
- apply explicit user-requested fixes

Not allowed behavior:

- hidden semantic rewrites

---

## 7. Recommended implementation guardrails

To keep this repo from becoming a junk drawer:

1. **Package-first, not platform-first**
   - if a feature does not directly help create, inspect, validate, migrate, or package canonical workout packages, question why it is here

2. **Service-first, not UI-first**
   - no editor-only business logic

3. **Shared-contract-first, not duplicate-schema-first**
   - prefer consuming `aerobeat-content-core` contracts over cloning them

4. **Explicit writes only**
   - read/inspect freely, write only through named operations

5. **Reports are product surface**
   - validation/migration output quality matters as much as raw pass/fail

6. **Demo package stays a fixture**
   - new workflows should prove themselves against the docs demo package

---

## 8. Proposed day-one command map

Examples only; naming can still change.

- `aerobeat-content scaffold package <path> --workout-id ...`
- `aerobeat-content inspect package <path>`
- `aerobeat-content validate package <path>`
- `aerobeat-content add song <package-path> ...`
- `aerobeat-content add routine <package-path> ...`
- `aerobeat-content add chart <package-path> ...`
- `aerobeat-content add environment <package-path> ...`
- `aerobeat-content add asset <package-path> ...`
- `aerobeat-content add session-entry <package-path> ...`
- `aerobeat-content migrate package <path> --preview`
- `aerobeat-content build package <path> --out <artifact>`

The key point is not exact syntax. The key point is that the command set stays aligned to the package contract rather than drifting into random utility behavior.

---

## 9. Open decisions before implementation planning

1. Should day-one authoring edits be limited to scaffold/add/update metadata flows, or should small safe in-place edit commands be considered first-slice scope too?
2. Should local installed-index refresh live in this repo on day one, or wait until a separate install/library tool owns it?
3. What exact output artifact should `build package` produce first: folder normalization only, zip/tarball, or both?
4. Should importers be completely deferred until after scaffold/inspect/validate/build are solid?
5. How much editor shell is worth keeping in the first slice if CLI plus services already deliver the core value?

---

## 10. Bottom line

Day one, `aerobeat-tool-content-authoring` should be a **headless-first package authoring and validation toolchain**.

Its first honest job is to make the locked AeroBeat package contract:

- easy to scaffold
- easy to inspect
- safe to validate
- explicit to migrate
- predictable to export

It should not try to become the runtime, the schema authority, the online service layer, or a giant everything-tool.
