# aerobeat-tool-content-authoring

`aerobeat-tool-content-authoring` is a **Godot-first runtime package** for AeroBeat workout authoring.

Its root contract is no longer a CLI toolchain or a published root-level GodotEnv manifest. The repo now aims at a runtime-capable singleton surface that can eventually run inside built consumers such as `aerobeat-assembly-community`, while `.testbed/` acts as the local GodotEnv-backed verification project for development and manual testing.

## Responsibility boundary

- `aerobeat-content-core` owns canonical workout-package contracts and the authoritative validation truth.
- `aerobeat-tool-content-authoring` owns authoring/runtime workflows that operate on those contracts.
- `.testbed/` owns local verification-only dependency sync, the automated headless test runner, and future human-facing authoring scenes.

If a rule changes the meaning of the package contract, it belongs in `aerobeat-content-core`, not here.

## Current architecture direction

The repo is being refactored toward a single runtime authority:

- `src/AeroContentAuthoring.gd` is the public singleton/runtime entrypoint.
- `src/services/` holds reusable workflow services used by the singleton.
- `src/editor/plugins/content_authoring_plugin.gd` is only a thin editor bridge over the same runtime registry.
- `.testbed/` is the Godot project used to sync local addons, import the package, and host future manual authoring UI.

This makes the repo truthful for eventual in-game/runtime consumption instead of treating Godot usage as a sidecar around a headless CLI.

## Repository shape

```text
aerobeat-tool-content-authoring/
├── .testbed/
│   ├── addons.jsonc
│   ├── assets/
│   ├── project.godot
│   ├── scenes/
│   └── scripts/
│       └── tests/
├── plugin.cfg
├── README.md
└── src/
    ├── AeroContentAuthoring.gd
    ├── assets/
    ├── docs/
    ├── editor/
    ├── interfaces/
    ├── mappers/
    └── services/
```

## GodotEnv posture

Root-level GodotEnv publication state has been removed from this repo.

The only addon sync manifest that should exist here is:

- `.testbed/addons.jsonc`

The only locally generated addon trees that should exist are:

- `.testbed/addons/`
- `.testbed/.addons/`

Those are development artifacts, not published package contract files.

## Runtime and validation contract

The intended runtime surface is `AeroContentAuthoring`, not `AeroToolManager` and not a CLI wrapper.

The singleton direction for the next slices is:

- create/reset runtime authoring state
- load an authored workout from an **unzipped folder**
- save authored output as an **unzipped folder plus sibling zip archive**
- delegate package validation truth toward `aerobeat-content-core` where the validator is runtime-loadable
- keep package contract rules centered on canonical authored data

Important contract notes already locked for follow-up implementation:

- primary + fallback environments are canonical set data
- a set without fallback is invalid
- fallback may equal primary
- video/audio preview dependencies are `.testbed` verification concerns, not root package contract dependencies

## Current open seam

Task 3 removes the repo's legacy singleton drift and establishes a workout-folder workflow surface, but two follow-up seams remain:

- `services/authoring/chart_authoring_service.gd` still contains quarantined legacy manifest/routine behavior
- `aerobeat-content-core` validation is only directly delegatable once that repo exposes a runtime-loadable addon/root-safe validator script

## Local development

Restore local testbed dependencies:

```bash
cd .testbed
godotenv addons install
```

Import the verification project:

```bash
godot --headless --path .testbed --import
```

Run the current repo validation tests:

```bash
godot --headless --path .testbed --script scripts/tests/run_tool_tests.gd
```
