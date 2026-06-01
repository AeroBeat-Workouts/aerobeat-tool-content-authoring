# AeroBeat Tool Content Authoring Blank-New Authoring Completion

**Date:** 2026-06-01
**Status:** In Progress
**Last Updated:** 2026-06-01 15:03 EDT
**Blocked Reason:** None
**Agent:** Pico

---

## Goal

Close the remaining blank-new authoring gap so `AeroContentAuthoring` can create a validator-clean workout package from empty state, not just load/edit/save an existing canonical package.

---

## Overview

The Godot-first refactor landed successfully, but the final audit found one material incompleteness: blank-new authoring does not yet produce a validator-clean package end to end. Right now the workflow is real for loading an existing canonical package, editing it, saving it, reloading it, and validating it. What is still missing is the from-scratch path: creating a new package state that seeds enough canonical structure and linkage to save a valid package without relying on a preexisting fixture.

This follow-up slice is specifically about finishing that new-package path. The work should seed the required baseline package structure and records, make authoring/import flows populate the minimum required workout/set/song/chart/environment relationships, and ensure save/export emits a validator-clean package from a blank-new session. The goal is not deep chart editing or additional UX polish; it is correctness and completeness for fresh package creation.

This slice should stay tightly scoped to the remaining truth gap identified by the auditor. The desired outcome is that the next independent audit can truthfully say the singleton can both create a valid new workout package and validate/edit existing ones.

---

## REFERENCES

| ID | Description | Path |
| --- | --- | --- |
| `REF-01` | Follow-up plan for blank-new authoring completion | `.plans/2026-06-01-aerobeat-tool-content-authoring-blank-new-authoring-completion.md` |
| `REF-02` | Prior Godot-first refactor plan showing the remaining gap | `.plans/2026-06-01-aerobeat-tool-content-authoring-godot-first-refactor.md` |
| `REF-03` | Current runtime singleton | `src/AeroContentAuthoring.gd` |
| `REF-04` | Current workflow serialization layer | `services/workflow/workout_package_yaml_codec.gd` |
| `REF-05` | Current workflow service | `services/workflow/workout_package_workflow_service.gd` |
| `REF-06` | Current validation seam | `services/validation/workout_package_validation_service.gd` |
| `REF-07` | Testbed workflow shell | `.testbed/scenes/ContentAuthoring.tscn` |
| `REF-08` | Core contract repo | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-content-core` |

---

## Tasks

### Task 1: Audit the blank-new authoring gap and define required seed data

**Bead ID:** `aerobeat-tool-content-authoring-kbh`
**SubAgent:** `primary`
**Role:** `research`
**References:** `REF-01`, `REF-02`, `REF-03`, `REF-04`, `REF-05`, `REF-06`, `REF-08`
**Prompt:** Claim the bead on start. Audit the current blank-new authoring path and identify the exact missing records, linkage fields, seeded files, and workflow assumptions that prevent `AeroContentAuthoring.create_new_workout_package(...)` from producing a validator-clean package. Produce an execution-ready list of required seed content and authoring-state transitions. Do not broaden scope beyond the fresh-package validity gap.

**Folders Created/Deleted/Modified:**
- `.plans/`
- `src/`
- `services/`
- `.testbed/`

**Files Created/Deleted/Modified:**
- `.plans/2026-06-01-aerobeat-tool-content-authoring-blank-new-authoring-completion.md`
- `src/AeroContentAuthoring.gd`
- `services/workflow/**`
- `services/validation/**`
- `.testbed/scripts/tests/**`

**Status:** ✅ Complete

**Results:** Audit complete. Current blank-new state is structurally insufficient for validator-clean save/export: `create_blank_package_state()` seeds `workout` plus disabled `coachConfig`, and `AeroContentAuthoring._normalize_state_for_authoring()` injects a single default set (`ab-set-001`), but leaves songs/charts/environments/sql empty and leaves the set unlinked (`songId`, `chartId`, `preferredEnvironmentId`, `fallbackEnvironmentId`, and serialized `environmentId` absent/blank). On save, `write_package_state()` always emits `workout.yaml`, `coaches/coach-config.yaml`, and `sets/*.yaml`, but it only copies SQL from `sourcePackageDir` via `sqlFiles`, so blank-new currently has no path to emit a required `sql/*.schema.sql` file at all. The current saved blank package therefore fails local validation with the expected families of issues: missing workout identity/config fields (`workoutId`, `workoutName`, `coachConfigId` when not explicitly seeded), missing songs/charts/environments/sql families, missing/blank set linkage fields, and the authoring-layer `missing_preferred_environment_ref` / `missing_fallback_environment_ref` rules; the content-core validator would additionally fail the same package on unresolved `songId`/`chartId`/`environmentId` and missing `coachConfigId` reference.

Execution-ready seeding recommendation: new-package creation should immediately seed one fully linked minimal package slice, not an empty graph. That slice should include: (1) a non-empty workout record with stable default `workoutId`, human default `workoutName`, `packageVersion`, `coachConfigId`, and `setOrder` containing the seeded set id; (2) one seeded set record whose `songId`, `chartId`, `preferredEnvironmentId`, `fallbackEnvironmentId`, and mirrored `environmentId` all point at seeded records; (3) one seeded song record with valid timing structure (`anchorMs`, one `tempoSegments` entry, empty `stopSegments`, one `timeSignatureSegments` entry) and an `audio.filePath` that resolves to a packaged placeholder audio asset; (4) one seeded chart record with a canonical supported feature/difficulty (simplest path: boxing/medium) and at least one validator-legal beat entry; (5) one seeded environment record with a packaged placeholder background asset and type/path alignment; (6) one seeded SQL schema file, ideally `sql/workouts.db.schema.sql`, containing at least one `CREATE TABLE` and one `CREATE INDEX`; and (7) one seeded enabled coach config with a stable `coachConfigId`, one featured coach, placeholder warmup/cooldown media refs, one overlay audio record, and the seeded set’s `coachingOverlayId` pointing at that overlay. Under the current validator contract, keeping coaching disabled is not enough for a validator-clean blank package because `workout.yaml` still requires a resolvable `coachConfigId`, while disabled coach config is intentionally minimal and carries no id; the lowest-risk path is therefore to seed enabled coaching plus placeholder media, not to weaken the contract.

Lazy-vs-immediate split: create the minimum valid slice immediately on `create_new_workout_package(...)`; defer only optional or user-replacement content. Immediate seed should cover exactly the canonical records/files needed for a clean validation pass and save/export from empty state. Lazy creation/replacement is appropriate for additional sets, additional songs/charts/environments, preview art, optional environment `configPath`, user-imported beatmaps/audio/video/image assets, and richer metadata/provenance fields. Implementation note: the workflow layer needs an explicit blank-new seed path for authored file payloads, not just record dictionaries. Today media can be copied from `draftAssetSources`, but SQL cannot because `sqlFiles` is source-dir-only; the implementation should add a first-class seeded artifact mechanism for both binary/text template assets (or equivalent repo template sources) so blank-new save can materialize SQL plus placeholder audio/image/video assets without relying on `sourcePackageDir`. Validation adjustment recommendation: keep current validation behavior as-is unless the team explicitly wants to redefine the package contract around disabled coaching. For this slice, the cleaner fix is to make the authoring seed path satisfy the existing contract rather than relaxing validators.

---

### Task 2: Implement validator-clean blank package seeding and linkage

**Bead ID:** `aerobeat-tool-content-authoring-nw1`
**SubAgent:** `primary`
**Role:** `coder`
**References:** `REF-01`, `REF-03`, `REF-04`, `REF-05`, `REF-06`, `REF-08`
**Prompt:** Claim the bead on start. Implement the from-scratch package path so a newly created authoring state seeds the minimum canonical structure needed for a validator-clean package. Ensure required workout/set/song/chart/environment/coach/sql/linkage fields are populated appropriately, and keep the runtime singleton/service workflow authoritative.

**Folders Created/Deleted/Modified:**
- `assets/`
- `src/`
- `services/`
- `.testbed/`

**Files Created/Deleted/Modified:**
- `assets/placeholders/blank-song.ogg`
- `assets/placeholders/blank-overlay.ogg`
- `assets/placeholders/blank-coaching-video.mp4`
- `assets/placeholders/blank-environment.png`
- `src/AeroContentAuthoring.gd`
- `services/workflow/workout_package_yaml_codec.gd`
- `.testbed/scripts/tests/run_tool_tests.gd`
- `.testbed/scripts/tests/test_aero_content_authoring_workflow.gd`
- `.testbed/scripts/tests/test_blank_new_package_seed_save_reload.gd`

**Status:** ✅ Complete

**Results:** Implemented validator-clean blank-new seeding in the workflow/codec path rather than weakening validation. `create_blank_package_state()` now seeds one fully linked minimal package slice immediately: workout + one set + one song + one chart + one environment + one enabled coach config + one SQL schema file. The seeded set carries `songId`, `chartId`, `preferredEnvironmentId`, `fallbackEnvironmentId`, mirrored `environmentId`, and `coachingOverlayId`; the workout gets non-empty `workoutId` / `workoutName` / `packageVersion` / `coachConfigId` / `setOrder`; the song gets minimal valid timing plus packaged placeholder audio; the chart gets a validator-legal one-beat boxing/medium beatmap; the environment gets a valid `image_background` + `.png` placeholder pairing; the coach config gets warmup/cooldown placeholder videos plus one overlay audio entry; and the package now emits canonical `sql/workouts.schema.sql` from new `draftTextSources` support instead of requiring `sourcePackageDir`. Added committed placeholder media under `assets/placeholders/` so blank-new save remains self-contained inside the addon repo, and extended `.testbed` coverage with `test_blank_new_package_seed_save_reload.gd` plus updated workflow assertions so fresh blank create/save/reload/validate is exercised explicitly. Validation on this coder slice: `godot --headless --path .testbed --import` ✅, `godot --headless --path .testbed --script res://scripts/tests/run_tool_tests.gd` ✅, and `godot --headless --path .testbed --script res://scripts/tests/smoke_content_authoring_scene.gd` ✅. Non-blocking note: the suite still prints existing Godot ObjectDB/resource leak warnings at exit, but the processes exit 0 and the new blank-new coverage passes.

---

### Task 3: QA fresh-package creation end to end

**Bead ID:** `Pending`
**SubAgent:** `primary`
**Role:** `qa`
**References:** `REF-01`, `REF-03`, `REF-05`, `REF-06`, `REF-07`
**Prompt:** Claim the bead on start. Verify that a brand-new package can be created from empty state, saved, reloaded, and validated cleanly through the real `.testbed` workflow and runtime singleton. Report exact evidence and convert any remaining failures into explicit follow-up work.

**Folders Created/Deleted/Modified:**
- `.testbed/`
- `src/`
- `services/`

**Files Created/Deleted/Modified:**
- `.testbed/scripts/tests/**`
- `src/**`
- `services/**`

**Status:** ⏳ Pending

**Results:** Pending.

---

### Task 4: Independent audit and closure

**Bead ID:** `Pending`
**SubAgent:** `primary`
**Role:** `auditor`
**References:** `REF-01`, `REF-02`, `REF-03`, `REF-04`, `REF-05`, `REF-06`, `REF-07`, `REF-08`
**Prompt:** Claim the bead on start. Independently verify that blank-new authoring is now validator-clean end to end, that the saved package structure is canonical, and that the earlier audit gap is truly closed. Close the bead only if the follow-up slice is fully complete.

**Folders Created/Deleted/Modified:**
- `.plans/`
- `.testbed/`
- `src/`
- `services/`

**Files Created/Deleted/Modified:**
- `.plans/2026-06-01-aerobeat-tool-content-authoring-blank-new-authoring-completion.md`
- `.testbed/scripts/tests/**`
- `src/**`
- `services/**`

**Status:** ⏳ Pending

**Results:** Pending.

---

## Final Results

**Status:** ⚠️ Partial

**What We Built:** Drafted the follow-up completion plan for the remaining blank-new authoring validity gap.

**Reference Check:** Pending execution.

**Commits:**
- None yet.

**Lessons Learned:** Existing-package round-trip and blank-new package creation are separate truths; both need explicit verification.

---

*Completed on 2026-06-01*
