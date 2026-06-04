# AeroBeat Tool Content Authoring Testbed Assets Relocation Correction

**Date:** 2026-06-03
**Status:** Complete
**Last Updated:** 2026-06-03 21:20 EDT
**Blocked Reason:** None
**Agent:** `byte`

---

## Goal

Move repo-owned testbed assets out of `src/assets/` and restore them to `.testbed/assets/`, then repair any references that should follow that ownership boundary.

---

## Overview

The prior cleanup normalized many path assumptions around the `src/` move, but you've called out a layout contract issue: `src/assets/` should not exist as the home for those assets. In this repo, those assets belong to the local testbed under `.testbed/assets/`, while `src/` should remain the runtime/plugin code tree.

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

**Results:** Moved the entire misplaced placeholder asset set out of `src/assets/placeholders/` into `.testbed/assets/placeholders/`: `blank-coaching-video.mp4`, `blank-environment.png`, `blank-environment.png.import`, `blank-overlay.ogg`, `blank-overlay.ogg.import`, `blank-song.ogg`, and `blank-song.ogg.import`. Updated `src/services/workflow/workout_package_yaml_codec.gd` so blank-package draft asset sources now resolve from `res://addons/aerobeat-tool-content-authoring/.testbed/assets/placeholders`, and updated the three tracked Godot `.import` metadata files so their `source_file` values match the new `.testbed` location. Updated `README.md` (`REF-01`) to remove the stale `src/assets/` runtime-tree claim and to state that placeholder verification assets live under `.testbed/assets/`, keeping the documented repo boundary aligned with `.testbed/project.godot` and `.testbed/addons.jsonc` (`REF-02`, `REF-03`). After the move, `src/assets/` was deleted because it was empty. Validation run: `cd .testbed && godotenv addons install`, then `godot --headless --path .testbed --import`, then `godot --headless --path .testbed --script scripts/tests/run_tool_tests.gd` - all succeeded with exit code 0, with the existing non-blocking Godot ObjectDB/resource-leak warnings still printed at shutdown.

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

**Status:** ✅ Complete

**Results:** QA independently verified the relocation and runtime resolution. Structural evidence: `find .testbed/assets -maxdepth 3 -type f | sort` showed all seven placeholder files under `.testbed/assets/placeholders/`, while checking `src/assets` confirmed the directory is absent. Reference/path evidence: `README.md` now documents `.testbed/assets/` as the placeholder asset home (`REF-01`), `src/services/workflow/workout_package_yaml_codec.gd` now points `PLACEHOLDER_SOURCE_ROOT` at `res://addons/aerobeat-tool-content-authoring/.testbed/assets/placeholders`, and `.testbed/addons.jsonc` (`REF-03`) still mounts this repo into `.testbed/addons/aerobeat-tool-content-authoring` via symlink, which resolves back to the same repo-local `.testbed/assets/placeholders/` files. Import metadata evidence: `.testbed/assets/placeholders/blank-environment.png.import` references the addon-mounted placeholder path directly, while the two `.ogg.import` files still use `res://assets/placeholders/...`; under `.testbed/project.godot` (`REF-02`) that `res://` root is the testbed project, so those audio import paths still resolve to the relocated `.testbed/assets/placeholders/*` files and did not break runtime loading. High-fidelity validation rerun from QA: `cd .testbed && godotenv addons install && godot --headless --path . --import && godot --headless --path . --script scripts/tests/run_tool_tests.gd` completed with exit code 0. The test output included the draft/runtime state proving relocated placeholder resolution through `draftAssetSources`, with all four placeholder media paths (`media/audio/blank-song.ogg`, `media/coaching/blank-overlay.ogg`, `media/coaching/blank-coaching-video.mp4`, `media/environments/blank-environment.png`) resolving to `.testbed/addons/aerobeat-tool-content-authoring/.testbed/assets/placeholders/*`, which realpaths back to the repo’s `.testbed/assets/placeholders/*`. Existing shutdown-only Godot ObjectDB/resource leak warnings still appeared after the suite, but they were non-blocking and identical in character to prior known warnings. No mismatches blocked QA.

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

**Status:** ✅ Complete

**Results:** Auditor reviewed the relocation commits (`5806087`, `e7a853f`), the tracked file state, and the QA/headless validation evidence. Repo truth in the touched scope is now correct: placeholder assets live only under `.testbed/assets/placeholders/`, `src/assets/` is absent, `README.md` (`REF-01`) now documents `.testbed/assets/` as the verification-asset home, and `src/services/workflow/workout_package_yaml_codec.gd` sources blank draft assets from `res://addons/aerobeat-tool-content-authoring/.testbed/assets/placeholders`, which resolves through `.testbed/addons.jsonc` (`REF-03`) back to the same repo-local files under the testbed project (`REF-02`). The QA-noted import metadata split was judged acceptable for closure, not a blocker: `.testbed/assets/placeholders/blank-environment.png.import` keeps an addon-mounted `source_file`, while the two `.ogg.import` files use `res://assets/placeholders/...` from the testbed project root; both path forms resolve to the same real files under `.testbed/assets/placeholders/`, neither path form points back into `src/`, and headless import/tests passed with exit code 0. Audit note: the mixed `.import` path style is mildly inconsistent and can leave duplicate ignored `.godot/imported/*` cache entries for the audio files, so normalizing those metadata paths later could reduce churn, but it is not required to make the ownership correction truthful or behaviorally complete.

---

## Final Results

**Status:** ✅ Complete

**What We Built:** Corrected the repo boundary so placeholder verification assets are owned by `.testbed/assets/placeholders/` instead of `src/assets/`, updated the documented/runtime references in the touched scope to match that ownership, and verified that local headless import/test flows still resolve those placeholders correctly.

**Reference Check:** `REF-01` now truthfully documents `.testbed/assets/` as the placeholder asset home; `REF-02` and `REF-03` still support both the testbed-root `res://assets/...` and addon-mounted `res://addons/aerobeat-tool-content-authoring/.testbed/assets/...` views of the same relocated files; `REF-04` remained satisfied as context only. The remaining mixed `.import` source-path style is a consistency nit, not an ownership or behavioral failure.

**Commits:**
- `5806087` - Move placeholder assets into testbed ownership
- `e7a853f` - Remove obsolete testbed asset placeholder gitkeep

**Lessons Learned:** In this testbed-mounted repo, ownership truth matters more than forcing one cosmetic `res://` spelling everywhere. When validating relocations, check both tracked references and ignored `.godot/imported/` behavior so harmless cache duplication does not get mistaken for a remaining source-of-truth bug.

---

*Completed on 2026-06-03*
