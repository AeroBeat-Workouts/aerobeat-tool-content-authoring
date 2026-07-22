class_name SongPackageAuthoringService
extends "../../interfaces/authoring_service.gd"

const DEFAULT_SCHEMA := "aerobeat.song-package.v1"

func upsert_record(record_data: Dictionary) -> Dictionary:
	var song_package := {
		"schemaId": String(record_data.get("schemaId", DEFAULT_SCHEMA)).strip_edges(),
		"schemaVersion": int(record_data.get("schemaVersion", 1)),
		"packageVersion": String(record_data.get("packageVersion", "1.0.0")).strip_edges(),
		"songId": String(record_data.get("songId", "")).strip_edges(),
		"songName": String(record_data.get("songName", record_data.get("title", ""))).strip_edges(),
		"charts": _normalize_chart_descriptors(record_data.get("charts", [])),
	}
	return {
		"ok": not String(song_package.get("songId", "")).is_empty(),
		"recordKind": "songPackage",
		"record": song_package,
	}

func _normalize_chart_descriptors(value: Variant) -> Array:
	if not (value is Array):
		return []
	var normalized: Array = []
	for entry in value:
		if not (entry is Dictionary):
			continue
		normalized.append({
			"chartId": String(entry.get("chartId", "")).strip_edges(),
			"feature": String(entry.get("feature", "")).strip_edges(),
			"difficulty": String(entry.get("difficulty", "")).strip_edges(),
			"path": String(entry.get("path", "")).strip_edges(),
		})
	return normalized
