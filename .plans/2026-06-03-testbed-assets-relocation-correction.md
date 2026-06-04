# AeroBeat Tool Content Authoring Testbed Assets Relocation Correction

**Date:** 2026-06-03  
**Status:** In Progress  
**Last Updated:** 2026-06-03 21:11 EDT  
**Blocked Reason:** None  
**Agent:** `byte`

---

## Goal

Move repo-owned testbed assets out of `src/assets/` and restore them to `.testbed/assets/`, then repair any references that should follow that ownership boundary.

---

## Overview

The prior cleanup normalized many path assumptions around the `src/` move, but you’ve called out a layout contract issue: `src/assets/` should not exist as the home for those assets. In this repo, those assets belong to the local testbed under `.testbed/assets/`, while `src/` should remain the runtime/plugin code tree.

This follow-up should be handled as a narrow ownership correction pass: identify what inside `src/assets/` actually belongs to the testbed, move it to `.testbed/assets/`, repair any runtime/testbed/import/config references that should point at the testbed location, and then delete the now-empty `src/assets/` folder once the move is safely complete. Because this potentially changes previously-fixed placeholder/resource paths, it needs a fresh coder → QA → auditor loop rather than assuming the earlier validation still covers it.

---

## REFERENCES

| ID | Description | Path |
| --- | --- | --- |
| `REF-01` | Current public repo layout contract | `README.md` |
| `REF-02` | Local testbed project wiring | `.testbed/project.godot` |
| `REF-03` | Local testbed addon sync configuration | `.testbed/addons.jsonc` |
| `REF-04` | Prior completed relink plan for context | `.plans/2026-06-03-path-relink-cleanup.md` |

---

## Tasks

### Task 1: Relocate misplaced assets from `src/assets/` to `.testbed/assets/`

**Bead ID:** `aerobeat-tool-content-authoring-07i`  
**SubAgent:** `primary` (for `coder` workflow role)  
**Role:** `coder`  
**References:** `REF-01`, `REF-02`, `REF-03`, `REF-04`  
**Prompt:** Inspect `src/assets/` in `aerobeat-tool-content-authoring`, determine which contents belong to the local testbed rather than the runtime/package tree, move them into `.testbed/assets/`, repair all repo-local references/import metadata/config/tests so the repo truthfully uses the testbed asset location, and delete the now-empty `src/assets/` folder once the move is safely complete. Keep scope tight, run the strongest local validation available, update the plan with exact changes, and commit/push by default.

**Folders Created/Deleted/Modified:**
- `src/assets/` (deleted after move)
- `.testbed/assets/`
- repo root docs and workflow service paths

**Files Created/Deleted/Modified:**
- `.testbed/assets/placeholders/blank-coaching-video.mp4`
- `.testbed/assets/placeholders/blank-environment.png`
- `.testbed/assets/placeholders/blank-environment.png.import`
- `.testbed/assets/placeholders/blank-overlay.ogg`
- `.testbed/assets/placeholders/blank-overlay.ogg.import`
- `.testbed/assets/placeholders/blank-song.ogg`
- `.testbed/assets/placeholders/blank-song.ogg.import`
- `README.md`
- `src/services/workflow/workout_package_yaml_codec.gd`
- removed former `src/assets/placeholders/*`

**Status:** ✅ Complete

**Results:** Moved the entire misplaced placeholder asset set out of `src/assets/placeholders/` into `.testbed/assets/placeholders/`: `blank-coaching-video.mp4`, `blank-environment.png`, `blank-environment.png.import`, `blank-overlay.ogg`, `blank-overlay.ogg.import`, `blank-song.ogg`, and `blank-song.ogg.import`. Updated `src/services/workflow/workout_package_yaml_codec.gd` so blank-package draft asset sources now resolve from `res://addons/aerobeat-tool-content-authoring/.testbed/assets/placeholders`, and updated the three tracked Godot `.import` metadata files so their `source_file` values match the new `.testbed` location. Updated `README.md` (`REF-01`) to remove the stale `src/assets/` runtime-tree claim and to state that placeholder verification assets live under `.testbed/assets/`, keeping the documented repo boundary aligned with `.testbed/project.godot` and `.testbed/addons.jsonc` (`REF-02`, `REF-03`). After the move, `src/assets/` was deleted because it was empty. Validation run: `cd .testbed && godotenv addons install`, then `godot --headless --path .testbed --import`, then `godot --headless --path .testbed --script scripts/tests/run_tool_tests.gd` — all succeeded with exit code 0, with the existing non-blocking Godot ObjectDB/resource-leak warnings still printed at shutdown.

---

### Task 2: Verify `.testbed/assets/` relocation behavior

**Bead ID:** `aerobeat-tool-content-authoring-v19`  
**SubAgent:** `primary` (for `qa` workflow role)  
**Role:** `qa`  
**References:** `REF-01`, `REF-02`, `REF-03`, `REF-04`  
**Prompt:** Claim the bead on start. Independently verify that the moved assets now live under `.testbed/assets/` and that the local testbed/runtime flow still resolves them correctly after the relocation. Use the highest-fidelity repo-local validation available, capture concrete evidence, and note any mismatches.

**Folders Created/Deleted/Modified:**
- `.testbed/` (runtime artifacts only if validation produces them)

**Files Created/Deleted/Modified:**
- validation artifacts/logs only if intentionally created

**Status:** ⏳ Pending

**Results:** Pending.

---

### Task 3: Independent audit and closure

**Bead ID:** `aerobeat-tool-content-authoring-eu6`  
**SubAgent:** `primary` (for `auditor` workflow role)  
**Role:** `auditor`  
**References:** `REF-01`, `REF-02`, `REF-03`, `REF-04`  
**Prompt:** Claim the bead on start. Audit the asset relocation against the plan, repo diff, and validation evidence. Confirm the repo is truthful about `src/` vs `.testbed/assets/` ownership and close the bead only if the touched scope is actually complete.

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
