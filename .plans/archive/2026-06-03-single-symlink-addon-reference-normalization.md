# AeroBeat Tool Content Authoring Single Symlink Addon Reference Normalization

**Date:** 2026-06-03
**Status:** Complete  
**Last Updated:** 2026-06-03 21:36 EDT  
**Blocked Reason:** None
**Agent:** `byte`

---

## Goal

Ensure the testbed uses exactly one `aerobeat-tool-content-authoring` reference model: the single symlinked addon entry from `.testbed/addons.jsonc`, with no duplicate path forms creating parallel references to the same repo.

---

## Overview

I checked `.testbed/addons.jsonc` directly: it already has only one declared addon entry for `aerobeat-tool-content-authoring`, and it is a symlink entry pointing at `..`. So the issue is not duplicate JSON entries there.

The likely real seam is downstream reference normalization: some files currently access the repo through the addon-mounted path form (`res://addons/aerobeat-tool-content-authoring/...`) while others use the testbed-root form (`res://assets/...`). If your rule is that this repo should be referenced only through the single symlinked addon mount, then this pass should normalize the touched testbed/import/runtime references so there is only one conceptual path to this repo's assets/code from the testbed side.

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

**Status:** ✅ Complete

**Results:** Independently rechecked the touched scope against `REF-01` and `REF-04` before reproducing behavior. Evidence: `.testbed/addons.jsonc` still declares exactly one `aerobeat-tool-content-authoring` addon entry (`url: ".."`, `source: "symlink"`, `subfolder: "/"`) and no duplicate declaration; `src/services/workflow/workout_package_yaml_codec.gd:28` still points placeholder resolution at `res://addons/aerobeat-tool-content-authoring/.testbed/assets/placeholders`; current import metadata shows the two audio imports at `.testbed/assets/placeholders/blank-song.ogg.import:10` and `.testbed/assets/placeholders/blank-overlay.ogg.import:10` using `source_file="res://assets/placeholders/..."`, while `.testbed/assets/placeholders/blank-environment.png.import:9` uses the addon-mounted spelling. I then manually rewrote both `.ogg.import` `source_file` values to the addon-mounted form and reran the highest-fidelity repo-local validation used by the coder (`cd .testbed && godotenv addons install && godot --headless --path . --import && godot --headless --path . --script scripts/tests/run_tool_tests.gd`). Validation passed with exit code 0, and runtime evidence still favored the addon-mounted model where it matters: the test output's `draftAssetSources` resolved placeholder assets from `.testbed/addons/aerobeat-tool-content-authoring/.testbed/assets/placeholders/...`. However, after `godot --import`, both `.ogg.import` files were rewritten back to `source_file="res://assets/placeholders/blank-song.ogg"` and `source_file="res://assets/placeholders/blank-overlay.ogg"`. QA verdict: **qualified pass**. The repo already uses a single addon symlink declaration and addon-mounted runtime/source resolution in the functional path, but the touched scope cannot be fully normalized to one textual path spelling because Godot re-canonicalizes these two audio import metadata files back to testbed-root `res://assets/...` during reimport. This looks like Godot import canonicalization behavior, not a duplicate addon reference problem. Repo state after QA was clean except for this plan update; no durable source changes survived the reproduction run.

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

**Status:** ✅ Complete

**Results:** Audited the repo truth against `REF-01` and `REF-04`, the current tracked file state, the plan diff, and the coder/QA validation evidence already captured in this plan. Independent evidence confirmed that `.testbed/addons.jsonc` still contains exactly one declared addon entry for `aerobeat-tool-content-authoring` and that `src/services/workflow/workout_package_yaml_codec.gd:28` still uses the addon-mounted placeholder root as the functional runtime source of truth. The only remaining mixed spelling in the touched scope is the pair of audio import metadata files, `.testbed/assets/placeholders/blank-song.ogg.import:10` and `.testbed/assets/placeholders/blank-overlay.ogg.import:10`, which currently point at `res://assets/placeholders/...` while `.testbed/assets/placeholders/blank-environment.png.import:10` retains the addon-mounted form. Based on the reproduced coder/QA evidence, that split is not a second declared addon path model in repo-owned source-of-truth configuration; it is Godot re-canonicalization of generated import metadata during `godot --import`, and attempts to force those two files to the addon-mounted spelling are not durable. Audit verdict: the touched scope behaviorally honors the single-symlink addon reference rule because there is one addon declaration, one runtime placeholder source root, no duplicate addon registration, and no user-maintained parallel reference model that survives validation. The remaining `.ogg.import` spelling difference is acceptable as non-blocking engine-generated metadata, not a blocker.

---

## Final Results

**Status:** ✅ Complete

**What We Built:** We truth-checked the single-symlink addon reference normalization concern and confirmed the repo's touched scope is behaviorally complete without any further durable source edits. `.testbed/addons.jsonc` already held exactly one symlinked addon declaration for `aerobeat-tool-content-authoring`, and the runtime placeholder source root in `src/services/workflow/workout_package_yaml_codec.gd` already resolved through the addon-mounted path. The only remaining mixed path spelling lives in two `.ogg.import` metadata files that Godot rewrites back to `res://assets/placeholders/...` during `godot --import`; this is engine canonicalization of generated import metadata, not a second repo-maintained addon reference model.

**Reference Check:** `REF-01` satisfied: one addon declaration only. `REF-04` satisfied: runtime placeholder resolution uses the addon-mounted root. `REF-03` remained consistent with the relocated placeholder/import state described there. `REF-02` was not contradicted by the audited behavior. No deliberate behavioral deviations remain in the touched scope.

**Commits:**
- `9c541b9` - Document addon symlink normalization limits
- Auditor bookkeeping commit: `Finalize addon symlink normalization audit`

**Lessons Learned:** For this testbed, textual path uniformity inside tracked `.import` files is not a reliable completion criterion when Godot re-canonicalizes generated metadata on import. The real source-of-truth checks are the addon declaration count and the functional runtime resolution path, not whether every engine-generated import file preserves the addon-mounted spelling.

---

*Completed on 2026-06-03*
