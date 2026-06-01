class_name WorkoutPackageYamlCodec
extends RefCounted

const ValidatePackageService = preload("../validation/validate_package_service.gd")

const AUTHORED_DIRECTORIES := ["songs", "charts", "sets", "coaches", "environments", "sql"]
const AUTHORED_ROOT_FILES := ["workout.yaml"]

var _yaml_loader: ValidatePackageService = ValidatePackageService.new()

func create_blank_package_state(seed: Dictionary = {}) -> Dictionary:
	var workout_id: String = _token(seed.get("workoutId", seed.get("packageId", "")))
	var coach_config_id: String = _token(seed.get("coachConfigId", ""))
	return {
		"packageVersion": String(seed.get("packageVersion", "1.0.0")).strip_edges(),
		"sourcePackageDir": "",
		"loadedPackageDir": "",
		"passthroughDirectories": [],
		"passthroughFiles": [],
		"workout": {
			"schemaId": "aerobeat.workout-package.v1",
			"schemaVersion": 1,
			"recordVersion": 1,
			"workoutId": workout_id,
			"workoutName": String(seed.get("workoutName", "")).strip_edges(),
			"description": String(seed.get("description", "")).strip_edges(),
			"packageVersion": String(seed.get("packageVersion", "1.0.0")).strip_edges(),
			"coachConfigId": coach_config_id,
			"setOrder": [],
		},
		"coachConfig": {"enabled": false},
		"songs": [],
		"charts": [],
		"sets": [],
		"environments": [],
		"sqlFiles": [],
	}

func load_package_state(package_dir: String) -> Dictionary:
	var absolute_dir: String = package_dir.simplify_path()
	if not DirAccess.dir_exists_absolute(absolute_dir):
		return {
			"ok": false,
			"errorCode": "package_dir_missing",
			"packageDir": absolute_dir,
		}
	var context: Dictionary = _yaml_loader._load_package_context(absolute_dir)
	var workout_record: Dictionary = Dictionary(context.get("workout", {}))
	if not bool(workout_record.get("ok", false)):
		return {
			"ok": false,
			"errorCode": "workout_yaml_missing_or_invalid",
			"packageDir": absolute_dir,
			"details": workout_record,
		}
	var workout: Dictionary = _normalize_workout_record(Dictionary(workout_record.get("data", {})))
	return {
		"ok": true,
		"packageDir": absolute_dir,
		"state": {
			"packageVersion": String(workout.get("packageVersion", "1.0.0")).strip_edges(),
			"sourcePackageDir": absolute_dir,
			"loadedPackageDir": absolute_dir,
			"passthroughDirectories": _discover_passthrough_directories(absolute_dir),
			"passthroughFiles": _discover_passthrough_files(absolute_dir),
			"workout": workout,
			"coachConfig": _normalize_coach_config_record(_single_record_data(context.get("coaches", []))),
			"songs": _extract_records(context.get("songs", []), "song"),
			"charts": _extract_records(context.get("charts", []), "chart"),
			"sets": _extract_records(context.get("sets", []), "set"),
			"environments": _extract_records(context.get("environments", []), "environment"),
			"sqlFiles": _extract_sql_files(context.get("sql", [])),
		},
	}

func write_package_state(state: Dictionary, package_dir: String) -> Dictionary:
	var absolute_dir: String = package_dir.simplify_path()
	_remove_tree(absolute_dir)
	DirAccess.make_dir_recursive_absolute(absolute_dir)

	var workout: Dictionary = _normalize_workout_record(Dictionary(state.get("workout", {})))
	var coach_config: Dictionary = _normalize_coach_config_record(Dictionary(state.get("coachConfig", {})))
	var songs: Array = _normalize_record_list(state.get("songs", []), "song")
	var charts: Array = _normalize_record_list(state.get("charts", []), "chart")
	var sets: Array = _normalize_record_list(state.get("sets", []), "set")
	var environments: Array = _normalize_record_list(state.get("environments", []), "environment")

	var written_files: Array = []
	if not _write_yaml_file(absolute_dir.path_join("workout.yaml"), workout):
		return {"ok": false, "errorCode": "write_failed", "path": absolute_dir.path_join("workout.yaml")}
	written_files.append("workout.yaml")
	if not _write_yaml_file(absolute_dir.path_join("coaches/coach-config.yaml"), coach_config):
		return {"ok": false, "errorCode": "write_failed", "path": absolute_dir.path_join("coaches/coach-config.yaml")}
	written_files.append("coaches/coach-config.yaml")

	for record in songs:
		var path: String = "songs/%s.yaml" % String(record.get("songId", "song"))
		if not _write_yaml_file(absolute_dir.path_join(path), record):
			return {"ok": false, "errorCode": "write_failed", "path": absolute_dir.path_join(path)}
		written_files.append(path)
	for record in charts:
		var path: String = "charts/%s.yaml" % String(record.get("chartId", "chart"))
		if not _write_yaml_file(absolute_dir.path_join(path), record):
			return {"ok": false, "errorCode": "write_failed", "path": absolute_dir.path_join(path)}
		written_files.append(path)
	for record in sets:
		var path: String = "sets/%s.yaml" % String(record.get("setId", "set"))
		if not _write_yaml_file(absolute_dir.path_join(path), record):
			return {"ok": false, "errorCode": "write_failed", "path": absolute_dir.path_join(path)}
		written_files.append(path)
	for record in environments:
		var path: String = "environments/%s.yaml" % String(record.get("environmentId", "environment"))
		if not _write_yaml_file(absolute_dir.path_join(path), record):
			return {"ok": false, "errorCode": "write_failed", "path": absolute_dir.path_join(path)}
		written_files.append(path)

	var copied_sql_files: Array = _copy_sql_files(state, absolute_dir)
	written_files.append_array(copied_sql_files)
	var copied_passthrough: Array = _copy_passthrough_content(state, absolute_dir)
	written_files.append_array(copied_passthrough)
	var copied_draft_assets: Array = _copy_draft_asset_sources(state, absolute_dir)
	written_files.append_array(copied_draft_assets)
	return {
		"ok": true,
		"packageDir": absolute_dir,
		"writtenFiles": written_files,
	}

func _extract_records(records: Array, kind: String) -> Array:
	var extracted: Array = []
	for record in records:
		var data: Dictionary = Dictionary(record.get("data", {})).duplicate(true)
		if data.is_empty():
			continue
		extracted.append(_normalize_record(data, kind))
	return extracted

func _extract_sql_files(records: Array) -> Array:
	var extracted: Array = []
	for record in records:
		var path: String = String(record.get("path", "")).strip_edges()
		if path.is_empty():
			continue
		extracted.append(path)
	return extracted

func _single_record_data(records: Array) -> Dictionary:
	if records.is_empty():
		return {}
	return Dictionary(records[0].get("data", {})).duplicate(true)

func _normalize_record_list(value: Variant, kind: String) -> Array:
	var result: Array = []
	if not (value is Array):
		return result
	for item in value:
		if item is Dictionary:
			result.append(_normalize_record(Dictionary(item).duplicate(true), kind))
	return result

func _normalize_record(record: Dictionary, kind: String) -> Dictionary:
	match kind:
		"song":
			return _normalize_song_record(record)
		"chart":
			return _normalize_chart_record(record)
		"set":
			return _normalize_set_record(record)
		"environment":
			return _normalize_environment_record(record)
		_:
			return record

func _normalize_workout_record(record: Dictionary) -> Dictionary:
	var normalized: Dictionary = record.duplicate(true)
	normalized["schemaId"] = String(normalized.get("schemaId", "aerobeat.workout-package.v1")).strip_edges()
	normalized["schemaVersion"] = int(normalized.get("schemaVersion", 1))
	normalized["recordVersion"] = int(normalized.get("recordVersion", 1))
	normalized["workoutId"] = _token(normalized.get("workoutId", ""))
	normalized["workoutName"] = String(normalized.get("workoutName", "")).strip_edges()
	normalized["description"] = String(normalized.get("description", "")).strip_edges()
	normalized["packageVersion"] = String(normalized.get("packageVersion", "1.0.0")).strip_edges()
	normalized["coachConfigId"] = _token(normalized.get("coachConfigId", ""))
	normalized["setOrder"] = _normalize_token_array(normalized.get("setOrder", []))
	return normalized

func _normalize_coach_config_record(record: Dictionary) -> Dictionary:
	var normalized: Dictionary = record.duplicate(true)
	if not bool(normalized.get("enabled", false)):
		return {"enabled": false}
	normalized["schemaId"] = String(normalized.get("schemaId", "aerobeat.coach-config.v1")).strip_edges()
	normalized["schemaVersion"] = int(normalized.get("schemaVersion", 1))
	normalized["recordVersion"] = int(normalized.get("recordVersion", 1))
	normalized["enabled"] = true
	normalized["coachConfigId"] = _token(normalized.get("coachConfigId", ""))
	normalized["coachConfigName"] = String(normalized.get("coachConfigName", "")).strip_edges()
	normalized["featuredCoaches"] = _normalize_dictionary_array(normalized.get("featuredCoaches", []))
	normalized["warmupVideo"] = _normalize_dictionary(normalized.get("warmupVideo", {}))
	normalized["cooldownVideo"] = _normalize_dictionary(normalized.get("cooldownVideo", {}))
	normalized["overlayAudio"] = _normalize_dictionary_array(normalized.get("overlayAudio", []))
	return normalized

func _normalize_song_record(record: Dictionary) -> Dictionary:
	var normalized: Dictionary = record.duplicate(true)
	normalized["schemaId"] = String(normalized.get("schemaId", "aerobeat.song.v1")).strip_edges()
	normalized["schemaVersion"] = int(normalized.get("schemaVersion", 1))
	normalized["recordVersion"] = int(normalized.get("recordVersion", 1))
	normalized["songId"] = _token(normalized.get("songId", ""))
	normalized["songName"] = String(normalized.get("songName", "")).strip_edges()
	normalized["audio"] = _normalize_dictionary(normalized.get("audio", {}))
	normalized["timing"] = _normalize_dictionary(normalized.get("timing", {}))
	return normalized

func _normalize_chart_record(record: Dictionary) -> Dictionary:
	var normalized: Dictionary = record.duplicate(true)
	normalized["schemaId"] = String(normalized.get("schemaId", "aerobeat.chart.boxing.v1")).strip_edges()
	normalized["schemaVersion"] = int(normalized.get("schemaVersion", 1))
	normalized["recordVersion"] = int(normalized.get("recordVersion", 1))
	normalized["chartId"] = _token(normalized.get("chartId", ""))
	normalized["chartName"] = String(normalized.get("chartName", "")).strip_edges()
	normalized["feature"] = String(normalized.get("feature", "boxing")).strip_edges()
	normalized["difficulty"] = String(normalized.get("difficulty", "medium")).strip_edges()
	if normalized.get("beats") is Array:
		normalized["beats"] = normalized.get("beats", [])
	else:
		normalized["beats"] = []
	return normalized

func _normalize_set_record(record: Dictionary) -> Dictionary:
	var normalized: Dictionary = record.duplicate(true)
	normalized["schemaId"] = String(normalized.get("schemaId", "aerobeat.set.v1")).strip_edges()
	normalized["schemaVersion"] = int(normalized.get("schemaVersion", 1))
	normalized["recordVersion"] = int(normalized.get("recordVersion", 1))
	normalized["setId"] = _token(normalized.get("setId", ""))
	normalized["setName"] = String(normalized.get("setName", "")).strip_edges()
	normalized["songId"] = _token(normalized.get("songId", ""))
	normalized["chartId"] = _token(normalized.get("chartId", ""))
	var preferred_environment_id: String = _token(normalized.get("preferredEnvironmentId", normalized.get("environmentId", "")))
	var fallback_environment_id: String = _token(normalized.get("fallbackEnvironmentId", ""))
	normalized["preferredEnvironmentId"] = preferred_environment_id
	normalized["fallbackEnvironmentId"] = fallback_environment_id
	if not preferred_environment_id.is_empty():
		normalized["environmentId"] = preferred_environment_id
	normalized["coachingOverlayId"] = _token(normalized.get("coachingOverlayId", ""))
	if String(normalized.get("coachingOverlayId", "")).is_empty():
		normalized.erase("coachingOverlayId")
	return normalized

func _normalize_environment_record(record: Dictionary) -> Dictionary:
	var normalized: Dictionary = record.duplicate(true)
	normalized["schemaId"] = String(normalized.get("schemaId", "aerobeat.environment.v1")).strip_edges()
	normalized["schemaVersion"] = int(normalized.get("schemaVersion", 1))
	normalized["recordVersion"] = int(normalized.get("recordVersion", 1))
	normalized["environmentId"] = _token(normalized.get("environmentId", ""))
	normalized["environmentName"] = String(normalized.get("environmentName", "")).strip_edges()
	normalized["type"] = String(normalized.get("type", "")).strip_edges()
	normalized["resourcePath"] = String(normalized.get("resourcePath", "")).strip_edges()
	if normalized.has("configPath"):
		normalized["configPath"] = String(normalized.get("configPath", "")).strip_edges()
	return normalized

func _copy_sql_files(state: Dictionary, package_dir: String) -> Array:
	var copied: Array = []
	var source_dir: String = String(state.get("sourcePackageDir", "")).strip_edges()
	if source_dir.is_empty():
		return copied
	for relative_path in state.get("sqlFiles", []):
		var sql_path: String = String(relative_path).strip_edges()
		if sql_path.is_empty():
			continue
		var source_path: String = source_dir.path_join(sql_path)
		var destination_path: String = package_dir.path_join(sql_path)
		DirAccess.make_dir_recursive_absolute(destination_path.get_base_dir())
		if FileAccess.file_exists(source_path) and DirAccess.copy_absolute(source_path, destination_path) == OK:
			copied.append(sql_path)
	return copied

func _copy_passthrough_content(state: Dictionary, package_dir: String) -> Array:
	var copied: Array = []
	var source_dir: String = String(state.get("sourcePackageDir", "")).strip_edges()
	if source_dir.is_empty():
		return copied
	for relative_dir in state.get("passthroughDirectories", []):
		var dir_name: String = String(relative_dir).strip_edges()
		if dir_name.is_empty():
			continue
		var source_path: String = source_dir.path_join(dir_name)
		var destination_path: String = package_dir.path_join(dir_name)
		if not DirAccess.dir_exists_absolute(source_path):
			continue
		_copy_tree(source_path, destination_path, copied, dir_name)
	for relative_file in state.get("passthroughFiles", []):
		var file_name: String = String(relative_file).strip_edges()
		if file_name.is_empty():
			continue
		var source_file: String = source_dir.path_join(file_name)
		var destination_file: String = package_dir.path_join(file_name)
		DirAccess.make_dir_recursive_absolute(destination_file.get_base_dir())
		if FileAccess.file_exists(source_file) and DirAccess.copy_absolute(source_file, destination_file) == OK:
			copied.append(file_name)
	return copied

func _copy_draft_asset_sources(state: Dictionary, package_dir: String) -> Array:
	var copied: Array = []
	var draft_sources: Dictionary = Dictionary(state.get("draftAssetSources", {}))
	for relative_path_variant in draft_sources.keys():
		var relative_path: String = String(relative_path_variant).strip_edges()
		var source_path: String = String(draft_sources.get(relative_path_variant, "")).strip_edges()
		if relative_path.is_empty() or source_path.is_empty():
			continue
		if not FileAccess.file_exists(source_path):
			continue
		var destination_path: String = package_dir.path_join(relative_path)
		DirAccess.make_dir_recursive_absolute(destination_path.get_base_dir())
		if DirAccess.copy_absolute(source_path, destination_path) == OK:
			copied.append(relative_path)
	return copied

func _discover_passthrough_directories(package_dir: String) -> Array:
	var directories: Array = []
	var dir := DirAccess.open(package_dir)
	if dir == null:
		return directories
	dir.list_dir_begin()
	while true:
		var name := dir.get_next()
		if name.is_empty():
			break
		if name == "." or name == ".." or name.begins_with("."):
			continue
		if dir.current_is_dir() and not AUTHORED_DIRECTORIES.has(name):
			directories.append(name)
	dir.list_dir_end()
	directories.sort()
	return directories

func _discover_passthrough_files(package_dir: String) -> Array:
	var files: Array = []
	var dir := DirAccess.open(package_dir)
	if dir == null:
		return files
	dir.list_dir_begin()
	while true:
		var name := dir.get_next()
		if name.is_empty():
			break
		if name == "." or name == ".." or name.begins_with("."):
			continue
		if not dir.current_is_dir() and not AUTHORED_ROOT_FILES.has(name):
			files.append(name)
	dir.list_dir_end()
	files.sort()
	return files

func _copy_tree(source_dir: String, output_dir: String, copied_files: Array, relative_root: String = "") -> void:
	DirAccess.make_dir_recursive_absolute(output_dir)
	var dir := DirAccess.open(source_dir)
	if dir == null:
		return
	dir.list_dir_begin()
	while true:
		var name := dir.get_next()
		if name.is_empty():
			break
		if name == "." or name == ".." or name.begins_with("."):
			continue
		var source_path: String = source_dir.path_join(name)
		var destination_path: String = output_dir.path_join(name)
		var relative_path: String = name if relative_root.is_empty() else relative_root.path_join(name)
		if dir.current_is_dir():
			_copy_tree(source_path, destination_path, copied_files, relative_path)
		else:
			DirAccess.make_dir_recursive_absolute(destination_path.get_base_dir())
			if DirAccess.copy_absolute(source_path, destination_path) == OK:
				copied_files.append(relative_path)
	dir.list_dir_end()

func _write_yaml_file(path: String, data: Variant) -> bool:
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(_serialize_yaml(data))
	file.close()
	return true

func _serialize_yaml(value: Variant, indent: int = 0) -> String:
	var prefix := "  ".repeat(indent)
	if value is Dictionary:
		var lines: Array[String] = []
		for key in value.keys():
			var child: Variant = value[key]
			if child is Dictionary or child is Array:
				if (child is Array and Array(child).is_empty()) or (child is Dictionary and Dictionary(child).is_empty()):
					lines.append("%s%s: %s" % [prefix, String(key), "[]" if child is Array else "{}"])
				else:
					lines.append("%s%s:" % [prefix, String(key)])
					lines.append(_serialize_yaml(child, indent + 1).trim_suffix("\n"))
			else:
				lines.append("%s%s: %s" % [prefix, String(key), _serialize_scalar(child)])
		return "\n".join(lines) + "\n"
	if value is Array:
		var lines: Array[String] = []
		for item in value:
			if item is Dictionary:
				var item_dict: Dictionary = item
				if item_dict.is_empty():
					lines.append("%s- {}" % prefix)
					continue
				var keys: Array = item_dict.keys()
				var first_key: Variant = keys[0]
				var first_value: Variant = item_dict[first_key]
				if first_value is Dictionary or first_value is Array:
					lines.append("%s- %s:" % [prefix, String(first_key)])
					lines.append(_serialize_yaml(first_value, indent + 2).trim_suffix("\n"))
				else:
					lines.append("%s- %s: %s" % [prefix, String(first_key), _serialize_scalar(first_value)])
				for index in range(1, keys.size()):
					var key = keys[index]
					var child: Variant = item_dict[key]
					if child is Dictionary or child is Array:
						if (child is Array and Array(child).is_empty()) or (child is Dictionary and Dictionary(child).is_empty()):
							lines.append("%s  %s: %s" % [prefix, String(key), "[]" if child is Array else "{}"])
						else:
							lines.append("%s  %s:" % [prefix, String(key)])
							lines.append(_serialize_yaml(child, indent + 2).trim_suffix("\n"))
					else:
						lines.append("%s  %s: %s" % [prefix, String(key), _serialize_scalar(child)])
			elif item is Array:
				lines.append("%s-" % prefix)
				lines.append(_serialize_yaml(item, indent + 1).trim_suffix("\n"))
			else:
				lines.append("%s- %s" % [prefix, _serialize_scalar(item)])
		return "\n".join(lines) + "\n"
	return "%s%s\n" % [prefix, _serialize_scalar(value)]

func _serialize_scalar(value: Variant) -> String:
	if value == null:
		return "null"
	if value is bool:
		return "true" if value else "false"
	if value is int or value is float:
		return str(value)
	var text: String = String(value)
	if text.contains("\n"):
		var indented := text.replace("\n", "\n  ")
		return "|-\n  %s" % indented
	if text.is_empty():
		return '""'
	if text.contains(":") or text.begins_with("{") or text.begins_with("[") or text.begins_with("#") or text.contains("\""):
		return JSON.stringify(text)
	return text

func _normalize_dictionary(value: Variant) -> Dictionary:
	return Dictionary(value).duplicate(true) if value is Dictionary else {}

func _normalize_dictionary_array(value: Variant) -> Array:
	var result: Array = []
	if not (value is Array):
		return result
	for item in value:
		if item is Dictionary:
			result.append(Dictionary(item).duplicate(true))
	return result

func _normalize_token_array(value: Variant) -> Array:
	var result: Array = []
	if not (value is Array):
		return result
	for item in value:
		var token: String = _token(item)
		if not token.is_empty():
			result.append(token)
	return result

func _token(value: Variant) -> String:
	return String(value).strip_edges()

func _remove_tree(path: String) -> void:
	if not DirAccess.dir_exists_absolute(path):
		return
	var dir := DirAccess.open(path)
	if dir == null:
		return
	dir.list_dir_begin()
	while true:
		var name := dir.get_next()
		if name.is_empty():
			break
		if name == "." or name == "..":
			continue
		var child_path := path.path_join(name)
		if dir.current_is_dir():
			_remove_tree(child_path)
			DirAccess.remove_absolute(child_path)
		else:
			DirAccess.remove_absolute(child_path)
	dir.list_dir_end()
	DirAccess.remove_absolute(path)
