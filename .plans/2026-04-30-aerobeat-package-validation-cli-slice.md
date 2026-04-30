# AeroBeat Package Validation CLI Slice

**Date:** 2026-04-30  
**Status:** In Progress  
**Agent:** Chip 🐱‍💻

---

## Goal

Implement the first real package-validation slice in `aerobeat-tool-content-authoring` so the authoring repo, not the docs repo, can validate the current AeroBeat workout package artifacts and expose that validation through small CLI entrypoints for package YAML/SQL surfaces plus a full-package validation command.

---

## Overview

Derrick locked an important boundary just now: the right home for workout-package validation is `aerobeat-tool-content-authoring`, not `aerobeat-docs`. The docs repo should only explain the package shape and point creators at the validation tool. That lines up with the already-written tool-definition doc in this repo, which says this tool owns package-validation orchestration and human-usable reports while `aerobeat-content-core` owns canonical record meaning. Source: `memory/2026-04-25.md#L28-L49`

The immediate target is practical, not theoretical: make the authoring repo able to validate the **current** demo workout package contents using its YAML records and SQL schema artifacts. The current example package in `aerobeat-docs` includes `workout.yaml`, domain YAML folders (`songs/`, `charts/`, `sets/`, `coaches/`, `environments/`, `assets/`), media references, and SQL schema files under `sql/` such as `workouts.db.schema.sql` and `leaderboard-cache.db.schema.sql`. There does not appear to be a checked-in live `workouts.db` file in the docs example today, so this slice should validate the actual shipped SQL/YAML artifacts first and define a clean path for validating a concrete SQLite DB file when one is part of the package/install flow.

Derrick also suggested a concrete CLI shape: a tiny validator command per YAML/SQL artifact family, plus a whole-package validator that runs all relevant checks together. That means this slice should not just add one monolithic validator buried in code. It should define a small stable command surface such as root-package validation, record-family validators, schema-SQL validation, and a top-level full-package pass wired through shared services. Because environment and asset YAML contracts are not intentionally designed yet, this slice should be honest about scope: validate their current structural presence/parse/reference behavior for now, but avoid pretending their deeper field-level contract is fully locked if it is not.

This slice belongs in `aerobeat-tool-content-authoring`, with a narrow docs follow-up in `aerobeat-docs` so the docs can mention and link to the tool instead of implying docs-local validation. The implementation should prove itself against the current demo package in `aerobeat-docs` and should leave a clean path for later environment/asset-contract deepening.

---

## REFERENCES

| ID | Description | Path |
| --- | --- | --- |
| `REF-01` | Authoring tool definition / ownership boundary | `projects/aerobeat/aerobeat-tool-content-authoring/docs/content-authoring-tool-definition.md` |
| `REF-02` | Existing authoring-tool responsibilities plan | `projects/aerobeat/aerobeat-tool-content-authoring/.plans/2026-04-25-aerobeat-tool-content-authoring-responsibilities.md` |
| `REF-03` | Demo workout package root record | `projects/aerobeat/aerobeat-docs/docs/examples/workout-packages/demo-neon-boxing-bootcamp/workout.yaml` |
| `REF-04` | Demo workout package example folder | `projects/aerobeat/aerobeat-docs/docs/examples/workout-packages/demo-neon-boxing-bootcamp/` |
| `REF-05` | Workout package/storage docs that should point at the tool | `projects/aerobeat/aerobeat-docs/docs/architecture/workout-package-storage-and-discovery.md` |
| `REF-06` | Demo workout package guide that should mention the validator | `projects/aerobeat/aerobeat-docs/docs/guides/demo_workout_package.md` |
| `REF-07` | Existing validation command test surface | `projects/aerobeat/aerobeat-tool-content-authoring/tests/test_validate_command.gd` |
| `REF-08` | Existing CLI entrypoint | `projects/aerobeat/aerobeat-tool-content-authoring/cli/main.gd` |
| `REF-09` | Current chart validation service lineage | `projects/aerobeat/aerobeat-tool-content-authoring/services/validation/validate_chart_service.gd` |

---

## Tasks

### Task 1: Reconstruct the current validation surface and package-artifact scope

**Bead ID:** `aerobeat-tool-content-authoring-2mb`  
**SubAgent:** `primary` (for `research`)  
**Role:** `research`  
**References:** `REF-01`, `REF-03`, `REF-04`, `REF-07`, `REF-08`, `REF-09`  
**Prompt:** Inspect the current authoring repo validation/CLI surfaces plus the current demo workout package contents. Document what validators/commands already exist, which YAML/SQL artifacts are actually shipped today, what can already be reused, and what exact validation scope is honest for this first package-validation slice.

**Folders Created/Deleted/Modified:**
- `.plans/`
- repo docs only if a separate note is truly justified

**Files Created/Deleted/Modified:**
- this plan file unless a separate note is justified

**Status:** ✅ Complete

**Results:** Reconstructed the current validation surface and the real first-slice artifact scope. Concrete findings: (1) the current authoring-repo `validate` CLI is already wired through `cli/main.gd` → `cli/commands/validate_command.gd` → `services/validation/validate_package_service.gd`, but it validates a legacy **JSON-manifest package shape**, not the current docs-package YAML shape; it expects `manifest.json` plus JSON records in `songs/`, `routines/`, `charts/`, and `workouts/`. (2) The reusable validation code today is narrow but real: `ValidatePackageService` already provides structured report output, duplicate-id checks, required-field checks, cross-record reference checks, and song-timing validation; `ValidateChartService` already provides reusable feature/difficulty/interaction-family checks; `tests/test_validate_command.gd`, `tests/test_validate_song_timing_contract.gd`, and `tests/run_tool_tests.gd` provide the existing validation test/report harness. (3) Packaging/build flow is also reusable in shape but not in contract: `services/packaging/build_content_package_service.gd` already enforces “validate before build,” yet it currently copies manifest-listed JSON files only. (4) The current demo package in `aerobeat-docs` ships these authored artifacts today: root `workout.yaml`; YAML records under `songs/`, `charts/`, `sets/`, `coaches/`, `environments/`, and `assets/`; package-local media files referenced by those YAML records; and two checked-in SQL schema documents under `sql/` (`workouts.db.schema.sql`, `leaderboard-cache.db.schema.sql`). (5) There is **no checked-in live SQLite database file** in the demo package right now—only `.schema.sql` files—so the honest first slice is SQL-schema-file validation, not runtime `.db` validation. (6) The docs-package contract has shifted from the old routine/workout JSON model to a set-centered YAML model: `workout.yaml` owns package metadata and `setOrder`; each set links `songId` + `chartId` + `environmentId` + optional `coachingOverlayId` + `assetSelections`; `coaches/coach-config.yaml` is the package-level coaching record; environments/assets are present as authored YAML but their deep semantic contracts are not yet implemented in this repo. Rationale for implementation scope: the first package-validation slice should stay honest and validate only what is actually durable and shipped now—YAML parse/load success, required package files/folders, exactly one `workout.yaml`, exactly one `coaches/coach-config.yaml`, uniqueness of ids across current YAML families, set/workout/coaching/environment/asset reference resolution, required package-local media/resource path existence, allowed `assetSelections` keys, and parse/basic sanity of checked-in `.schema.sql` artifacts. It should explicitly defer deeper SQLite file validation, install/runtime catalog behavior, and richer environment/asset semantic rules until those artifacts/contracts are intentionally introduced.

---

### Task 2: Design the validation command map and shared-service boundary

**Bead ID:** `aerobeat-tool-content-authoring-1ot`  
**SubAgent:** `primary` (for `research`)  
**Role:** `research`  
**References:** `REF-01`, `REF-02`, `REF-07`, `REF-08`, `REF-09`  
**Prompt:** Design the first-pass validation command surface for `aerobeat-tool-content-authoring`. Include tiny validator entrypoints per current YAML/SQL artifact family where justified, plus a full-package validator. Make the shared-service versus CLI boundary explicit, and decide how partial validation results/reporting should look.

**Folders Created/Deleted/Modified:**
- `.plans/`
- maybe repo docs if needed

**Files Created/Deleted/Modified:**
- this plan file unless a separate note is justified

**Status:** ✅ Complete

**Results:** Recommended first-pass validation command map: keep the existing top-level `validate` family, but make it honest and package-contract aligned instead of adding a broad pile of unrelated commands. The small CLI surface should be: (1) `validate package <package_dir>` as the default full-package pass; (2) `validate workout <package_dir>` for root `workout.yaml` + package-shape checks; (3) `validate songs <package_dir>`; (4) `validate charts <package_dir>`; (5) `validate sets <package_dir>`; (6) `validate coaches <package_dir>`; (7) `validate environments <package_dir>`; (8) `validate assets <package_dir>`; and (9) `validate sql <package_dir>` for checked-in `sql/*.schema.sql` artifacts. Rationale: this stays small, mirrors the actual current artifact families, and gives creators/CI a way to isolate failures without pretending the tool already has a richer editor-grade semantic model. To keep the surface honest, do **not** add validators for live `.db` files, install catalogs, cache folders, or invented subdomains yet. Also do not split charts by feature into separate CLI commands in this slice; feature-specific legality should remain internal reuse inside the shared chart validator unless an actual user workflow demands otherwise.

Recommended CLI syntax/behavior: `validate <subject> <package_dir> [--json]`, with `package` as the default when the subject is omitted for backward-friendly ergonomics (`validate <package_dir>` can continue to mean full-package validation). Each subject command is a thin wrapper that resolves package-relative file groups, calls one shared service entrypoint, and renders either plain text or JSON. The full-package command should orchestrate the subject validators in a fixed order: package/workout root → songs → charts → sets → coaches → environments → assets → sql, then append cross-family package-level reference/media/path checks after the per-family structural passes. Order matters because later cross-reference errors are easier to understand when early parse/shape failures are already present in the report.

Recommended shared-service boundary: move the real logic into a new package-contract-oriented validation layer under `services/validation/`, with the CLI only responsible for argument parsing and output formatting. The service side should expose one orchestrator plus small family validators: e.g. `ValidateWorkoutPackageService` (full package orchestration), `ValidateWorkoutRootService`, `ValidateSongsService`, `ValidateChartsService`, `ValidateSetsService`, `ValidateCoachConfigService`, `ValidateEnvironmentsService`, `ValidateAssetsService`, and `ValidateSqlSchemaFilesService`. Supporting helpers should be shared, not duplicated in commands: package file discovery, YAML loading, issue construction, result aggregation, id indexing, reference resolution, and package-local path checks. The existing `ValidateChartService` should be retained and adapted as the chart-family validator core because its feature/difficulty checks already reflect durable chart semantics; its current legacy JSON assumptions should be stripped away, and the new chart-family service should layer package-file loading plus any light YAML-shape checks around it. The old manifest/JSON `ValidatePackageService` should either be replaced outright or clearly renamed to legacy-only code if it must temporarily coexist; the new package validator should not be forced through `manifest.json` terminology.

Recommended first-slice validation scope per family: `workout` validates exactly one root `workout.yaml`, required root fields, parse success, and root-owned references such as `coachConfigId`, `preview.coverArtPath`, and `setOrder`; `songs` validates YAML parse/load, required ids/names, reusable song timing shape, `audio.filePath` existence, and duplicate song ids; `charts` validates YAML parse/load, required ids/names, feature/difficulty legality via the shared chart validator, and duplicate chart ids, while deferring deep beat-grammar validation beyond what current shared logic can honestly prove; `sets` validates parse/load, required ids and the exact composition links (`songId`, `chartId`, `environmentId`, optional `coachingOverlayId`, `assetSelections`), allowed `assetSelections` keys, and duplicate set ids; `coaches` validates exactly one `coaches/coach-config.yaml`, disabled-vs-enabled shape, roster/overlay/warmup/cooldown requirements when enabled, uniqueness of `overlayId`, and package-local media path existence; `environments` validates parse/load, required ids/names, `scenePath` existence, and duplicate environment ids; `assets` validates parse/load, required ids/names/types, allowed asset type enum (`gloves`, `targets`, `obstacles`, `trails`), `resourcePath` existence, and duplicate asset ids; `sql` validates that expected `.schema.sql` files exist when present, are readable, are non-empty, and are minimally sane as SQL schema documents (for this slice: file presence, extension/name convention, basic statement presence such as `CREATE TABLE` / `CREATE INDEX`, and no live SQLite-open requirement). Cross-family full-package validation then resolves the actual contract joins: `setOrder` ids → set files, set `songId/chartId/environmentId/coachingOverlayId/assetSelections` → matching records, `workout.coachConfigId` → the single coach config id, and chart-to-song coherence where the chart contract exposes song linkage later. Because current YAML charts do not yet clearly embed `songId`, the full-package rule should validate the set as the single linker and avoid inventing redundant chart→song invariants unless the YAML contract truly adds them.

Recommended reporting shape: keep the current structured-report pattern, but make it package-family aware and aggregation-friendly. Every service should return `{ ok, valid, subject, packageDir, issueCount, warningCount, issues, warnings, counts, artifacts }`, and the full-package validator should additionally return `sections` keyed by family (`workout`, `songs`, `charts`, `sets`, `coaches`, `environments`, `assets`, `sql`, `package`). Each issue should stay machine-usable: `{ code, severity, message, path, subject, recordId?, field?, reference? }`. `counts` should include discovered file counts per family and maybe duplicate/parsed totals where easy. `artifacts` should summarize what was inspected, such as root paths and schema file paths. Partial results behavior: family validators must report their own issues even when sibling families fail, and the full-package orchestrator should continue collecting independent families after one family errors, only skipping downstream checks that require missing/invalid prerequisites. Example: if `songs/` has a parse failure, still validate `charts/`, `sets/`, and `sql/`, but cross-package checks that need indexed song ids should emit a clear prerequisite-style issue or skip note instead of crashing. This gives creators a single useful report rather than a fail-fast whack-a-mole loop.

Recommended implementation scope for Task 3: implement the new YAML/SQL package-validation stack entirely in `aerobeat-tool-content-authoring`, keep the CLI wrappers thin, preserve `--json`, and add fixture-style tests that target the current demo package plus a few repo-local invalid-package fixtures for specific failure modes. Task 3 should include: package file discovery helpers; YAML loading utilities; family validators for workout/songs/charts/sets/coaches/environments/assets/sql; one full-package orchestrator; a refreshed `validate` CLI command/parser that supports `validate <package_dir>` and `validate <subject> <package_dir>`; plain-text + JSON formatter updates for sectioned reports; tests covering full-package success on the docs demo package, bad/missing `workout.yaml`, duplicate ids, bad set references, invalid coaching config/path coverage, invalid asset-selection keys, and SQL schema-file sanity failures. Task 3 should explicitly defer live SQLite DB validation, build/export contract rewiring, and deeper environment/asset/chart semantic legality beyond the currently locked structural/reference rules. That keeps this slice small, honest, and aligned with `REF-01` / `REF-02`.

---

### Task 3: Implement package-validation services, CLI entrypoints, and tests in `aerobeat-tool-content-authoring`

**Bead ID:** `aerobeat-tool-content-authoring-83n`  
**SubAgent:** `primary` (for `coder`)  
**Role:** `coder`  
**References:** `REF-01` through `REF-09`  
**Prompt:** Implement the approved first-pass package-validation slice in `aerobeat-tool-content-authoring`. Add shared validation services and thin CLI commands for the current YAML/SQL artifact families plus a full-package validator, then add/update tests so the current demo package in `aerobeat-docs` validates successfully. Keep environment/assets validation honest to currently locked structural/reference rules rather than inventing deeper contracts.

**Folders Created/Deleted/Modified:**
- `cli/`
- `services/validation/`
- `tests/`
- repo docs/README only if necessary

**Files Created/Deleted/Modified:**
- implementation scope only

**Status:** ✅ Complete

**Results:** Implemented the first-pass YAML/SQL package-validation slice in `aerobeat-tool-content-authoring` and proved it against the current demo package in `aerobeat-docs`. Files changed for this task: `cli/commands/validate_command.gd`, `cli/formatters/plain_text_output.gd`, `services/validation/validate_package_service.gd`, `services/validation/validate_chart_service.gd`, `services/packaging/build_content_package_service.gd`, `services/authoring/chart_authoring_service.gd`, `tests/run_tool_tests.gd`, `tests/test_validate_command.gd`, `tests/test_build_content_package_service.gd`, `tests/test_validate_song_timing_contract.gd`, `tests/test_validate_package_failure_modes.gd`, `tests/test_support.gd`, `tests/test_chart_authoring_service.gd`, and `tests/test_author_command.gd`. Validation/tests run: `godot --headless --path .testbed --script ../tests/run_tool_tests.gd` (pass). Implementation details: replaced the legacy manifest-driven package validator with a current package-root/workout-family YAML validator that covers `workout.yaml`, songs/charts/sets/coaches/environments/assets YAML families, package-local media/resource references, SQL schema-file sanity checks, and set-centered cross-record reference resolution; updated the CLI to support the approved `validate <package_dir>` / `validate <subject> <package_dir>` command map with machine-friendly sectioned reports; updated build-package coverage to validate/copy the actual current package shape; added failure-mode tests for duplicate ids, missing set references, bad coaching paths, invalid asset-selection keys, and SQL schema failures; and made legacy manifest-based chart-authoring fixtures explicitly skip the new YAML package-validation gate instead of falsely pretending they are current package-model validations. Commit hash: `3e5939b` (`Implement YAML package validation CLI slice`).

---

### Task 4: Update `aerobeat-docs` to point to the authoring validator, then QA and audit the full slice

**Bead ID:** `aerobeat-tool-content-authoring-2ax`  
**SubAgent:** `primary` (for `coder` / `qa` / `auditor`)  
**Role:** `coder` / `qa` / `auditor`  
**References:** `REF-03`, `REF-04`, `REF-05`, `REF-06`, plus the implementation results from Task 3  
**Prompt:** After the authoring-repo validator is implemented and green, update the relevant docs in `aerobeat-docs` so they mention and link to the validator tool instead of implying docs-local validation. Then run the standard coder → QA → auditor loop across the authoring repo implementation and the docs follow-up.

**Folders Created/Deleted/Modified:**
- `projects/aerobeat/aerobeat-docs/docs/`
- plan files in the owning repo and docs repo as needed

**Files Created/Deleted/Modified:**
- docs follow-up scope only

**Status:** ⏳ In Progress — coder retry after QA failure

**Results:** Updated the docs follow-up in `aerobeat-docs` so package authors are pointed at `aerobeat-tool-content-authoring` for real validation instead of the docs repo implying docs-local validation. Files changed in `aerobeat-docs`: `docs/architecture/workout-package-storage-and-discovery.md`, `docs/guides/demo_workout_package.md`, `docs/examples/workout-packages/overview.md`, `docs/examples/workout-packages/demo-neon-boxing-bootcamp/README.md`, and `docs/guides/coaching.md`. The edits explicitly state the current first-slice scope: the authoring validator covers current YAML package records plus checked-in `sql/*.schema.sql` artifacts, supports full-package and subject-specific validation, and still defers live SQLite `.db` validation. Coder-side evidence recorded here remains: (1) `./venv/bin/mkdocs build --strict` in `aerobeat-docs`, (2) headless CLI proof run in `aerobeat-tool-content-authoring` against the docs demo package using the implemented `validate` command surface via a tiny temporary Godot script entrypoint, with `validate <package_dir> --json` passing, and (3) `validate sql <package_dir> --json` passing for the checked-in schema artifacts. Commit hashes: authoring-repo implementation from Task 3 is `3e5939b` (`Implement YAML package validation CLI slice`); docs follow-up commit is `6cc1572` (`Point package docs at authoring validator`).

QA pass findings (independent rerun on 2026-04-30):
- Re-ran `godot --headless --path .testbed --script ../tests/run_tool_tests.gd` in `aerobeat-tool-content-authoring`: pass.
- Re-ran `./venv/bin/mkdocs build --strict` in `aerobeat-docs`: pass, with the same existing nav-not-included warnings noted by coder.
- Re-exercised the real CLI surface through a tiny temporary Godot entrypoint script that calls `cli/main.gd`:
  - `validate <demo-package-dir> --json`: pass.
  - `validate <demo-package-dir>` plain-text path: reproducible runtime error from `cli/formatters/plain_text_output.gd:7` (`Invalid call 'String' constructor: subject=package`). Despite the script error, the wrapper process still returned status 0, so the non-JSON surface currently both throws and can appear successful at the shell boundary.
- Reproduced a deeper contract gap with a temporary copy of the demo package: removed one set `coachingOverlayId` while coaching remained enabled, and changed another set `assetSelections.gloves` to point at an asset whose `assetType` is `targets`. The implemented validator still returned `valid: true` / `issueCount: 0` on the full-package JSON pass.

Defects/gaps identified by QA:
1. **Plain-text CLI output path is broken**. This is not just a formatting nicety: the documented command surface is `validate <package_dir>` and `validate <subject> <package_dir> [--json]`, which implies plain-text/default output is a supported path. Right now that default path throws at runtime.
2. **Enabled-coaching overlay completeness is not enforced**. The docs/tool definition currently say that when coaching is enabled, every set should resolve exactly one overlay audio record. Implementation only validates `coachingOverlayId` when present; it does not require one for each set.
3. **`assetSelections` type-to-asset contract is not enforced**. Docs say the referenced asset id must exist and its `assetType` must match the key used in `assetSelections`, but implementation only checks that the asset id exists.

QA verdict for Task 4: the demo package does validate successfully on the working JSON path, and the docs are directionally correct about validator ownership/scope versus docs-local validation. However, the current implementation does **not** fully satisfy the documented/claimed validation contract, and the default plain-text CLI path is materially broken. This bead should **bounce back to coder**, not proceed to audit yet.

Coder retry on 2026-04-30: fixed the plain-text formatter so the default `validate <package_dir>` path renders successfully instead of throwing on `String(...)` conversions; tightened package cross-reference validation so enabled coaching now requires every set to declare a non-empty `coachingOverlayId` that resolves into `coaches/coach-config.yaml`; and enforced `assetSelections` key ↔ asset `assetType` matching once the referenced asset record resolves. Files changed in this retry: `cli/formatters/plain_text_output.gd`, `services/validation/validate_package_service.gd`, `tests/test_validate_command.gd`, and `tests/test_validate_package_failure_modes.gd`. Validation/tests rerun for the retry: `godot --headless --path .testbed --script ../tests/run_tool_tests.gd` (pass); real CLI smoke via a temporary headless Godot entry script against `projects/aerobeat/aerobeat-docs/docs/examples/workout-packages/demo-neon-boxing-bootcamp/` on both `validate <package_dir>` plain-text output and `validate <package_dir> --json` (both pass with `issueCount: 0` on the demo package). Commit hash: `7722333` (`Fix validate CLI retry defects`).

---

## Final Results

**Status:** ⚠️ Draft / Discussion only

**What We Built:** Created the implementation plan for moving workout-package validation into `aerobeat-tool-content-authoring`, where it belongs. The plan scopes the first slice around the actual current package artifacts: root `workout.yaml`, domain YAML records, SQL schema files, cross-file/reference checks, media-path checks, and a thin CLI surface with both per-artifact-family and full-package validation entrypoints. It also reserves a small docs follow-up so `aerobeat-docs` can point to the tool instead of pretending to own validation.

**Reference Check:** Pending.

**Commits:**
- None yet.

**Lessons Learned:** The biggest risk here is over-claiming contract depth for package surfaces whose detailed semantics are not locked yet, especially environments/assets. The honest first slice should validate what is really current and durable now, and leave clean seams for deeper contract validators after those schemas are purposefully designed.

---

*Completed on 2026-04-30 (draft for discussion)*
