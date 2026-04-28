extends RefCounted

const AudioMetadataImportService = preload("../services/importers/audio_metadata_import_service.gd")

static func run() -> Dictionary:
	var fixture_path := ProjectSettings.globalize_path("res://tmp/audio_metadata_import_service/demo-song.ogg")
	_ensure_parent_dir(fixture_path)
	_ensure_fixture_file(fixture_path)

	var result: Dictionary = AudioMetadataImportService.new().import_source(fixture_path, {
		"songId": "song_demo_imported",
		"songName": "Demo Imported Song",
		"anchorMs": 24,
		"tempoSegments": [
			{"startBeat": 0, "bpm": 128},
			{"startBeat": 64, "bpm": 132},
		],
		"stopSegments": [
			{"startBeat": 32, "durationMs": 500},
		],
		"timeSignatureSegments": [
			{"startBeat": 0, "numerator": 4, "denominator": 4},
		],
	})
	var record: Dictionary = result.get("record", {})
	var timing: Dictionary = record.get("timing", {})
	var passed := bool(result.get("ok", false)) \
		and String(result.get("recordKind", "")) == "song" \
		and String(record.get("songId", "")) == "song_demo_imported" \
		and String(record.get("songName", "")) == "Demo Imported Song" \
		and String(record.get("title", "")) == "" \
		and String(record.get("audio", {}).get("resourcePath", "")) == fixture_path \
		and int(timing.get("anchorMs", -1)) == 24 \
		and Array(timing.get("tempoSegments", [])).size() == 2 \
		and Array(timing.get("stopSegments", [])).size() == 1 \
		and Array(timing.get("timeSignatureSegments", [])).size() == 1 \
		and not timing.has("bpm")
	return {
		"name": "test_audio_metadata_import_service",
		"passed": passed,
		"details": {
			"fixturePath": fixture_path,
			"result": result,
			"record": record,
			"timing": timing,
		},
	}

static func _ensure_parent_dir(path: String) -> void:
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())

static func _ensure_fixture_file(path: String) -> void:
	if FileAccess.file_exists(path):
		return
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file != null:
		file.store_buffer(PackedByteArray([0x4f, 0x67, 0x67, 0x53]))
