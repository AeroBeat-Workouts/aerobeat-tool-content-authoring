# BeatSaver converter foundation

This repo now owns the first honest staged BeatSaver -> AeroBeat authoring foundation.

Current scope:
- ingest a staged BeatSaver directory that contains `source_material_manifest.json` plus the staged ZIP
- support BeatSaver Standard difficulty files in v3/v4 object form
- parse both legacy v2.x/v3-style Info metadata and actual v4 `Info.dat` nested `song` / `audio` / `difficultyBeatmaps` metadata when selecting Standard difficulties, BPM, and primary song audio
- emit canonical song-package-shaped authored output in repo-local runtime state
- convert Boxing v1 source semantics into canonical Boxing chart beats
- convert Flow v1 Standard-map semantics into canonical Flow `note`, `burst`, `bomb`, `obstacle`, and `arc` beats
- preserve source/provenance/debug material under package-local `.artifacts/beatsaver/`

Coverage currently proved in-repo:
- synthetic staged v3 conversion fixture
- synthetic staged v4 beat-object normalization fixture
- synthetic actual-v4-info fixture with nested `audio.songFilename`, separate `songPreviewFilename`, `BPMInfo.dat`, `lightshowDataFilename`, and ignored non-Standard sidecar/custom-data permutations
- real-world staged Starlight `524b6` v3 probe through the shared-contract validation path
- real-world staged legacy map `1` rejection coverage, proving we still fail honestly on unsupported v2 beatmap payloads instead of pretending successful conversion

Important seam kept honest:
- Flow's direct 4x3 gameplay rules and the minimum shared authored contract now align across this repo and `aerobeat-content-core`
- Flow chart validation now delegates directly to the shared `aerobeat-content-core` chart validator instead of mirroring the Flow beat contract locally
- package-level validation now surfaces shared-validator availability truth and fails explicitly when `aerobeat-content-core` cannot be loaded, instead of silently passing via local fallback
- raw BeatSaver source plus conversion traces still stay in `.artifacts/beatsaver/conversion/report.json` and source snapshots so package output remains AeroBeat-native without losing provenance

This keeps repo boundaries truthful:
- BeatSaver fetching/staging still belongs in `aerobeat-vendor-beatsaver`
- durable content-schema expansion still belongs in `aerobeat-content-core`
- this repo owns the runtime/tool workflow that turns a staged source package into authored AeroBeat package state
