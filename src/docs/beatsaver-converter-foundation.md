# BeatSaver converter foundation

This repo now owns the first honest staged BeatSaver -> AeroBeat authoring foundation.

Current scope:
- ingest a staged BeatSaver directory that contains `source_material_manifest.json` plus the staged ZIP
- support BeatSaver Standard difficulty files in v3/v4 object form
- emit canonical song-package-shaped authored output in repo-local runtime state
- convert Boxing v1 source semantics into canonical Boxing chart beats
- convert Flow v1 Standard-map semantics into canonical Flow `note`, `burst`, `bomb`, `obstacle`, and `arc` beats
- preserve source/provenance/debug material under package-local `.artifacts/beatsaver/`

Important seam kept honest:
- Flow's direct 4x3 gameplay rules and the minimum shared authored contract now align across this repo and `aerobeat-content-core`
- raw BeatSaver source plus conversion traces still stay in `.artifacts/beatsaver/conversion/report.json` and source snapshots so package output remains AeroBeat-native without losing provenance

This keeps repo boundaries truthful:
- BeatSaver fetching/staging still belongs in `aerobeat-vendor-beatsaver`
- durable content-schema expansion still belongs in `aerobeat-content-core`
- this repo owns the runtime/tool workflow that turns a staged source package into authored AeroBeat package state
