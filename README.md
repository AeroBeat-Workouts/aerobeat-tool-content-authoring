# aerobeat-tool-content-authoring

`aerobeat-tool-content-authoring` is the first concrete **Tool-lane** repo for AeroBeat content authoring.

It exists to give humans, CI, and other automation a shared place to **author, inspect, validate, migrate, package, and transform canonical AeroBeat content**. This repo owns those workflows; it does **not** own the durable meaning of the content itself.

## Purpose

This repo sits on top of the approved lane-based architecture:

- `aerobeat-content-core` owns canonical content contracts such as `Song`, `Routine`, `Chart Variant`, `Workout`, shared chart-envelope contracts, manifests, ids, and shared structural validation rules.
- `aerobeat-tool-core` owns shared tool-side DTOs, operation/result models, progress/report contracts, and other tooling-common interfaces.
- `aerobeat-tool-content-authoring` owns the concrete workflows that operate on that content: authoring, validation orchestration, migration, packaging, import/export, and inspection.

If a behavior belongs to canonical schema ownership, it should live in `aerobeat-content-core`. If it belongs to gameplay runtime logic or presentation, it should live in `aerobeat-feature-core` or a concrete `aerobeat-feature-*` repo instead.

## Architectural position

This repo is intentionally a **workflow product**, not a schema repo and not a gameplay repo.

It should make the following split explicit:

- **Depends on `aerobeat-content-core`** for durable content records, ids, manifests, registry/query interfaces, migration contracts, and shared validators.
- **Depends on `aerobeat-tool-core`** for tool-common contracts, operation-state models, and shared tool-side interfaces.
- **Does not own canonical content schemas** like `Song`, `Routine`, `Chart Variant`, or `Workout`.
- **Does not own gameplay runtime logic** such as scoring, spawning, runtime interpretation, 2D lanes, 3D portals, or other feature-side visuals.

## Shared-service rule

The key rule for this repo is:

> Headless/CLI workflows and optional editor UX must share one service layer.

That means:

- CLI/headless validation should call the same validation services used by any future editor action.
- Non-interactive migration and packaging flows should call the same core workflow services used by interactive tooling.
- Editor code should stay thin and orchestrate shared services instead of becoming a second validation or schema engine.

In practice, the long-term structure for this repo should separate:

- `services/` as the canonical workflow layer
- `cli/` as a thin headless surface over those services
- `editor/` as an optional interactive surface over the same services

## What this repo should own

This repo is the correct home for workflow-oriented content tooling such as:

- authoring services for routines, workouts, and chart variants
- validation orchestration for packages and charts
- migration workflows for approved schema changes
- package-building flows
- import/export adapters
- inspection and indexing helpers
- thin CLI commands and optional editor UI built on shared services

## What this repo should not own

This repo should **not** become a grab bag for unrelated architecture concerns.

Keep the following out of this repo:

- canonical content contract definitions that belong in `aerobeat-content-core`
- gameplay scoring/runtime execution logic
- feature/runtime presentation systems
- mode-specific gameplay interpretation that belongs in `aerobeat-feature-*`
- a replacement for `aerobeat-tool-core`

## Current state

This repository is currently scaffolded from the AeroBeat Tool template and is being aligned to the approved architecture.

That means the repo identity is now specific, but the deeper implementation work still needs to land. The next iterations should build out the shared workflow service layer first, keep headless/CLI support first-class from day one, and add editor UX only as a thin layer over those same services.

## GodotEnv development flow

This repo uses the AeroBeat GodotEnv package convention.

- Canonical dev/test manifest: `.testbed/addons.jsonc`
- Installed dev/test addons: `.testbed/addons/`
- GodotEnv cache: `.testbed/.addons/`
- Hidden workbench project: `.testbed/project.godot`
- Repo-local unit tests: `.testbed/tests/`

The repo root remains the package/published boundary for downstream consumers. Day-to-day development, debugging, and validation happen from the hidden `.testbed/` workbench using the pinned OpenClaw toolchain: Godot `4.6.2 stable standard`.

### Restore dev/test dependencies

From the repo root:

```bash
cd .testbed
godotenv addons install
```

### Open the workbench

From the repo root:

```bash
godot --editor --path .testbed
```

### Import smoke check

From the repo root:

```bash
godot --headless --path .testbed --import
```

### Run unit tests

From the repo root:

```bash
godot --headless --path .testbed --script addons/gut/gut_cmdln.gd \
  -gdir=res://tests \
  -ginclude_subdirs \
  -gexit
```

## Validation notes

- `.testbed/addons.jsonc` is the committed dev/test dependency contract.
- This repo should depend on `aerobeat-tool-core` and `aerobeat-content-core`, not a legacy catch-all `aerobeat-core` package.
- Repo-local tests should verify that CLI/headless and editor entrypoints use the same shared services as implementation fills in.
- The current package shape is still consumed from the repo root (`subfolder: "/"`) for downstream installs.
