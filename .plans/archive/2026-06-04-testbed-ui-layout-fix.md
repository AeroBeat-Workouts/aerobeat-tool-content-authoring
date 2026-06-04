# AeroBeat Tool Content Authoring Testbed UI Layout Fix

**Date:** 2026-06-04  
**Status:** Complete  
**Last Updated:** 2026-06-04 13:00 EDT  
**Blocked Reason:** None  
**Agent:** `cookie`

---

## Goal

Fix the `.testbed` scene UI layout so the content authoring interface is no longer visually smushed together.

---

## Overview

The next slice is a repo-local UI/layout debugging pass in the testbed scene. The likely seam is in `.testbed/scenes/ContentAuthoring.tscn` and any supporting UI scripts/theme/container settings that determine anchoring, sizing, minimum sizes, split behavior, and responsive layout inside the local Godot testbed.

The safest path is to inspect the actual testbed scene in Godot, capture the current broken state, identify the layout nodes/properties causing the compression, apply a narrow fix in the owning repo source/testbed files, then verify both visually and through the normal editor/testbed flow that the UI lays out correctly without regressing the existing addon wiring.

From the provided screenshot, the visible failure mode is specific enough to guide the first pass: the metadata help/description copy is overlapping the form controls in the left column, which suggests a container sizing, minimum-size, shrink, or wrap issue rather than a data-binding bug. The implementation pass should start by tracing that metadata panel/container hierarchy before widening scope.

---

## REFERENCES

| ID | Description | Path |
| --- | --- | --- |
| `REF-01` | Testbed scene likely showing the smushed UI | `.testbed/scenes/ContentAuthoring.tscn` |
| `REF-02` | Testbed project wiring | `.testbed/project.godot` |
| `REF-03` | Current addon and source layout after the root-to-src normalization | `src/`, `plugin.cfg`, `.testbed/addons.jsonc` |
| `REF-04` | Screenshot of the smushed metadata form overlap in the testbed scene | `/home/derrick/.openclaw/workspace/.temp/nerve-uploads/2026/06/04/image-c8bb2373.png` |

Use these IDs later in tasks, audit notes, and final results when work must match or be checked against a specific source.

---

## Tasks

### Task 1: Diagnose and fix the smushed testbed UI layout

**Bead ID:** `aerobeat-tool-content-authoring-9gd`  
**SubAgent:** `primary` (for `coder` workflow role)  
**Role:** `coder`  
**References:** `REF-01`, `REF-02`, `REF-03`  
**Prompt:** Pending Derrick approval. Claim the bead on start. Inspect the `.testbed` scene/UI in Godot, identify why the interface is visually smushed together, apply a narrow layout fix in the owning repo files, verify the affected scene/UI flow, update the plan with actual results, and commit/push unless blocked.

**Folders Created/Deleted/Modified:**
- `.testbed/`

**Files Created/Deleted/Modified:**
- `.plans/2026-06-04-testbed-ui-layout-fix.md`
- `.testbed/scenes/ContentAuthoring.tscn`
- `.testbed/scripts/tests/smoke_content_authoring_scene.gd`

**Status:** ✅ Complete

**Results:** Claimed bead `aerobeat-tool-content-authoring-9gd` and traced the overlap to `REF-01`: both `MetadataForm` and `MetadataHint` were direct children of `MetadataMargin`, a `MarginContainer`, so Godot assigned both controls the same inner rect and the hint text painted on top of the left-column form fields. Applied a narrow structural fix by inserting `MetadataStack` (`VBoxContainer`) under `MetadataMargin` and moving both the form and hint under that stack so they flow vertically instead of overlapping. Updated the smoke test node paths to match the new scene hierarchy. Validation evidence: `godot --headless --path .testbed -s res://scripts/tests/smoke_content_authoring_scene.gd` passed; `godot --headless --path .testbed -s /tmp/check_metadata_layout.gd` reported non-overlapping rects with `hint_top_below_form_bottom=true`; `godot --headless --path .testbed -s res://scripts/tests/run_tool_tests.gd` returned a passing suite payload (with existing Godot resource-leak warnings at shutdown, but no test failure). Godot plugin/editor control was unavailable in this session (`godot_sessions` returned zero active sessions), so headless Godot was the highest-fidelity repo-local validation path.

---

### Task 2: Verify the UI layout fix in the testbed

**Bead ID:** `aerobeat-tool-content-authoring-qee`  
**SubAgent:** `primary` (for `qa` workflow role)  
**Role:** `qa`  
**References:** `REF-01`, `REF-02`, `REF-03`  
**Prompt:** Pending Derrick approval. Claim the bead on start. Independently verify the testbed UI layout after the fix using the highest-fidelity Godot/editor validation available, capture visual and functional evidence, and note any remaining layout defects.

**Folders Created/Deleted/Modified:**
- `.testbed/` runtime/evidence artifacts only if intentionally created

**Files Created/Deleted/Modified:**
- `.plans/2026-06-04-testbed-ui-layout-fix.md`
- `/tmp/qa_metadata_layout_probe.gd` (temporary local QA probe, not committed)

**Status:** ✅ Complete

**Results:** Claimed bead `aerobeat-tool-content-authoring-qee` and independently verified both structure and runtime layout for `REF-01`. Structural check: `rg -n 'MetadataStack|MetadataForm|MetadataHint' .testbed/scenes/ContentAuthoring.tscn` confirms `MetadataForm` and `MetadataHint` now live under `MetadataStack` (`VBoxContainer`) instead of overlapping as siblings under `MetadataMargin`. Runtime/layout check: `godot --headless --path .testbed -s res://scripts/tests/smoke_content_authoring_scene.gd` returned `"passed": true`; `godot --headless --path .testbed -s /tmp/qa_metadata_layout_probe.gd` returned `"passed": true` with `overlaps=false`, `hint_top_below_form_bottom=true`, `form_parent="MetadataStack"`, and `hint_parent="MetadataStack"`; `godot --headless --path .testbed -s res://scripts/tests/run_tool_tests.gd` returned passing suite entries for the repo-local tool tests. Screenshot capture was attempted from the QA probe, but headless Godot's dummy renderer reported `Parameter "t" is null`, so no screenshot artifact could be produced in this environment. Godot editor/plugin control was unavailable (`godot_sessions` returned zero active sessions), `xvfb-run` was not installed for a virtual-display fallback, and headless Godot was therefore the highest-fidelity repo-local validation path available. QA result: pass. I did not find a remaining metadata hint/form overlap defect in the validated testbed scene/state.

---

### Task 3: Audit final UI layout truthfulness and closure

**Bead ID:** `aerobeat-tool-content-authoring-teb`  
**SubAgent:** `primary` (for `auditor` workflow role)  
**Role:** `auditor`  
**References:** `REF-01`, `REF-02`, `REF-03`  
**Prompt:** Pending Derrick approval. Claim the bead on start. Audit the completed UI layout fix against the scene state, diff, and validation evidence. Confirm the smushed layout issue is resolved in the intended testbed scope and close the bead only if the work is actually complete.

**Folders Created/Deleted/Modified:**
- none expected

**Files Created/Deleted/Modified:**
- none expected unless the audit needs plan-result updates

**Status:** ✅ Complete

**Results:** Claimed bead `aerobeat-tool-content-authoring-teb` and independently audited `REF-01`/`REF-04` against the committed scene state at `88860f5`. Diff review confirms the actual fix is the insertion of `MetadataStack` (`VBoxContainer`) under `MetadataMargin`, with both `MetadataForm` and `MetadataHint` moved beneath that stack; this directly removes the prior same-parent/same-rect overlap that was visible in `REF-04`. I re-checked the live repo scene file and smoke-test path updates, then produced higher-fidelity rendered evidence by launching the `.testbed` project on the host X11 display (`DISPLAY=:1`) and capturing the real window contents to `/home/derrick/.openclaw/workspace/.temp/audit-ui/content-authoring.png`. That rendered capture shows the metadata hint flowing below the description field instead of painting on top of the form controls, matching the intended fix and materially differing from `REF-04`. Confidence is high for this bead's actual goal because the audit includes both the structural cause/fix analysis and a real rendered post-fix screenshot, not just headless node/rect checks. Note: closing the manually launched runtime window via `xdotool windowclose` caused a Godot crash on exit; I am not treating that as a failure for this bead because the scoped bug was the metadata layout overlap, not shutdown behavior, but it is worth noting separately if close-path stability matters later.

---

## Final Results

**Status:** ✅ Complete

**What We Built:** Fixed the `.testbed` metadata authoring layout so the hint copy no longer renders on top of the metadata form fields. The final scene now uses a dedicated `MetadataStack` vertical container under `MetadataMargin`, which makes the form and hint participate in normal vertical layout flow instead of competing for the same inner rect.

**Reference Check:** `REF-01` and `REF-04` are satisfied for the scoped bug: the committed scene hierarchy removes the exact overlap cause visible in the broken screenshot, and the live rendered audit capture at `/home/derrick/.openclaw/workspace/.temp/audit-ui/content-authoring.png` shows the hint text below the form rather than smushed into it. `REF-02` and `REF-03` remained intact; the fix stayed within the local testbed scene/test wiring and did not require contract changes.

**Commits:**
- `88860f5` - Fix content authoring metadata layout overlap

**Lessons Learned:** For Godot `Control` layouts, a structural hierarchy check can explain the bug, but a final visual truth-check still matters; in this case, the extra rendered capture was the difference between "probably fixed" and a confident closure.

---

*Drafted on 2026-06-04*
