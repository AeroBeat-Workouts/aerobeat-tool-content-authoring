# AeroBeat BeatSaver Legacy v1/v2 Normalization

**Date:** 2026-07-21  
**Status:** In Progress  
**Last Updated:** 2026-07-21 09:02 EDT  
**Blocked Reason:** None  
**Agent:** `pico`

---

## Goal

Resume the next approved BeatSaver compatibility seam by truthfully adding legacy v2/v1 metadata+difficulty normalization first, then legacy v2/v1 beat-object normalization, before the later `.egg` -> `.ogg` vendor seam.

---

## Overview

The BeatSaver preview-audio seam is now complete and audited. Derrick confirmed the remaining work order for this lane: (1) legacy v2/v1 metadata+difficulty normalization, (2) legacy v2/v1 beat-object normalization, (3) confirm exact real-world `.egg` support requirements, and only then (4) land the separate `aerobeat-vendor-ffmpeg` `.egg` -> `.ogg` seam.

This plan stays intentionally scoped to the first two legacy-compatibility steps inside `aerobeat-tool-content-authoring`, because this repo owns staged-source -> authored-package conversion. It should not prematurely widen into transcoding, preview-audio rework, or vendor-fetch responsibilities. The immediate next slice is to establish the smallest honest legacy v2/v1 metadata+difficulty normalization path, with repo-local proof from real or synthetic staged fixtures, then decide whether the next seam can move straight into beat-object normalization inside the same repo plan.

Execution follows the normal loop: coder/research establishes the normalization slice, QA verifies it at the highest-fidelity repo-local level available, and auditor independently checks that support claims remain truthful and bounded.

---

## REFERENCES

| ID | Description | Path |
| --- | --- | --- |
| `REF-01` | Latest AeroBeat canonical handoff | `/home/derrick/.openclaw/workspace/projects/openclaw-pico/handoffs/handoff-2026-07-20T21-35-00-04-00-aerobeat.md` |
| `REF-02` | Completed BeatSaver preview-audio plan/result chain | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-tool-content-authoring/.plans/2026-07-21-beatsaver-preview-audio-contract-and-import.md` |
| `REF-03` | Prior BeatSaver foundation plan capturing remaining legacy / ffmpeg order | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-tool-content-authoring/.plans/2026-07-20-beatsaver-flow-boxing-converter-foundation.md` |
| `REF-04` | Current BeatSaver converter docs | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-tool-content-authoring/src/docs/beatsaver-converter-foundation.md` |
| `REF-05` | Shared authored contract repo | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-content-core/README.md` |

---

## Tasks

### Task 1: Implement legacy v2/v1 metadata + difficulty normalization

**Bead ID:** `aerobeat-tool-content-authoring-aci`  
**SubAgent:** `primary` (for `coder`)  
**Role:** `coder`  
**References:** `REF-02`, `REF-03`, `REF-04`, `REF-05`  
**Prompt:** In `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-tool-content-authoring`, implement the next approved BeatSaver compatibility slice: legacy v2/v1 metadata + difficulty normalization. Claim the bead on start with `bd update <id> --status in_progress --json`. Add the smallest honest staged-source normalization path needed so legacy v2/v1 maps can be parsed/selected truthfully at the metadata+difficulty layer without pretending beat-object conversion is already solved. Keep scope bounded to metadata/info/difficulty normalization plus fixtures/tests/docs needed to prove it. Do not widen into `.egg` -> `.ogg` transcoding, preview-audio rework, or legacy beat-object conversion unless a tiny inseparable bug fix is required. Run the strongest relevant repo-local validation, commit, and push to `main` before handoff. Do not close the bead; leave it ready for QA with exact evidence.

**Folders Created/Deleted/Modified:**
- `src/services/importers/`
- `.testbed/assets/fixtures/`
- `.testbed/scripts/tests/`
- `src/docs/`

**Files Created/Deleted/Modified:**
- `src/services/importers/beatsaver_stage_conversion_service.gd`
- `src/AeroContentAuthoring.gd`
- `.testbed/scripts/tests/run_tool_tests.gd`
- `.testbed/scripts/tests/test_beatsaver_stage_legacy_metadata_normalization.gd`
- `.testbed/scripts/tests/test_beatsaver_stage_conversion_service_real_world_legacy_v2.gd`
- `.testbed/assets/fixtures/beatsaver_stage_legacy_v1_synthetic/source_material_manifest.json`
- `.testbed/assets/fixtures/beatsaver_stage_legacy_v1_synthetic/synthetic-legacy-v1-stage.zip`
- `README.md`
- `src/docs/beatsaver-converter-foundation.md`

**Status:** ✅ Complete

**Results:** Coder landed the bounded legacy metadata+difficulty normalization slice and pushed commit `5f45e4c` (`Normalize legacy BeatSaver metadata and difficulties`). The repo now has a new bounded inspection seam via `BeatSaverStageConversionService.inspect_stage(...)` and `AeroContentAuthoring.inspect_beatsaver_stage_source(...)`, which normalize legacy v2/v1 `Info.dat` metadata, Standard difficulty selection, difficulty labels/ranks, and beatmap version-family tagging (`legacy_v1`, `legacy_v2`, `v3`, `v4`). Difficulty normalization was fixed so missing legacy ranks derive truthfully from labels instead of staying `0`. Full conversion now fails honestly on legacy maps with `legacy_beatmap_object_normalization_pending` instead of the stale blanket `unsupported_beatmap_version`. Full repo-local validation passed via `godot --headless --path .testbed --script scripts/tests/run_tool_tests.gd`. Legacy cases now supported: legacy v1/v2 staged-source metadata inspection/normalization, Standard difficulty discovery from legacy `_difficultyBeatmapSets`, legacy difficulty-rank normalization when rank is missing, truthful version-family classification, and truthful bounded failure once unsupported legacy beat-object payloads are reached. Still intentionally unsupported: legacy v1/v2 beat-object normalization into the current internal source summary, legacy Flow/Boxing authored chart emission from v1/v2 objects, `.egg` -> `.ogg` transcoding, and any preview-audio rework beyond the already-complete separate seam. Newly exposed next seam: implement legacy v2/v1 beat-object normalization into the current normalized source families used by `_convert_boxing_chart(...)` / `_convert_flow_chart(...)`, starting with legacy adapters inside `_normalize_source_summary(...)` while keeping audio/transcoding out of scope.

---

### Task 2: QA legacy v2/v1 metadata + difficulty normalization

**Bead ID:** `Pending`  
**SubAgent:** `primary` (for `qa`)  
**Role:** `qa`  
**References:** `REF-03`, `REF-04`, `REF-05`  
**Prompt:** Verify at the highest-fidelity repo-local level available that legacy v2/v1 metadata+difficulty normalization is truthful and bounded. Confirm supported legacy staged packages are now parsed/selected honestly, unsupported beat-object conversion is still reported honestly if not yet implemented, and docs/tests do not overclaim wider legacy support. Re-run the strongest relevant validation and inspect produced outputs as needed. Do not self-implement missing work; report exact evidence and whether the slice is ready for audit.

**Folders Created/Deleted/Modified:**
- verification-only if needed

**Files Created/Deleted/Modified:**
- verification notes only if needed

**Status:** ⏳ Pending

**Results:** Pending.

---

### Task 3: Audit legacy v2/v1 metadata + difficulty normalization

**Bead ID:** `Pending`  
**SubAgent:** `primary` (for `auditor`)  
**Role:** `auditor`  
**References:** `REF-01`, `REF-03`, `REF-04`, `REF-05`  
**Prompt:** Independently audit the legacy v2/v1 metadata+difficulty normalization slice against the request, docs, diffs, validation evidence, and produced outputs. Confirm the slice stayed bounded to metadata/difficulty normalization and close the relevant bead(s) if it passes. If it fails, leave the bead open and report the exact gap.

**Folders Created/Deleted/Modified:**
- audit-only if needed

**Files Created/Deleted/Modified:**
- audit notes only if needed

**Status:** ⏳ Pending

**Results:** Pending.

---

## Final Results

**Status:** ⚠️ Partial

**What We Built:** Landed the first half of the approved legacy-compatibility path: legacy v2/v1 metadata+difficulty normalization is now implemented and pushed, while QA/audit plus the next legacy beat-object normalization seam remain for the next session.

**Reference Check:** `REF-02`..`REF-05` currently satisfied for the metadata+difficulty normalization slice. Legacy beat-object conversion and later ffmpeg/vendor work are still intentionally out of scope for this plan state.

**Commits:**
- `5f45e4c` - Normalize legacy BeatSaver metadata and difficulties

**Lessons Learned:** A bounded inspection/normalization seam lets us support legacy package discovery and truthful staged-source inspection without falsely claiming full legacy chart conversion before the beat-object adapters exist.

---

*Started on 2026-07-21*
