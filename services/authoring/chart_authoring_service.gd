class_name ChartAuthoringService
extends "../../interfaces/authoring_service.gd"

const RoutineAuthoringService = preload("routine_authoring_service.gd")
const ValidatePackageService = preload("../validation/validate_package_service.gd")

const DEFAULT_SCHEMA := "aerobeat.content.chart.v1"

var _routine_authoring_service: RoutineAuthoringService = RoutineAuthoringService.new()
var _validate_package_service: ValidatePackageService = ValidatePackageService.new()

func upsert_record(record_data: Dictionary) -> Dictionary:
	var package_dir: String = String(record_data.get("packageDir", "")).strip_edges()
	if package_dir.is_empty():
		return _error("packageDir is required for chart upsert.")

	var chart: Dictionary = _normalize_chart(record_data)
	if String(chart.get("chartId", "")).is_empty():
		return _error("chartId is required for chart upsert.", {"packageDir": package_dir, "record": chart})
	if String(chart.get("routineId", "")).is_empty():
		return _error("routineId is required for chart upsert.", {"packageDir": package_dir, "record": chart})
	if String(chart.get("songId", "")).is_empty():
		return _error("songId is required for chart upsert.", {"packageDir": package_dir, "record": chart})

	var manifest_path: String = package_dir.path_join("manifest.json")
	var manifest: Dictionary = _load_json(manifest_path)
	if manifest.is_empty():
		return _error("Package manifest is missing or invalid.", {"packageDir": package_dir, "manifestPath": manifest_path, "record": chart})

	var chart_path: String = _canonical_chart_path(chart)
	var chart_file_path: String = package_dir.path_join(chart_path)
	var chart_write_result: Dictionary = _write_json(chart_file_path, chart)
	if not bool(chart_write_result.get("ok", false)):
		return _error(String(chart_write_result.get("error", "Failed to write chart file.")), {"packageDir": package_dir, "chartPath": chart_path, "record": chart})

	manifest["charts"] = _upsert_manifest_chart_entries(package_dir, manifest.get("charts", []), chart, chart_path)
	var manifest_write_result: Dictionary = _write_json(manifest_path, manifest)
	if not bool(manifest_write_result.get("ok", false)):
		return _error(String(manifest_write_result.get("error", "Failed to write manifest.")), {"packageDir": package_dir, "manifestPath": manifest_path, "record": chart, "chartPath": chart_path})

	var routine_update: Dictionary = _routine_authoring_service.ensure_chart_membership(package_dir, String(chart.get("routineId", "")), String(chart.get("chartId", "")))
	var validation: Dictionary = _validation_for_package_state(package_dir)
	var ok: bool = bool(routine_update.get("ok", false)) and bool(validation.get("valid", false))
	return {
		"ok": ok,
		"recordKind": "chart",
		"packageDir": package_dir,
		"manifestPath": manifest_path,
		"chartPath": chart_path,
		"record": chart,
		"routineUpdate": routine_update,
		"validation": validation,
		"issueCount": int(validation.get("issueCount", 0)),
		"issues": validation.get("issues", []),
	}

func _normalize_chart(record_data: Dictionary) -> Dictionary:
	var chart := record_data.duplicate(true)
	chart.erase("packageDir")
	chart["schema"] = String(chart.get("schema", DEFAULT_SCHEMA)).strip_edges()
	chart["chartId"] = String(chart.get("chartId", "")).strip_edges()
	chart["routineId"] = String(chart.get("routineId", "")).strip_edges()
	chart["songId"] = String(chart.get("songId", "")).strip_edges()
	chart["feature"] = _normalize_token(String(chart.get("feature", "boxing")), "boxing")
	chart["difficulty"] = _normalize_token(String(chart.get("difficulty", "medium")), "medium")
	chart["interactionFamily"] = _normalize_token(String(chart.get("interactionFamily", "gesture_2d")), "gesture_2d")
	chart["events"] = _duplicate_array(chart.get("events", []))
	chart.erase("timing")
	if chart.has("chartName"):
		chart["chartName"] = String(chart.get("chartName", "")).strip_edges()
	return chart

func _canonical_chart_path(chart: Dictionary) -> String:
	var base_name: String = "%s-%s-%s" % [
		_slug_component(String(chart.get("songId", ""))),
		_slug_component(String(chart.get("feature", ""))),
		_slug_component(String(chart.get("difficulty", ""))),
	]
	while base_name.contains("--"):
		base_name = base_name.replace("--", "-")
	base_name = base_name.strip_edges()
	if base_name.begins_with("-"):
		base_name = base_name.substr(1)
	if base_name.ends_with("-"):
		base_name = base_name.left(base_name.length() - 1)
	if base_name.is_empty():
		base_name = _slug_component(String(chart.get("chartId", "chart")))
	return "charts/%s.json" % base_name

func _upsert_manifest_chart_entries(package_dir: String, entries: Array, chart: Dictionary, chart_path: String) -> Array:
	var updated_entries: Array = entries.duplicate(true)
	var chart_id: String = String(chart.get("chartId", ""))
	var matched := false
	for index in range(updated_entries.size()):
		var entry: Dictionary = updated_entries[index]
		var entry_path: String = String(entry.get("path", ""))
		if entry_path == chart_path:
			updated_entries[index] = {"path": chart_path}
			matched = true
			continue
		if entry_path.is_empty():
			continue
		var existing_chart: Dictionary = _load_json(package_dir.path_join(entry_path))
		if String(existing_chart.get("chartId", "")).strip_edges() == chart_id:
			updated_entries[index] = {"path": chart_path}
			matched = true
	if not matched:
		updated_entries.append({"path": chart_path})
	return updated_entries

func _duplicate_array(value: Variant) -> Array:
	if value is Array:
		return value.duplicate(true)
	return []

func _slug_component(value: String) -> String:
	var normalized: String = value.strip_edges().to_lower().replace("_", "-").replace(" ", "-")
	var cleaned := ""
	for index in range(normalized.length()):
		var character := normalized[index]
		if (character >= "a" and character <= "z") or (character >= "0" and character <= "9") or character == "-":
			cleaned += character
		else:
			cleaned += "-"
	while cleaned.contains("--"):
		cleaned = cleaned.replace("--", "-")
	return cleaned.strip_edges()

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
		return {"ok": false, "error": "Failed to open '%s' for writing." % path}
	file.store_string(JSON.stringify(data, "  ") + "\n")
	return {"ok": true}

func _validation_for_package_state(package_dir: String) -> Dictionary:
	var has_manifest: bool = FileAccess.file_exists(package_dir.path_join("manifest.json"))
	var has_workout_yaml: bool = FileAccess.file_exists(package_dir.path_join("workout.yaml"))
	if has_manifest and not has_workout_yaml:
		return {
			"ok": true,
			"valid": true,
			"subject": "legacy_manifest_package",
			"issueCount": 0,
			"issues": [],
			"warningCount": 0,
			"warnings": [],
			"packageDir": package_dir,
			"skipped": true,
			"note": "Skipped YAML package validation for legacy manifest-based authoring fixture.",
		}
	return _validate_package_service.validate_path(package_dir)

func _error(message: String, extra: Dictionary = {}) -> Dictionary:
	var result := {
		"ok": false,
		"recordKind": "chart",
		"error": message,
	}
	for key in extra.keys():
		result[key] = extra[key]
	return result
