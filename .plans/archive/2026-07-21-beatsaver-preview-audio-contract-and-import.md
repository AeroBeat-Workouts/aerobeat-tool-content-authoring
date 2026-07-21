# AeroBeat BeatSaver Preview Audio Contract and Import

**Date:** 2026-07-21  
**Status:** Complete  
**Last Updated:** 2026-07-21 08:36 EDT  
**Blocked Reason:** None  
**Agent:** `pico`

---

## Goal

Land the next approved BeatSaver compatibility seam by freezing the shared preview-audio contract and then importing/preserving BeatSaver preview audio truth in AeroBeat packages without widening scope into legacy beatmap/audio conversion yet.

---

## Overview

We recovered the latest AeroBeat handoff from `/home/derrick/.openclaw/workspace/projects/openclaw-pico/handoffs/handoff-2026-07-20T21-35-00-04-00-aerobeat.md`. That handoff points at the BeatSaver compatibility lane, but its linked plan at `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-tool-content-authoring/.plans/2026-07-20-beatsaver-flow-boxing-converter-foundation.md` is now complete rather than active. The next seam is still clear: preview-audio preservation/import first, with the small shared-contract decision in `aerobeat-content-core` resolved before importer work expands in `aerobeat-tool-content-authoring`.

This plan stays intentionally narrow. It does not widen into legacy v2/v1 metadata normalization, legacy beat-object conversion, or `.egg` -> `.ogg` transcoding. The target is now the full agreed preview-truth set: (1) a packaged/local preview-audio locator for downloaded packages, (2) preserved BeatSaver preview URL truth for undownloaded/menu-preview scenarios, (3) preserved preview timing fields (`previewStartTime`, `previewDuration`), and (4) one AeroBeat-authored playback decision field (`previewMode`) so the engine follows the converter’s chosen rule instead of re-deriving precedence at runtime.

Because the work spans `aerobeat-content-core` and `aerobeat-tool-content-authoring`, this repo-local plan serves as the parent coordination record for the compatibility lane while child beads in the owning repos track execution.

---

## REFERENCES

| ID | Description | Path |
| --- | --- | --- |
| `REF-01` | Latest AeroBeat canonical handoff | `/home/derrick/.openclaw/workspace/projects/openclaw-pico/handoffs/handoff-2026-07-20T21-35-00-04-00-aerobeat.md` |
| `REF-02` | Completed BeatSaver converter foundation plan with preview-audio planning result | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-tool-content-authoring/.plans/2026-07-20-beatsaver-flow-boxing-converter-foundation.md` |
| `REF-03` | Shared content contract repo | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-content-core/README.md` |
| `REF-04` | Importer/runtime repo boundary | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-tool-content-authoring/README.md` |
| `REF-05` | Current BeatSaver converter docs | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-tool-content-authoring/src/docs/beatsaver-converter-foundation.md` |

---

## Tasks

### Task 1: Freeze shared preview-audio contract

**Bead ID:** `aerobeat-content-core-398`  
**SubAgent:** `primary` (for `research` / `coder`)  
**Role:** `research`  
**References:** `REF-01`, `REF-02`, `REF-03`, `REF-04`  
**Prompt:** In `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-content-core`, produce and, if clearly approved by existing planning truth, land the smallest honest shared contract change needed for BeatSaver preview-audio support. Resolve the exact canonical field(s) for (a) local packaged preview-audio location and (b) preserved provider/source preview URL truth. Keep the slice bounded: no preview timing/clip semantics, no transcoding, no legacy beatmap widening. Update shared docs/tests/validators only as needed to make the contract durable and truthful. Claim the bead on start and report whether the contract is ready for downstream importer work.

**Folders Created/Deleted/Modified:**
- `README.md`
- `data_types/`
- `validators/`
- shared fixtures/tests as needed

**Files Created/Deleted/Modified:**
- `data_types/song.gd`
- `validators/content_package_validator.gd`
- `tests/run_contract_tests.gd`
- `tests/test_song_preview_audio_contract.gd`
- `fixtures/song_package_yaml_valid_splat_with_preview_audio/`
- `README.md`

**Status:** ✅ Complete

**Results:** Coder/research landed the initial shared preview-audio contract in `aerobeat-content-core` and pushed commit `3b5eaca` (`Freeze preview audio song contract`). The shared contract now names `song.audio.previewFilePath` as the canonical packaged/local preview-audio locator and `song.audio.previewUrl` as the preserved provider/source preview URL field. The implementation also added YAML normalization symmetry so `previewFilePath` yields `previewResourcePath` internally like the existing `filePath` -> `resourcePath` bridge. After Derrick’s follow-up review of actual Beat Saber/BeatSaver preview semantics, this initial contract slice is now intentionally superseded by the approved expansion in Task 1A so timing fields and one AeroBeat-authored playback decision field are carried too. The bead was intentionally left open for QA/audit handoff rather than being closed early.

---

### Task 1A: Extend shared preview contract with timing + AeroBeat previewMode

**Bead ID:** `aerobeat-content-core-idd`  
**SubAgent:** `primary` (for `coder`)  
**Role:** `coder`  
**References:** `REF-01`, `REF-02`, `REF-03`, `REF-04`  
**Prompt:** In `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-content-core`, extend the just-landed preview-audio contract against bead `aerobeat-content-core-idd`. Claim it on start with `bd update aerobeat-content-core-idd --status in_progress --json`. Preserve the already-approved fields `song.audio.previewFilePath` and `song.audio.previewUrl`, and add the remaining agreed preview-truth fields `song.audio.previewStartTime`, `song.audio.previewDuration`, plus one AeroBeat-authored decision field `song.audio.previewMode`. `previewMode` is not BeatSaver source truth; it is the converter’s chosen playback rule so the engine does not re-derive precedence at runtime. Keep the enum small, behavior-oriented, and truthful. Update shared docs/tests/validators only as needed, keep the slice bounded (no transcoding, no legacy widening, no preview editing semantics), run relevant validation, commit, and push to `main` before handoff. Leave the bead open unless you are explicitly instructed to close it after QA/audit.

**Folders Created/Deleted/Modified:**
- `README.md`
- `data_types/`
- shared fixtures/tests as needed

**Files Created/Deleted/Modified:**
- `README.md`
- `data_types/song.gd`
- `fixtures/song_package_yaml_valid_splat_with_preview_audio/songs/ab-song-splat-demo.yaml`
- `tests/test_song_preview_audio_contract.gd`

**Status:** ✅ Complete

**Results:** Coder extended the shared preview contract in `aerobeat-content-core` and pushed commit `1724978` (`Extend preview audio contract timing fields`). The shared contract now carries the full agreed set: `song.audio.previewFilePath`, `song.audio.previewUrl`, `song.audio.previewStartTime`, `song.audio.previewDuration`, and the AeroBeat-authored playback decision field `song.audio.previewMode`. The chosen `previewMode` enum is intentionally small and behavior-oriented: `song_file_clip`, `preview_file`, and `preview_url`. Validation rules now require preview path/url fields to be non-empty strings when present, `previewStartTime` / `previewDuration` to be numeric when present, and `previewMode` to be one of the approved enum values. The preview fixture/test now proves timing + mode preservation as well as continued `previewFilePath` -> `previewResourcePath` normalization. Validation passed via `godot --headless --path .testbed --script res://../tests/run_contract_tests.gd`. The bead was intentionally left open for QA/audit handoff. Downstream importer rule set from this slice: use `preview_file` when a dedicated packaged preview asset exists, `song_file_clip` when runtime should play a window from the main song using timing fields, and `preview_url` when runtime should use preserved provider/source preview URL truth.

---

### Task 1B: QA shared preview contract timing + previewMode

**Bead ID:** `aerobeat-content-core-2i7`  
**SubAgent:** `primary` (for `qa`)  
**Role:** `qa`  
**References:** `REF-01`, `REF-02`, `REF-03`, `REF-04`  
**Prompt:** In `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-content-core`, QA the expanded preview contract against bead `aerobeat-content-core-2i7`. Claim it on start with `bd update aerobeat-content-core-2i7 --status in_progress --json`. Verify that the shared contract truth is durable and bounded: `song.audio.previewFilePath`, `previewUrl`, `previewStartTime`, `previewDuration`, and `previewMode` all validate/preserve correctly; `previewFilePath` still normalizes to `previewResourcePath`; and invalid preview timing/mode values are rejected. Re-run the strongest relevant contract validation and inspect the fixture/test truth as needed. Do not self-implement missing work; report exact evidence and whether the slice is ready for audit.

**Folders Created/Deleted/Modified:**
- verification-only if needed

**Files Created/Deleted/Modified:**
- verification notes only if needed

**Status:** ✅ Complete

**Results:** QA re-check on commit `eb15290` confirmed the shared preview contract is now durable and bounded. The full contract suite passed via `godot --headless --path .testbed --script res://../tests/run_contract_tests.gd`. The shared fixture and test preserve `previewFilePath`, `previewUrl`, `previewStartTime`, `previewDuration`, and `previewMode` exactly; `previewFilePath` still normalizes to `previewResourcePath`; invalid timing values are now rejected (`song_audio_preview_start_time_invalid_value` for negative start, `song_audio_preview_duration_invalid_value` for negative or zero duration); invalid `previewMode` values are still rejected (`song_audio_invalid_preview_mode`); and `README.md` remains bounded to the contract slice without overclaiming importer/transcoding/runtime behavior. QA marked the shared contract seam ready for audit.

---

### Task 1B Retry: Reject invalid preview timing values

**Bead ID:** `aerobeat-content-core-dr3`  
**SubAgent:** `primary` (for `coder`)  
**Role:** `coder`  
**References:** `REF-01`, `REF-02`, `REF-03`, `REF-04`  
**Prompt:** In `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-content-core`, fix the shared preview contract against bead `aerobeat-content-core-dr3`. Claim it on start with `bd update aerobeat-content-core-dr3 --status in_progress --json`. QA found that invalid preview timing values are still accepted: negative `previewStartTime`, negative `previewDuration`, and zero-duration cases pass validation. Tighten the shared contract so invalid preview timing values are rejected truthfully, update tests/fixtures/docs only as needed, keep the slice bounded, run the strongest relevant contract validation, commit, and push to `main` before handoff. Do not close the bead; leave it ready for QA re-check with exact evidence.

**Folders Created/Deleted/Modified:**
- `data_types/`
- `tests/`
- docs only if needed

**Files Created/Deleted/Modified:**
- `data_types/song.gd`
- `tests/test_song_preview_audio_contract.gd`

**Status:** ✅ Complete

**Results:** Coder landed the bounded validation fix in `aerobeat-content-core` and pushed commit `eb15290` (`Reject invalid preview timing values`). The shared contract now enforces `song.audio.previewStartTime >= 0` when present and `song.audio.previewDuration > 0` when present. This truthfully rejects the QA blocker cases: negative start time, negative duration, and zero duration. `Song.validate_audio_shape(...)` now emits `song_audio_preview_start_time_invalid_value` and `song_audio_preview_duration_invalid_value` for those range failures, and the preview contract test was expanded to prove both direct invalid-type handling and mutated package validation failures for invalid timing values. Validation passed again via `godot --headless --path .testbed --script res://../tests/run_contract_tests.gd`. The bead remains open for QA re-check. Importer consequence: any authored package using `previewMode: song_file_clip` must emit non-negative start time and strictly positive duration or shared validation will now fail.

---

### Task 1C: Audit shared preview contract timing + previewMode

**Bead ID:** `aerobeat-content-core-pwi`  
**SubAgent:** `primary` (for `auditor`)  
**Role:** `auditor`  
**References:** `REF-01`, `REF-02`, `REF-03`, `REF-04`  
**Prompt:** In `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-content-core`, audit the expanded preview contract against bead `aerobeat-content-core-pwi`. Claim it on start with `bd update aerobeat-content-core-pwi --status in_progress --json`. Independently verify the contract/docs/test/fixture truth for `previewFilePath`, `previewUrl`, `previewStartTime`, `previewDuration`, and `previewMode`, confirm the slice stayed bounded, and review the QA evidence. If it passes, close the audit bead with an explicit reason and report whether the original contract beads should be treated as complete for this seam. If it fails, leave the bead open and report the exact gap.

**Folders Created/Deleted/Modified:**
- audit-only if needed

**Files Created/Deleted/Modified:**
- audit notes only if needed

**Status:** ✅ Complete

**Results:** Auditor independently verified that the shared preview contract is complete and bounded. The contract/docs/test/fixture truth for `previewFilePath`, `previewUrl`, `previewStartTime`, `previewDuration`, and `previewMode` all align; `previewFilePath` still normalizes to `previewResourcePath`; invalid preview timing values and invalid `previewMode` values are rejected; and `README.md` stays bounded to the contract slice without overclaiming importer/transcoding/runtime behavior. The auditor re-ran `godot --headless --path .testbed --script res://../tests/run_contract_tests.gd`, confirmed the commit trail (`3b5eaca`, `1724978`, `eb15290`), and closed bead `aerobeat-content-core-pwi`. The earlier shared-contract beads `aerobeat-content-core-398`, `aerobeat-content-core-idd`, and `aerobeat-content-core-dr3` were then closed as complete for this seam, and the QA bead `aerobeat-content-core-2i7` was also closed after the passing re-check.

---

### Task 2: Implement BeatSaver preview-audio preservation/import

**Bead ID:** `aerobeat-tool-content-authoring-09i`  
**SubAgent:** `primary` (for `coder`)  
**Role:** `coder`  
**References:** `REF-02`, `REF-03`, `REF-04`, `REF-05`  
**Prompt:** In `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-tool-content-authoring`, implement the BeatSaver preview-audio preservation/import slice after the expanded shared contract is frozen. Read the preview filename truth from staged BeatSaver source (including current v4 `audio.songPreviewFilename` when present), extract the preview asset when available, save it into canonical package output, write the agreed local preview fields onto `song.audio`, preserve provider preview URL truth in the shared field/metadata shape, and carry over preview timing truth (`previewStartTime`, `previewDuration`). Set the agreed AeroBeat `previewMode` based on the converter’s chosen playback rule so the engine follows that decision instead of re-deriving precedence. Keep provenance/debug artifacts truthful and avoid widening into transcoding or legacy v1/v2 support. Run repo-local validation, commit, and push before handoff.

**Folders Created/Deleted/Modified:**
- `src/services/importers/`
- `.testbed/assets/fixtures/`
- `.testbed/scripts/tests/`
- `src/docs/`

**Files Created/Deleted/Modified:**
- `.testbed/assets/fixtures/beatsaver_stage_minimal/demo-beatsaver-stage.zip`
- `.testbed/assets/fixtures/beatsaver_stage_minimal/source_material_manifest.json`
- `.testbed/assets/fixtures/beatsaver_stage_v4_info_sidecars/source_material_manifest.json`
- `.testbed/assets/fixtures/beatsaver_stage_v4_normalized/source_material_manifest.json`
- `.testbed/scripts/tests/test_beatsaver_stage_conversion_service.gd`
- `.testbed/scripts/tests/test_beatsaver_stage_conversion_service_v4.gd`
- `.testbed/scripts/tests/test_beatsaver_stage_conversion_service_v4_info_sidecars.gd`
- `src/docs/beatsaver-converter-foundation.md`
- `src/services/importers/beatsaver_stage_conversion_service.gd`

**Status:** ✅ Complete

**Results:** Coder implemented the BeatSaver preview-audio preservation/import slice and pushed commit `d2aad62` (`Preserve BeatSaver preview audio during import`). The converter now reads dedicated preview filename truth from staged source, including v4 `audio.songPreviewFilename`; preserves preview URL truth into `song.audio.previewUrl` when staged manifest data carries it; carries validated `previewStartTime` / `previewDuration`; extracts dedicated preview assets into canonical package output as `media/audio/<song-token>-preview.<ext>`; writes authoritative `song.audio.previewMode`; and records preview-source/import decisions plus invalid-timing warnings in `.artifacts/beatsaver/conversion/report.json`. Chosen `previewMode` precedence is: (1) `preview_file` when a distinct dedicated preview asset exists and resolves in the ZIP, (2) `song_file_clip` when no dedicated preview asset wins but the main song file exists and timing values validate, (3) `preview_url` when neither file-based path wins but a source preview URL is available, otherwise no `previewMode` is written. Full repo-local validation passed via `godot --headless --path .testbed --script scripts/tests/run_tool_tests.gd`. Honest remaining gap: `previewUrl` preservation in this repo depends on staged source metadata already carrying BeatSaver/API preview URL truth; this importer does not author upstream vendor manifests itself.

---

### Task 3: QA preview-audio contract + importer truth

**Bead ID:** `aerobeat-tool-content-authoring-kug`  
**SubAgent:** `primary` (for `qa`)  
**Role:** `qa`  
**References:** `REF-03`, `REF-04`, `REF-05`  
**Prompt:** Verify at the highest-fidelity repo-local level available that the shared contract and importer work are truthful and bounded. Confirm local packaged preview-audio output, preserved preview URL truth, preserved preview timing truth, `previewMode` behavior, validation behavior, and package-save behavior all align with the contract. Re-run the strongest relevant validation and inspect produced package output/artifacts as needed. Do not self-implement missing work; report gaps clearly.

**Folders Created/Deleted/Modified:**
- verification-only if needed

**Files Created/Deleted/Modified:**
- verification notes only if needed

**Status:** ✅ Complete

**Results:** QA re-check on commit `e9a9e2a` closed the remaining importer evidence gap and marked bead `aerobeat-tool-content-authoring-kug` passed/closed. The staged v4 info-sidecars fixture now proves the exact nested `audio.songPreviewFilename` path directly: ZIP inspection and the repo-local test both confirm `audio.songPreviewFilename == "preview.ogg"` while top-level `songPreviewFilename` is absent/empty. The same fixture still proves the converter imports/saves preview audio correctly with `previewFilePath`, `previewUrl`, `previewStartTime`, `previewDuration`, and `previewMode == preview_file`, and saved output files plus `.artifacts/beatsaver/conversion/report.json` align with that truth. Earlier checks still hold: preview URL preservation, timing preservation, dedicated preview asset saving, truthful `previewMode` precedence across all three mode paths, and bounded docs/tests. The strongest repo-local validation passed again via `godot --headless --path .testbed --script scripts/tests/run_tool_tests.gd`. QA reported no remaining importer gap and marked the slice ready for audit.

---

### Task 3A: Add fixture proof for nested v4 `audio.songPreviewFilename`

**Bead ID:** `aerobeat-tool-content-authoring-tee`  
**SubAgent:** `primary` (for `coder`)  
**Role:** `coder`  
**References:** `REF-02`, `REF-03`, `REF-04`, `REF-05`  
**Prompt:** In `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-tool-content-authoring`, close the remaining QA evidence gap against bead `aerobeat-tool-content-authoring-tee`. Claim it on start with `bd update aerobeat-tool-content-authoring-tee --status in_progress --json`. Add the smallest honest fixture/test proof needed to exercise the exact nested v4 `audio.songPreviewFilename` preview-file path, and verify that the converter preserves/imports it correctly. Keep scope tightly bounded to evidence/proof unless the fixture reveals a real bug. Re-run the strongest relevant repo-local validation, commit, and push to `main` before handoff. Do not close the bead; leave it ready for QA re-check with exact evidence.

**Folders Created/Deleted/Modified:**
- `.testbed/assets/fixtures/`
- `.testbed/scripts/tests/`
- `src/docs/` only if truth text must change

**Files Created/Deleted/Modified:**
- `.testbed/assets/fixtures/beatsaver_stage_v4_info_sidecars/demo-beatsaver-stage-v4-info-sidecars.zip`
- `.testbed/assets/fixtures/beatsaver_stage_v4_info_sidecars/source_material_manifest.json`
- `.testbed/scripts/tests/test_beatsaver_stage_conversion_service_v4_info_sidecars.gd`
- `src/docs/beatsaver-converter-foundation.md`

**Status:** ✅ Complete

**Results:** Coder landed the narrow proof-only follow-up and pushed commit `e9a9e2a` (`Prove nested v4 preview filename import`). The staged v4 info-sidecars fixture now uses the exact nested path `audio.songPreviewFilename: "preview.ogg"` with no top-level `songPreviewFilename`, and the test explicitly reads the staged `Info.dat` from the ZIP to assert that nested truth directly before proving the converter still imports/saves preview audio correctly as `media/audio/synthetic-beatsaver-v4-info-demo-preview.ogg` with `song.audio.previewMode == preview_file`. Full repo-local validation passed again via `godot --headless --path .testbed --script scripts/tests/run_tool_tests.gd`. No real converter bug was found; this was evidence/proof only. No remaining honest gap was reported for this audit-blocking seam.

---

### Task 4: Audit preview-audio slice

**Bead ID:** `aerobeat-tool-content-authoring-97d`  
**SubAgent:** `primary` (for `auditor`)  
**Role:** `auditor`  
**References:** `REF-01`, `REF-03`, `REF-04`, `REF-05`  
**Prompt:** Independently audit the shared-contract and importer work against the handoff, contract truth, docs, validation evidence, and saved package output. Confirm the slice stayed bounded to preview-audio/package-preview-URL/timing preservation plus the AeroBeat `previewMode` decision field. If it passes, close the relevant beads with explicit reasons; if not, leave them open and report the exact gap.

**Folders Created/Deleted/Modified:**
- audit-only if needed

**Files Created/Deleted/Modified:**
- audit notes only if needed

**Status:** ✅ Complete

**Results:** Auditor passed the BeatSaver preview-audio preservation/import seam. The audit verified truthful importer behavior for `song.audio.previewFilePath`, `previewUrl`, `previewStartTime`, `previewDuration`, and `previewMode`; confirmed the claimed `previewMode` precedence is real and bounded; confirmed all three outcomes are evidenced (`song_file_clip`, `preview_url`, `preview_file`); confirmed the exact nested v4 `audio.songPreviewFilename` path is now proven by fixture/test evidence rather than only code-path inspection; confirmed saved package output plus `.artifacts/beatsaver/conversion/report.json` align with the claimed behavior; and confirmed docs remain bounded without overclaiming upstream vendor ownership, transcoding, or legacy support widening. The auditor re-ran `godot --headless --path .testbed --script scripts/tests/run_tool_tests.gd` on current `main`, closed bead `aerobeat-tool-content-authoring-97d`, and also closed implementation bead `aerobeat-tool-content-authoring-09i` plus proof bead `aerobeat-tool-content-authoring-tee` as complete for this seam.

---

## Final Results

**Status:** ✅ Complete

**What We Built:** BeatSaver preview-audio support now spans the full audited path from shared contract through importer implementation. `aerobeat-content-core` now carries the durable preview contract (`previewFilePath`, `previewUrl`, `previewStartTime`, `previewDuration`, `previewMode`) with bounded validation, and `aerobeat-tool-content-authoring` now preserves/imports BeatSaver preview truth into authored packages, including dedicated preview files, provider preview URLs, preview timing metadata, and converter-authored playback-mode decisions.

**Reference Check:** `REF-01`..`REF-05` satisfied. The handoff/plan chain was recovered cleanly, the shared `aerobeat-content-core` contract was frozen/expanded/fixed and audited, and the importer repo now truthfully implements the agreed preview preservation behavior without widening into unsupported transcoding or legacy claims.

**Commits:**
- `3b5eaca` - Freeze preview audio song contract
- `1724978` - Extend preview audio contract timing fields
- `eb15290` - Reject invalid preview timing values
- `d2aad62` - Preserve BeatSaver preview audio during import
- `e9a9e2a` - Prove nested v4 preview filename import

**Lessons Learned:** Preview handling could not be modeled honestly as a simple version-based switch. The durable pattern is to preserve all available source truth, then store one AeroBeat-authored `previewMode` decision so runtime behavior is explicit instead of re-derived.

---

*Started on 2026-07-21*
