# AeroBeat Tool Content Authoring Testbed Input Width Fix

**Date:** 2026-06-04  
**Status:** In Progress  
**Last Updated:** 2026-06-04 15:35 EDT  
**Blocked Reason:** None  
**Agent:** `cookie`

---

## Goal

Fix the `.testbed` UI tabs so text input fields render at a reasonable usable width uniformly across the scene.

---

## Overview

The prior layout fix resolved the overlapping hint text, but the new screenshot shows a second layout seam: the metadata form controls are still collapsing to a very narrow width in the left column. Derrick has now clarified that this should be fixed uniformly across each UI tab in the testbed scene, so the scope is no longer just one metadata subsection.

The likely causes are container size flags, missing horizontal expand/fill behavior, overly constrained custom minimum sizes, or HBox/Grid/Form-style parents that are not giving the control columns enough stretch. The safest path is to inspect `.testbed/scenes/ContentAuthoring.tscn`, trace the repeated form/container patterns across tabs, apply a narrow but uniform width/layout fix, then verify both structurally and visually that the fields expand to a sane width everywhere without regressing the prior overlap fix.

---

## REFERENCES

| ID | Description | Path |
| --- | --- | --- |
| `REF-01` | Testbed scene containing the metadata form | `.testbed/scenes/ContentAuthoring.tscn` |
| `REF-02` | Prior metadata layout fix context | `.plans/2026-06-04-testbed-ui-layout-fix.md` |
| `REF-03` | Screenshot showing narrow metadata inputs after the overlap fix | `/home/derrick/.openclaw/workspace/.temp/nerve-uploads/2026/06/04/image-5a948db1.png` |
| `REF-04` | Testbed project wiring and current addon layout | `.testbed/project.godot`, `.testbed/addons.jsonc`, `plugin.cfg` |
| `REF-05` | User clarification that the width fix should apply uniformly across each UI tab in the testbed scene | current request in this session |

Use these IDs later in tasks, audit notes, and final results when work must match or be checked against a specific source.

---

## Tasks

### Task 1: Diagnose and fix the narrow input widths uniformly across UI tabs

**Bead ID:** `aerobeat-tool-content-authoring-y55`  
**SubAgent:** `primary` (for `coder` workflow role)  
**Role:** `coder`  
**References:** `REF-01`, `REF-02`, `REF-03`, `REF-04`, `REF-05`  
**Prompt:** Approved by Derrick. Claim the bead on start. Inspect the repeated form/input layout patterns in `.testbed/scenes/ContentAuthoring.tscn`, identify why the text inputs are collapsing to an unreasonably narrow width, apply a narrow scene/layout fix uniformly across each relevant UI tab, verify the result, update the plan with actual results, and commit/push unless blocked.

**Folders Created/Deleted/Modified:**
- `.testbed/`

**Files Created/Deleted/Modified:**
- `.plans/2026-06-04-testbed-input-width-fix.md`
- `.testbed/scenes/ContentAuthoring.tscn`

**Status:** ✅ Complete

**Results:** Claimed bead `aerobeat-tool-content-authoring-y55` and traced two related width-collapse causes in `REF-01`. First, the active metadata tab routes its form through `MetadataScroll`, whose direct child `MetadataMargin` had no horizontal expand flag, so the scroll content shrank to its minimum width (`227px`) and forced `MetadataForm`/`WorkoutIdEdit` down to `211px`/`68.5px` even inside a `1240px` tab. Second, the repeated text-entry controls in the metadata, warm-up, and cool-down `GridContainer` rows were left at default horizontal sizing, and the warm-up/cool-down forms themselves also lacked horizontal expand flags, so those tabs would size their input column to minimum content width when activated. Applied a narrow scene-only fix by adding `size_flags_horizontal = 3` to `MetadataMargin`, the relevant `LineEdit` controls in the metadata/warm-up/cool-down forms, and the `WarmUpForm`/`CoolDownForm` containers. Validation evidence: a headless layout probe before/after showed metadata widths grow from `MetadataForm=211px` / `WorkoutIdEdit=68.5px` to `MetadataForm=1224px` / `WorkoutIdEdit=1081px`, and active warm-up/cool-down widths now resolve to `WarmUpForm=1240px` / `CoachConfigNameEdit=1063px` and `CoolDownForm=1240px` / `CooldownVideoPathEdit=1052px`; `godot --headless --path .testbed -s res://scripts/tests/smoke_content_authoring_scene.gd` passed; `godot --headless --path .testbed -s res://scripts/tests/run_tool_tests.gd` passed (with the existing Godot shutdown leak warnings only); and a host-rendered metadata screenshot was captured at `/home/derrick/.openclaw/workspace/.temp/testbed-width-fix/content-authoring-front.png`, showing full-width metadata inputs with the prior hint/layout overlap still resolved. Committed and pushed as `7018d65` (`Fix testbed content authoring input widths`). During screenshot teardown, closing the host-run Godot window via `xdotool windowclose` reproduced a separate Godot/NVIDIA crash-on-close path; I did not treat that as a regression for this scoped input-width bead because the rendered frame was captured successfully and the layout fix remained correct.

---

### Task 2: Verify the input width fix across UI tabs in the testbed

**Bead ID:** `aerobeat-tool-content-authoring-aoz`  
**SubAgent:** `primary` (for `qa` workflow role)  
**Role:** `qa`  
**References:** `REF-01`, `REF-02`, `REF-03`, `REF-04`, `REF-05`  
**Prompt:** Approved by Derrick. Claim the bead on start. Independently verify the metadata and related text input width fix across each relevant UI tab using the highest-fidelity validation available, capture structural and rendered evidence, and note any remaining layout defects.

**Folders Created/Deleted/Modified:**
- `.testbed/` runtime/evidence artifacts only if intentionally created

**Files Created/Deleted/Modified:**
- evidence artifacts/logs/screenshots only if intentionally created

**Status:** ⏳ Pending

**Results:** Not started.

---

### Task 3: Audit final layout truthfulness and closure

**Bead ID:** `aerobeat-tool-content-authoring-16r`  
**SubAgent:** `primary` (for `auditor` workflow role)  
**Role:** `auditor`  
**References:** `REF-01`, `REF-02`, `REF-03`, `REF-04`, `REF-05`  
**Prompt:** Approved by Derrick. Claim the bead on start. Audit the completed input-width fix against the scene state, diff, and validation evidence. Confirm the text inputs now render at a sane usable width uniformly across the intended testbed UI tabs and close the bead only if the work is actually complete.

**Folders Created/Deleted/Modified:**
- none expected

**Files Created/Deleted/Modified:**
- none expected unless the audit needs plan-result updates

**Status:** ⏳ Pending

**Results:** Not started.

---

## Final Results

**Status:** ⚠️ Coder pass complete; QA/audit pending

**What We Built:** Fixed the testbed content-authoring scene so the metadata, warm-up, and cool-down text inputs no longer collapse to tiny widths. The fix stayed inside `.testbed/scenes/ContentAuthoring.tscn` and preserved the prior metadata hint overlap fix.

**Reference Check:** `REF-01`, `REF-03`, and `REF-05` are satisfied for the coder slice: the active metadata scroll content now expands to the full tab width, and the repeated text-entry rows across the metadata/warm-up/cool-down tabs now expand to usable widths. `REF-02` remained intact because the `MetadataStack` overlap fix is still present in the rendered post-fix capture.

**Commits:**
- `7018d65` - Fix testbed content authoring input widths

**Lessons Learned:** In this scene, the width collapse was not just a child-control flag problem. The metadata tab also needed its `ScrollContainer` content root to opt into horizontal expansion, otherwise the form stayed pinned to its minimum width no matter how wide the tab viewport was.

---

*Drafted on 2026-06-04*
