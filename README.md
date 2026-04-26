# aerobeat-tool-content-authoring

`aerobeat-tool-content-authoring` is the first concrete **Tool-lane** repo for AeroBeat content authoring.

It exists to give humans, CI, and other automation a shared place to **author, inspect, validate, migrate, package, and transform canonical AeroBeat workout packages**. This repo owns those workflows; it does **not** own the durable meaning of the content itself.

The current definition-phase source of truth for repo scope, day-one workflows, and the package/content-core contract lives in:

- [`docs/content-authoring-tool-definition.md`](docs/content-authoring-tool-definition.md)

That definition also locks the downstream catalog stance for future tooling: local and remote workout catalogs should project from one shared browse core (`workouts`, `tags`, `modes`, `difficulties`, `songs`, `coaches`, `genres`) with companion tables `workout_local` and `workout_remote`, rather than divergent local-vs-remote schemas.

## Purpose

This repo sits on top of the approved lane-based architecture:

- `aerobeat-content-core` owns canonical content contracts such as `Song`, `Routine`, `Chart`, `Workout`, shared chart-envelope contracts, manifests, ids, and shared structural validation rules.
- `aerobeat-tool-core` owns shared tool-side DTOs, operation/result models, progress/report contracts, and other tooling-common interfaces.
- `aerobeat-tool-content-authoring` owns the concrete workflows that operate on that content: authoring, validation orchestration, migration, packaging, import/export, and inspection.

If a behavior belongs to canonical schema ownership, it should live in `aerobeat-content-core`. If it belongs to gameplay runtime logic or presentation, it should live in `aerobeat-feature-core` or a concrete `aerobeat-feature-*` repo instead.

## Headless-first architecture

This repo now follows the intended day-one split:

- `services/` is the **canonical workflow layer**.
- `cli/` is a **thin headless surface** that delegates to shared services.
- `editor/` is **optional scaffolding only**, and it also delegates to shared services instead of duplicating logic.
- `mappers/` convert normalized service reports into output-friendly or UI-friendly shapes.
- `tests/` verify that the service layer is the authority and that both CLI and editor entrypoints depend on it.

The important rule is:

> CLI/headless workflows and editor/interactive workflows must call the same service layer.

### Current scaffolded workflow slices

The repo now includes a minimal but real first slice for:

- authoring service boundaries for routines, workouts, and charts
- package validation aligned to the `aerobeat-content-core` fixture path shape
- packaging/build workflow scaffolding
- migration and import workflow scaffolding
- inspection and formatting helpers for CLI use
- an editor plugin scaffold that resolves shared services instead of implementing parallel logic

## Repository shape

```text
aerobeat-tool-content-authoring/
├── interfaces/
├── services/
│   ├── authoring/
│   ├── validation/
│   ├── migration/
│   ├── packaging/
│   ├── importers/
│   └── registry/
├── cli/
│   ├── commands/
│   └── formatters/
├── editor/
│   ├── plugins/
│   ├── docks/
│   ├── inspectors/
│   └── view_models/
├── mappers/
├── tests/
├── plugin.cfg
└── addons.jsonc
```

## Shared-service rule in practice

Examples from the current scaffold:

- `cli/commands/validate_command.gd` calls `services/validation/validate_package_service.gd`
- `cli/commands/package_command.gd` calls `services/packaging/build_content_package_service.gd`
- `editor/plugins/content_authoring_plugin.gd` exposes the same shared validation and packaging services for future editor UI
- report formatting is kept in `cli/formatters/` and `mappers/`, not embedded inside the service layer

## What this repo should own

This repo is the correct home for workflow-oriented content tooling such as:

- authoring services for routines, workouts, and charts
- validation orchestration for packages and charts
- migration workflows for approved schema changes
- package-building flows
- import/export adapters
- inspection and indexing helpers
- thin CLI commands and optional editor UI built on shared services

## What this repo should not own

This repo should **not** become a schema repo or a gameplay repo.

Keep the following out of this repo:

- canonical content contract definitions that belong in `aerobeat-content-core`
- gameplay scoring/runtime execution logic
- feature/runtime presentation systems
- mode-specific gameplay interpretation that belongs in `aerobeat-feature-*`
- a replacement for `aerobeat-tool-core`

## GodotEnv development flow

This repo uses the AeroBeat GodotEnv package convention.

- Canonical package dependency manifest: `addons.jsonc`
- Canonical dev/test manifest: `.testbed/addons.jsonc`
- Installed dev/test addons: `.testbed/addons/`
- GodotEnv cache: `.testbed/.addons/`
- Hidden workbench project: `.testbed/project.godot`
- Root workflow tests: `tests/`

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

### Run the headless workflow tests

From the repo root:

```bash
godot --headless --path .testbed --script ../tests/run_tool_tests.gd
```

## Validation notes

- The authoritative runnable validation path is the headless workflow runner at `tests/run_tool_tests.gd`, executed with `godot --headless --path .testbed --script ../tests/run_tool_tests.gd`.
- `.testbed` is the hidden import/workbench project used to restore addons and provide a Godot project context for headless execution; it is not a separate authoritative test suite.
- The validation scaffold should stay aligned to the approved package shape described in `docs/content-authoring-tool-definition.md` (`workout.yaml`, `songs/`, `routines/`, `charts/`, `coaches/`, `environments/`, `assets/`, `media/`).
- The service layer currently performs lightweight structural validation suitable for the first scaffold slice.
- As richer shared contracts land in `aerobeat-content-core` and `aerobeat-tool-core`, those services should tighten around those canonical DTOs rather than growing duplicate schema logic here.
