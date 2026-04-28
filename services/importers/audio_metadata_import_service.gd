class_name AudioMetadataImportService
extends "../../interfaces/import_export_service.gd"

const DEFAULT_TEMPO_BPM := 120

func import_source(source_path: String, options: Dictionary = {}) -> Dictionary:
	var file_name: String = source_path.get_file().get_basename()
	var default_song_name: String = file_name.capitalize()
	var song_name: String = String(options.get("songName", options.get("title", default_song_name)))
	var bpm_value: Variant = options.get("bpm", DEFAULT_TEMPO_BPM)
	var anchor_ms: int = int(options.get("anchorMs", 0))
	return {
		"ok": FileAccess.file_exists(source_path),
		"sourcePath": source_path,
		"recordKind": "song",
		"record": {
			"schema": "aerobeat.content.song.v1",
			"songId": String(options.get("songId", file_name.to_lower().replace(" ", "_"))),
			"songName": song_name,
			"audio": {
				"resourcePath": source_path,
			},
			"timing": {
				"anchorMs": anchor_ms,
				"tempoSegments": options.get("tempoSegments", [
					{
						"startBeat": 0,
						"bpm": bpm_value,
					}
				]),
				"stopSegments": options.get("stopSegments", []),
				"timeSignatureSegments": options.get("timeSignatureSegments", [
					{
						"startBeat": 0,
						"numerator": 4,
						"denominator": 4,
					}
				]),
			},
		},
	}
