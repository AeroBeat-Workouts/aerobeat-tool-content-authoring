# AeroBeat Tool Content Authoring Root-to-src Relink

**Date:** 2026-06-04  
**Status:** In Progress  
**Last Updated:** 2026-06-04 12:30 EDT  
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
- `.testbed/` runtime artifacts only if validation produces them

**Files Created/Deleted/Modified:**
- validation artifacts/logs only if intentionally created

**Status:** ⏳ Pending

**Results:** Not started.

---

### Task 3: Audit final layout truthfulness and closure

**Bead ID:** `aerobeat-tool-content-authoring-n5p`  
**SubAgent:** `primary` (for `auditor` workflow role)  
**Role:** `auditor`  
**References:** `REF-01`, `REF-02`, `REF-03`, `REF-04`  
**Prompt:** Pending Derrick approval. Claim the bead on start. Audit the completed refactor against the plan, repo diff, and validation evidence. Confirm repo-root code in scope now lives under `src/`, `.testbed/` is correctly relinked, and touched docs/configs tell the truth. Close the bead only if the work is actually complete.

**Folders Created/Deleted/Modified:**
- none expected

**Files Created/Deleted/Modified:**
- none expected unless the audit requires plan-result updates

**Status:** ⏳ Pending

**Results:** Not started.

---

## Final Results

**Status:** ⚠️ Coder pass complete; QA and audit still pending

**What We Built:** The repo root no longer carries the leftover source-tree shells; the addon/plugin entrypoint now resolves into `src/`, and the `.testbed/` validation flow still runs successfully against the refactored layout.

**Reference Check:** `REF-01`/`REF-04` now match the normalized repo shape; `REF-02`/`REF-03` required no durable edits because the existing `.testbed/` wiring already targeted the repo root symlink correctly once `plugin.cfg` pointed into `src/`.

**Commits:**
- Pending coder commit

**Lessons Learned:** The remaining root-layout drift was mostly a truthiness problem: empty ignored `.uid` shells and one stale plugin path were enough to make the repo look half-migrated even though the real source already lived under `src/`.

---

*Drafted on 2026-06-04*
