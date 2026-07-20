class_name WorkoutPackageYamlCodec
extends RefCounted

const ValidatePackageService = preload("../validation/validate_package_service.gd")

const AUTHORED_DIRECTORIES := ["songs", "charts", "sets", "coaches", "environments", "sql"]
const AUTHORED_ROOT_FILES := ["song-package.yaml"]
const DEFAULT_SONG_PACKAGE_ID := "ab-song-package-draft"
const DEFAULT_SONG_PACKAGE_NAME := "Draft Song Package"
const DEFAULT_SET_ID := "ab-set-001"
const DEFAULT_SET_NAME := "Set 1"
const DEFAULT_SONG_ID := "ab-song-001"
const DEFAULT_SONG_NAME := "Placeholder Song"
const DEFAULT_CHART_ID := "ab-chart-001"
const DEFAULT_CHART_NAME := "Placeholder Boxing Chart"
const DEFAULT_SQL_PATH := "sql/workouts.schema.sql"
const PLACEHOLDER_SONG_AUDIO_PATH := "media/audio/blank-song.ogg"
const PLACEHOLDER_SOURCE_ROOT := "res://addons/aerobeat-tool-content-authoring/.testbed/assets/placeholders"
const DEFAULT_SQL_SCHEMA := "CREATE TABLE IF NOT EXISTS workouts (\n  workout_id TEXT PRIMARY KEY,\n  workout_name TEXT NOT NULL\n);\n\nCREATE INDEX IF NOT EXISTS idx_workouts_name ON workouts(workout_name);\n"

var _yaml_loader: ValidatePackageService = ValidatePackageService.new()

func create_blank_package_state(seed: Dictionary = {}) -> Dictionary:
	var package_version: String = String(seed.get("packageVersion", "1.0.0")).strip_edges()
	var song_package_id: String = _token(seed.get("songPackageId", seed.get("packageId", DEFAULT_SONG_PACKAGE_ID)))
	if song_package_id.is_empty():
		song_package_id = DEFAULT_SONG_PACKAGE_ID
	var song_package_name: String = String(seed.get("songPackageName", DEFAULT_SONG_PACKAGE_NAME)).strip_edges()
	if song_package_name.is_empty():
		song_package_name = DEFAULT_SONG_PACKAGE_NAME
	var description: String = String(seed.get("description", "")).strip_edges()
	var set_id: String = _token(seed.get("setId", DEFAULT_SET_ID))
	var set_name: String = String(seed.get("setName", DEFAULT_SET_NAME)).strip_edges()
	var song_id: String = _token(seed.get("songId", DEFAULT_SONG_ID))
	var song_name: String = String(seed.get("songName", DEFAULT_SONG_NAME)).strip_edges()
	var chart_id: String = _token(seed.get("chartId", DEFAULT_CHART_ID))
	var chart_name: String = String(seed.get("chartName", DEFAULT_CHART_NAME)).strip_edges()
	return {
		"packageVersion": package_version,
		"sourcePackageDir": "",
		"loadedPackageDir": "",
		"passthroughDirectories": [],
		"passthroughFiles": [],
		"draftAssetSources": {
			PLACEHOLDER_SONG_AUDIO_PATH: _placeholder_source_path("blank-song.ogg"),
		},
		"draftTextSources": {
			DEFAULT_SQL_PATH: String(seed.get("sqlSchemaText", DEFAULT_SQL_SCHEMA)),
		},
		"songPackage": {
			"schemaId": "aerobeat.song-package.v1",
			"schemaVersion": 1,
			"recordVersion": 1,
			"songPackageId": song_package_id,
			"songPackageName": song_package_name,
			"description": description,
			"packageVersion": package_version,
			"setIds": [set_id],
		},
		"songs": [{
			"schemaId": "aerobeat.song.v1",
			"schemaVersion": 1,
			"recordVersion": 1,
			"songId": song_id,
			"songName": song_name,
			"audio": {
				"filePath": PLACEHOLDER_SONG_AUDIO_PATH,
			},
			"timing": {
				"anchorMs": 0,
				"tempoSegments": [{
					"startBeat": 0,
					"bpm": 120,
				}],
				"stopSegments": [],
				"timeSignatureSegments": [{
					"startBeat": 0,
					"numerator": 4,
					"denominator": 4,
				}],
			},
		}],
		"charts": [{
			"schemaId": "aerobeat.chart.boxing.v1",
			"schemaVersion": 1,
			"recordVersion": 1,
			"chartId": chart_id,
			"chartName": chart_name,
			"feature": "boxing",
			"difficulty": "Normal",
			"beats": [{
				"start": 1.0,
				"type": "straight_left",
			}],
		}],
		"sets": [{
			"schemaId": "aerobeat.set.v1",
			"schemaVersion": 1,
			"recordVersion": 1,
			"setId": set_id,
			"setName": set_name,
			"songId": song_id,
			"chartId": chart_id,
		}],
		"environments": [],
		"coachConfig": {},
		"sqlFiles": [DEFAULT_SQL_PATH],
	}

func _placeholder_source_path(file_name: String) -> String:
	return ProjectSettings.globalize_path(PLACEHOLDER_SOURCE_ROOT.path_join(file_name))

func load_package_state(package_dir: String) -> Dictionary:
	var absolute_dir: String = package_dir.simplify_path()
	if not DirAccess.dir_exists_absolute(absolute_dir):
		return {
			"ok": false,
			"errorCode": "package_dir_missing",
			"packageDir": absolute_dir,
		}
	var context: Dictionary = _yaml_loader._load_package_context(absolute_dir)
	var root_record: Dictionary = Dictionary(context.get("songPackage", {}))
	if not bool(root_record.get("ok", false)):
		return {
			"ok": false,
			"errorCode": "song_package_yaml_missing_or_invalid",
			"packageDir": absolute_dir,
			"details": root_record,
		}
	var song_package: Dictionary = _normalize_song_package_record(Dictionary(root_record.get("data", {})))
	return {
		"ok": true,
		"packageDir": absolute_dir,
		"state": {
			"packageVersion": String(song_package.get("packageVersion", "1.0.0")).strip_edges(),
			"sourcePackageDir": absolute_dir,
			"loadedPackageDir": absolute_dir,
			"passthroughDirectories": _discover_passthrough_directories(absolute_dir),
			"passthroughFiles": _discover_passthrough_files(absolute_dir),
			"songPackage": song_package,
			"songs": _extract_records(context.get("songs", []), "song"),
			"charts": _extract_records(context.get("charts", []), "chart"),
			"sets": _extract_records(context.get("sets", []), "set"),
			"environments": _extract_records(context.get("environments", []), "environment"),
			"coachConfig": _single_record_data(context.get("coaches", [])),
			"sqlFiles": _extract_sql_files(context.get("sql", [])),
		},
	}

func write_package_state(state: Dictionary, package_dir: String) -> Dictionary:
	var absolute_dir: String = package_dir.simplify_path()
	_remove_tree(absolute_dir)
	DirAccess.make_dir_recursive_absolute(absolute_dir)

	var song_package: Dictionary = _normalize_song_package_record(Dictionary(state.get("songPackage", state.get("workout", {}))))
	var songs: Array = _normalize_record_list(state.get("songs", []), "song")
	var charts: Array = _normalize_record_list(state.get("charts", []), "chart")
	var sets: Array = _normalize_record_list(state.get("sets", []), "set")
	var environments: Array = _normalize_record_list(state.get("environments", []), "environment")
	var coach_config: Dictionary = _normalize_dictionary(state.get("coachConfig", {}))

	var written_files: Array = []
	if not _write_yaml_file(absolute_dir.path_join("song-package.yaml"), song_package):
		return {"ok": false, "errorCode": "write_failed", "path": absolute_dir.path_join("song-package.yaml")}
	written_files.append("song-package.yaml")

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
	if not coach_config.is_empty():
		if not _write_yaml_file(absolute_dir.path_join("coaches/coach-config.yaml"), coach_config):
			return {"ok": false, "errorCode": "write_failed", "path": absolute_dir.path_join("coaches/coach-config.yaml")}
		written_files.append("coaches/coach-config.yaml")

	var written_text_files: Array = _write_draft_text_sources(state, absolute_dir)
	written_files.append_array(written_text_files)
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

func _normalize_song_package_record(record: Dictionary) -> Dictionary:
	var normalized: Dictionary = record.duplicate(true)
	normalized.erase("workoutId")
	normalized.erase("workoutName")
	normalized.erase("coachConfigId")
	normalized.erase("setOrder")
	normalized["schemaId"] = String(normalized.get("schemaId", "aerobeat.song-package.v1")).strip_edges()
	normalized["schemaVersion"] = int(normalized.get("schemaVersion", 1))
	normalized["recordVersion"] = int(normalized.get("recordVersion", 1))
	normalized["songPackageId"] = _token(normalized.get("songPackageId", ""))
	normalized["songPackageName"] = String(normalized.get("songPackageName", "")).strip_edges()
	normalized["description"] = String(normalized.get("description", "")).strip_edges()
	normalized["packageVersion"] = String(normalized.get("packageVersion", "1.0.0")).strip_edges()
	normalized["setIds"] = _normalize_token_array(normalized.get("setIds", []))
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
	normalized["difficulty"] = _normalize_difficulty_label(String(normalized.get("difficulty", "Normal")).strip_edges())
	normalized["beats"] = Array(normalized.get("beats", [])).duplicate(true) if normalized.get("beats") is Array else []
	return normalized

func _normalize_difficulty_label(value: String) -> String:
	match value:
		"easy":
			return "Easy"
		"medium", "normal":
			return "Normal"
		"hard":
			return "Hard"
		"pro", "expert":
			return "Expert"
		"expertplus", "expert_plus":
			return "ExpertPlus"
		_:
			return value

func _normalize_set_record(record: Dictionary) -> Dictionary:
	var normalized: Dictionary = record.duplicate(true)
	normalized.erase("preferredEnvironmentId")
	normalized.erase("fallbackEnvironmentId")
	normalized.erase("environmentId")
	normalized.erase("coachingOverlayId")
	normalized["schemaId"] = String(normalized.get("schemaId", "aerobeat.set.v1")).strip_edges()
	normalized["schemaVersion"] = int(normalized.get("schemaVersion", 1))
	normalized["recordVersion"] = int(normalized.get("recordVersion", 1))
	normalized["setId"] = _token(normalized.get("setId", ""))
	normalized["setName"] = String(normalized.get("setName", "")).strip_edges()
	normalized["songId"] = _token(normalized.get("songId", ""))
	normalized["chartId"] = _token(normalized.get("chartId", ""))
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

func _write_draft_text_sources(state: Dictionary, package_dir: String) -> Array:
	var written: Array = []
	var draft_text_sources: Dictionary = Dictionary(state.get("draftTextSources", {}))
	for relative_path_variant in draft_text_sources.keys():
		var relative_path: String = String(relative_path_variant).strip_edges()
		if relative_path.is_empty():
			continue
		var text: String = String(draft_text_sources.get(relative_path_variant, ""))
		var destination_path: String = package_dir.path_join(relative_path)
		if _write_text_file(destination_path, text):
			written.append(relative_path)
	return written

func _copy_sql_files(state: Dictionary, package_dir: String) -> Array:
	var copied: Array = []
	var source_dir: String = String(state.get("sourcePackageDir", "")).strip_edges()
	if source_dir.is_empty():
		return copied
	for relative_path in state.get("sqlFiles", []):
		var sql_path: String = String(relative_path).strip_edges()
		if sql_path.is_empty():
			continue
		var destination_path: String = package_dir.path_join(sql_path)
		if FileAccess.file_exists(destination_path):
			continue
		var source_path: String = source_dir.path_join(sql_path)
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

func _write_text_file(path: String, text: String) -> bool:
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(text)
	file.close()
	return true

func _write_yaml_file(path: String, data: Variant) -> bool:
	return _write_text_file(path, _serialize_yaml(data))

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
