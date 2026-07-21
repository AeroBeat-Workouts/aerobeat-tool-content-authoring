# BeatSaver converter foundation

This repo now owns the first honest staged BeatSaver -> AeroBeat authoring foundation.

Current scope:
- ingest a staged BeatSaver directory that contains `source_material_manifest.json` plus the staged ZIP
- support BeatSaver Standard difficulty files in v3/v4 object form for full beat-object conversion
- inspect and normalize legacy v2/v1 staged metadata + Standard difficulty selection truthfully before conversion
- normalize legacy v2/v1 note/bomb/obstacle beat objects into the current Boxing/Flow source families for authored chart emission
- parse both legacy v2.x/v3-style Info metadata and actual v4 `Info.dat` nested `song` / `audio` / `difficultyBeatmaps` metadata when selecting Standard difficulties, BPM, primary song audio, preview timing, and dedicated preview-file truth
- emit canonical song-package-shaped authored output in repo-local runtime state
- convert Boxing v1 source semantics into canonical Boxing chart beats
- convert Flow v1 Standard-map semantics into canonical Flow `note`, `burst`, `bomb`, `obstacle`, and `arc` beats
- import supported staged cover-art assets into canonical package `image_background` environment output, including explicit `.jpg` / `.jpeg` coverage
- preserve BeatSaver preview truth into the shared song-audio contract: `previewFilePath`, `previewUrl`, `previewStartTime`, `previewDuration`, and converter-authored `previewMode`
- preserve source/provenance/debug material under package-local `.artifacts/beatsaver/`

Coverage currently proved in-repo:
- synthetic staged v3 conversion fixture with saved `cover.png` package output checks plus preserved preview URL/timing truth and `previewMode: song_file_clip`
- synthetic staged `.jpg` / `.jpeg` cover-art import fixtures with saved folder + zip package checks
- synthetic staged v4 beat-object normalization fixture plus preserved preview URL truth and `previewMode: preview_url`
- synthetic actual-v4-info fixture with nested `audio.songFilename`, nested `audio.songPreviewFilename`, preserved preview timing, preserved preview URL, extracted preview asset output, and `previewMode: preview_file`
- synthetic legacy v1 staged fixture proving Standard-only difficulty selection plus normalized song/audio/cover metadata inspection
- synthetic legacy v2 conversion fixture proving truthful Boxing + Flow note/bomb/obstacle emission from legacy beat objects without inventing slider/chain support
- real-world staged Starlight `524b6` v3 probe through the shared-contract validation path
- real-world staged legacy map `1` full conversion through shared package/chart validation, proving v2 metadata+difficulty normalization and legacy note/bomb/obstacle authored emission are both real

Important seam kept honest:
- Flow's direct 4x3 gameplay rules and the minimum shared authored contract now align across this repo and `aerobeat-content-core`
- Flow chart validation now delegates directly to the shared `aerobeat-content-core` chart validator instead of mirroring the Flow beat contract locally
- package-level validation now surfaces shared-validator availability truth and fails explicitly when `aerobeat-content-core` cannot be loaded, instead of silently passing via local fallback
- raw BeatSaver source plus conversion traces still stay in `.artifacts/beatsaver/conversion/report.json` and source snapshots so package output remains AeroBeat-native without losing provenance

Current honest legacy seam:
- `AeroContentAuthoring.inspect_beatsaver_stage_source(...)` / `BeatSaverStageConversionService.inspect_stage(...)` expose normalized staged metadata+difficulty truth for legacy v2/v1 packages
- full authored conversion now also supports legacy v2/v1 note, bomb, and obstacle objects via adapters into the current normalized source families consumed by Boxing + Flow conversion
- legacy sliders/chains/arcs remain unsupported because v1/v2 source maps do not provide those modern families directly and this slice does not invent faux parity
- no `.egg` -> `.ogg` transcoding is attempted in this slice

This keeps repo boundaries truthful:
- BeatSaver fetching/staging still belongs in `aerobeat-vendor-beatsaver`
- durable content-schema expansion still belongs in `aerobeat-content-core`
- this repo owns the runtime/tool workflow that turns a staged source package into authored AeroBeat package state
