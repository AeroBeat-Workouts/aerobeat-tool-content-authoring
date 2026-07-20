class_name SongPackageAuthoringService
extends "../../interfaces/authoring_service.gd"

const DEFAULT_SCHEMA := "aerobeat.song-package.v1"

func upsert_record(record_data: Dictionary) -> Dictionary:
	var song_package_name: String = String(record_data.get("songPackageName", record_data.get("title", ""))).strip_edges()
	var song_package := {
		"schemaId": String(record_data.get("schemaId", DEFAULT_SCHEMA)).strip_edges(),
		"schemaVersion": int(record_data.get("schemaVersion", 1)),
		"recordVersion": int(record_data.get("recordVersion", 1)),
		"songPackageId": String(record_data.get("songPackageId", "")).strip_edges(),
		"songPackageName": song_package_name,
		"description": String(record_data.get("description", "")).strip_edges(),
		"packageVersion": String(record_data.get("packageVersion", "1.0.0")).strip_edges(),
		"setIds": _normalize_set_ids(record_data.get("setIds", record_data.get("sets", []))),
	}
	return {
		"ok": not String(song_package.get("songPackageId", "")).is_empty(),
		"recordKind": "songPackage",
		"record": song_package,
	}

func _normalize_set_ids(value: Variant) -> Array:
	if not (value is Array):
		return []
	var normalized: Array = []
	for entry in value:
		if entry is Dictionary:
			normalized.append(String(entry.get("setId", "")).strip_edges())
		else:
			normalized.append(String(entry).strip_edges())
	return normalized
