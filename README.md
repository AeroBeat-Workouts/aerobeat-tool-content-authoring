# aerobeat-tool-content-authoring

`aerobeat-tool-content-authoring` is a **Godot-first runtime package** for AeroBeat **manual-authored song-package** authoring.

> **Scope note:** this repo currently targets the richer authored-package lane. It should not be treated as the default BeatSaver imported-player workflow, which is being simplified away from package-required coaching and package-owned environment selection.

Its root contract is no longer a CLI toolchain or a published root-level GodotEnv manifest. The repo now aims at a runtime-capable singleton surface that can eventually run inside built consumers such as `aerobeat-assembly-community`, while `.testbed/` acts as the local GodotEnv-backed verification project for development and manual testing.

## Responsibility boundary

- `aerobeat-content-core` owns canonical song-package contracts and the authoritative validation truth.
- `aerobeat-tool-content-authoring` owns authoring/runtime workflows that operate on those contracts.
- `.testbed/` owns local verification-only dependency sync, placeholder verification assets under `.testbed/assets/`, the automated headless test runner, and future human-facing authoring scenes.

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

## BeatSaver converter foundation

A first staged BeatSaver -> AeroBeat converter foundation now lives in `src/services/importers/beatsaver_stage_conversion_service.gd`.

- staged source acquisition remains owned by `aerobeat-vendor-beatsaver`
- durable package-contract evolution remains owned by `aerobeat-content-core`
- this repo owns the runtime/tool workflow that ingests a staged source package and produces authored package state plus `.artifacts/` provenance

Current Flow posture: the shared Flow v1 authored contract is frozen in `aerobeat-content-core`; normalized Beat Saber `x`, `y`, and `cell` values remain explicit bottom-left source coordinates, while Flow emission transforms notes, bombs, arc heads/tails, burst/chain heads/tails, and obstacle-covered cells exactly once into canonical top-left row-major AeroBeat cells. Boxing keeps its existing explicit source-cell conversion and is not flipped twice. This repo delegates chart/package validation to the shared contract.

Current Boxing posture: each compatible source difficulty produces the four canonical prototype identities—`row_family_balanced_height_v1` and `cut_family_source_height_v1` crossed with Semantic-Track and Spatial-Grid rulesets—plus its Flow chart. The deterministic converter owns 360 ms punch spacing, source lineage, recipe/ruleset/source/content hashes, obstacle-aware 8×6 reach checks without a minimum movement allowance, crossed/relocated instantaneous guards whose full ±180 ms windows exclude punches, instantaneous avoidance checkpoints, and detailed emit/drop traces. Machine-readable parity inputs live under `assets/recipes/`, `assets/rulesets/`, and the sanitized `assets/fixtures/boxing_prototype_golden_v1.json`; no third-party audio or archive is stored there. `AeroContentAuthoring.list_boxing_prototype_recipes()`, `list_boxing_prototype_rulesets()`, and `get_boxing_prototype_contract_id()` are the public discovery entrypoints.

A generated chart’s `prototype.modifiers` identity is the sorted unique union of requested chart modifiers and modifiers emitted by generated events. For example, a requested modifier profile still gains `crossed_guard` when deterministic guard assignment emits a crossed guard; the shared content contract requires every event modifier to appear in the chart identity.

BeatSaver conversion records the extracted source audio as lowercase `sha256:` `audio.contentHash`. Callers may also provide `expectedAudioContentHash` and a staged-path-keyed `expectedDifficultyContentHashes` dictionary; conversion fails explicitly before package publication when declared source bytes do not match.

BeatSaver conversion is intentionally serialized through package save. `convert_beatsaver_stage_to_current_package()` is synchronous and prepares package-token-scoped deferred asset sources; concurrent or overlapping conversion jobs are not supported. Callers must serialize all conversions, and must complete `save_current_package()` before starting another conversion for the same package token, including from another `AeroContentAuthoring` instance. Tests save the baseline package before running independent hash-verification conversions so those jobs cannot replace its deferred workspace.

BeatSaver coverage includes staged archive cover-art import for supported image assets, actual-v4 nested audio/difficulty metadata, legacy v1/v2 note/bomb/obstacle normalization, and late v2.6 slider normalization into Flow arcs. Legacy maps still do **not** claim burst-slider/chain parity or `.egg` → `.ogg` transcoding in this repo. Raw source copies and conversion traces remain package-local under `.artifacts/`, while generated chart records stay free of provider payloads.

See `src/docs/beatsaver-converter-foundation.md` for the foundation slice details.

## Runtime and validation contract

The intended runtime surface is `AeroContentAuthoring`, not `AeroToolManager` and not a CLI wrapper.

The singleton direction for the next slices is:

- create/reset runtime authoring state
- load an authored song package from an **unzipped folder**
- save authored output as an **unzipped folder plus sibling zip archive**
- delegate package validation truth toward `aerobeat-content-core`, including direct Flow chart-contract validation against the shared chart validator
- keep package contract rules centered on canonical authored data

Important implementation notes currently locked for this repo's authored-song-package lane:

- primary + fallback environments are part of the **current authored-song-package implementation seam**, not a universal imported-player rule
- a set without fallback is currently invalid **for this repo's authored-package flow**
- fallback may equal primary
- video/audio preview dependencies are `.testbed` verification concerns, not root package contract dependencies

## Current open seam

Task 3 removes the repo's legacy singleton drift and establishes a song-package-folder workflow surface, but one notable follow-up seam remains:

- `src/services/authoring/chart_authoring_service.gd` still contains quarantined legacy manifest/routine behavior

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
