# AeroBeat Tool Content Authoring Responsibilities

**Date:** 2026-04-25  
**Status:** In Progress  
**Agent:** Chip 🐱‍💻

---

## Goal

Define the responsibilities, boundaries, day-one workflows, and implementation-facing contract for `aerobeat-tool-content-authoring` now that the AeroBeat package format, example workout package, and package/storage/docs contract are locked.

---

## Overview

The package side of AeroBeat is finally in a good place. We now have a locked v1 package contract, aligned polyrepo docs, and a full commented demo workout package in `aerobeat-docs` that shows what a real workout folder should look like. That means the next missing piece is no longer “what does the content look like?” — it is “what exactly is the authoring tool responsible for doing with that content?” Source: `memory/2026-04-24.md#L1-L20`, `memory/2026-04-21.md#L53-L72`

This plan is for definition work, not implementation yet. The goal is to turn `aerobeat-tool-content-authoring` from a generally-correct repo concept into an explicit product contract: what jobs it owns, what jobs belong elsewhere, what the first real creator workflows are, what headless/CLI surfaces are required, what optional editor surfaces are justified, and how it should interact with `aerobeat-content-core`, the demo workout package examples, and future package validation/discovery flows.

This work belongs in `aerobeat-tool-content-authoring` because the question is specifically about that repo’s responsibilities. Some outputs will likely land in `aerobeat-docs` too, but the owning plan should live with the tool repo.

---

## REFERENCES

| ID | Description | Path |
| --- | --- | --- |
| `REF-01` | Current package/storage contract | `projects/aerobeat/aerobeat-docs/docs/architecture/workout-package-storage-and-discovery.md` |
| `REF-02` | Current content model | `projects/aerobeat/aerobeat-docs/docs/architecture/content-model.md` |
| `REF-03` | Demo workout package guide | `projects/aerobeat/aerobeat-docs/docs/guides/demo_workout_package.md` |
| `REF-04` | Demo workout package example | `projects/aerobeat/aerobeat-docs/docs/examples/workout-packages/demo-neon-boxing-bootcamp/` |
| `REF-05` | Existing content-core/tool definition lineage | `projects/aerobeat/aerobeat-content-core/.plans/2026-04-23-aerobeat-content-core-first-implementation-slice.md` |
| `REF-06` | Prior memory on tool-repo identity and shared service direction | `memory/2026-04-21.md#L53-L72` |
| `REF-07` | Recent implementation handoff mentioning first real tool slice | `memory/2026-04-24.md#L1-L20` |

---

## Tasks

### Task 1: Define the core responsibility boundary of `aerobeat-tool-content-authoring`

**Bead ID:** `aerobeat-tool-content-authoring-nre`  
**SubAgent:** `primary` (for `research`)  
**Role:** `research`  
**References:** `REF-01`, `REF-02`, `REF-05`, `REF-06`, `REF-07`  
**Prompt:** Define what `aerobeat-tool-content-authoring` owns versus what belongs in `aerobeat-content-core`, feature repos, and future service/distribution layers. Make the repo’s job explicit: authoring, editing, validation, packaging, migration, import/export, install helpers, inspection, and what is intentionally out of scope on day one.

**Folders Created/Deleted/Modified:**
- `.plans/`
- likely repo docs/README surfaces
- maybe `aerobeat-docs` if canonical architecture docs need a follow-up

**Files Created/Deleted/Modified:**
- this plan file
- likely definition docs/README updates

**Status:** ✅ Complete

**Results:** Defined the repo as a headless-first package authoring and package-operations tool, not a schema or runtime repo. Captured explicit ownership boundaries in `docs/content-authoring-tool-definition.md`, including what belongs in `aerobeat-content-core`, feature repos, and future service/distribution layers. Updated `README.md` to point at the new definition doc. Validated against `REF-01`, `REF-02`, and `REF-05`.

---

### Task 2: Define the day-one creator workflows and tool surfaces

**Bead ID:** `aerobeat-tool-content-authoring-voh`  
**SubAgent:** `primary` (for `research`)  
**Role:** `research`  
**References:** `REF-01`, `REF-03`, `REF-04`, `REF-06`, `REF-07`  
**Prompt:** Define the first concrete creator workflows the tool must support using the now-locked package shape and demo workout package as the teaching baseline. Clarify the minimum required surfaces: headless CLI commands, shared service layer, optional editor/UI surfaces, and which workflows are must-have versus later expansion.

**Folders Created/Deleted/Modified:**
- `.plans/`
- likely repo docs/README surfaces
- maybe `aerobeat-docs`

**Files Created/Deleted/Modified:**
- this plan file
- likely workflow definition docs

**Status:** ✅ Complete

**Results:** Defined the honest day-one creator workflows and surfaces in `docs/content-authoring-tool-definition.md`: scaffold package, inspect package, validate package, scaffold/add records, prepare export/submission payloads, and preview/apply migrations. Clarified the split between required shared services, required CLI, and optional thin editor shell. Also documented explicit non-day-one scope to avoid UI and service sprawl. Validated against `REF-01`, `REF-03`, and `REF-04`.

---

### Task 3: Define the content-authoring tool contract against the package example and content core

**Bead ID:** `aerobeat-tool-content-authoring-gzz`  
**SubAgent:** `primary` (for `research`)  
**Role:** `research`  
**References:** `REF-01`, `REF-02`, `REF-03`, `REF-04`, `REF-05`  
**Prompt:** Define how the tool should relate to the demo workout package and `aerobeat-content-core`: what it reads, what it writes, what it validates, what it can scaffold, what it must never silently mutate, and which responsibilities remain in content-core versus tool-side orchestration.

**Folders Created/Deleted/Modified:**
- `.plans/`
- likely repo docs/README surfaces
- maybe `aerobeat-docs`

**Files Created/Deleted/Modified:**
- this plan file
- likely contract or workflow docs

**Status:** ✅ Complete

**Results:** Defined the tool contract against the locked package example and content-core in `docs/content-authoring-tool-definition.md`. Documented what the tool reads, what it may write through explicit operations, what it validates, what it scaffolds, what migrations it fronts, and what it must not silently mutate. The contract is anchored to the demo workout package and to `aerobeat-content-core` as the owner of canonical record meaning and shared validation/migration interfaces. Validated against `REF-01` through `REF-05`.

---

### Task 4: Convert the agreed responsibilities into an implementation-ready plan

**Bead ID:** `aerobeat-tool-content-authoring-eu3`  
**SubAgent:** `primary` (for `primary`)  
**Role:** `primary`  
**References:** `REF-01` through `REF-07`  
**Prompt:** After Derrick approves the responsibilities and workflows, convert this definition plan into an implementation-ready plan with explicit Beads, coder → QA → auditor sequencing, concrete file targets, and validation expectations for the first `aerobeat-tool-content-authoring` slice.

**Folders Created/Deleted/Modified:**
- `.plans/`

**Files Created/Deleted/Modified:**
- this plan file
- any final definition docs that become source of truth

**Status:** ⏳ Pending discussion

**Results:** Blocked until the responsibility/workflow definition is approved.

---

## Current Discussion Direction

The package contract is now strong enough that the authoring tool should be defined against something concrete instead of hypothetical shapes.

That means this definition pass should answer things like:

- Is the tool primarily a package authoring tool, a validator, a migration tool, an installer, or some staged combination?
- Which package records can it create from scratch on day one?
- Which records are safe to edit directly versus generated/derived by tool workflows?
- What should the CLI be able to do with the demo workout package immediately?
- What belongs in a shared service layer versus a CLI wrapper versus a future editor UI?
- What should the tool read from `aerobeat-content-core` rather than re-own?

---

## Open Questions To Resolve In This Pass

1. What is the minimum honest day-one scope of `aerobeat-tool-content-authoring` now that the package format is defined?
2. Which workflows are first-class on day one: scaffold, inspect, validate, edit, migrate, package, install, export, import?
3. Which operations should be headless-first CLI commands, and which are only justified once a richer editor exists?
4. What exact responsibilities stay in `aerobeat-content-core` so the tool repo does not duplicate contract logic incorrectly?
5. How should the demo workout package influence the tool contract — as docs only, as fixture input, as scaffold template, or some combination?
6. What does “shared service layer used by both CLI and optional editor” mean concretely for this repo now that the package shape is no longer theoretical?

---

## Final Results

**Status:** ⚠️ Partial

**What We Built:** Completed the definition pass for the tool repo's responsibility boundary, day-one workflows/surfaces, and package/content-core contract. Added `docs/content-authoring-tool-definition.md` as the repo-local source of truth, updated `README.md` to point at it, and updated this plan with actual results for Tasks 1-3. Task 4 remains intentionally pending until Derrick approves the proposed definition and wants the implementation-ready plan.

**Reference Check:** Tasks 1-3 were grounded in `REF-01` through `REF-05`, especially the locked package/storage contract, content-model ownership split, demo workout package example, and the earlier content-core definition plan.

**Commits:**
- Pending definition-pass commit.

**Lessons Learned:** The cleanest boundary is package-operations ownership. The tool stays useful and coherent when it is scoped to explicit package workflows and shared-service-backed authoring operations rather than drifting into schema ownership, runtime concerns, or future service/catalog behavior.

---

*Updated on 2026-04-25*
