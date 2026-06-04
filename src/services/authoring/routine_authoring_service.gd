class_name RoutineAuthoringService
extends "../../interfaces/authoring_service.gd"

const DEFAULT_SCHEMA := "aerobeat.content.routine.v1"

func upsert_record(record_data: Dictionary) -> Dictionary:
	var routine := record_data.duplicate(true)
	routine.erase("packageDir")
	routine["schema"] = String(routine.get("schema", DEFAULT_SCHEMA)).strip_edges()
	routine["routineId"] = String(routine.get("routineId", "")).strip_edges()
	routine["songId"] = String(routine.get("songId", "")).strip_edges()
	routine["feature"] = _normalize_token(String(routine.get("feature", "boxing")), "boxing")
	routine["title"] = String(routine.get("title", routine.get("routineName", ""))).strip_edges()
	routine["charts"] = _normalize_chart_ids(routine.get("charts", []))
	return {
		"ok": not routine["routineId"].is_empty(),
		"recordKind": "routine",
		"record": routine,
	}

func ensure_chart_membership(package_dir: String, routine_id: String, chart_id: String) -> Dictionary:
	if package_dir.is_empty():
		return _error("packageDir is required to update a routine chart list.")
	if routine_id.is_empty():
		return _error("routineId is required to update a routine chart list.")
	if chart_id.is_empty():
		return _error("chartId is required to update a routine chart list.")

	var manifest_path: String = package_dir.path_join("manifest.json")
	var manifest: Dictionary = _load_json(manifest_path)
	if manifest.is_empty():
		return _error("Package manifest is missing or invalid.", {"manifestPath": manifest_path})

	var routine_entry: Dictionary = _find_manifest_entry_by_id(package_dir, manifest.get("routines", []), "routineId", routine_id)
	if routine_entry.is_empty():
		return _error("Routine '%s' is not present in the package manifest." % routine_id, {"manifestPath": manifest_path, "routineId": routine_id})

	var routine_path: String = String(routine_entry.get("path", ""))
	var routine_file_path: String = package_dir.path_join(routine_path)
	var routine: Dictionary = _load_json(routine_file_path)
	if routine.is_empty():
		return _error("Routine file '%s' is missing or invalid JSON." % routine_path, {"routinePath": routine_path})

	var updated_routine: Dictionary = routine.duplicate(true)
	var charts: Array = _normalize_chart_ids(updated_routine.get("charts", []))
	var chart_added := false
	if not charts.has(chart_id):
		charts.append(chart_id)
		chart_added = true
	updated_routine["charts"] = charts

	var write_result: Dictionary = _write_json(routine_file_path, updated_routine)
	if not bool(write_result.get("ok", false)):
		return write_result

	return {
		"ok": true,
		"recordKind": "routine",
		"record": updated_routine,
		"routinePath": routine_path,
		"chartAdded": chart_added,
	}

func _find_manifest_entry_by_id(package_dir: String, entries: Array, id_key: String, expected_id: String) -> Dictionary:
	for entry in entries:
		var path: String = String(entry.get("path", ""))
		if path.is_empty():
			continue
		var record: Dictionary = _load_json(package_dir.path_join(path))
		if String(record.get(id_key, "")).strip_edges() == expected_id:
			return entry
	return {}

func _normalize_chart_ids(chart_ids: Array) -> Array:
	var normalized: Array = []
	for chart_id in chart_ids:
		var normalized_id: String = String(chart_id).strip_edges()
		if normalized_id.is_empty() or normalized.has(normalized_id):
			continue
		normalized.append(normalized_id)
	return normalized

func _normalize_token(value: String, fallback: String) -> String:
	var normalized: String = value.strip_edges().to_lower().replace(" ", "_").replace("-", "_")
	return normalized if not normalized.is_empty() else fallback

func _load_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if parsed == null or not (parsed is Dictionary):
		return {}
	return parsed

func _write_json(path: String, data: Dictionary) -> Dictionary:
	var parent_dir: String = path.get_base_dir()
	if not parent_dir.is_empty():
		DirAccess.make_dir_recursive_absolute(parent_dir)
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return _error("Failed to open '%s' for writing." % path)
	file.store_string(JSON.stringify(data, "  ") + "\n")
	return {"ok": true}

func _error(message: String, extra: Dictionary = {}) -> Dictionary:
	var result := {
		"ok": false,
		"recordKind": "routine",
		"error": message,
	}
	for key in extra.keys():
		result[key] = extra[key]
	return result
