# AeroBeat BeatSaver Flow/Boxing Converter Foundation

**Date:** 2026-07-20  
**Status:** In Progress  
**Last Updated:** 2026-07-20 19:47 EDT  
**Blocked Reason:** Session wrap-up stop point: next session should execute the approved legacy compatibility order and also verify whether the `aerobeat-input-camera-tracking` regression seam was worked on.  
**Agent:** `pico`

---

## Goal

Build the first real BeatSaver -> AeroBeat converter foundation in the repo that owns authoring/runtime workflows so we can generate truthful Flow and Boxing song-package output for validation, debugging, and later gameplay use.

---

## Overview

We recovered the latest AeroBeat handoff from `/home/derrick/.openclaw/workspace/projects/openclaw-pico/handoffs/handoff-2026-07-20T13-06-00-04-00-aerobeat.md`. That handoff ended cleanly with no active plan and pointed the next session at a new repo-owned plan for the actual BeatSaver conversion lane.

This slice will use `aerobeat-tool-content-authoring` as the owning repo because `aerobeat-content-core` owns the durable package contracts, `aerobeat-vendor-beatsaver` owns provider-specific acquisition/staging, and `aerobeat-tool-content-authoring` owns the runtime/tool workflows that operate on those contracts. The first implementation target is a converter foundation that can ingest staged BeatSaver source truth, apply the locked Flow and Boxing conversion rules, emit canonical song-package-shaped output, and preserve provenance/debug artifacts rather than hiding conversion semantics in runtime-only logic. The converter should remain library-shaped so downstream consumers — especially the `aerobeat-vendor-beatsaver` testbed/workbench path — can exercise a truthful download -> convert -> validate flow without duplicating conversion logic in the vendor seam.

Execution will follow the normal loop on one bead: coder implements the foundation and repo-local validation, QA verifies the behavior at the package/workflow level, and auditor independently checks the result against the docs and produced artifacts before closure.

---

## REFERENCES

| ID | Description | Path |
| --- | --- | --- |
| `REF-01` | Latest AeroBeat handoff that defines the next slice | `/home/derrick/.openclaw/workspace/projects/openclaw-pico/handoffs/handoff-2026-07-20T13-06-00-04-00-aerobeat.md` |
| `REF-02` | Flow v1 BeatSaver conversion spec | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-docs/docs/architecture/beatsaver-flow-v1-conversion.md` |
| `REF-03` | Boxing v1 BeatSaver conversion spec | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-docs/docs/architecture/beatsaver-boxing-v1-conversion.md` |
| `REF-04` | Content-authoring repo boundary and runtime direction | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-tool-content-authoring/README.md` |
| `REF-05` | Shared canonical song-package/content validation contract | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-content-core/README.md` |

---

## Tasks

### Task 1: Build converter foundation

**Bead ID:** `aerobeat-tool-content-authoring-8ge`  
**SubAgent:** `primary` (for `coder`)  
**Role:** `coder`  
**References:** `REF-02`, `REF-03`, `REF-04`, `REF-05`  
**Prompt:** Implement the first BeatSaver -> AeroBeat converter foundation in `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-tool-content-authoring` against bead `aerobeat-tool-content-authoring-8ge`. Claim it on start with `bd update aerobeat-tool-content-authoring-8ge --status in_progress --json`. Use the Flow and Boxing conversion docs plus the content-authoring/content-core repo boundaries as truth. The output should establish the smallest honest end-to-end foundation that can ingest staged BeatSaver source truth, convert locked Flow and Boxing semantics into canonical song-package-shaped authored output, preserve provenance/debug artifacts, stay library-shaped for downstream reuse, and add/adjust tests or fixtures as needed. In particular, preserve a callable seam that a downstream `aerobeat-vendor-beatsaver` testbed can use for a truthful download -> convert -> validate flow without moving provider responsibilities into this repo. Run all relevant repo-local validation, commit, and push to `main` by default before handoff. Do not close the bead unless you are explicitly finishing the coder-owned implementation stage and the work is ready for QA handoff; include exact validation evidence and any open seams discovered.  

**Folders Created/Deleted/Modified:**
- `src/`
- `.testbed/`
- `src/services/`
- `src/mappers/`
- `src/docs/`

**Files Created/Deleted/Modified:**
- `README.md`
- `src/AeroContentAuthoring.gd`
- `src/services/importers/beatsaver_stage_conversion_service.gd`
- `src/services/packaging/build_content_package_service.gd`
- `src/services/validation/validate_chart_service.gd`
- `src/docs/beatsaver-converter-foundation.md`
- `.testbed/scripts/tests/test_beatsaver_stage_conversion_service.gd`
- `.testbed/scripts/tests/run_tool_tests.gd`
- `.testbed/assets/fixtures/beatsaver_stage_minimal/source_material_manifest.json`
- `.testbed/assets/fixtures/beatsaver_stage_minimal/demo-beatsaver-stage.zip`

**Status:** ✅ Complete  

**Results:** Coder implemented the first staged BeatSaver -> AeroBeat converter foundation and pushed commit `b367e68` (`Add BeatSaver conversion foundation`). The new runtime seam exposes `convert_beatsaver_stage_to_current_package(...)` on `src/AeroContentAuthoring.gd`, adds `src/services/importers/beatsaver_stage_conversion_service.gd`, preserves provenance/debug material under `.artifacts/beatsaver/...`, and adds a synthetic staged fixture plus headless end-to-end coverage in `.testbed/scripts/tests/test_beatsaver_stage_conversion_service.gd`. Repo-local validation passed via `godot --headless --path .testbed --script scripts/tests/run_tool_tests.gd`; Godot still emitted the pre-existing shutdown resource-leak warnings, but the functional suite passed. Current honest seam: Flow authored output is intentionally frozen to canonical `burst` beats only, while ordinary Flow notes, bombs, obstacles, and sliders remain preserved in conversion artifacts/reporting instead of being forced into an invented contract. References validated: `REF-02`, `REF-03`, `REF-04`, `REF-05`.

---

### Task 2: Verify converter foundation

**Bead ID:** `aerobeat-tool-content-authoring-8ge`  
**SubAgent:** `primary` (for `qa`)  
**Role:** `qa`  
**References:** `REF-02`, `REF-03`, `REF-04`, `REF-05`  
**Prompt:** Perform QA on bead `aerobeat-tool-content-authoring-8ge` in `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-tool-content-authoring` after coder handoff. Claim the bead if needed with `bd update aerobeat-tool-content-authoring-8ge --status in_progress --json`. Verify the new converter foundation end-to-end at the highest-fidelity repo-local level available: confirm the implemented workflow really converts staged BeatSaver-shaped source truth into canonical song-package-shaped output, confirm Flow and Boxing rules align with the locked docs, and confirm the seam is library-shaped enough for a downstream `aerobeat-vendor-beatsaver` testbed/workbench to exercise a truthful download -> convert -> validate path. Run the strongest available repo-local validation/manual package checks. Do not self-implement missing work; report gaps clearly with evidence. Do not close the bead; leave it ready for audit with exact verification notes.  

**Folders Created/Deleted/Modified:**
- verification-only if needed

**Files Created/Deleted/Modified:**
- verification notes only if needed

**Status:** ❌ Failed  

**Results:** QA verified that the staged BeatSaver fixture ingests successfully, `AeroContentAuthoring.convert_beatsaver_stage_to_current_package(...)` is library-shaped, validate -> save -> revalidate works repo-locally, and provenance/debug artifacts are preserved in the saved package and zip. However, QA found a blocking spec mismatch against `REF-03`: the Boxing row-family mapping is inverted. The locked doc requires top row `0..3` -> `uppercut`, middle row `4..7` -> `straight`, bottom row `8..11` -> `hook`, but the implementation currently maps top -> `hook`, middle -> `straight`, bottom -> `uppercut`. The current test fixture also bakes in the inverted behavior, so the suite passes while asserting non-canonical Boxing output. Non-blocking notes: current fixture evidence is synthetic v3 only, so claimed v4 support is not yet strongly evidenced by QA; Godot still emits the known shutdown leak warnings. References validated: `REF-02`, `REF-03`, `REF-04`, `REF-05`.

---

### Task 2A: Fix Boxing row-family mapping and test expectations

**Bead ID:** `aerobeat-tool-content-authoring-8ge`  
**SubAgent:** `primary` (for `coder`)  
**Role:** `coder`  
**References:** `REF-03`, `REF-04`, `REF-05`  
**Prompt:** Fix bead `aerobeat-tool-content-authoring-8ge` in `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-tool-content-authoring` by correcting the Boxing row-family mapping to match the locked Boxing v1 conversion spec: top row `0..3` -> `uppercut`, middle row `4..7` -> `straight`, bottom row `8..11` -> `hook`. Update both normal Boxing note conversion and Boxing burst row sampling if they share the same mapper, and correct the automated test fixture expectations so the suite enforces canonical Boxing output instead of the inverted mapping. Re-run the strongest repo-local validation, commit, and push to `main` before handoff. Keep the existing honest Flow seam unchanged unless the fix truly requires otherwise. Do not close the bead; report exact files changed, validation results, and commit/push status.  

**Folders Created/Deleted/Modified:**
- `src/services/importers/`
- `.testbed/scripts/tests/`

**Files Created/Deleted/Modified:**
- `src/services/importers/beatsaver_stage_conversion_service.gd`
- `.testbed/scripts/tests/test_beatsaver_stage_conversion_service.gd`
- any tightly related repo-local docs/tests only if required by the fix

**Status:** ✅ Complete  

**Results:** Coder fixed the blocking Boxing row-family defect and pushed commit `f353bc6` (`Fix Boxing row family mapping`). `src/services/importers/beatsaver_stage_conversion_service.gd` now maps top row `0..3` -> `uppercut`, middle row `4..7` -> `straight`, bottom row `8..11` -> `hook`, and Boxing burst row sampling follows the same shared mapping path. `.testbed/scripts/tests/test_beatsaver_stage_conversion_service.gd` was updated so the suite now enforces the canonical Boxing output instead of the previously inverted expectation. Repo-local validation passed again via `godot --headless --path .testbed --script scripts/tests/run_tool_tests.gd`; the usual shutdown leak/resource warnings remain non-blocking noise. References validated: `REF-03`, `REF-04`, `REF-05`.

---

### Task 2B: Re-check corrected Boxing mapping

**Bead ID:** `aerobeat-tool-content-authoring-8ge`  
**SubAgent:** `primary` (for `qa`)  
**Role:** `qa`  
**References:** `REF-03`, `REF-04`, `REF-05`  
**Prompt:** Re-check bead `aerobeat-tool-content-authoring-8ge` in `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-tool-content-authoring` after commit `f353bc6` (`Fix Boxing row family mapping`). Verify that Boxing note conversion and Boxing burst row sampling now match the locked Boxing spec exactly, and confirm the updated test expectations are asserting canonical output rather than encoding another mistaken mapping. Re-run the strongest repo-local validation needed to prove the fix. Do not self-implement; report exact evidence and whether the bead is now ready for audit. Do not close the bead.  

**Folders Created/Deleted/Modified:**
- verification-only if needed

**Files Created/Deleted/Modified:**
- verification notes only if needed

**Status:** ✅ Complete  

**Results:** QA re-check confirmed commit `f353bc6` corrected the Boxing mapping defect. Code now matches `REF-03` exactly: top row `0..3` -> `uppercut`, middle row `4..7` -> `straight`, bottom row `8..11` -> `hook`. Boxing burst row sampling also follows the same canonical mapping through the shared mapper path, updated test expectations now assert canonical Boxing output, and repo-local validation still passes via `godot --headless --path .testbed --script scripts/tests/run_tool_tests.gd`. QA also inspected actual emitted conversion-report output and confirmed single notes plus burst beats resolve to the expected hook/straight/uppercut sequence across bottom/middle/top rows. Remaining non-blockers: the known Godot shutdown leak/resource warnings persist, and fixture evidence is still synthetic v3-focused rather than broad real-world/v4 coverage. References validated: `REF-03`, `REF-04`, `REF-05`.

---

### Task 3: Audit converter foundation

**Bead ID:** `aerobeat-tool-content-authoring-8ge`  
**SubAgent:** `primary` (for `auditor`)  
**Role:** `auditor`  
**References:** `REF-01`, `REF-02`, `REF-03`, `REF-04`, `REF-05`  
**Prompt:** Independently audit bead `aerobeat-tool-content-authoring-8ge` in `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-tool-content-authoring`. Review the coder diff, validation output, QA evidence, and the produced package/converter truth against the references. Confirm the repo choice and seam boundaries remain truthful. If the work passes, close the bead with `bd close aerobeat-tool-content-authoring-8ge --reason "BeatSaver converter foundation implemented, verified, and audited" --json`. If it fails, do not close it; report the exact gap and evidence.  

**Folders Created/Deleted/Modified:**
- audit-only if needed

**Files Created/Deleted/Modified:**
- audit notes only if needed

**Status:** ❌ Failed  

**Results:** Auditor independently confirmed the repo choice, converter seam, provenance preservation, and honest Flow burst-only authored surface, but found one remaining blocking mismatch against `REF-03`: same-hand simultaneous Boxing note clusters currently resolve row-count ties incorrectly. The Boxing spec requires same-color simultaneous groups to choose the highest row on ties, but the implementation currently prefers the larger row index (bottom over middle/top). The current synthetic fixture encodes that wrong `hook_left` expectation, so the suite still passes while masking the spec mismatch. Non-blocking risks remain the same: fixture evidence is still synthetic/v3-focused and the known Godot shutdown leak/resource warnings persist. The bead remains open.

---

### Task 3A: Fix Boxing same-hand tie resolution and test expectation

**Bead ID:** `aerobeat-tool-content-authoring-8ge`  
**SubAgent:** `primary` (for `coder`)  
**Role:** `coder`  
**References:** `REF-03`, `REF-04`, `REF-05`  
**Prompt:** Fix bead `aerobeat-tool-content-authoring-8ge` in `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-tool-content-authoring` by correcting same-hand simultaneous Boxing note cluster tie handling to match the locked Boxing v1 conversion spec. For same-color simultaneous groups, when row counts tie, the highest row must win. Audit evidence indicates the current implementation in `src/services/importers/beatsaver_stage_conversion_service.gd` prefers the larger row index instead, causing a bottom-row `hook_left` to win where a middle/top row should win. Correct the implementation and update `.testbed/scripts/tests/test_beatsaver_stage_conversion_service.gd` (and only tightly related fixtures/tests if needed) so the automated suite catches the spec-canonical tie behavior. Re-run the strongest repo-local validation, commit, and push to `main` before handoff. Keep the existing Flow seam and already-correct Boxing row-family mapping unchanged unless truly necessary. Do not close the bead; report exact files changed, validation results, and commit/push status.  

**Folders Created/Deleted/Modified:**
- `src/services/importers/`
- `.testbed/scripts/tests/`

**Files Created/Deleted/Modified:**
- `src/services/importers/beatsaver_stage_conversion_service.gd`
- `.testbed/scripts/tests/test_beatsaver_stage_conversion_service.gd`
- any tightly related repo-local docs/tests only if required by the fix

**Status:** ✅ Complete  

**Results:** Coder fixed the remaining Boxing same-hand simultaneous tie-resolution defect and pushed commit `f6548fc` (`Fix Boxing same-hand cluster tie resolution`). Same-color simultaneous groups now count rows, keep the dominant row, and on ties keep the higher row per `REF-03`. `.testbed/scripts/tests/test_beatsaver_stage_conversion_service.gd` was updated so the synthetic fixture now expects the canonical `straight_left` outcome instead of the previously masked `hook_left` error. Repo-local validation passed again via `godot --headless --path .testbed --script scripts/tests/run_tool_tests.gd`; the known shutdown leak/resource warnings remain non-blocking noise. References validated: `REF-03`, `REF-04`, `REF-05`.

---

### Task 4: Freeze minimum Flow v1 authored contract

**Bead ID:** `Pending approval packet`  
**SubAgent:** `primary` (for `research`)  
**Role:** `research`  
**References:** `REF-02`, `REF-04`, `REF-05`  
**Prompt:** Draft the minimum honest Flow v1 authored-contract approval packet that unblocks non-burst BeatSaver Flow conversion. The packet should define which Flow BeatSaver source families become canonical authored objects now, which remain artifact-only, the required fields for each approved authored object type, and whether the contract must land in `aerobeat-content-core` before further converter expansion. Keep the proposal as small and truthful as possible.  

**Folders Created/Deleted/Modified:**
- planning/docs only if approved

**Files Created/Deleted/Modified:**
- approval packet / follow-up contract docs to be determined after Derrick review

**Status:** ✅ Complete  

**Results:** Derrick approved the full Flow v1 authored contract freeze, including `note.angleOffset`, `bomb`, occupancy-based `obstacle`, and source-semantic `arc` objects with `headCurveMultiplier`, `tailCurveMultiplier`, `midAnchorMode`, and optional `startNoteRef` / `endNoteRef`. The shared contract then landed, passed QA, and passed audit in `aerobeat-content-core` under commit `18db07e` (`Freeze Flow v1 shared authored contract`). That approval gate is now resolved and downstream converter work in this repo is unblocked.

---

### Task 5: Expand Flow converter to emit shared contract objects

**Bead ID:** `aerobeat-tool-content-authoring-5nm`  
**SubAgent:** `primary` (for `coder`)  
**Role:** `coder`  
**References:** `REF-02`, `REF-04`, `REF-05`  
**Prompt:** Expand the BeatSaver Flow converter in `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-tool-content-authoring` against bead `aerobeat-tool-content-authoring-5nm` so it emits the newly landed shared Flow v1 contract instead of remaining `burst`-only on the authored side. Claim it on start with `bd update aerobeat-tool-content-authoring-5nm --status in_progress --json`. Consume the shared contract shape now frozen in `aerobeat-content-core` commit `18db07e`. Emit canonical Flow `note`, `burst`, `bomb`, `obstacle`, and `arc` objects with truthful mapping from staged BeatSaver source, including `note.angleOffset`, occupancy-based obstacles, and source-semantic arc fields plus optional note-link refs where applicable. Preserve raw source/conversion artifacts under `.artifacts/beatsaver/...`, keep repo boundaries truthful, update repo-local tests/fixtures/docs as needed, run the strongest repo-local validation, commit, and push to `main` before handoff. Do not close the bead; report exact files changed, validation evidence, and any still-open seams.  

**Folders Created/Deleted/Modified:**
- `src/services/importers/`
- `.testbed/scripts/tests/`
- `.testbed/assets/fixtures/`
- `src/docs/`

**Files Created/Deleted/Modified:**
- `src/services/importers/beatsaver_stage_conversion_service.gd`
- `src/services/validation/validate_chart_service.gd`
- `.testbed/scripts/tests/test_beatsaver_stage_conversion_service.gd`
- `.testbed/assets/fixtures/beatsaver_stage_minimal/demo-beatsaver-stage.zip`
- `.testbed/assets/fixtures/beatsaver_stage_minimal/source_material_manifest.json`
- `README.md`
- `src/docs/beatsaver-converter-foundation.md`

**Status:** ✅ Complete  

**Results:** Coder expanded the Flow converter to emit the full shared Flow v1 contract and pushed commit `8bb7c80` (`Emit full Flow v1 BeatSaver conversion output`). `BeatSaverStageConversionService` now emits canonical Flow `note`, `burst`, `bomb`, `obstacle`, and `arc` objects from staged BeatSaver source, including `note.angleOffset`, occupancy-based `obstacle.cells`, and source-semantic `arc` fields plus optional `startNoteRef` / `endNoteRef` when exact endpoint note matches exist. The synthetic staged fixture/test now proves full shared-contract Flow emission instead of burst-only behavior, and docs were updated to remove the stale burst-only limitation. Repo-local validation passed via `godot --headless --path .testbed --script scripts/tests/run_tool_tests.gd`. QA then independently verified the saved package output, artifact preservation, and direct field truth against the shared contract from `aerobeat-content-core@18db07e`, including real emitted `note`, `burst`, `bomb`, `obstacle`, and `arc` objects plus `delegatedValidator: "aerobeat-content-core"` on the good delegated path. Remaining non-blocking cautions from QA: evidence is still mostly synthetic and v3-oriented, and broader real-world/v4 map coverage is still pending. References validated: `REF-02`, `REF-04`, `REF-05`.

---

### Task 6: Remove local Flow-validator drift by delegating to shared contract truth

**Bead ID:** `aerobeat-tool-content-authoring-96r`  
**SubAgent:** `primary` (for `coder`)  
**Role:** `coder`  
**References:** `REF-04`, `REF-05`  
**Prompt:** In `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-tool-content-authoring`, eliminate the local-vs-shared Flow validator drift risk against bead `aerobeat-tool-content-authoring-96r`. Claim it on start with `bd update aerobeat-tool-content-authoring-96r --status in_progress --json`. Replace the repo-local mirrored Flow chart-shape validation path with direct use of the shared `aerobeat-content-core` validator truth wherever runtime/package validation currently reports `delegatedValidator: "local"` for this surface. Keep repo boundaries truthful, update tests/fixtures/docs as needed to prove delegation is real, run the strongest repo-local validation, commit, and push to `main` before handoff. Do not close the bead; report exact files changed, validation evidence, and any remaining delegation caveats.  

**Folders Created/Deleted/Modified:**
- `src/services/validation/`
- `.testbed/scripts/tests/`
- `src/docs/`

**Files Created/Deleted/Modified:**
- `src/services/validation/validate_chart_service.gd`
- `src/services/validation/song_package_validation_service.gd`
- `src/services/importers/beatsaver_stage_conversion_service.gd`
- `src/services/workflow/song_package_yaml_codec.gd`
- `.testbed/scripts/tests/test_beatsaver_stage_conversion_service.gd`
- `README.md`
- `src/docs/beatsaver-converter-foundation.md`

**Status:** ❌ Failed  

**Results:** QA confirmed that direct Flow chart validation now genuinely delegates to `aerobeat-content-core`, exposes `delegatedValidator: "aerobeat-content-core"`, and fails explicitly with `flow_validator_unavailable` when the shared chart validator is forced unavailable. It also confirmed `durationSec` is truthful on the staged fixture (`7`, matching `ceil(maxBeatEnd 13.0 * 60 / bpm 120)`). However, QA found a remaining truth gap at the aggregate/package-validation level: when the shared content-core validator is forced unavailable, package validation can still silently fall back to `delegatedValidator: "local"` and report `valid: true` with no issues. That means the no-silent-fallback requirement is not yet satisfied across higher-level validation/report surfaces. References validated: `REF-04`, `REF-05`.

---

### Task 6A: Remove package-level silent fallback and expose shared delegation truth

**Bead ID:** `aerobeat-tool-content-authoring-96r`  
**SubAgent:** `primary` (for `coder`)  
**Role:** `coder`  
**References:** `REF-04`, `REF-05`  
**Prompt:** Fix bead `aerobeat-tool-content-authoring-96r` in `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-tool-content-authoring` by removing the remaining silent local fallback in aggregate/package-level validation surfaces when the shared `aerobeat-content-core` validator is unavailable. QA proved direct chart-level delegation is correct, but forced-unavailable package validation still reports `delegatedValidator: "local"`, `valid: true`, and no issues. Make package-level validation/reporting fail explicitly or otherwise surface unavailable shared-validator truth instead of silently passing via local fallback. Keep the direct shared delegation path intact, update tests/probes/docs as needed to prove the higher-level behavior is truthful, run the strongest repo-local validation, commit, and push to `main` before handoff. Do not close the bead; report exact files changed, validation evidence, and any remaining delegation caveats.  

**Folders Created/Deleted/Modified:**
- `src/services/validation/`
- `.testbed/scripts/tests/`
- `src/docs/`

**Files Created/Deleted/Modified:**
- `src/services/validation/song_package_validation_service.gd`
- tightly related validation/report wiring files as needed
- `.testbed/scripts/tests/test_beatsaver_stage_conversion_service.gd`
- probe/verification script(s) if needed
- `README.md`
- `src/docs/beatsaver-converter-foundation.md`

**Status:** ✅ Complete  

**Results:** Coder removed the remaining package-level silent fallback and pushed commit `d9e9004` (`Fail package validation when shared validator is unavailable`). `SongPackageValidationService` now reports `delegatedValidator: "unavailable"`, returns `valid: false`, and emits explicit issue code `content_core_package_validator_unavailable` when the shared package validator cannot be loaded, instead of falling through to a false local success path. A targeted failure-mode test was added in `.testbed/scripts/tests/test_validate_package_failure_modes.gd`, full repo-local validation passed via `godot --headless --path .testbed --script scripts/tests/run_tool_tests.gd`, and a focused forced-unavailable probe confirmed the new failure behavior while direct chart-level delegation to `aerobeat-content-core` remained intact. References validated: `REF-04`, `REF-05`.

---

### Task 6B: Re-check package-level unavailable-validator behavior

**Bead ID:** `aerobeat-tool-content-authoring-96r`  
**SubAgent:** `primary` (for `qa`)  
**Role:** `qa`  
**References:** `REF-04`, `REF-05`  
**Prompt:** Re-check bead `aerobeat-tool-content-authoring-96r` in `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-tool-content-authoring` after commit `d9e9004` (`Fail package validation when shared validator is unavailable`). Verify that package-level validation no longer silently falls back to local success when the shared `aerobeat-content-core` validator is unavailable, and confirm direct chart-level delegation to `aerobeat-content-core` is still intact. Re-run the strongest repo-local validation and inspect the focused failure-mode evidence. Do not self-implement. Do not close the bead. Report whether the delegation seam is now ready for audit.  

**Folders Created/Deleted/Modified:**
- verification-only if needed

**Files Created/Deleted/Modified:**
- verification notes only if needed

**Status:** ✅ Complete  

**Results:** QA re-check after `d9e9004` confirmed that package-level validation no longer silently falls back to local success when the shared `aerobeat-content-core` validator is unavailable. The targeted validator re-check showed three truthful states: normal local package validation on the known-good fixture still passes, delegated package validation through `aerobeat-content-core` reports `delegatedValidator: "aerobeat-content-core"` and passes, and forced-unavailable shared package validation now reports `valid: false`, `delegatedValidator: "unavailable"`, and issue code `content_core_package_validator_unavailable`. Direct Flow chart delegation to `aerobeat-content-core` remained observable and valid. References validated: `REF-04`, `REF-05`.

---

### Task 6C: Audit shared-validator delegation + no-silent-fallback behavior

**Bead ID:** `aerobeat-tool-content-authoring-96r`  
**SubAgent:** `primary` (for `auditor`)  
**Role:** `auditor`  
**References:** `REF-04`, `REF-05`  
**Prompt:** Independently audit bead `aerobeat-tool-content-authoring-96r` in `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-tool-content-authoring` after commit `d9e9004`. Verify that direct Flow chart validation delegates to shared `aerobeat-content-core` truth, package-level validation no longer silently falls back to local success when the shared validator is unavailable, explicit unavailable-validator failure truth is surfaced at the package/report level, and repo boundaries stayed clean. Close the bead if it passes.  

**Folders Created/Deleted/Modified:**
- audit-only if needed

**Files Created/Deleted/Modified:**
- audit notes only if needed

**Status:** ✅ Complete  

**Results:** Auditor independently verified the implementation diff, runtime behavior, and boundary truth, then closed bead `aerobeat-tool-content-authoring-96r` with reason `Flow validation delegates to shared content-core truth and package validation fails explicitly when unavailable`. Audit confirmed direct Flow chart validation now loads `aerobeat-content-core/data_types/chart.gd`, package validation surfaces `coreValidation` and explicit unavailable-state failure truth instead of local-success fallback, and the dangerous local/shared drift behavior is removed for the validated Flow surface. Remaining non-blocking risks: Godot still emits shutdown leak/resource warnings after headless runs, and evidence for this seam is still largely synthetic-fixture based. References validated: `REF-04`, `REF-05`.

---

### Task 5A: Audit full shared-contract Flow emission

**Bead ID:** `aerobeat-tool-content-authoring-5nm`  
**SubAgent:** `primary` (for `auditor`)  
**Role:** `auditor`  
**References:** `REF-02`, `REF-04`, `REF-05`  
**Prompt:** Independently audit bead `aerobeat-tool-content-authoring-5nm` in `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-tool-content-authoring`. Verify that the BeatSaver Flow converter now truthfully emits canonical shared-contract `note`, `burst`, `bomb`, `obstacle`, and `arc` objects from staged source, that the emitted fields align with `aerobeat-content-core` commit `18db07e`, that provenance/debug artifacts remain preserved under `.artifacts/beatsaver/...`, and that repo boundaries stayed clean. Pay attention to the remaining non-blocking cautions: synthetic/v3-heavy evidence and the need for broader real-world/v4 coverage. If the work passes, close the bead with `bd close aerobeat-tool-content-authoring-5nm --reason "Full Flow v1 BeatSaver conversion output implemented, verified, and audited" --json`. If it fails, do not close it; report the exact gap and evidence.  

**Folders Created/Deleted/Modified:**
- audit-only if needed

**Files Created/Deleted/Modified:**
- audit notes only if needed

**Status:** ✅ Complete  

**Results:** Auditor independently verified that the BeatSaver Flow converter now truthfully emits canonical shared-contract `note`, `burst`, `bomb`, `obstacle`, and `arc` objects from staged source, that emitted fields align with `aerobeat-content-core` commit `18db07e`, that provenance/debug artifacts remain preserved under `.artifacts/beatsaver/...`, and that repo boundaries stayed clean. The auditor then closed bead `aerobeat-tool-content-authoring-5nm` with reason `Full Flow v1 BeatSaver conversion output implemented, verified, and audited`. Remaining non-blocking risks for this seam: evidence is still mostly synthetic and v3-heavy, broader real-world BeatSaver coverage is still pending, and explicit v4-focused normalization confidence still needs stronger fixtures. References validated: `REF-02`, `REF-04`, `REF-05`.

---

### Task 7: Broaden real-world BeatSaver coverage and v4 normalization evidence

**Bead ID:** `aerobeat-tool-content-authoring-gc1`  
**SubAgent:** `primary` (for `coder`)  
**Role:** `coder`  
**References:** `REF-02`, `REF-04`, `REF-05`  
**Prompt:** In `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-tool-content-authoring`, broaden BeatSaver conversion confidence against bead `aerobeat-tool-content-authoring-gc1`. Claim it on start with `bd update aerobeat-tool-content-authoring-gc1 --status in_progress --json`. Focus on the two approved next seams: (1) broader real-world BeatSaver map coverage and (2) explicit v4-oriented normalization coverage. Add the smallest honest set of additional fixtures/tests/probes needed to prove the converter and shared-validator path across more realistic BeatSaver inputs, including meaningful v4 object normalization checks for Flow/Boxing where applicable. Preserve repo boundaries, keep raw source/conversion artifacts truthful, run the strongest repo-local validation, commit, and push to `main` before handoff. Do not close the bead; report exact files changed, what new coverage was added, validation evidence, and any remaining compatibility gaps.  

**Folders Created/Deleted/Modified:**
- `.testbed/assets/fixtures/`
- `.testbed/scripts/tests/`
- `src/docs/`

**Files Created/Deleted/Modified:**
- new BeatSaver fixtures/tests/probes as needed
- `README.md` / `src/docs/beatsaver-converter-foundation.md` only if coverage truth changes
- tightly related converter files only if required by legit normalization fixes

**Status:** ✅ Complete  

**Results:** Coder broadened BeatSaver conversion confidence and pushed commit `b90859d` (`Add BeatSaver v4 and real-world conversion coverage`). The converter now supports normalized v4 beat object payloads for `colorNotes/colorNotesData`, `bombNotes/bombNotesData`, `obstacles/obstaclesData`, `arcs/arcsData`, and `chains/chainsData`. A new synthetic staged v4 fixture and automated test now prove both Flow shared-validator behavior and Boxing authored output, and a focused real-world probe against the staged BeatSaver `524b6` Starlight artifact from `aerobeat-vendor-beatsaver` adds broader map coverage. That real-world probe exposed a legitimate normalization bug: some off-grid BeatSaver obstacles normalized into empty Flow obstacle cell lists; coder fixed this by clamping obstacle occupancy to the nearest playable grid edge instead of emitting invalid empty obstacles. Repo-local validation passed via `godot --headless --path .testbed --script scripts/tests/run_tool_tests.gd` and the real-world probe `godot --headless --path .testbed --script scripts/tests/probe_beatsaver_stage_conversion_real_world_v3.gd`. QA then independently verified that the v4 normalization families are real, the synthetic v4 fixture is meaningful, the Starlight probe truly runs through the shared-contract validation path, and the obstacle fix eliminated empty `cells: []` output in inspected synthetic-v4 and Starlight flow charts. Remaining non-blocking gaps: v4 sidecar/info/audio ecosystem handling is still not broad, and real-world coverage still centers on one substantial staged v3 artifact. References validated: `REF-02`, `REF-04`, `REF-05`.

---

### Task 7A: Audit broader real-world/v4 coverage slice

**Bead ID:** `aerobeat-tool-content-authoring-gc1`  
**SubAgent:** `primary` (for `auditor`)  
**Role:** `auditor`  
**References:** `REF-02`, `REF-04`, `REF-05`  
**Prompt:** Independently audit bead `aerobeat-tool-content-authoring-gc1` in `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-tool-content-authoring`. Verify that broader real-world BeatSaver coverage and explicit v4 normalization evidence are now truthful: v4 object families are genuinely normalized, the synthetic v4 fixture proves meaningful Flow/Boxing outcomes, the staged Starlight `524b6` probe truly runs through the shared-contract path, and the off-grid obstacle normalization fix prevents invalid empty Flow obstacle cells. Treat broader real-world v4 diversity and v4 sidecar/info/audio ecosystem coverage as potential non-blocking risks unless they invalidate the claimed slice. If the work passes, close the bead with `bd close aerobeat-tool-content-authoring-gc1 --reason "Real-world BeatSaver and v4 normalization coverage implemented, verified, and audited" --json`. If it fails, do not close it; report the exact gap and evidence.  

**Folders Created/Deleted/Modified:**
- audit-only if needed

**Files Created/Deleted/Modified:**
- audit notes only if needed

**Status:** ✅ Complete  

**Results:** Auditor independently verified that v4 object-family normalization is truly wired for `colorNotes/colorNotesData`, `bombNotes/bombNotesData`, `obstacles/obstaclesData`, `arcs/arcsData`, and `chains/chainsData`; that the synthetic v4 fixture/test proves meaningful Flow and Boxing outcomes rather than serving as a smoke test; that the staged Starlight `524b6` probe is real and validates through the shared-contract path; and that the off-grid obstacle normalization fix prevents invalid empty Flow obstacle cells. Auditor then closed bead `aerobeat-tool-content-authoring-gc1` with reason `Real-world BeatSaver and v4 normalization coverage implemented, verified, and audited`. Remaining non-blocking risks: real-world coverage is still centered on one substantial staged v3 map, v4 ecosystem breadth beyond core beat-object families is still limited, and Godot headless runs still emit known shutdown warnings. References validated: `REF-02`, `REF-04`, `REF-05`.

---

### Task 8: Broaden BeatSaver map-family diversity and v4 ecosystem coverage

**Bead ID:** `aerobeat-tool-content-authoring-djk`  
**SubAgent:** `primary` (for `coder`)  
**Role:** `coder`  
**References:** `REF-02`, `REF-04`, `REF-05`  
**Prompt:** In `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-tool-content-authoring`, continue the approved BeatSaver conversion hardening path against bead `aerobeat-tool-content-authoring-djk`. Claim it on start with `bd update aerobeat-tool-content-authoring-djk --status in_progress --json`. Focus on the next explicit risk-reduction seams exposed by Task 7 audit: (1) broaden real-world BeatSaver map-family diversity beyond the single staged Starlight probe, and (2) broaden v4 ecosystem coverage beyond core beat-object normalization, including meaningful sidecar/custom-data/audio-info permutations when they affect truthful conversion/package validation. Add the smallest honest fixtures/probes/tests needed, preserve repo boundaries and raw source/conversion artifacts, and only change converter logic if new coverage reveals a real issue worth fixing now. Run the strongest repo-local validation, commit, and push to `main` before handoff. Do not close the bead; report exact files changed, what new diversity/coverage was added, validation evidence, and any still-open compatibility gaps.  

**Folders Created/Deleted/Modified:**
- `.testbed/assets/fixtures/`
- `.testbed/scripts/tests/`
- `src/docs/`

**Files Created/Deleted/Modified:**
- new fixtures/tests/probes as needed
- `README.md` / `src/docs/beatsaver-converter-foundation.md` only if coverage truth changes
- tightly related converter files only if required by legit compatibility fixes

**Status:** ✅ Complete  

**Results:** Coder broadened BeatSaver map-family diversity and v4 ecosystem coverage and pushed commit `fe0fd68` (`Broaden BeatSaver v4 and map-family coverage`). New real-world map-family coverage now includes a staged real legacy v2 BeatSaver map (`succducc - me & u`) that proves honest unsupported-v2 rejection via `unsupported_beatmap_version` rather than fake support claims. New v4 ecosystem coverage now includes an actual-v4 `Info.dat` fixture proving nested `song` / `audio` / `difficultyBeatmaps` parsing, primary-vs-preview audio handling, and non-Standard sidecar/custom-data permutations without widening support dishonestly. The new coverage revealed a real gap, so the converter gained v4-aware helpers for `song.title`, `audio.bpm`, `audio.songFilename`, and Standard difficulty selection from v4 `difficultyBeatmaps`, while preserving existing v2/v3-style paths and fallback behavior. Repo-local validation passed via `godot --headless --path .testbed --script scripts/tests/run_tool_tests.gd` and `godot --headless --path .testbed --script scripts/tests/probe_beatsaver_stage_conversion_real_world_v3.gd`. QA then independently verified that the real legacy v2 staged map is genuine and truthfully rejected, that the actual-v4 `Info.dat` fixture really proves nested metadata/audio/difficultyBeatmaps parsing plus bounded non-Standard sidecar behavior, that the new v4-aware helpers are real and preserve existing v2/v3-style behavior, and that docs/tests do not overclaim support. Remaining honest gaps: legacy v2 conversion remains unsupported by design, real-world successful coverage is still centered on staged v3 Starlight, and v4 sidecars are still only covered where they affect truthful package selection/validation rather than preserved as first-class authored artifacts. References validated: `REF-02`, `REF-04`, `REF-05`.

---

### Task 9: Plan legacy-audio and legacy-beatmap support expansion

**Bead ID:** `aerobeat-tool-content-authoring-433`  
**SubAgent:** `primary` (for `research`)  
**Role:** `research`  
**References:** `REF-02`, `REF-04`, `REF-05`  
**Prompt:** In `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-tool-content-authoring`, plan the next compatibility expansion path against bead `aerobeat-tool-content-authoring-433`. Claim it on start with `bd update aerobeat-tool-content-authoring-433 --status in_progress --json`. Produce the smallest honest implementation plan for the newly approved seams: (1) support `.jpg`/`.jpeg` cover-art import, (2) preserve/import preview audio into AeroBeat packages for menu preview use, (3) design the legacy `.egg` -> `.ogg` conversion seam, likely via a new `aerobeat-vendor-ffmpeg` repo with pinned ffmpeg assets under `/assets/` and a root singleton script under `/src/` exposing a function like `convert_egg_to_ogg_audio`, and (4) assess/support legacy BeatSaver/Beat Saber v1/v2 payloads so the conversion lane aims for blanket BeatSaver package coverage where practical. Also determine whether lowercase `info.dat` is merely a case-tolerant archive lookup gap, whether v1 can fall out of a v2 parser path or needs separate treatment, and what should remain explicitly unsupported even after this expansion. Keep the plan bounded and truthful before coding.  

**Folders Created/Deleted/Modified:**
- planning/docs only for now

**Files Created/Deleted/Modified:**
- to be determined by the planning result

**Status:** ✅ Complete  

**Results:** Research/planning completed on bead `aerobeat-tool-content-authoring-433` and left a concrete handoff in the bead notes. Main conclusions: lowercase `info.dat` is already effectively handled via case-tolerant archive lookup and is not a major new architecture seam; `.jpg/.jpeg` cover-art import is a small next implementation slice; preview-audio preservation/import is a real open seam that may need a small `aerobeat-content-core` contract decision first; legacy `.egg` -> `.ogg` conversion should likely live in a new `aerobeat-vendor-ffmpeg` repo with pinned ffmpeg assets and a singleton wrapper API; and legacy v1/v2 support should be treated as an explicit legacy normalization adapter path rather than assumed to fall out of current v3/v4 handling. Recommended implementation order from the planning pass: (1) cover-art import from staged archives, (2) preview-audio preservation/import, (3) legacy v2/v1 metadata+difficulty normalization, (4) legacy v2/v1 beat-object normalization into the current internal source summary, then (5) the `aerobeat-vendor-ffmpeg` seam once exact legacy audio requirements are proven. References validated: `REF-02`, `REF-04`, `REF-05`.

---

### Task 8A: Audit map-family diversity and v4 ecosystem coverage slice

**Bead ID:** `aerobeat-tool-content-authoring-djk`  
**SubAgent:** `primary` (for `auditor`)  
**Role:** `auditor`  
**References:** `REF-02`, `REF-04`, `REF-05`  
**Prompt:** Independently audit bead `aerobeat-tool-content-authoring-djk` in `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-tool-content-authoring`. Verify that the real legacy v2 staged map is genuine and truthfully rejected as unsupported, that the actual-v4 `Info.dat` fixture really proves nested `song` / `audio` / `difficultyBeatmaps` parsing plus bounded primary-vs-preview audio and non-Standard sidecar/custom-data behavior, that the new v4-aware helpers are real and preserve existing v2/v3-style behavior, and that repo boundaries/docs/tests remain honest and bounded. Treat the remaining legacy-v2 unsupported status, limited real-world successful v4 diversity, and limited sidecar preservation as non-blocking risks unless they invalidate the claimed slice. If the work passes, close the bead with `bd close aerobeat-tool-content-authoring-djk --reason "BeatSaver map-family diversity and v4 ecosystem coverage implemented, verified, and audited" --json`. If it fails, do not close it; report the exact gap and evidence.  

**Folders Created/Deleted/Modified:**
- audit-only if needed

**Files Created/Deleted/Modified:**
- audit notes only if needed

**Status:** ✅ Complete  

**Results:** Auditor independently verified that the real legacy v2 staged map is genuine and truthfully rejected as unsupported, that the actual-v4 `Info.dat` fixture really proves nested `song` / `audio` / `difficultyBeatmaps` parsing plus bounded primary-vs-preview audio and non-Standard sidecar/custom-data behavior, that the new v4-aware helpers are real and preserve existing v2/v3-style behavior, and that repo boundaries/docs/tests remained honest and bounded. Auditor then closed bead `aerobeat-tool-content-authoring-djk` with reason `BeatSaver map-family diversity and v4 ecosystem coverage implemented, verified, and audited`. Remaining non-blocking risks: legacy v2 conversion is still unsupported by design, successful real-world conversion breadth is still narrow, v4 sidecars/custom-data are only handled where needed for truthful selection/validation, and Godot headless runs still emit known shutdown warnings. References validated: `REF-02`, `REF-04`, `REF-05`.

---

## Final Results

**Status:** ⚠️ Partial

**What We Built:** The converter foundation in `aerobeat-tool-content-authoring` is now structurally sound for staged source ingestion, provenance preservation, Boxing mapping truth, full shared-contract Flow object emission, direct delegation of Flow validation to shared `aerobeat-content-core` truth without silent package-level fallback, broader real-world BeatSaver coverage, and broader v4 normalization/info-sidecar evidence. The next seam is no longer implementation hardening of the current surface; it is planning support expansion for legacy audio, lowercase `info.dat`, and legacy v2 beatmaps.

**Reference Check:** `REF-01` satisfied for handoff recovery and next-slice selection. `REF-02`..`REF-05` were used across implementation, QA, audit, the downstream contract freeze, validator-delegation follow-up, and broader coverage hardening. Boxing mapping defects found against `REF-03` were fixed, the shared Flow contract exists under `aerobeat-content-core` commit `18db07e`, and the follow-on beads `aerobeat-tool-content-authoring-5nm`, `aerobeat-tool-content-authoring-96r`, `aerobeat-tool-content-authoring-gc1`, and `aerobeat-tool-content-authoring-djk` are now audited closed.

**Commits:**
- `b367e68` - Add BeatSaver conversion foundation
- `f353bc6` - Fix Boxing row family mapping
- `f6548fc` - Fix Boxing same-hand cluster tie resolution
- downstream shared-contract dependency landed in `aerobeat-content-core`: `18db07e` - Freeze Flow v1 shared authored contract
- `8bb7c80` - Emit full Flow v1 BeatSaver conversion output
- `c32c00d` - Delegate Flow chart validation to content-core
- `d9e9004` - Fail package validation when shared validator is unavailable

**Lessons Learned:** Converter work should not invent private Flow truth ahead of the shared contract. Now that the contract is frozen and audited upstream, the approved continuation is to teach this repo to emit the full shared Flow object surface instead of keeping non-burst Flow semantics in artifacts only.

---

*Completed on 2026-07-20*
