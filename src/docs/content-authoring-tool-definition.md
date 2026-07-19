# AeroBeat Content Authoring Tool Definition

**Date:** 2026-06-01
**Status:** In-progress refactor definition
**Repo:** `aerobeat-tool-content-authoring`

---

## Goal

Define the Godot-first runtime architecture for `aerobeat-tool-content-authoring` so the repo truthfully reflects where **manual-authored workout-package** creation is going.

> **Scope note:** this definition is for the authored-package lane. It should not be read as the default BeatSaver imported-player contract, which is being simplified away from package-required coaching and package-owned environment selection.

This document is intentionally narrower than the older CLI-first definition. It records the approved runtime direction for the refactor slices now in progress.

---

## 1. Product stance

`aerobeat-tool-content-authoring` is a **runtime-capable Godot authoring package** for canonical AeroBeat workout content.

It is not the schema authority and it is not a CLI product anymore.

In plain terms:

- `aerobeat-content-core` owns canonical content contracts and validation truth.
- `aerobeat-tool-content-authoring` owns authoring/runtime workflows over those contracts.
- `.testbed/` owns local dependency sync and human verification scaffolding.

If `aerobeat-content-core` defines what valid content means, this repo defines how a Godot runtime and future creator UI work with that content.

---

## 2. Architecture target

### Root runtime surface

The root public surface should be a real singleton:

- `src/AeroContentAuthoring.gd`

That singleton is the runtime authority for package authoring behavior. Editor tools, testbed UI, and future embedded consumers should call into the same runtime surface rather than maintaining separate business-logic paths.

`src/AeroToolManager.gd` is no longer the truthful root concept and should not remain the public direction.

### Repo layout stance

The repo root is no longer treated as a published GodotEnv package manifest surface.

Removed root posture:

- root `addons.jsonc`
- root `addons/`
- root `.addons/`
- CLI-first package language in public docs/config

Retained local verification posture:

- `.testbed/addons.jsonc`
- `.testbed/addons/` as a generated local sync tree
- `.testbed/.addons/` as a generated local cache tree
- `.testbed/project.godot` as the local verification project

### Editor/testbed relationship

- `editor/` remains a thin bridge layer only.
- `.testbed/` becomes the primary local human-verification surface.
- future creator-facing scenes belong in `.testbed/` until the runtime is ready to embed elsewhere.

---

## 3. Validation and package truth

Validation truth belongs to `aerobeat-content-core`.

This repo may orchestrate validation and surface reports, but it should not become a shadow schema owner.

The approved package-direction rules relevant to this refactor are:

- load targets an **unzipped workout folder**
- save emits an **unzipped workout folder plus a sibling zip archive**
- primary + fallback environments are part of the **current authored-workout implementation seam**, not a universal imported-player rule
- a set without a fallback environment is currently invalid **for this repo's authored-package flow**
- fallback may equal primary
- video/audio previews are `.testbed` verification dependencies, not root package contract dependencies
- no compatibility layer should preserve the old CLI-first system as an ongoing public surface

---

## 4. Runtime responsibility boundary

### This repo owns

- runtime authoring orchestration
- package load/save workflow orchestration
- package inspection/reporting helpers
- package validation orchestration over `aerobeat-content-core`
- future testbed/editor UI that calls the same runtime surface

### This repo does not own

- canonical schema definitions
- long-term duplication of validation rules already defined in `aerobeat-content-core`
- old CLI compatibility as a product surface
- testbed-only preview dependencies as package-contract requirements

---

## 5. Current refactor seam

Task 2 is the architecture/layout migration slice, not the full authoring implementation slice.

That means the repo can truthfully move to the new runtime direction now, while still carrying one explicit seam forward:

- some legacy authoring behavior still exists in `services/authoring/chart_authoring_service.gd`

That seam is temporary and should be replaced by real `AeroContentAuthoring` workout-folder workflows in the next implementation slice rather than hidden behind compatibility language.

---

## 6. Near-term implementation target

The next implementation slice should make `AeroContentAuthoring` able to:

1. create a new workout package state
2. reset current authoring state
3. load an unzipped workout package folder
4. validate that package through `aerobeat-content-core`
5. save authored output as a folder plus sibling zip archive

That is the truthful minimal runtime contract for eventual use inside `aerobeat-assembly-community`.

---

## 7. Bottom line

`aerobeat-tool-content-authoring` is no longer defined as a headless-first CLI toolchain.

It is being refactored into a Godot-first, runtime-capable authoring package centered on `AeroContentAuthoring`, with `.testbed/` as the local sync and verification environment and `aerobeat-content-core` as the validation truth point.
