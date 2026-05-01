# AeroBeat Asset V1 Validator Rollout

**Date:** 2026-04-30  
**Status:** Draft  
**Agent:** Chip 🐱‍💻

---

## Goal

Align `aerobeat-tool-content-authoring` with the approved AeroBeat Asset v1 contract so the tool docs and validator enforce the locked asset record shape and Set/package composition rules.

---

## Overview

Derrick approved the Asset v1 package contract today and explicitly chose to normalize the asset record field to `type` instead of the older `assetType` name. The approved first-pass contract stays intentionally small: shared schema/provenance, `assetId`, `assetName`, `type`, and `resourcePath`, with the closed v1 enum values left unchanged. The richer composition rule also stays where it belongs: Sets may reference multiple assets, but a valid Set may include at most one asset per asset type.

The validator/tooling repo now needs to reflect that contract honestly. This rollout should validate the approved record shape, the exact enum, package-local `resourcePath` existence, and the Set/package composition rules that are already part of the package model. It should not broaden scope into runtime rendering semantics, athlete preference overrides, marketplace metadata, or future asset families.

---

## REFERENCES

| ID | Description | Path |
| --- | --- | --- |
| `REF-01` | Docs-side Asset v1 rollout plan | `projects/aerobeat/aerobeat-docs/.plans/2026-04-30-aerobeat-asset-v1-contract-rollout.md` |
| `REF-02` | Environment/asset contract review plan with asset research findings | `projects/aerobeat/aerobeat-docs/.plans/2026-04-30-aerobeat-environment-and-asset-yaml-contract-review.md` |
| `REF-03` | Existing tool responsibilities plan | `projects/aerobeat/aerobeat-tool-content-authoring/.plans/2026-04-25-aerobeat-tool-content-authoring-responsibilities.md` |
| `REF-04` | Package-validation CLI slice plan | `projects/aerobeat/aerobeat-tool-content-authoring/.plans/archive/2026-04-30-aerobeat-package-validation-cli-slice.md` |
| `REF-05` | Environment v1 validator rollout plan | `projects/aerobeat/aerobeat-tool-content-authoring/.plans/2026-04-30-aerobeat-environment-v1-validator-rollout.md` |
| `REF-06` | Existing validate command surface | `projects/aerobeat/aerobeat-tool-content-authoring/cli/commands/validate_command.gd` |
| `REF-07` | Existing package validator service | `projects/aerobeat/aerobeat-tool-content-authoring/services/validation/validate_package_service.gd` |
| `REF-08` | Existing validation tests | `projects/aerobeat/aerobeat-tool-content-authoring/tests/` |

---

## Tasks

### Task 1: Implement Asset v1 validator/doc alignment in `aerobeat-tool-content-authoring`

**Bead ID:** `Pending`  
**SubAgent:** `primary` (for `coder`)  
**Role:** `coder`  
**References:** `REF-01` through `REF-08`  
**Prompt:** Implement the approved Asset v1 contract in the authoring tool repo. Update validator behavior, relevant docs/help text, and tests so the repo enforces the locked asset shape (`assetId`, `assetName`, `type`, `resourcePath`, shared schema/provenance) and the exact v1 type enum (`gloves`, `targets`, `obstacles`, `trails`), plus the Set/package rule that each Set may reference multiple assets but at most one asset per asset type. Keep scope first-pass and honest; do not invent deep runtime/performance validation or broaden into future asset families.

**Folders Created/Deleted/Modified:**
- `docs/`
- `services/validation/`
- `cli/`
- `tests/`
- `.plans/`

**Files Created/Deleted/Modified:**
- implementation scope only

**Status:** ⏳ Pending

**Results:** Pending implementation.

---

### Task 2: QA the Asset v1 validator/doc alignment

**Bead ID:** `Pending`  
**SubAgent:** `primary` (for `qa`)  
**Role:** `qa`  
**References:** `REF-01` through `REF-08`  
**Prompt:** Independently verify that the authoring tool repo now matches the approved Asset v1 contract. Re-run the relevant validation/test suite, exercise the validator against the docs demo package, and check that the tool behavior/docs align with the locked field names, enum, and Set/package asset-composition rules without overclaiming runtime semantics.

**Folders Created/Deleted/Modified:**
- implementation scope only

**Files Created/Deleted/Modified:**
- QA-only scope if a trivial parity fix is needed

**Status:** ⏳ Pending

**Results:** Pending QA.

---

### Task 3: Audit the Asset v1 validator/doc alignment

**Bead ID:** `Pending`  
**SubAgent:** `primary` (for `auditor`)  
**Role:** `auditor`  
**References:** `REF-01` through `REF-08`  
**Prompt:** Independently truth-check the authoring tool repo Asset v1 rollout against the approved docs contract, validator behavior, and test evidence. Confirm the bead is actually done or report the exact remaining gap.

**Folders Created/Deleted/Modified:**
- implementation scope only

**Files Created/Deleted/Modified:**
- audit-only scope if a final parity note is required

**Status:** ⏳ Pending

**Results:** Pending audit.

---

## Final Results

**Status:** ⚠️ Partial

**What We Built:** Drafted the tool-repo execution plan for locking the approved Asset v1 contract into `aerobeat-tool-content-authoring`. No validator or docs changes are implemented yet.

**Reference Check:** This plan is intentionally downstream of the docs-side Asset v1 decision and should not drift beyond that approved scope.

**Commits:**
- None yet

**Lessons Learned:** The key risk is silent legacy naming drift. The validator and docs need to agree on `type` explicitly so `assetType` does not linger as an accidental second contract.

---

*Drafted on 2026-04-30*