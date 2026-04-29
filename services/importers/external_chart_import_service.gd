class_name ExternalChartImportService
extends "../../interfaces/import_export_service.gd"

func import_source(source_path: String, options: Dictionary = {}) -> Dictionary:
	var parsed: Dictionary = _load_json(source_path)
	var chart_id: String = String(options.get("chartId", parsed.get("chartId", source_path.get_file().get_basename().to_lower())))
	return {
		"ok": not parsed.is_empty(),
		"sourcePath": source_path,
		"recordKind": "chart",
		"record": {
			"schema": "aerobeat.content.chart.v1",
			"chartId": chart_id,
			"routineId": String(options.get("routineId", parsed.get("routineId", ""))),
			"songId": String(options.get("songId", parsed.get("songId", ""))),
			"feature": String(options.get("feature", parsed.get("feature", "boxing"))),
			"difficulty": String(options.get("difficulty", parsed.get("difficulty", "medium"))),
			"interactionFamily": String(options.get("interactionFamily", parsed.get("interactionFamily", "gesture_2d"))),
			"events": parsed.get("events", []),
		},
	}

func _load_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var text: String = FileAccess.get_file_as_string(path)
	var parsed: Variant = JSON.parse_string(text)
	if parsed == null or not (parsed is Dictionary):
		return {}
	return parsed
