# AeroBeat Package Validation CLI Slice

**Date:** 2026-04-30  
**Status:** Draft  
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

**Bead ID:** `Pending`  
**SubAgent:** `primary` (for `research`)  
**Role:** `research`  
**References:** `REF-01`, `REF-03`, `REF-04`, `REF-07`, `REF-08`, `REF-09`  
**Prompt:** Inspect the current authoring repo validation/CLI surfaces plus the current demo workout package contents. Document what validators/commands already exist, which YAML/SQL artifacts are actually shipped today, what can already be reused, and what exact validation scope is honest for this first package-validation slice.

**Folders Created/Deleted/Modified:**
- `.plans/`
- repo docs only if a separate note is truly justified

**Files Created/Deleted/Modified:**
- this plan file unless a separate note is justified

**Status:** ⏳ Pending

**Results:** Pending.

---

### Task 2: Design the validation command map and shared-service boundary

**Bead ID:** `Pending`  
**SubAgent:** `primary` (for `research`)  
**Role:** `research`  
**References:** `REF-01`, `REF-02`, `REF-07`, `REF-08`, `REF-09`  
**Prompt:** Design the first-pass validation command surface for `aerobeat-tool-content-authoring`. Include tiny validator entrypoints per current YAML/SQL artifact family where justified, plus a full-package validator. Make the shared-service versus CLI boundary explicit, and decide how partial validation results/reporting should look.

**Folders Created/Deleted/Modified:**
- `.plans/`
- maybe repo docs if needed

**Files Created/Deleted/Modified:**
- this plan file unless a separate note is justified

**Status:** ⏳ Pending

**Results:** Pending.

---

### Task 3: Implement package-validation services, CLI entrypoints, and tests in `aerobeat-tool-content-authoring`

**Bead ID:** `Pending`  
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

**Status:** ⏳ Pending

**Results:** Pending.

---

### Task 4: Update `aerobeat-docs` to point to the authoring validator, then QA and audit the full slice

**Bead ID:** `Pending`  
**SubAgent:** `primary` (for `coder` / `qa` / `auditor`)  
**Role:** `coder` / `qa` / `auditor`  
**References:** `REF-03`, `REF-04`, `REF-05`, `REF-06`, plus the implementation results from Task 3  
**Prompt:** After the authoring-repo validator is implemented and green, update the relevant docs in `aerobeat-docs` so they mention and link to the validator tool instead of implying docs-local validation. Then run the standard coder → QA → auditor loop across the authoring repo implementation and the docs follow-up.

**Folders Created/Deleted/Modified:**
- `projects/aerobeat/aerobeat-docs/docs/`
- plan files in the owning repo and docs repo as needed

**Files Created/Deleted/Modified:**
- docs follow-up scope only

**Status:** ⏳ Pending

**Results:** Pending.

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
