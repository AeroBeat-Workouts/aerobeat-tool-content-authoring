# AeroBeat Tool Content Authoring Root-to-src Relink

**Date:** 2026-06-04  
**Status:** Complete  
**Last Updated:** 2026-06-04 12:42 EDT  
**Blocked Reason:** None  
**Agent:** `cookie`

---

## Goal

Move the remaining repo-root source code in `aerobeat-tool-content-authoring` under `src/` and relink `.testbed/` so the refactored layout still works cleanly.

---

## Overview

This repo already has a partial `src/` layout, but there are still source-bearing root paths such as `editor/`, `interfaces/`, `mappers/`, and `services/` living alongside the newer `src/` tree. The requested slice is to finish normalizing that structure so repo-root code lives under `src/`, then repair any `.testbed/` addon wiring, preload paths, config references, and validation flows that still assume the old root layout.

To keep this safe, execution should stay repo-local and follow the normal implementation loop: one coder pass for the structural move plus reference repair, one QA pass to verify the `.testbed/` project and local validation flow still resolve the addon correctly, and one independent auditor pass to truth-check the final state against the repo layout and touched references.

---

## REFERENCES

| ID | Description | Path |
| --- | --- | --- |
| `REF-01` | Current repo layout and documentation contract | `README.md` |
| `REF-02` | Testbed project wiring | `.testbed/project.godot` |
| `REF-03` | Testbed addon sync config | `.testbed/addons.jsonc` |
| `REF-04` | Current root vs `src/` tree to normalize | repo root (`editor/`, `interfaces/`, `mappers/`, `services/`, `src/`) |

Use these IDs later in tasks, audit notes, and final results when work must match or be checked against a specific source.

---

## Tasks

### Task 1: Move remaining root source trees under `src/` and repair internal references

**Bead ID:** `aerobeat-tool-content-authoring-nxo`  
**SubAgent:** `primary` (for `coder` workflow role)  
**Role:** `coder`  
**References:** `REF-01`, `REF-02`, `REF-03`, `REF-04`  
**Prompt:** Pending Derrick approval. Claim the bead on start. Move the remaining source-bearing repo-root directories/files into the canonical `src/` tree, update repo/testbed/Godot references so they resolve through the new layout, run the strongest repo-local validation available, and commit/push unless blocked. Record exactly what moved, what relinks changed, and any follow-ups.

**Folders Created/Deleted/Modified:**
- repo root (removed empty legacy source-shell folders `editor/`, `interfaces/`, `mappers/`, `services/`)
- `src/` (validated as the only remaining in-repo source tree)
- `.testbed/` (validated only; no durable config change required)

**Files Created/Deleted/Modified:**
- `.plans/2026-06-04-root-to-src-relink.md`
- `plugin.cfg`

**Status:** ✅ Complete

**Results:** Claimed bead `aerobeat-tool-content-authoring-nxo`, inspected the repo layout, and confirmed the actual Godot source had already been moved into `src/`; the remaining repo-root source-named folders were only ignored `.uid` shells. Removed those empty root folders so the repo root now normalizes cleanly to `src/` plus metadata/config files. Repaired the stale addon/plugin entrypoint in `plugin.cfg` from `editor/plugins/content_authoring_plugin.gd` to `src/editor/plugins/content_authoring_plugin.gd` so root-symlinked addon consumers resolve the editor bridge through the refactored layout. Validation: `godot --headless --path .testbed --import` followed by `godot --headless --path .testbed --script scripts/tests/run_tool_tests.gd` both completed successfully (exit 0); the test run passed while still emitting pre-existing Godot exit warnings about leaked ObjectDB instances / resources. References checked: `REF-01`, `REF-02`, `REF-03`, `REF-04`.

---

### Task 2: Verify `.testbed/` after the structural move

**Bead ID:** `aerobeat-tool-content-authoring-bza`  
**SubAgent:** `primary` (for `qa` workflow role)  
**Role:** `qa`  
**References:** `REF-01`, `REF-02`, `REF-03`, `REF-04`  
**Prompt:** Pending Derrick approval. Claim the bead on start. Independently verify that `.testbed/` still resolves the addon correctly after the root-to-`src/` move using the highest-fidelity repo-local validation available. Capture concrete pass/fail evidence, especially around addon install/symlink wiring and any headless test flow.

**Folders Created/Deleted/Modified:**
- `.testbed/.headless/` (QA evidence logs only)

**Files Created/Deleted/Modified:**
- `.testbed/.headless/qa-root-to-src-20260604T123607-summary.txt`
- `.testbed/.headless/qa-root-to-src-20260604T123607-godotenv-addons-install.log`
- `.testbed/.headless/qa-root-to-src-20260604T123607-godot-import.log`
- `.testbed/.headless/qa-root-to-src-20260604T123607-godot-tests.log`

**Status:** ✅ Complete

**Results:** Claimed bead `aerobeat-tool-content-authoring-bza` and independently verified the repo at implementation commit `289a24d`. Wiring check: `.testbed/addons/aerobeat-tool-content-authoring` resolves to the repo root, `plugin.cfg` inside that addon resolves to the repo-root `plugin.cfg`, and the plugin entrypoint now points to `src/editor/plugins/content_authoring_plugin.gd`, which resolves successfully through the symlinked addon root. Root-layout check: repo-root `editor/`, `interfaces/`, `mappers/`, and `services/` are absent while `src/` remains present, matching the intended normalized layout. High-fidelity validation passed with exit code 0 for all steps: `(cd .testbed && godotenv addons install)`, `godot --headless --path .testbed --import`, and `godot --headless --path .testbed --script scripts/tests/run_tool_tests.gd`. `godotenv addons install` reported `✅ Addons installed successfully.` and resolved the addon from `addons.jsonc` at `/` on branch `main` of this repo. The test run returned top-level JSON `"passed": true`; the only stderr-style noise was the same pre-existing Godot shutdown warnings about leaked ObjectDB instances and `9 resources still in use at exit`. Evidence logs were captured under `.testbed/.headless/qa-root-to-src-20260604T123607-*`. References checked: `REF-01`, `REF-02`, `REF-03`, `REF-04`. No code changes required.

---

### Task 3: Audit final layout truthfulness and closure

**Bead ID:** `aerobeat-tool-content-authoring-n5p`  
**SubAgent:** `primary` (for `auditor` workflow role)  
**Role:** `auditor`  
**References:** `REF-01`, `REF-02`, `REF-03`, `REF-04`  
**Prompt:** Pending Derrick approval. Claim the bead on start. Audit the completed refactor against the plan, repo diff, and validation evidence. Confirm repo-root code in scope now lives under `src/`, `.testbed/` is correctly relinked, and touched docs/configs tell the truth. Close the bead only if the work is actually complete.

**Folders Created/Deleted/Modified:**
- `.testbed/.headless/` (audit evidence logs only)

**Files Created/Deleted/Modified:**
- `.plans/2026-06-04-root-to-src-relink.md`
- `.testbed/.headless/audit-root-to-src-20260604T1240/godotenv-addons-install.log`
- `.testbed/.headless/audit-root-to-src-20260604T1240/godot-import.log`
- `.testbed/.headless/audit-root-to-src-20260604T1240/godot-tests.log`

**Status:** ✅ Complete

**Results:** Claimed bead `aerobeat-tool-content-authoring-n5p` and independently audited the finished refactor at `289a24d` against the repo state, plan, and QA evidence. Layout truth check passed: the repo root now contains only metadata/config plus `src/` and `.testbed/`; the legacy root source paths `editor/`, `interfaces/`, `mappers/`, and `services/` are absent while their in-scope code lives under `src/` (`src/editor/`, `src/interfaces/`, `src/mappers/`, `src/services/`). Wiring truth check passed: `plugin.cfg` now points at `src/editor/plugins/content_authoring_plugin.gd`; `.testbed/addons/aerobeat-tool-content-authoring` is a symlink to the repo root; and the plugin script target resolves successfully through that addon boundary. Reference truth check passed for the touched contract files: `README.md`'s repository-shape description matches the current tree, `.testbed/addons.jsonc` still correctly targets the repo root with `subfolder: "/"`, and `.testbed/project.godot` required no path change for this slice. Validation evidence passed twice: QA logs under `.testbed/.headless/qa-root-to-src-20260604T123607-*` show successful addon install/import/tests at `289a24d`, and an independent auditor rerun also passed with exit code 0 for `godotenv addons install`, `godot --headless --path . --import`, and `godot --headless --path . --script scripts/tests/run_tool_tests.gd`, with only the same pre-existing Godot shutdown warnings about leaked ObjectDB instances / `9 resources still in use at exit`. References checked: `REF-01`, `REF-02`, `REF-03`, `REF-04`. Audit verdict: complete; bead may be closed.

---

## Final Results

**Status:** ✅ Complete

**What We Built:** The repo root is now truthful to the intended addon layout: in-scope source code lives under `src/`, the stale root plugin entrypoint was updated to resolve through `src/`, and the `.testbed/` root-symlinked addon flow continues to install, import, and execute tests successfully.

**Reference Check:** `REF-01` and `REF-04` match the normalized repository shape (`src/` is the only remaining in-repo source tree and the legacy root source directories are gone). `REF-02` and `REF-03` remained correct without durable edits because the existing `.testbed/` wiring already targeted the repo root via symlink; once `plugin.cfg` pointed to `src/editor/plugins/content_authoring_plugin.gd`, the addon/testbed boundary resolved cleanly. QA evidence plus the independent auditor rerun both passed against those references.

**Commits:**
- `289a24d` - Point plugin entry script at `src/` after root cleanup

**Lessons Learned:** This refactor was mostly about making the repo tell the truth: the real code had already moved, but empty ignored legacy folders and one stale `plugin.cfg` path still made the addon look half-migrated. The important coupling to protect was the repo-root `plugin.cfg` consumed via the `.testbed` root symlink, not a separate addon-local manifest.

---

*Drafted on 2026-06-04*
