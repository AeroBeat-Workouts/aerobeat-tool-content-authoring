# AeroBeat Environment V1 Validator Rollout

**Date:** 2026-04-30  
**Status:** In Progress  
**Agent:** Chip 🐱‍💻

---

## Goal

Align `aerobeat-tool-content-authoring` with the newly approved AeroBeat Environment v1 contract so the tool docs and validator enforce the locked environment record shape and type enum.

---

## Overview

Derrick approved the Environment v1 package contract in the docs-side review today. The locked decision is to keep environment records intentionally small and typed, with exactly one environment selected per Set and with no baseline `godot_scene` support in the public v1 package contract. Instead, the runtime-facing first-pass environment families are `image_background`, `video_background`, and `glb_environment`.

That means the validator/tooling repo now needs to stop treating environments as only shallow structural placeholders and instead enforce the approved contract honestly — but only to first-pass scope. This rollout should not invent deep runtime/performance validation. It should validate the locked shape, the locked type enum, the `resourcePath` presence/type-family expectations, and the existing package composition rule that Sets link exactly one valid environment.

This work belongs in `aerobeat-tool-content-authoring`, but it depends on the docs repo having just locked the contract language. The implementation should therefore track the docs-approved contract exactly and avoid broadening scope into future asset-contract or advanced `godot_scene` pipeline work.

---

## REFERENCES

| ID | Description | Path |
| --- | --- | --- |
| `REF-01` | Docs-side environment/asset contract review plan | `projects/aerobeat/aerobeat-docs/.plans/2026-04-30-aerobeat-environment-and-asset-yaml-contract-review.md` |
| `REF-02` | Current package-validation CLI slice plan | `projects/aerobeat/aerobeat-tool-content-authoring/.plans/archive/2026-04-30-aerobeat-package-validation-cli-slice.md` |
| `REF-03` | Tool definition / ownership boundary | `projects/aerobeat/aerobeat-tool-content-authoring/docs/content-authoring-tool-definition.md` |
| `REF-04` | Existing validate command surface | `projects/aerobeat/aerobeat-tool-content-authoring/cli/commands/validate_command.gd` |
| `REF-05` | Existing package validator service | `projects/aerobeat/aerobeat-tool-content-authoring/services/validation/validate_package_service.gd` |
| `REF-06` | Existing validation tests | `projects/aerobeat/aerobeat-tool-content-authoring/tests/` |

---

## Tasks

### Task 1: Implement Environment v1 validator/doc alignment in `aerobeat-tool-content-authoring`

**Bead ID:** `aerobeat-tool-content-authoring-fqi`  
**SubAgent:** `primary` (for `coder`)  
**Role:** `coder`  
**References:** `REF-01` through `REF-06`  
**Prompt:** Implement the approved Environment v1 contract in the authoring tool repo. Update validator behavior, relevant docs/help text, and tests so the repo enforces the locked environment shape (`environmentId`, `environmentName`, `type`, `resourcePath`, shared schema/provenance) and the exact v1 type enum (`image_background`, `video_background`, `glb_environment`). Keep scope first-pass and honest; do not invent advanced runtime/performance validation or baseline `godot_scene` support.

**Folders Created/Deleted/Modified:**
- `docs/`
- `services/validation/`
- `cli/`
- `tests/`
- `.plans/`

**Files Created/Deleted/Modified:**
- implementation scope only

**Status:** ✅ Complete

**Results:** Updated `services/validation/validate_package_service.gd` so environment records now require `type` + `resourcePath` instead of legacy `scenePath`, enforce the exact v1 enum (`image_background`, `video_background`, `glb_environment`), verify package-local `resourcePath` existence, and flag coarse type/path-family mismatches by extension. Updated repo docs in `docs/content-authoring-tool-definition.md` and `README.md` to match the locked Environment v1 contract and explicitly keep validation scope first-pass only. Expanded `tests/test_validate_package_failure_modes.gd` with coverage for invalid environment types, mismatched resource families, and legacy `scenePath` usage. Validation run: `godot --headless --path .testbed --script ../tests/run_tool_tests.gd` ✅. Commit hash: `278ebeb`.

---

### Task 2: QA the Environment v1 validator/doc alignment

**Bead ID:** `Pending`  
**SubAgent:** `primary` (for `qa`)  
**Role:** `qa`  
**References:** `REF-01` through `REF-06`  
**Prompt:** Independently verify that the authoring tool repo now matches the approved Environment v1 contract. Re-run the relevant validation/test suite, exercise the validator against the docs demo package, and check that the tool behavior/docs align with the locked enum and field names without overclaiming `godot_scene` or deep runtime validation.

**Folders Created/Deleted/Modified:**
- implementation scope only

**Files Created/Deleted/Modified:**
- QA-only scope if a trivial parity fix is needed

**Status:** ⏳ Pending

**Results:** Pending QA.

---

### Task 3: Audit the Environment v1 validator/doc alignment

**Bead ID:** `Pending`  
**SubAgent:** `primary` (for `auditor`)  
**Role:** `auditor`  
**References:** `REF-01` through `REF-06`  
**Prompt:** Independently truth-check the authoring tool repo Environment v1 rollout against the approved docs contract, the validator behavior, and the test evidence. Confirm the bead is actually done or report the exact remaining gap.

**Folders Created/Deleted/Modified:**
- implementation scope only

**Files Created/Deleted/Modified:**
- audit-only scope if a final parity note is required

**Status:** ⏳ Pending

**Results:** Pending audit.

---

## Final Results

**Status:** ⚠️ Partial

**What We Built:** Implemented the Environment v1 validator/doc alignment slice in `aerobeat-tool-content-authoring`: the validator now requires the locked environment record shape (`environmentId`, `environmentName`, `type`, `resourcePath` plus shared schema/provenance), enforces the exact v1 type enum, checks package-local environment resource existence, and performs coarse file-family matching by type. Repo docs/help text now describe the same contract without reintroducing baseline `godot_scene` support or deep runtime claims.

**Reference Check:** `REF-03`, `REF-04`, `REF-05`, and `REF-06` are now aligned to the approved downstream contract from `REF-01`, with validation scope intentionally limited to first-pass structural checks only.

**Commits:**
- `278ebeb` - Align Environment v1 validator contract

**Lessons Learned:** The key risk stayed the same: enforce the approved contract exactly, but keep the validator honest about what it can actually prove today. Coarse type/path-family checks were enough for this slice without inventing deeper runtime or performance rules.

---

*Updated on 2026-04-30*