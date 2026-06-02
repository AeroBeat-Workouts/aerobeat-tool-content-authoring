# AeroBeat Tool Content Authoring Downscope Alignment

**Date:** 2026-05-01  
**Status:** Stale  
**Agent:** Chip 🐱‍💻

---

## Goal

Align `aerobeat-tool-content-authoring` with the newly downscoped AeroBeat v1 package/content direction so the repo stops teaching or validating removed workout-package concepts.

---

## Overview

The docs-first downscope is complete, and the wider polyrepo audit identified `aerobeat-tool-content-authoring` as the highest-mismatch repo outside `aerobeat-docs`. Right now it still represents stale package truths such as workout-package `assets/`, `assetSelections`, and broader feature acceptance that no longer match the approved product scope.

This slice should make the repo truthful to the new contract: official v1 gameplay features are `boxing` and `flow`; official v1 gameplay input is camera-only; workout packages still keep songs/charts/sets/workouts/coaching/environments; and package-local gameplay `assets` are no longer an active authored package concept. Internal AeroBeat assets still exist at the product level, but not as workout-package subsets. That distinction needs to be reflected carefully so we do not accidentally delete legitimate internal asset abstractions while removing stale package authoring assumptions.

The goal of this slice is alignment first: repo docs, definitions, examples, validators, and tests should match the updated contract. Later slices can continue broader polyrepo cleanup once this highest-risk source of stale package truth is fixed.

---

## REFERENCES

| ID | Description | Path |
| --- | --- | --- |
| `REF-01` | Active plan for this repo-local cleanup slice | `.plans/2026-05-01-aerobeat-tool-content-authoring-downscope-alignment.md` |
| `REF-02` | Updated AeroBeat docs source of truth | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-docs` |
| `REF-03` | Parent coordination plan and matrix | `/home/derrick/.openclaw/workspace/projects/openclaw-chip/.plans/2026-05-01-aerobeat-polyrepo-downscope-audit.md` |
| `REF-04` | Repo-local tool definition doc | `docs/content-authoring-tool-definition.md` |

---

## Tasks

### Task 1: Audit `aerobeat-tool-content-authoring` for stale package assumptions

**Bead ID:** `aerobeat-tool-content-authoring-23y`  
**SubAgent:** `primary`  
**Role:** `research`  
**References:** `REF-01`, `REF-02`, `REF-03`, `REF-04`  
**Prompt:** Audit this repo against the updated docs/source-of-truth. Identify every place the repo still teaches, validates, or assumes removed workout-package concepts such as package `assets/`, `assetSelections`, or removed feature scope (`dance`, `step`). Also flag any repo text that still overstates non-camera gameplay support as current v1 behavior. Do not edit yet; produce an execution-ready list.

**Folders Created/Deleted/Modified:**
- `.plans/`
- `docs/`
- `src/`
- `tests/`

**Files Created/Deleted/Modified:**
- `.plans/2026-05-01-aerobeat-tool-content-authoring-downscope-alignment.md`
- `docs/**`
- `src/**`
- `tests/**`

**Status:** ✅ Complete

**Results:** Completed the repo-local stale-contract audit. Main findings: `services/validation/validate_package_service.gd` still enforces package `assets/` and `assetSelections`; `cli/commands/validate_command.gd` still exposes `validate assets`; `services/validation/validate_chart_service.gd` still accepts removed features `dance` and `step`; repo docs still teach the old package model; and the current test suite already fails against the updated docs demo package because `assets/` is no longer present there. Derrick approved the strict cleanup direction: old package `assets/` and `assetSelections` should now fail validation explicitly rather than being tolerated as migration-era inputs.

---

### Task 2: Apply the repo cleanup and contract alignment

**Bead ID:** `aerobeat-tool-content-authoring-dmg`  
**SubAgent:** `primary`  
**Role:** `coder`  
**References:** `REF-01`, `REF-02`, `REF-03`, `REF-04`  
**Prompt:** After the audit/action list is approved, update this repo so its docs, definitions, validators, examples, and tests match the new downscoped AeroBeat package contract. Commit and push by default.

**Folders Created/Deleted/Modified:**
- `.plans/`
- `docs/`
- `src/`
- `tests/`

**Files Created/Deleted/Modified:**
- `.plans/2026-05-01-aerobeat-tool-content-authoring-downscope-alignment.md`
- `docs/**`
- `src/**`
- `tests/**`

**Status:** ✅ Complete

**Results:** Applied the downscope contract alignment. The coder pass removed package `assets` as an accepted validation subject, removed package-asset family loading/counting/validation, made legacy `assets/` fail explicitly as `assets_directory_not_supported`, made `assetSelections` fail explicitly as `asset_selections_not_supported`, removed the stale `validate assets` CLI surface, narrowed chart validation to `boxing` and `flow`, rewrote the repo docs/README around the new authored package truth, and updated failure-mode tests to cover forbidden `assets/`, forbidden `assetSelections`, and rejected `dance`/`step` charts. Validation passed via `godot --headless --path .testbed --script ../tests/run_tool_tests.gd`, and the changes were committed/pushed as `7c13202` (`Align package validation with downscoped v1 contract`). The repo still has unrelated pre-existing modified `.plans/` files left unstaged.

---

### Task 3: QA and audit the alignment

**Bead ID:** `aerobeat-tool-content-authoring-dhh` (QA), `aerobeat-tool-content-authoring-sxt` (Auditor)  
**SubAgent:** `primary`  
**Role:** `qa` then `auditor`  
**References:** `REF-01`, `REF-02`, `REF-03`, `REF-04`  
**Prompt:** Independently verify that the repo no longer teaches or validates workout-package `assets` / `assetSelections`, no longer presents removed features as active authored package scope, and still correctly supports environments/coaching/internal product asset concepts where appropriate.

**Folders Created/Deleted/Modified:**
- `.plans/`
- `docs/`
- `src/`
- `tests/`

**Files Created/Deleted/Modified:**
- `.plans/2026-05-01-aerobeat-tool-content-authoring-downscope-alignment.md`
- `docs/**`
- `src/**`
- `tests/**`

**Status:** ⏳ In Progress

**Results:** QA pass completed with no fixes required and recommended auditor handoff. QA independently confirmed that the repo now accepts only `boxing` and `flow`, rejects `dance` and `step`, rejects package-local `assets/` and set-level `assetSelections` explicitly, no longer exposes `validate assets` in the CLI surface, and keeps environments/coaching valid while treating internal AeroBeat assets as product-side rather than workout-package subsets. Full repo validation passed again via `godot --headless --path .testbed --script ../tests/run_tool_tests.gd`.

---

## Final Results

**Status:** ⚠️ Partial

**What We Built:** Draft repo-local plan for the first post-docs polyrepo cleanup slice.

**Reference Check:** Pending repo audit and execution.

**Commits:**
- None yet.

**Lessons Learned:** This repo is a contract-enforcement surface, so stale package assumptions here are more dangerous than stale marketing copy elsewhere.

---

*Completed on 2026-05-01*