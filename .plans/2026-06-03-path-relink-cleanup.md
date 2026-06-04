# AeroBeat Tool Content Authoring Path Relink Cleanup

**Date:** 2026-06-03
**Status:** In Progress
**Last Updated:** 2026-06-03 20:40 EDT
**Blocked Reason:** None
**Agent:** `byte`

---

## Goal

Repair the repo's internal path/linkage assumptions after the code moved under `src/` and the testbed-owned content moved under `.testbed/`.

---

## Overview

The repo was recently reshaped so the runtime/plugin code now lives under the root `src/` tree, while testbed-owned content such as the local demo assets/docs lives under `.testbed/`. That reshuffle likely broke Godot preload paths, addon-relative lookups, test fixtures, and any helper scripts/config that still assume the old root layout.

The safest slice is to treat this as a repo-local path normalization pass: audit references to the old root locations, update `.testbed/` and repo scripts/config to respect the new layout, then verify the testbed project still resolves the authoring package correctly. Since you believe this repo is not currently consumed as a dependency by other repos, the plan stays tightly scoped to this repo and its local testbed/runtime validation.

---

## REFERENCES

| ID | Description | Path |
| --- | --- | --- |
| `REF-01` | Current repo structure and public layout contract | `README.md` |
| `REF-02` | Local testbed project and addon wiring | `.testbed/project.godot` |
| `REF-03` | Testbed addon sync configuration | `.testbed/addons.jsonc` |

Use these IDs later in tasks, audit notes, and final results when work must match or be checked against a specific source.

---

## Tasks

### Task 1: Audit and repair repo/testbed path assumptions

**Bead ID:** `aerobeat-tool-content-authoring-516`  
**SubAgent:** `primary` (for `coder` workflow role)  
**Role:** `coder`  
**References:** `REF-01`, `REF-02`, `REF-03`  
**Prompt:** Inspect `aerobeat-tool-content-authoring` for broken path assumptions after code moved under root `src/` and testbed-owned `assets/` + `docs/` moved under `.testbed/`. Claim the bead on start. Update the repo’s Godot/testbed/config/script references so the new layout is respected, run the strongest repo-local validation available, and commit/push the changes unless blocked. Record exactly which files changed and any remaining follow-ups.

**Folders Created/Deleted/Modified:**
- `.testbed/`
- `src/`
- repo root config/script locations as needed

**Files Created/Deleted/Modified:**
- `.plans/2026-06-03-path-relink-cleanup.md`
- `README.md`
- `.testbed/scripts/tests/test_audio_metadata_import_service.gd`
- `.testbed/scripts/tests/test_build_content_package_service.gd`
- `.testbed/scripts/tests/test_chart_authoring_service.gd`
- `.testbed/scripts/tests/test_editor_uses_shared_services.gd`
- `.testbed/scripts/tests/test_validate_package_failure_modes.gd`
- `.testbed/scripts/tests/test_validate_song_timing_contract.gd`
- `.testbed/scripts/tests/test_workout_authoring_service.gd`
- `src/AeroContentAuthoring.gd`
- `src/assets/placeholders/blank-environment.png.import`
- `src/assets/placeholders/blank-overlay.ogg.import`
- `src/assets/placeholders/blank-song.ogg.import`
- `src/editor/plugins/content_authoring_plugin.gd`
- `src/services/workflow/workout_package_yaml_codec.gd`

**Status:** ✅ Complete

**Results:** Audited repo-local path assumptions and fixed the stale pre-reshape references that still assumed code/resources lived at the addon root instead of under `src/`. Updated `src/AeroContentAuthoring.gd`, `src/editor/plugins/content_authoring_plugin.gd`, `src/services/workflow/workout_package_yaml_codec.gd`, the placeholder `.import` metadata files under `src/assets/placeholders/`, and the affected `.testbed/scripts/tests/*.gd` preload/load constants so the testbed now resolves runtime/plugin/services through `res://addons/aerobeat-tool-content-authoring/src/...` consistently. Also corrected `README.md` so the documented repo shape matches the current `src/`-owned layout (`REF-01`), while keeping the testbed scope aligned with `.testbed/project.godot` and `.testbed/addons.jsonc` (`REF-02`, `REF-03`).

Validation run:
- `cd .testbed && godotenv addons install`
- `godot --headless --path .testbed --import`
- `godot --headless --path .testbed --script scripts/tests/run_tool_tests.gd`

Validation passed after one follow-up fix to `src/AeroContentAuthoring.gd`, which still had old `../services/...` preloads from before the repo move. Remaining follow-up to note for QA/audit only: Godot exits with the pre-existing warnings `ObjectDB instances leaked at exit` and `resources still in use at exit`, but the headless suite completed successfully with exit code `0`.

---

### Task 2: Verify the repaired layout in the local testbed

**Bead ID:** `aerobeat-tool-content-authoring-jgl`
**SubAgent:** `primary` (for `qa` workflow role)
**Role:** `qa`
**References:** `REF-01`, `REF-02`, `REF-03`
**Prompt:** Claim the bead on start. Independently verify that the `aerobeat-tool-content-authoring` testbed resolves the package correctly after the path relink cleanup. Use the highest-fidelity repo-local validation available, focusing on `.testbed/` runtime/test resolution and any scripts/config touched by the coder. Capture concrete pass/fail evidence and note any mismatches.

**Folders Created/Deleted/Modified:**
- `.testbed/` (runtime artifacts only if validation produces them)

**Files Created/Deleted/Modified:**
- validation artifacts/logs only if intentionally created

**Status:** ⏳ Pending

**Results:** Pending.

---

### Task 3: Independent audit and closure

**Bead ID:** `aerobeat-tool-content-authoring-f3x`
**SubAgent:** `primary` (for `auditor` workflow role)
**Role:** `auditor`
**References:** `REF-01`, `REF-02`, `REF-03`
**Prompt:** Claim the bead on start. Audit the completed path relink cleanup against the plan, repo diff, and validation evidence. Confirm the repo now respects the new `src/` and `.testbed/` layout without silent scope drift. Close the bead directly only if the work is actually complete; otherwise leave it open and explain the gap precisely.

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
