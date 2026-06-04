# AeroBeat Tool Content Authoring Path Relink Cleanup

**Date:** 2026-06-03
**Status:** Complete
**Last Updated:** 2026-06-03 20:56 EDT
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

**Status:** ✅ Complete

**Results:** Independently re-ran the repo-local testbed flow against commit `bd4c9ca` and confirmed the reshaped layout resolves through the actual `.testbed` addon wiring rather than only via static edits. First, `godotenv addons install` in `.testbed/` re-symlinked `aerobeat-tool-content-authoring` from `..` as declared in `.testbed/addons.jsonc` (`REF-03`). I then verified `.testbed/addons/aerobeat-tool-content-authoring` is a symlink back to the repo root and that the repaired runtime entrypoints exist under `src/`, including `src/AeroContentAuthoring.gd`, `src/editor/plugins/content_authoring_plugin.gd`, and `src/services/workflow/workout_package_yaml_codec.gd` (`REF-02`, `REF-03`).

QA validation run:
- `cd .testbed && godotenv addons install`
- `cd .. && godot --headless --path .testbed --import`
- `cd .. && godot --headless --path .testbed --script scripts/tests/run_tool_tests.gd`
- `cd .. && tmp=$(mktemp); godot --headless --path .testbed --script scripts/tests/run_tool_tests.gd >"$tmp" 2>&1; status=$?; printf 'exit_code=%s\n' "$status"; rg -n '"passed": true|WARNING: ObjectDB instances leaked at exit|ERROR: [0-9]+ resources still in use at exit|"name": "test_' "$tmp" | tail -n 40; rm -f "$tmp"; exit $status`

Evidence from the passing suite: `exit_code=0`; `test_aero_content_authoring_workflow`, `test_blank_new_package_seed_save_reload`, and `test_task6_set_authoring_runtime` all passed; the runtime state emitted by the suite shows `draftAssetSources` resolving placeholder assets from `.testbed/addons/aerobeat-tool-content-authoring/src/assets/placeholders/...`, which confirms the repaired `src/` paths are being consumed through the local testbed/addon boundary. I also spot-checked the affected preload constants with `rg`, and the touched tests now point at `res://addons/aerobeat-tool-content-authoring/src/...` while placeholder imports point at `res://addons/aerobeat-tool-content-authoring/src/assets/placeholders/...` (`REF-01`, `REF-02`, `REF-03`).

No new defects were found in this QA pass. The previously noted Godot shutdown warnings still reproduce (`ObjectDB instances leaked at exit` and `9 resources still in use at exit`), but they appear to be pre-existing/non-blocking because the full headless suite still exits `0` and all targeted runtime/test scenarios pass.

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

**Status:** ❌ Failed

**Results:** Independent audit confirmed the implementation commit `bd4c9ca` repaired the actual runtime/testbed path seams that were breaking after the move to `src/`: the touched `.testbed/scripts/tests/*.gd` files now load from `res://addons/aerobeat-tool-content-authoring/src/...`, `src/AeroContentAuthoring.gd` and `src/editor/plugins/content_authoring_plugin.gd` use corrected relative preloads, and `src/services/workflow/workout_package_yaml_codec.gd` plus the placeholder `.import` metadata now point at `src/assets/placeholders/...`. I also re-ran the local verification flow (`godotenv addons install`, `godot --headless --path .testbed --import`, `godot --headless --path .testbed --script scripts/tests/run_tool_tests.gd`) and independently reproduced a passing headless suite with `exit_code=0`, alongside the already-known non-blocking Godot shutdown warnings.

The audit does **not** pass yet because a touched documentation seam was missed in `README.md`: the `Current open seam` section still references `services/authoring/chart_authoring_service.gd` instead of the new `src/services/authoring/chart_authoring_service.gd` path. That means the plan’s earlier claim that `README.md` was corrected to match the current `src`-owned layout is not fully truthful, and the repo does not yet present a fully consistent post-move path story in all touched areas. The bead should remain open for a narrow doc follow-up to finish the cleanup.

---

### Task 4: Repair stale README path seam after audit

**Bead ID:** `aerobeat-tool-content-authoring-ozj`
**SubAgent:** `primary` (for `coder` workflow role)
**Role:** `coder`
**References:** `REF-01`
**Prompt:** Claim the bead on start. Apply the narrow audit follow-up needed to finish the path relink cleanup: repair the stale pre-move path reference still left in `README.md` (`services/authoring/chart_authoring_service.gd` → `src/services/authoring/chart_authoring_service.gd`) and sweep any immediately adjacent touched doc wording needed to keep the README truthful about the post-move layout. Keep scope tight, update the plan with actual results, commit/push the follow-up, and close the bead if complete.

**Folders Created/Deleted/Modified:**
- none expected

**Files Created/Deleted/Modified:**
- `README.md`
- `.plans/2026-06-03-path-relink-cleanup.md`

**Status:** ✅ Complete

**Results:** Updated the `README.md` `Current open seam` bullet to point at `src/services/authoring/chart_authoring_service.gd`, matching the post-move layout already reflected elsewhere in the repo. No broader README wording changes were needed because the surrounding seam description remained truthful once the stale path was corrected. Commit/push completed in the narrow doc follow-up commit for this bead.

---

### Task 5: Verify README/doc seam follow-up

**Bead ID:** `aerobeat-tool-content-authoring-9u3`
**SubAgent:** `primary` (for `qa` workflow role)
**Role:** `qa`
**References:** `REF-01`
**Prompt:** Claim the bead on start. Independently verify the narrow README/doc seam follow-up after the audit failure. Confirm the stale README path reference was corrected and that the documented layout in the touched area now matches the `src/`-owned repo structure. Keep scope tight, update the plan with evidence, and close the bead if QA passes.

**Folders Created/Deleted/Modified:**
- none expected

**Files Created/Deleted/Modified:**
- `.plans/2026-06-03-path-relink-cleanup.md` only if needed for QA notes

**Status:** ✅ Complete

**Results:** Independently verified the narrow README follow-up at commit `1a4235a`. I checked the touched `README.md` seam directly and confirmed the `Current open seam` bullet now reads `src/services/authoring/chart_authoring_service.gd` rather than the stale pre-move `services/authoring/chart_authoring_service.gd` (`REF-01`). I also verified the referenced file exists at `src/services/authoring/chart_authoring_service.gd` and that no root-level `services/authoring/chart_authoring_service.gd` path exists anymore, so the touched README area now matches the repo’s post-move `src/`-owned layout. Evidence checked: `README.md` lines around the `Current open seam` section, `git show 1a4235a -- README.md`, `ls -l src/services/authoring/chart_authoring_service.gd`, and an existence check confirming the stale root path is absent. No new mismatches were found in this narrow doc seam scope.

---

### Task 6: Final audit closure after doc seam fix

**Bead ID:** `aerobeat-tool-content-authoring-e4v`
**SubAgent:** `primary` (for `auditor` workflow role)
**Role:** `auditor`
**References:** `REF-01`, `REF-02`, `REF-03`
**Prompt:** Claim the bead on start. Perform the final audit after the README/doc seam fix. Confirm the repo and plan are now truthful about the post-move `src/` + `.testbed/` layout, ensure there is no remaining blocker in the touched scope, update Final Results in the plan, and close the bead only if the work is actually complete.

**Folders Created/Deleted/Modified:**
- none expected

**Files Created/Deleted/Modified:**
- `.plans/2026-06-03-path-relink-cleanup.md` if needed for final audit notes

**Status:** ✅ Complete

**Results:** Final audit passes. I checked the previously blocking README seam at `HEAD` (`1a4235a`) and confirmed the touched `Current open seam` bullet now points at `src/services/authoring/chart_authoring_service.gd`, the real file exists there, and the stale root-level `services/authoring/chart_authoring_service.gd` path is absent (`REF-01`). I also spot-checked the earlier implementation scope against the repo’s current state: the touched `.testbed/scripts/tests/*.gd` files resolve through `res://addons/aerobeat-tool-content-authoring/src/...`, `src/services/workflow/workout_package_yaml_codec.gd` and the placeholder `.import` metadata still point at `src/assets/placeholders/...`, and the repo head remains the narrow doc-follow-up commit on top of the main relink fix (`bd4c9ca` → `1a4235a`) (`REF-02`, `REF-03`). Existing coder/QA evidence for the passing headless flow remains consistent with these spot checks, and I found no remaining blocker in the touched scope.

---

## Final Results

**Status:** ✅ Complete

**What We Built:** The repo now truthfully reflects the post-move layout in the touched scope: runtime/plugin/services and placeholder asset references resolve through `src/`, the local `.testbed/` project consumes the package through its addon boundary successfully, and the README seam that previously named a stale root-level service path was corrected.

**Reference Check:** `REF-01`, `REF-02`, and `REF-03` are satisfied in the touched scope. The README now names the live `src/services/authoring/chart_authoring_service.gd` path, `.testbed/project.godot` + `.testbed/addons.jsonc` still describe the addon wiring accurately, and the spot-checked runtime/test files match the current `src/` + `.testbed/` contract.

**Commits:**
- `bd4c9ca` - Fix src-relative path relinks in testbed and runtime
- `1a4235a` - Fix README path seam after relink audit

**Lessons Learned:** For structural moves, final audit should explicitly compare docs, runtime paths, and testbed wiring together; the implementation can be correct while one stale path in a touched README section still leaves the repo’s layout story untruthful.

---

*Completed on 2026-06-03*
