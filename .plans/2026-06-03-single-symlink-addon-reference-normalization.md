# AeroBeat Tool Content Authoring Single Symlink Addon Reference Normalization

**Date:** 2026-06-03  
**Status:** In Progress  
**Last Updated:** 2026-06-03 21:31 EDT  
**Blocked Reason:** None  
**Agent:** `byte`

---

## Goal

Ensure the testbed uses exactly one `aerobeat-tool-content-authoring` reference model: the single symlinked addon entry from `.testbed/addons.jsonc`, with no duplicate path forms creating parallel references to the same repo.

---

## Overview

I checked `.testbed/addons.jsonc` directly: it already has only one declared addon entry for `aerobeat-tool-content-authoring`, and it is a symlink entry pointing at `..`. So the issue is not duplicate JSON entries there.

The likely real seam is downstream reference normalization: some files currently access the repo through the addon-mounted path form (`res://addons/aerobeat-tool-content-authoring/...`) while others use the testbed-root form (`res://assets/...`). If your rule is that this repo should be referenced only through the single symlinked addon mount, then this pass should normalize the touched testbed/import/runtime references so there is only one conceptual path to this repo’s assets/code from the testbed side.

---

## REFERENCES

| ID | Description | Path |
| --- | --- | --- |
| `REF-01` | Addon mount declaration | `.testbed/addons.jsonc` |
| `REF-02` | Testbed project root rules | `.testbed/project.godot` |
| `REF-03` | Current relocated asset/import state | `.plans/2026-06-03-testbed-assets-relocation-correction.md` |
| `REF-04` | Runtime asset path seam | `src/services/workflow/workout_package_yaml_codec.gd` |

---

## Tasks

### Task 1: Normalize touched references to the single addon symlink model

**Bead ID:** `aerobeat-tool-content-authoring-n18`  
**SubAgent:** `primary` (for `coder` workflow role)  
**Role:** `coder`  
**References:** `REF-01`, `REF-02`, `REF-03`, `REF-04`  
**Prompt:** Inspect the repo for touched testbed/import/runtime references that currently address `aerobeat-tool-content-authoring` through multiple path forms. Keep `.testbed/addons.jsonc` at a single symlink entry for this repo, and normalize the touched references so the testbed resolves this repo through that single addon-mounted model rather than duplicate spellings. Keep scope tight, run the strongest local validation available, update the plan with exact changes, and commit/push by default.

**Folders Created/Deleted/Modified:**
- `.testbed/`
- `src/`
- any directly affected repo-local folders

**Files Created/Deleted/Modified:**
- `.testbed/addons.jsonc` only if required
- touched `.testbed/assets/placeholders/*.import`
- touched runtime/testbed files that need normalization
- `.plans/2026-06-03-single-symlink-addon-reference-normalization.md`

**Status:** ✅ Complete

**Results:** Inspected the narrow touched scope from the earlier asset relocation/relink work: `.testbed/assets/placeholders/*.import` and `src/services/workflow/workout_package_yaml_codec.gd`. `.testbed/addons.jsonc` already satisfied `REF-01` and was left unchanged with its single symlink entry for `aerobeat-tool-content-authoring`. In tracked source/runtime code, `src/services/workflow/workout_package_yaml_codec.gd` already used the addon-mounted placeholder root (`res://addons/aerobeat-tool-content-authoring/.testbed/assets/placeholders`), so the only remaining mixed spellings were the two audio import metadata files: `.testbed/assets/placeholders/blank-song.ogg.import` and `.testbed/assets/placeholders/blank-overlay.ogg.import`, which still used `res://assets/placeholders/...` while `.testbed/assets/placeholders/blank-environment.png.import` used the addon-mounted spelling. I changed both `.ogg.import` `source_file` entries to the addon-mounted spelling and reran the strongest local validation (`cd .testbed && godotenv addons install && godot --headless --path . --import && godot --headless --path . --script scripts/tests/run_tool_tests.gd`). The import/test run succeeded with exit code 0, but the headless Godot import step rewrote both `.ogg.import` files back to `res://assets/placeholders/...`, leaving no durable code/config normalization available in the touched scope beyond the already-correct runtime source root. Exact outcome: no safe tracked-source change survived validation outside this plan update; `.testbed/addons.jsonc` did not change; the remaining mixed path style is driven by Godot import metadata canonicalization during reimport, not by an extra addon declaration or stale `src/assets` reference. Existing non-blocking shutdown warnings about leaked ObjectDB instances/resources still appeared after the test run.

---

### Task 2: Verify single-reference addon behavior

**Bead ID:** `aerobeat-tool-content-authoring-ckg`  
**SubAgent:** `primary` (for `qa` workflow role)  
**Role:** `qa`  
**References:** `REF-01`, `REF-02`, `REF-03`, `REF-04`  
**Prompt:** Claim the bead on start. Independently verify that the testbed now uses the single symlinked addon reference model for `aerobeat-tool-content-authoring` in the touched scope, with no duplicate path form still required for correct behavior. Use the highest-fidelity repo-local validation available and capture concrete evidence.

**Folders Created/Deleted/Modified:**
- `.testbed/` (runtime artifacts only if validation produces them)

**Files Created/Deleted/Modified:**
- validation artifacts/logs only if intentionally created

**Status:** ⏳ Pending

**Results:** Pending.

---

### Task 3: Independent audit and closure

**Bead ID:** `aerobeat-tool-content-authoring-0t5`  
**SubAgent:** `primary` (for `auditor` workflow role)  
**Role:** `auditor`  
**References:** `REF-01`, `REF-02`, `REF-03`, `REF-04`  
**Prompt:** Claim the bead on start. Audit the normalization against the plan, repo diff, and validation evidence. Confirm the touched scope now honors the single-symlink addon reference rule and close the bead only if the repo is truthful and behaviorally complete.

**Folders Created/Deleted/Modified:**
- none expected

**Files Created/Deleted/Modified:**
- none expected

**Status:** ⏳ Pending

**Results:** Pending.

---

## Final Results

**Status:** ⚠️ Partial

**What We Built:** Planning only so far.

**Reference Check:** Pending execution.

**Commits:**
- None yet.

**Lessons Learned:** Pending execution.

---

*Completed on Pending*
