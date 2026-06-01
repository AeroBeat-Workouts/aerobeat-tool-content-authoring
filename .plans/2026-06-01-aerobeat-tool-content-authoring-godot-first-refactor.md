# AeroBeat Tool Content Authoring Godot-First Refactor

**Date:** 2026-06-01  
**Status:** In Progress  
**Last Updated:** 2026-06-01 11:53 EDT  
**Blocked Reason:** None  
**Agent:** Pico

---

## Goal

Refactor `aerobeat-tool-content-authoring` from a CLI-first package tool into a Godot-engine-first content authoring system centered on a root-level singleton and a human-verifiable `.testbed` authoring UI that can create, save, load, preview, and validate workout packages.

---

## Overview

This refactor changes the repo's center of gravity. Today the repo still reflects a headless-first tool split with CLI entrypoints, root-level GodotEnv addon state, and tests living beside the package logic. The desired future state is a cleaner Godot-native package: the repo root exposes a stable `/src/` singleton API for workout authoring, while `.testbed/` becomes the primary human-verification surface where creators can author and validate real workout packages through a scene-driven workflow.

The main architectural shift is turning `src/AeroToolManager.gd` into `src/AeroContentAuthoring.gd`, promoted as the authoritative singleton for content authoring. That singleton should orchestrate package creation, package loading, package validation, and package export/import behaviors, while editor/testbed UI and any remaining automation surfaces become thin clients over the same service layer. The singleton must be able to create a valid new workout package and also load an existing packaged workout and confirm whether it is valid.

Because this work likely affects multiple AeroBeat repos, the plan includes an explicit cross-repo dependency audit and downstream sync pass. The refactor should not stop at local code movement; it must also verify how this repo is consumed elsewhere, update impacted integrations, and then run the GodotEnv sync workflow so dependent repos pick up the new package structure and singleton contract.

Per Derrick's execution instruction, the plan included an explicit pause after the audit phase completed. That pause is now cleared. Derrick confirmed the key architecture decisions: root `addons.jsonc` should be removed; `.testbed/addons/` and `.testbed/.addons/` should be locally generated and ignored via GodotEnv sync; `AeroContentAuthoring` should be a real singleton and fully runtime-capable for eventual use inside built `aerobeat-assembly-community`; CLI compatibility should be removed entirely; contract validation should flow through `aerobeat-content-core`; save should emit both an unarchived workout folder and a sibling zip archive side-by-side; load should target an unzipped workout folder; primary+fallback environments are now required canonical authored contract data; and video/audio preview dependencies are testbed-only verification aids rather than root package contract requirements.

---

## REFERENCES

| ID | Description | Path |
| --- | --- | --- |
| `REF-01` | New refactor plan | `.plans/2026-06-01-aerobeat-tool-content-authoring-godot-first-refactor.md` |
| `REF-02` | Current root singleton entrypoint to replace | `src/AeroToolManager.gd` |
| `REF-03` | Current product/tool-definition doc that still describes a headless-first stance | `docs/content-authoring-tool-definition.md` |
| `REF-04` | Current root dependency manifest slated for removal from repo root | `addons.jsonc` |
| `REF-05` | Existing testbed project root to expand into the primary human-verification surface | `.testbed/project.godot` |
| `REF-06` | Current repo README and public contract surface | `README.md` |
| `REF-07` | Core content contract repo that should own validation truth | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-content-core` |
| `REF-08` | Assembly/runtime target that will eventually host real creator-facing authoring flows | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-assembly-community` |
| `REF-09` | Device-driven environment fallback context | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-tool-device-detection` |
| `REF-10` | Environment loading/runtime swap behavior context | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-environment-loader` |
| `REF-11` | Testbed-only video preview dependency surface | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-tool-video-player` |
| `REF-12` | Testbed-only vendor video dependency surface | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-vendor-godot-video` |
| `REF-13` | Testbed-only audio preview dependency surface | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-tool-audio-player` |
| `REF-14` | Testbed-only vendor audio dependency surface | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-vendor-godot-audio` |

Use these IDs in execution notes and audit results.

---

## Tasks

### Task 1: Audit current repo structure, singleton boundaries, and downstream dependents

**Bead ID:** `aerobeat-tool-content-authoring-ptd`  
**SubAgent:** `primary`  
**Role:** `research`  
**References:** `REF-01`, `REF-02`, `REF-03`, `REF-04`, `REF-05`, `REF-06`  
**Prompt:** Claim the bead on start. Audit `aerobeat-tool-content-authoring` for all current CLI-first assumptions, root-level GodotEnv/addon layout usage, current singleton/service boundaries, `.testbed` usage, and every known downstream consumer or dependency touchpoint. Include likely cross-repo impacts for `aerobeat-assembly-community`, `aerobeat-content-core`, `aerobeat-tool-video-player`, `aerobeat-vendor-godot-video`, `aerobeat-tool-audio-player`, and `aerobeat-vendor-godot-audio`. Produce an execution-ready architecture note and consumer-impact list; do not edit code yet.

**Folders Created/Deleted/Modified:**
- `.plans/`
- `src/`
- `.testbed/`
- `cli/`
- `editor/`
- `tests/`

**Files Created/Deleted/Modified:**
- `.plans/2026-06-01-aerobeat-tool-content-authoring-godot-first-refactor.md`
- `src/AeroToolManager.gd`
- `docs/content-authoring-tool-definition.md`
- `README.md`
- `addons.jsonc`

**Status:** ✅ Complete

**Results:** Audit completed on 2026-06-01. Key findings: the repo is still materially CLI-first (`cli/main.gd`, `cli/commands/*.gd`, README/doc language, and tests centered on CLI/service calls), current write-path authoring is legacy-manifest-only (`services/authoring/chart_authoring_service.gd`, `cli/commands/author_command.gd`), `.testbed/` is only a minimal hidden import harness (`.testbed/project.godot`, `.testbed/addons.jsonc`) with no human authoring scene yet, and the current singleton boundary is a thin `src/AeroToolManager.gd` wrapper around `ContentAuthoringPlugin.build_service_registry()` rather than a real authoring state manager. Root/package layout assumptions are split between root `addons.jsonc` (published dependency contract) and `.testbed/addons.jsonc` (dev/test manifest), while local/generated addon trees still exist under repo root and testbed paths and are part of the planned cleanup surface. Downstream impact notes: this refactor will affect docs/demo-package expectations in `aerobeat-docs`, fixture/test coupling to `aerobeat-content-core`, and any future media-preview integration should follow the explicit collision-safe `.testbed` + facade patterns already documented in `aerobeat-tool-video-player`, `aerobeat-vendor-godot-video`, `aerobeat-tool-audio-player`, and `aerobeat-vendor-godot-audio`; `aerobeat-assembly-community` is less a direct consumer and more the contrasting assembly-level root-manifest exception. This is the required pause point before any coding work starts; after this audit is complete, summarize findings and wait for Derrick's sanity-check confirmation.

---

### Task 2: Define the Godot-first architecture and repo layout migration

**Bead ID:** `aerobeat-tool-content-authoring-apk`  
**SubAgent:** `primary`  
**Role:** `coder`  
**References:** `REF-01`, `REF-02`, `REF-03`, `REF-04`, `REF-05`, `REF-06`  
**Prompt:** Claim the bead on start. Based on the approved audit and Derrick's follow-up decisions, update the repo architecture so the root package is Godot-engine-first and runtime-capable: remove root-level `/addons/`, `/.addons/`, `addons.jsonc`, and all root-level GodotEnv state; update `.gitignore` so `.testbed/addons/` and `.testbed/.addons/` are treated as locally generated sync artifacts; preserve only what is needed inside `.testbed/`; define the new stable `/src/` API around a real singleton named `AeroContentAuthoring.gd`; and remove CLI as a first-class surface rather than preserving compatibility. Validation truth should be delegated toward `aerobeat-content-core`, and any architecture/documentation changes needed to support future runtime use inside `aerobeat-assembly-community` should be made explicit.

**Folders Created/Deleted/Modified:**
- `addons/`
- `.addons/`
- `src/`
- `.testbed/`
- `cli/`
- `editor/`

**Files Created/Deleted/Modified:**
- `addons.jsonc`
- `src/AeroToolManager.gd`
- `src/AeroContentAuthoring.gd`
- `plugin.cfg`
- `.gitignore`
- `README.md`
- `docs/content-authoring-tool-definition.md`
- `editor/plugins/content_authoring_plugin.gd`
- `.testbed/project.godot`
- `tests/run_tool_tests.gd`
- `tests/test_editor_uses_shared_services.gd`
- `tests/test_validate_command.gd`
- `tests/test_author_command.gd`

**Status:** ✅ Complete

**Results:** Completed the repo-layout migration on 2026-06-01. Root `addons.jsonc` was deleted and the repo no longer presents a root-level published GodotEnv package posture; `.gitignore` now treats only `.testbed/addons/` and `.testbed/.addons/` as local generated sync artifacts. The root singleton direction was made truthful by deleting `src/AeroToolManager.gd`, adding `src/AeroContentAuthoring.gd` as the new runtime-facing singleton, and changing `editor/plugins/content_authoring_plugin.gd` into a thin bridge over `AeroContentAuthoring.build_service_registry()` rather than the source of runtime truth. Public docs/config were rewritten from CLI-first/headless-first language to Godot-first/runtime-capable language, explicitly calling out `aerobeat-content-core` as validation truth, `.testbed` as the local verification surface, the save/load contract (save emits folder + sibling zip, load targets unzipped folder), canonical primary+fallback environment requirements, and media preview dependencies as testbed-only concerns. The first-class CLI surface was removed in this slice by deleting `cli/` and the CLI-only tests from the active runner. Validation run for this slice: `godot --headless --path .testbed --import` succeeded, a targeted Godot runtime smoke script confirmed `AeroContentAuthoring` initializes and exposes the expected service registry, and `git diff --check` passed. The legacy full test harness (`godot --headless --path .testbed --script ../tests/run_tool_tests.gd`) still fails because the existing out-of-project test setup hits global-class/preload collisions; that harness problem predates the runtime-direction change and should be addressed during the later `.testbed`-owned test migration. Remaining explicit seam for Task 3: `services/authoring/chart_authoring_service.gd` still contains quarantined legacy manifest/routine behavior and must be replaced by real workout-folder authoring behind `AeroContentAuthoring` rather than kept as compatibility surface.

---

### Task 3: Implement the `AeroContentAuthoring` singleton and package workflow API

**Bead ID:** `Pending`  
**SubAgent:** `primary`  
**Role:** `coder`  
**References:** `REF-01`, `REF-02`, `REF-03`, `REF-05`, `REF-06`  
**Prompt:** Claim the bead on start. Replace `AeroToolManager.gd` with `AeroContentAuthoring.gd` as the authoritative singleton for workout authoring. The singleton must be a real runtime-capable surface and expose structured operations for: creating a new workout package, loading an existing unzipped workout package folder into editable state, validating whether the loaded package is valid through `aerobeat-content-core` contract truth, saving a workout by emitting both an unarchived output folder and a sibling zip archive side-by-side at the chosen destination, and resetting authoring state before loading a different package. Keep UI strings out of the core logic and route authoring behavior through reusable services.

**Folders Created/Deleted/Modified:**
- `src/`
- `services/`
- `interfaces/`
- `mappers/`
- `editor/`

**Files Created/Deleted/Modified:**
- `src/AeroToolManager.gd`
- `src/AeroContentAuthoring.gd`
- `services/**`
- `interfaces/**`
- `mappers/**`
- `editor/**`

**Status:** ⏳ Pending

**Results:** Pending.

---

### Task 4: Move automated tests into `.testbed/` and build the testbed project skeleton

**Bead ID:** `Pending`  
**SubAgent:** `primary`  
**Role:** `coder`  
**References:** `REF-01`, `REF-05`  
**Prompt:** Claim the bead on start. Move the repo-root `/tests/` suite into `/.testbed/` and reorganize the testbed so it has clear `/assets/`, `/scenes/`, and `/scripts/` folders. Preserve or improve automated coverage while making `.testbed/` the canonical human-verifiable validation surface for authoring and package round-tripping.

**Folders Created/Deleted/Modified:**
- `tests/`
- `.testbed/`
- `.testbed/assets/`
- `.testbed/scenes/`
- `.testbed/scripts/`

**Files Created/Deleted/Modified:**
- `tests/**`
- `.testbed/project.godot`
- `.testbed/**/*.gd`
- `.testbed/**/*.tscn`
- `.testbed/**/*.tres`

**Status:** ⏳ Pending

**Results:** Pending.

---

### Task 5: Build the `ContentAuthoring` testbed scene and workflow tabs

**Bead ID:** `Pending`  
**SubAgent:** `primary`  
**Role:** `coder`  
**References:** `REF-01`, `REF-05`  
**Prompt:** Claim the bead on start. Build a Godot scene named `ContentAuthoring` inside `.testbed` that acts as the primary manual workflow surface. The top-level UI must provide tabs for `Metadata`, `Warm-Up Coaching`, `Sets`, and `Cool-Down Coaching`, with `Save Workout` and `Load Workout` actions in the top-right. `Save Workout` should create a workout folder, fill/write the relevant YAML files, copy required assets, and emit a sibling zip archive side-by-side at the user-selected location. `Load Workout` should accept an unzipped workout folder, clear current authoring state, import the loaded workout, and repopulate the scene from that data. The `Metadata` tab should be the default and use scrolling so the form remains usable at smaller sizes.

**Folders Created/Deleted/Modified:**
- `.testbed/scenes/`
- `.testbed/scripts/`
- `.testbed/assets/`

**Files Created/Deleted/Modified:**
- `.testbed/scenes/ContentAuthoring.tscn`
- `.testbed/scripts/content_authoring/**`
- `.testbed/assets/**`
- `.testbed/project.godot`

**Status:** ⏳ Pending

**Results:** Pending.

---

### Task 6: Implement set authoring, environment preview, and media-preview integrations

**Bead ID:** `Pending`  
**SubAgent:** `primary`  
**Role:** `coder`  
**References:** `REF-01`, `REF-05`  
**Prompt:** Claim the bead on start. Implement the set-authoring flow in the `Sets` tab: default to one set, allow creating/deleting sets, and reveal set-specific sub-tabs or equivalent lower-level tabs when a set is selected. Each set must support file-picker linking for Beatmap, primary Environment, fallback Environment, and coaching audio. Primary+fallback environment pairing is canonical contract data now; a set without a fallback environment is invalid, and a fallback may equal the primary environment ID. Beatmap selection should display parsed file metadata. Environment selection should preview the environment live in the scene background using the config sidecar's transform/fit_mode rules, with video environments autoplaying and looping. Warm-up and cool-down coaching must accept `.ogv` files and display metadata plus video preview using `aerobeat-tool-video-player` with `aerobeat-vendor-godot-video` as testbed-only verification dependencies. Coaching audio must provide play/pause, seek, and volume preview using `aerobeat-tool-audio-player` with `aerobeat-vendor-godot-audio` as testbed-only verification dependencies.

**Folders Created/Deleted/Modified:**
- `.testbed/scenes/`
- `.testbed/scripts/`
- `.testbed/assets/`
- `src/`
- `services/`

**Files Created/Deleted/Modified:**
- `.testbed/scripts/content_authoring/**`
- `.testbed/scenes/ContentAuthoring.tscn`
- `src/AeroContentAuthoring.gd`
- `services/**`
- dependency manifests/configuration as needed

**Status:** ⏳ Pending

**Results:** Pending.

---

### Task 7: Validate package round-tripping, audit downstream repos, and sync dependencies

**Bead ID:** `Pending`  
**SubAgent:** `primary`  
**Role:** `qa`  
**References:** `REF-01`, `REF-05`, `REF-06`  
**Prompt:** Claim the bead on start. Verify the full round-trip flow end to end: author a new workout in the `ContentAuthoring` scene, save it, confirm the exported zip contains the correct YAML/assets structure, load that saved workout back into a fresh scene state, and confirm the singleton reports the workout as valid. Then audit downstream repos/consumers for breakage caused by the Godot-first refactor, apply or document required follow-up updates, and run the relevant GodotEnv sync/update workflow so dependent repos consume the new state. Report all bugs discovered and either fix them in-scope or convert them into explicit follow-up work.

**Folders Created/Deleted/Modified:**
- `.testbed/`
- `src/`
- `services/`
- downstream repos as discovered during audit

**Files Created/Deleted/Modified:**
- `.testbed/**`
- `src/**`
- `services/**`
- repo docs and dependency config in this repo and impacted consumers

**Status:** ⏳ Pending

**Results:** Pending.

---

### Task 8: Independently audit completion and close the refactor slice

**Bead ID:** `Pending`  
**SubAgent:** `primary`  
**Role:** `auditor`  
**References:** `REF-01`, `REF-02`, `REF-03`, `REF-04`, `REF-05`, `REF-06`  
**Prompt:** Claim the bead on start. Perform an independent truth-check of the refactor. Confirm the repo root no longer contains the removed GodotEnv/addon files, `AeroContentAuthoring.gd` is the new singleton authority, `.testbed` now owns the test and manual validation surface, `ContentAuthoring` can save and load valid workout packages, media previews work to the agreed scope, and downstream sync fallout was handled explicitly. Close the bead only if the behavior matches the approved plan and references.

**Folders Created/Deleted/Modified:**
- `.plans/`
- `src/`
- `.testbed/`
- repo docs/config as needed for audit notes

**Files Created/Deleted/Modified:**
- `.plans/2026-06-01-aerobeat-tool-content-authoring-godot-first-refactor.md`
- audit evidence files if needed

**Status:** ⏳ Pending

**Results:** Pending.

---

## Final Results

**Status:** ⚠️ Partial

**What We Built:** Drafted the execution plan for a repo-wide Godot-first refactor centered on a new `AeroContentAuthoring` singleton and a `.testbed`-driven authoring/validation workflow.

**Reference Check:** Plan drafted against the current singleton entrypoint, tool-definition doc, root dependency manifest, existing `.testbed` project, and repo README. Cross-repo dependency references still need to be added during the audit task before implementation begins.

**Commits:**
- None yet.

**Lessons Learned:** This refactor is both an internal architecture migration and a workflow-contract migration. Treating `.testbed` as the primary human-verifiable surface should reduce ambiguity, but only if the singleton/service layer stays authoritative and downstream dependency fallout is audited explicitly.

---

*Completed on 2026-06-01*
