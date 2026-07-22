class_name ValidatePackageService
extends RefCounted

const ValidateChartService = preload("validate_chart_service.gd")

const VALID_SUBJECTS := ["package", "song_package", "songs", "charts", "sets", "coaches", "environments", "sql"]
const RECORD_FAMILY_ORDER := ["songs", "charts", "sets", "coaches", "environments", "sql"]
const ROOT_CHART_DESCRIPTOR_REQUIRED_FIELDS := ["chartId", "feature", "difficulty", "path"]
const FAMILY_CONFIG := {
	"songs": {
		"dir": "songs",
		"extension": ".yaml",
		"idKey": "songId",
		"requiredFields": ["schemaId", "schemaVersion", "recordVersion", "songId", "songName", "audio", "timing"],
	},
	"charts": {
		"dir": "charts",
		"extension": ".yaml",
		"idKey": "chartId",
		"requiredFields": ["schemaId", "schemaVersion", "recordVersion", "chartId", "chartName", "feature", "difficulty"],
	},
	"sets": {
		"dir": "sets",
		"extension": ".yaml",
		"idKey": "setId",
		"requiredFields": ["schemaId", "schemaVersion", "recordVersion", "setId", "setName", "songId", "chartId"],
	},
	"coaches": {
		"dir": "coaches",
		"extension": ".yaml",
		"idKey": "coachConfigId",
		"requiredFields": ["enabled"],
	},
	"environments": {
		"dir": "environments",
		"extension": ".yaml",
		"idKey": "environmentId",
		"requiredFields": ["schemaId", "schemaVersion", "recordVersion", "environmentId", "environmentName", "type", "resourcePath"],
	},
}
const VALID_ENVIRONMENT_TYPES := ["image_background", "video_background", "glb_environment", "splat"]
const ENVIRONMENT_RESOURCE_EXTENSIONS := {
	"image_background": [".png", ".jpg", ".jpeg", ".webp"],
	"video_background": [".mp4", ".webm", ".ogv"],
	"glb_environment": [".glb"],
	"splat": [".compressed.ply", ".ply", ".splat", ".sog"],
}
const ENVIRONMENT_CONFIG_EXTENSIONS := [".config.yaml", ".config.yml", ".yaml", ".yml"]
const SONG_TIMING_REQUIRED_FIELDS := ["anchorMs", "tempoSegments", "stopSegments", "timeSignatureSegments"]
const FORBIDDEN_SONG_COMPOSITION_LINK_FIELDS := ["chartId", "setId", "workoutId"]
const FORBIDDEN_CHART_COMPOSITION_LINK_FIELDS := ["songId", "setId", "workoutId"]

var _chart_validator: ValidateChartService = ValidateChartService.new()

func validate_path(package_dir: String, subject: String = "package") -> Dictionary:
	subject = String(subject).to_lower()
	if not VALID_SUBJECTS.has(subject):
		return _report(subject, package_dir, [
			_issue("unknown_subject", "Unknown validation subject '%s'." % subject, package_dir, subject)
		], {}, {}, {})
	var context: Dictionary = _load_package_context(package_dir)
	match subject:
		"package":
			return _validate_package(context)
		"song_package":
			return _validate_song_package(context)
		"songs":
			return _validate_songs(context)
		"charts":
			return _validate_charts(context)
		"sets":
			return _validate_sets(context)
		"coaches":
			return _validate_coaches(context)
		"environments":
			return _validate_environments(context)
		"sql":
			return _validate_sql(context)
		_:
			return _report(subject, package_dir, [], {}, {}, {})

func _validate_package(context: Dictionary) -> Dictionary:
	var package_dir: String = String(context.get("packageDir", ""))
	var sections: Dictionary = {}
	var all_issues: Array = []
	sections["song_package"] = _validate_song_package(context)
	all_issues.append_array(sections["song_package"].get("issues", []))
	for family in RECORD_FAMILY_ORDER:
		var section_report: Dictionary = {}
		match family:
			"songs":
				section_report = _validate_songs(context)
			"charts":
				section_report = _validate_charts(context)
			"sets":
				section_report = _validate_sets(context)
			"coaches":
				section_report = _validate_coaches(context)
			"environments":
				section_report = _validate_environments(context)
			"sql":
				section_report = _validate_sql(context)
		sections[family] = section_report
		all_issues.append_array(section_report.get("issues", []))
	var package_report: Dictionary = _validate_package_cross_references(context)
	sections["package"] = package_report
	all_issues.append_array(package_report.get("issues", []))
	var counts: Dictionary = _base_counts(context)
	counts["sectionCount"] = sections.size()
	return _report("package", package_dir, all_issues, counts, context.get("artifacts", {}), sections)

func _validate_song_package(context: Dictionary) -> Dictionary:
	var package_dir: String = String(context.get("packageDir", ""))
	var issues: Array = []
	var song_package: Dictionary = context.get("songPackage", {})
	var path: String = String(song_package.get("path", "song.package.yaml"))
	if not bool(song_package.get("exists", false)):
		issues.append(_issue("song_package_missing", "Package root song.package.yaml is required.", path, "song_package"))
		return _report("song_package", package_dir, issues, {"fileCount": 0}, {"songPackage": path}, {})
	if not bool(song_package.get("ok", false)):
		issues.append(_issue("song_package_invalid_yaml", "%s could not be parsed as YAML." % path, path, "song_package", "", "", {"error": song_package.get("error", "")}))
		return _report("song_package", package_dir, issues, {"fileCount": 1}, {"songPackage": path}, {})
	var data: Dictionary = song_package.get("data", {})
	for field in ["schemaId", "schemaVersion", "songId", "songName", "packageVersion", "song", "charts"]:
		if _is_missing_value(data.get(field, null)):
			issues.append(_issue("required_field_missing", "Song package is missing required field '%s'." % field, path, "song_package", String(data.get("songId", "")), field))
	for forbidden_field in ["recordVersion", "songPackageId", "songPackageName", "description", "workoutId", "workoutName", "coachConfigId", "setOrder", "setIds"]:
		if data.has(forbidden_field) and not _is_missing_value(data.get(forbidden_field, null)):
			issues.append(_issue("song_package_forbidden_field", "Song package field '%s' is retired from the clean-break manifest contract and must not be present." % forbidden_field, path, "song_package", String(data.get("songId", "")), forbidden_field))
	if data.has("song") and not (data.get("song") is Dictionary):
		issues.append(_issue("song_invalid_type", "Song package song must be an embedded song details dictionary.", path, "song_package", String(data.get("songId", "")), "song"))
	if data.has("charts") and not (data.get("charts") is Array):
		issues.append(_issue("charts_invalid_type", "Song package charts must be an array of root chart descriptors.", path, "song_package", String(data.get("songId", "")), "charts"))
	else:
		for index in range(Array(data.get("charts", [])).size()):
			var descriptor_variant: Variant = Array(data.get("charts", []))[index]
			if not (descriptor_variant is Dictionary):
				issues.append(_issue("chart_descriptor_invalid_type", "Root charts entries must be dictionaries.", path, "song_package", String(data.get("songId", "")), "charts[%d]" % index))
				continue
			var descriptor := Dictionary(descriptor_variant)
			for required_field in ROOT_CHART_DESCRIPTOR_REQUIRED_FIELDS:
				if _is_missing_value(descriptor.get(required_field, null)):
					issues.append(_issue("chart_descriptor_missing_field", "Root charts entry is missing required field '%s'." % required_field, path, "song_package", String(data.get("songId", "")), "charts[%d].%s" % [index, required_field]))
	return _report("song_package", package_dir, issues, {"fileCount": 1}, {"songPackage": path}, {})

func _validate_songs(context: Dictionary) -> Dictionary:
	return _validate_record_family(context, "songs")

func _validate_charts(context: Dictionary) -> Dictionary:
	return _validate_record_family(context, "charts")

func _validate_sets(context: Dictionary) -> Dictionary:
	return _validate_record_family(context, "sets")

func _validate_coaches(context: Dictionary) -> Dictionary:
	var package_dir: String = String(context.get("packageDir", ""))
	var issues: Array = []
	var records: Array = context.get("coaches", [])
	if records.is_empty():
		return _report("coaches", package_dir, issues, {"fileCount": 0}, {"files": []}, {})
	if records.size() != 1 or String(records[0].get("path", "")) != "coaches/coach-config.yaml":
		issues.append(_issue("coach_config_count_invalid", "Optional coaching data must use exactly one coaches/coach-config.yaml file.", "coaches/", "coaches"))
	var record: Dictionary = records[0]
	var path: String = String(record.get("path", "coaches/coach-config.yaml"))
	if not bool(record.get("ok", false)):
		issues.append(_issue("coach_config_invalid_yaml", "Coach config could not be parsed as YAML.", path, "coaches", "", "", {"error": record.get("error", "")}))
		return _report("coaches", package_dir, issues, {"fileCount": records.size()}, {"files": _record_paths(records)}, {})
	return _report("coaches", package_dir, issues, {"fileCount": records.size()}, {"files": _record_paths(records)}, {})

func _validate_environments(context: Dictionary) -> Dictionary:
	return _validate_record_family(context, "environments")


func _validate_sql(context: Dictionary) -> Dictionary:
	var package_dir: String = String(context.get("packageDir", ""))
	var issues: Array = []
	var sql_files: Array = context.get("sql", [])
	if sql_files.is_empty():
		return _report("sql", package_dir, issues, {"fileCount": 0}, {"files": []}, {})
	for sql_file in sql_files:
		var path: String = String(sql_file.get("path", ""))
		if not String(path.get_file()).ends_with(".schema.sql"):
			issues.append(_issue("sql_schema_name_invalid", "SQL schema file must end with .schema.sql.", path, "sql"))
		if not bool(sql_file.get("ok", false)):
			issues.append(_issue("sql_schema_unreadable", "SQL schema file could not be read.", path, "sql"))
			continue
		var text: String = String(sql_file.get("text", ""))
		if text.strip_edges().is_empty():
			issues.append(_issue("sql_schema_empty", "SQL schema file must not be empty.", path, "sql"))
			continue
		var upper_text: String = text.to_upper()
		if upper_text.find("CREATE TABLE") == -1:
			issues.append(_issue("sql_schema_missing_create_table", "SQL schema file must contain at least one CREATE TABLE statement.", path, "sql"))
		if upper_text.find("CREATE INDEX") == -1:
			issues.append(_issue("sql_schema_missing_create_index", "SQL schema file should contain at least one CREATE INDEX statement for this first slice.", path, "sql"))
	return _report("sql", package_dir, issues, {"fileCount": sql_files.size()}, {"files": _sql_paths(sql_files)}, {})

func _validate_record_family(context: Dictionary, family: String) -> Dictionary:
	var package_dir: String = String(context.get("packageDir", ""))
	var config: Dictionary = FAMILY_CONFIG.get(family, {})
	var issues: Array = []
	var records: Array = context.get(family, [])
	var family_dir: String = String(config.get("dir", family))
	if records.is_empty():
		if family == "environments":
			return _report(family, package_dir, issues, {"fileCount": 0}, {"files": []}, {})
		issues.append(_issue("records_missing", "Package must contain at least one %s YAML file." % family, family_dir.path_join(""), family))
		return _report(family, package_dir, issues, {"fileCount": 0}, {"files": []}, {})
	var seen_ids: Dictionary = {}
	for record in records:
		var path: String = String(record.get("path", family_dir))
		if not bool(record.get("ok", false)):
			issues.append(_issue("invalid_yaml", "%s YAML could not be parsed." % family.capitalize(), path, family, "", "", {"error": record.get("error", "")}))
			continue
		var data: Dictionary = record.get("data", {})
		for field in config.get("requiredFields", []):
			if _is_missing_value(data.get(field, null)):
				issues.append(_issue("required_field_missing", "%s is missing required field '%s'." % [_family_label(family), field], path, family, String(data.get(config.get("idKey", "id"), "")), field))
		var record_id: String = String(data.get(config.get("idKey", "id"), ""))
		if record_id.is_empty():
			issues.append(_issue("invalid_id", "%s id field '%s' must be present." % [_family_label(family), config.get("idKey", "id")], path, family, "", String(config.get("idKey", "id"))))
		elif seen_ids.has(record_id):
			issues.append(_issue("duplicate_id", "Duplicate %s id '%s'." % [family.trim_suffix("s"), record_id], path, family, record_id, String(config.get("idKey", "id"))))
		else:
			seen_ids[record_id] = true
		match family:
			"songs":
				issues.append_array(_validate_song_record(package_dir, path, data))
			"charts":
				issues.append_array(Array(_chart_validator.validate_chart_record(data, path).get("issues", [])))
				issues.append_array(_validate_forbidden_composition_link_fields(path, "charts", record_id, data, FORBIDDEN_CHART_COMPOSITION_LINK_FIELDS))
			"sets":
				issues.append_array(_validate_set_record(path, data))
			"environments":
				issues.append_array(_validate_environment_record(package_dir, path, data))
	return _report(family, package_dir, issues, {"fileCount": records.size()}, {"files": _record_paths(records)}, {})

func _validate_song_record(package_dir: String, path: String, song: Dictionary) -> Array:
	var issues: Array = []
	var song_id: String = String(song.get("songId", ""))
	issues.append_array(_validate_forbidden_composition_link_fields(path, "songs", song_id, song, FORBIDDEN_SONG_COMPOSITION_LINK_FIELDS))
	if not (song.get("audio") is Dictionary):
		issues.append(_issue("song_audio_invalid_type", "Song audio must be a dictionary.", path, "songs", song_id, "audio"))
	else:
		var audio: Dictionary = song.get("audio", {})
		var file_path: String = String(audio.get("filePath", ""))
		if file_path.is_empty():
			issues.append(_issue("song_audio_file_missing", "Song audio.filePath is required.", path, "songs", song_id, "audio.filePath"))
	issues.append_array(_validate_song_timing(path, song))
	return issues

func _validate_forbidden_composition_link_fields(path: String, subject: String, record_id: String, record: Dictionary, forbidden_fields: Array) -> Array:
	var issues: Array = []
	for field in forbidden_fields:
		if not record.has(String(field)):
			continue
		if _is_missing_value(record.get(String(field), null)):
			continue
		issues.append(_issue(
			"forbidden_composition_link_field",
			"%s must not declare composition-link field '%s'; sets are the canonical linker." % [_family_label(subject).trim_suffix("s"), String(field)],
			path,
			subject,
			record_id,
			String(field),
			{"field": String(field)}
		))
	return issues

func _validate_set_record(path: String, set_data: Dictionary) -> Array:
	var issues: Array = []
	var set_id: String = String(set_data.get("setId", ""))
	if set_data.has("assetSelections") and not _is_missing_value(set_data.get("assetSelections", null)):
		issues.append(_issue(
			"asset_selections_not_supported",
			"Set assetSelections is no longer part of the v1 song-package contract; remove package-local asset selection data.",
			path,
			"sets",
			set_id,
			"assetSelections"
		))
	return issues

func _validate_environment_record(package_dir: String, path: String, environment: Dictionary) -> Array:
	var issues: Array = []
	var environment_id: String = String(environment.get("environmentId", ""))
	var environment_type: String = String(environment.get("type", ""))
	if not environment_type.is_empty() and not VALID_ENVIRONMENT_TYPES.has(environment_type):
		issues.append(_issue("invalid_environment_type", "Environment type must be one of image_background/video_background/glb_environment/splat.", path, "environments", environment_id, "type"))
	var resource_path: String = String(environment.get("resourcePath", ""))
	if not resource_path.is_empty() and not _package_file_exists(package_dir, resource_path):
		issues.append(_issue("missing_file", "Environment resourcePath does not resolve inside the package.", path, "environments", environment_id, "resourcePath", {"pathValue": resource_path}))
	if not environment_type.is_empty() and not resource_path.is_empty() and VALID_ENVIRONMENT_TYPES.has(environment_type):
		var allowed_extensions: Array = ENVIRONMENT_RESOURCE_EXTENSIONS.get(environment_type, [])
		if not _path_has_allowed_extension(resource_path, allowed_extensions):
			issues.append(_issue(
				"environment_resource_type_mismatch",
				"Environment resourcePath must match the expected file family for type '%s'." % environment_type,
				path,
				"environments",
				environment_id,
				"resourcePath",
				{"pathValue": resource_path, "type": environment_type, "allowedExtensions": allowed_extensions}
			))
	var config_path: String = String(environment.get("configPath", ""))
	if not config_path.is_empty():
		if not _package_file_exists(package_dir, config_path):
			issues.append(_issue("missing_file", "Environment configPath does not resolve inside the package.", path, "environments", environment_id, "configPath", {"pathValue": config_path}))
		elif not _path_has_allowed_extension(config_path, ENVIRONMENT_CONFIG_EXTENSIONS):
			issues.append(_issue("environment_config_type_mismatch", "Environment configPath must point to a YAML sidecar file.", path, "environments", environment_id, "configPath", {"pathValue": config_path, "allowedExtensions": ENVIRONMENT_CONFIG_EXTENSIONS}))
	return issues


func _validate_media_reference(package_dir: String, path: String, field_name: String, value: Variant, subject: String, record_id: String) -> Array:
	var issues: Array = []
	if not (value is Dictionary):
		issues.append(_issue("media_reference_invalid_type", "%s must be a dictionary." % field_name, path, subject, record_id, field_name))
		return issues
	var media: Dictionary = value
	var media_path: String = String(media.get("path", ""))
	if media_path.is_empty():
		issues.append(_issue("media_reference_path_missing", "%s.path is required." % field_name, path, subject, record_id, "%s.path" % field_name))
	elif not _package_file_exists(package_dir, media_path):
		issues.append(_issue("missing_file", "%s.path does not resolve inside the package." % field_name, path, subject, record_id, "%s.path" % field_name, {"pathValue": media_path}))
	return issues

func _validate_package_cross_references(context: Dictionary) -> Dictionary:
	var package_dir: String = String(context.get("packageDir", ""))
	var issues: Array = _legacy_package_contract_issues(context)
	var song_package: Dictionary = context.get("songPackage", {}).get("data", {}) if bool(context.get("songPackage", {}).get("ok", false)) else {}
	var root_path: String = String(context.get("songPackage", {}).get("path", "song.package.yaml"))
	var songs_by_id: Dictionary = _index_records(context.get("songs", []), "songId")
	var charts_by_id: Dictionary = _index_records(context.get("charts", []), "chartId")
	var referenced_chart_ids: Dictionary = {}
	if not song_package.is_empty() and song_package.get("charts") is Array:
		for index in range(song_package.get("charts", []).size()):
			var descriptor := Dictionary(song_package.get("charts", [])[index])
			var chart_id: String = String(descriptor.get("chartId", "")).strip_edges()
			var path_value: String = String(descriptor.get("path", "")).strip_edges()
			var feature: String = String(descriptor.get("feature", "")).strip_edges()
			var difficulty: String = String(descriptor.get("difficulty", "")).strip_edges()
			var issue_id: String = String(song_package.get("songId", ""))
			if path_value.is_empty() or not _package_file_exists(package_dir, path_value):
				issues.append(_issue("missing_chart_path", "%s charts entry points at a chart file that does not exist." % root_path, root_path, "package", issue_id, "charts[%d].path" % index, {"pathValue": path_value}))
			if not chart_id.is_empty():
				referenced_chart_ids[chart_id] = true
			if chart_id.is_empty() or not charts_by_id.has(chart_id):
				continue
			var chart_data: Dictionary = Dictionary(charts_by_id.get(chart_id, {}).get("data", {}))
			if feature != String(chart_data.get("feature", "")).strip_edges():
				issues.append(_issue("chart_descriptor_feature_mismatch", "Root charts[] descriptor feature must match the referenced chart file feature.", root_path, "package", issue_id, "charts[%d].feature" % index, {"chartId": chart_id, "feature": feature, "chartFeature": chart_data.get("feature", "")}))
			if difficulty != String(chart_data.get("difficulty", "")).strip_edges():
				issues.append(_issue("chart_descriptor_difficulty_mismatch", "Root charts[] descriptor difficulty must match the referenced chart file difficulty.", root_path, "package", issue_id, "charts[%d].difficulty" % index, {"chartId": chart_id, "difficulty": difficulty, "chartDifficulty": chart_data.get("difficulty", "")}))
	for set_record in context.get("sets", []):
		if not bool(set_record.get("ok", false)):
			continue
		var path: String = String(set_record.get("path", ""))
		var set_data: Dictionary = set_record.get("data", {})
		var set_id: String = String(set_data.get("setId", ""))
		var song_id: String = String(set_data.get("songId", ""))
		var chart_id: String = String(set_data.get("chartId", ""))
		if not song_id.is_empty() and not songs_by_id.has(song_id):
			issues.append(_issue("missing_song_ref", "Root charts[] descriptor references a songId that is not present in the package.", path, "package", set_id, "songId", {"songId": song_id}))
		if not chart_id.is_empty() and not charts_by_id.has(chart_id):
			issues.append(_issue("missing_chart_ref", "Root charts[] descriptor references a chartId that is not present in the package.", path, "package", set_id, "chartId", {"chartId": chart_id}))
	for chart_record in context.get("charts", []):
		if not bool(chart_record.get("ok", false)):
			continue
		var chart_path: String = String(chart_record.get("path", ""))
		var chart_data: Dictionary = chart_record.get("data", {})
		var chart_id: String = String(chart_data.get("chartId", "")).strip_edges()
		if not chart_id.is_empty() and not referenced_chart_ids.has(chart_id):
			issues.append(_issue("orphan_chart_record", "Chart file is present on disk but is not referenced from root charts[].", chart_path, "package", chart_id, "chartId"))
	return _report("package", package_dir, issues, {"crossCheckCount": 1}, context.get("artifacts", {}), {})

func _legacy_package_contract_issues(context: Dictionary) -> Array:
	var issues: Array = []
	var package_dir: String = String(context.get("packageDir", ""))
	if bool(context.get("legacyAssetsDirExists", false)):
		issues.append(_issue(
			"assets_directory_not_supported",
			"Package assets/ is no longer an accepted authored package family in the v1 song-package contract.",
			package_dir.path_join("assets"),
			"package",
			"",
			"assets"
		))
	if bool(context.get("legacySongsDirExists", false)):
		issues.append(_issue("songs_directory_not_supported", "Canonical song-package packages now embed root song metadata instead of using songs/.", package_dir.path_join("songs"), "package", "", "songs"))
	if bool(context.get("legacySetsDirExists", false)):
		issues.append(_issue("sets_directory_not_supported", "Canonical song-package packages now embed root charts[] descriptors instead of using sets/.", package_dir.path_join("sets"), "package", "", "sets"))
	if bool(context.get("legacyEnvironmentsDirExists", false)):
		issues.append(_issue("environments_directory_not_supported", "Package-owned environments/ are no longer part of the default imported song-package contract.", package_dir.path_join("environments"), "package", "", "environments"))
	return issues

func _load_package_context(package_dir: String) -> Dictionary:
	var root_file_name := "song.package.yaml"
	var root_path: String = package_dir.path_join(root_file_name)
	var song_package_record: Dictionary = {
		"path": root_file_name,
		"absolutePath": root_path,
		"exists": FileAccess.file_exists(root_path),
		"ok": false,
		"data": {},
		"error": "",
	}
	if song_package_record["exists"]:
		var parsed_root: Dictionary = _load_yaml_file(root_path)
		song_package_record["ok"] = bool(parsed_root.get("ok", false))
		song_package_record["data"] = _normalize_song_package_root(Dictionary(parsed_root.get("data", {})))
		song_package_record["error"] = String(parsed_root.get("error", ""))
	var context: Dictionary = {
		"packageDir": package_dir,
		"songPackage": song_package_record,
		"songs": _root_song_records(song_package_record),
		"charts": _load_root_chart_records(package_dir, song_package_record),
		"sets": _derive_root_sets(song_package_record),
		"coaches": _load_yaml_records(package_dir, "coaches"),
		"environments": _load_yaml_records(package_dir, "environments"),
		"sql": _load_sql_files(package_dir),
		"legacyAssetsDirExists": DirAccess.dir_exists_absolute(package_dir.path_join("assets")),
		"legacySongsDirExists": DirAccess.dir_exists_absolute(package_dir.path_join("songs")),
		"legacySetsDirExists": DirAccess.dir_exists_absolute(package_dir.path_join("sets")),
		"legacyEnvironmentsDirExists": DirAccess.dir_exists_absolute(package_dir.path_join("environments")),
	}
	context["artifacts"] = {
		"songPackage": root_file_name,
		"songs": _record_paths(context.get("songs", [])),
		"charts": _record_paths(context.get("charts", [])),
		"sets": _record_paths(context.get("sets", [])),
		"coaches": _record_paths(context.get("coaches", [])),
		"environments": _record_paths(context.get("environments", [])),
		"sql": _sql_paths(context.get("sql", [])),
	}
	return context

func _normalize_song_package_root(data: Dictionary) -> Dictionary:
	var normalized := data.duplicate(true)
	normalized["songId"] = String(normalized.get("songId", "")).strip_edges()
	normalized["songName"] = String(normalized.get("songName", "")).strip_edges()
	if normalized.get("song") is Dictionary:
		var song_record := Dictionary(normalized.get("song", {})).duplicate(true)
		song_record["songId"] = normalized["songId"]
		song_record["songName"] = normalized["songName"]
		normalized["song"] = _normalize_song_root(song_record)
	var descriptors: Array = []
	for descriptor_variant in Array(normalized.get("charts", [])):
		if not (descriptor_variant is Dictionary):
			continue
		var descriptor := Dictionary(descriptor_variant).duplicate(true)
		for field in ROOT_CHART_DESCRIPTOR_REQUIRED_FIELDS:
			descriptor[field] = String(descriptor.get(field, "")).strip_edges()
		descriptors.append(descriptor)
	normalized["charts"] = descriptors
	return normalized

func _normalize_song_root(song: Dictionary) -> Dictionary:
	var normalized := song.duplicate(true)
	normalized["schemaId"] = String(normalized.get("schemaId", "aerobeat.song.v1")).strip_edges()
	normalized["schemaVersion"] = int(normalized.get("schemaVersion", 1))
	normalized["recordVersion"] = int(normalized.get("recordVersion", 1))
	return normalized

func _root_song_records(song_package_record: Dictionary) -> Array:
	if not bool(song_package_record.get("ok", false)):
		return []
	var data: Dictionary = Dictionary(song_package_record.get("data", {}))
	if not (data.get("song") is Dictionary):
		return []
	var song_record := Dictionary(data.get("song", {})).duplicate(true)
	song_record["songId"] = String(data.get("songId", song_record.get("songId", ""))).strip_edges()
	song_record["songName"] = String(data.get("songName", song_record.get("songName", ""))).strip_edges()
	return [{
		"family": "songs",
		"path": "%s#song" % String(song_package_record.get("path", "song.package.yaml")),
		"absolutePath": String(song_package_record.get("absolutePath", "")),
		"ok": true,
		"data": _normalize_song_root(song_record),
		"error": "",
	}]

func _load_root_chart_records(package_dir: String, song_package_record: Dictionary) -> Array:
	var records: Array = []
	if not bool(song_package_record.get("ok", false)):
		return records
	var data: Dictionary = Dictionary(song_package_record.get("data", {}))
	for descriptor_variant in Array(data.get("charts", [])):
		if not (descriptor_variant is Dictionary):
			continue
		var descriptor := Dictionary(descriptor_variant)
		var relative_path: String = String(descriptor.get("path", "")).strip_edges()
		if relative_path.is_empty():
			continue
		var absolute_path: String = package_dir.path_join(relative_path)
		if not FileAccess.file_exists(absolute_path):
			continue
		var parsed: Dictionary = _load_yaml_file(absolute_path)
		records.append({
			"family": "charts",
			"path": relative_path,
			"absolutePath": absolute_path,
			"ok": parsed.get("ok", false),
			"data": parsed.get("data", {}),
			"error": parsed.get("error", ""),
		})
	return records

func _derive_root_sets(song_package_record: Dictionary) -> Array:
	var sets: Array = []
	if not bool(song_package_record.get("ok", false)):
		return sets
	var data: Dictionary = Dictionary(song_package_record.get("data", {}))
	var song_id: String = String(data.get("songId", "")).strip_edges()
	var song_name: String = String(data.get("songName", "")).strip_edges()
	var index: int = 0
	for descriptor_variant in Array(data.get("charts", [])):
		if not (descriptor_variant is Dictionary):
			continue
		var descriptor := Dictionary(descriptor_variant)
		var chart_id := String(descriptor.get("chartId", "")).strip_edges()
		var feature := String(descriptor.get("feature", "")).strip_edges()
		var difficulty := String(descriptor.get("difficulty", "")).strip_edges()
		sets.append({
			"family": "sets",
			"path": "%s#charts[%d]" % [String(song_package_record.get("path", "song.package.yaml")), index],
			"absolutePath": String(song_package_record.get("absolutePath", "")),
			"ok": true,
			"data": {
				"schemaId": "aerobeat.set.v1",
				"schemaVersion": 1,
				"recordVersion": 1,
				"setId": chart_id,
				"setName": ("%s %s %s" % [song_name, difficulty, feature.capitalize()]).strip_edges(),
				"songId": song_id,
				"chartId": chart_id,
			},
			"error": "",
		})
		index += 1
	return sets

func _load_yaml_records(package_dir: String, family: String) -> Array:
	var config: Dictionary = FAMILY_CONFIG.get(family, {})
	var relative_paths: Array = _list_files(package_dir.path_join(String(config.get("dir", family))), [".yaml", ".yml"])
	var records: Array = []
	for relative_path in relative_paths:
		var absolute_path: String = package_dir.path_join(relative_path)
		var parsed: Dictionary = _load_yaml_file(absolute_path)
		records.append({
			"family": family,
			"path": relative_path,
			"absolutePath": absolute_path,
			"ok": parsed.get("ok", false),
			"data": parsed.get("data", {}),
			"error": parsed.get("error", ""),
		})
	return records

func _load_sql_files(package_dir: String) -> Array:
	var relative_paths: Array = _list_files(package_dir.path_join("sql"), [".sql"])
	var sql_files: Array = []
	for relative_path in relative_paths:
		var absolute_path: String = package_dir.path_join(relative_path)
		var ok: bool = FileAccess.file_exists(absolute_path)
		var text: String = FileAccess.get_file_as_string(absolute_path) if ok else ""
		sql_files.append({
			"path": relative_path,
			"absolutePath": absolute_path,
			"ok": ok,
			"text": text,
		})
	return sql_files

func _load_yaml_file(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {"ok": false, "data": {}, "error": "File does not exist."}
	var text: String = FileAccess.get_file_as_string(path)
	var parsed: Dictionary = _parse_yaml_text(text)
	if not bool(parsed.get("ok", false)):
		return parsed
	var data: Variant = parsed.get("data", {})
	if not (data is Dictionary):
		return {"ok": false, "data": {}, "error": "Top-level YAML document must be a dictionary."}
	return {"ok": true, "data": data, "error": ""}

func _parse_yaml_text(text: String) -> Dictionary:
	var lines: Array = []
	for raw_line in text.split("\n"):
		var normalized_line: String = String(raw_line).rstrip("\r")
		var stripped_line: String = normalized_line.strip_edges()
		if stripped_line.is_empty() or stripped_line.begins_with("#"):
			continue
		var trimmed_left: String = normalized_line.lstrip(" \t")
		var indent: int = normalized_line.length() - trimmed_left.length()
		lines.append({"indent": indent, "text": trimmed_left.rstrip(" \t")})
	if lines.is_empty():
		return {"ok": true, "data": {}, "error": ""}
	var state := {"lines": lines, "index": 0}
	var data: Variant = _parse_yaml_node(state, int(lines[0].get("indent", 0)))
	return {"ok": true, "data": data, "error": ""}

func _parse_yaml_node(state: Dictionary, indent: int) -> Variant:
	if int(state.get("index", 0)) >= state.get("lines", []).size():
		return {}
	var line: Dictionary = state.get("lines", [])[int(state.get("index", 0))]
	var text: String = String(line.get("text", ""))
	if text.begins_with("- "):
		return _parse_yaml_sequence(state, indent)
	return _parse_yaml_mapping(state, indent)

func _parse_yaml_mapping(state: Dictionary, indent: int) -> Dictionary:
	var result: Dictionary = {}
	while int(state.get("index", 0)) < state.get("lines", []).size():
		var line: Dictionary = state.get("lines", [])[int(state.get("index", 0))]
		var line_indent: int = int(line.get("indent", 0))
		var text: String = String(line.get("text", ""))
		if line_indent < indent:
			break
		if line_indent > indent:
			state["index"] = int(state.get("index", 0)) + 1
			continue
		if text.begins_with("- "):
			break
		var parts: Array = _split_mapping_entry(text)
		var key: String = String(parts[0])
		var remainder: String = String(parts[1])
		state["index"] = int(state.get("index", 0)) + 1
		if remainder.is_empty():
			if int(state.get("index", 0)) < state.get("lines", []).size() and int(state.get("lines", [])[int(state.get("index", 0))].get("indent", 0)) > indent:
				result[key] = _parse_yaml_node(state, int(state.get("lines", [])[int(state.get("index", 0))].get("indent", 0)))
			else:
				result[key] = null
		elif remainder == ">" or remainder == ">-" or remainder == "|" or remainder == "|-":
			result[key] = _parse_yaml_block_scalar(state, indent, remainder)
		else:
			result[key] = _parse_yaml_scalar(remainder)
	return result

func _parse_yaml_sequence(state: Dictionary, indent: int) -> Array:
	var result: Array = []
	while int(state.get("index", 0)) < state.get("lines", []).size():
		var line: Dictionary = state.get("lines", [])[int(state.get("index", 0))]
		var line_indent: int = int(line.get("indent", 0))
		var text: String = String(line.get("text", ""))
		if line_indent < indent or line_indent != indent or not text.begins_with("- "):
			break
		var item_text: String = text.substr(2)
		state["index"] = int(state.get("index", 0)) + 1
		if item_text.is_empty():
			if int(state.get("index", 0)) < state.get("lines", []).size() and int(state.get("lines", [])[int(state.get("index", 0))].get("indent", 0)) > indent:
				result.append(_parse_yaml_node(state, int(state.get("lines", [])[int(state.get("index", 0))].get("indent", 0))))
			else:
				result.append(null)
			continue
		if _looks_like_mapping_entry(item_text):
			var parts: Array = _split_mapping_entry(item_text)
			var entry: Dictionary = {}
			var key: String = String(parts[0])
			var remainder: String = String(parts[1])
			if remainder.is_empty():
				if int(state.get("index", 0)) < state.get("lines", []).size() and int(state.get("lines", [])[int(state.get("index", 0))].get("indent", 0)) > indent:
					entry[key] = _parse_yaml_node(state, int(state.get("lines", [])[int(state.get("index", 0))].get("indent", 0)))
				else:
					entry[key] = null
			elif remainder == ">" or remainder == ">-" or remainder == "|" or remainder == "|-":
				entry[key] = _parse_yaml_block_scalar(state, indent, remainder)
			else:
				entry[key] = _parse_yaml_scalar(remainder)
			if int(state.get("index", 0)) < state.get("lines", []).size() and int(state.get("lines", [])[int(state.get("index", 0))].get("indent", 0)) > indent:
				var continuation: Variant = _parse_yaml_node(state, int(state.get("lines", [])[int(state.get("index", 0))].get("indent", 0)))
				if continuation is Dictionary:
					for continuation_key in continuation.keys():
						entry[continuation_key] = continuation.get(continuation_key)
			result.append(entry)
		else:
			result.append(_parse_yaml_scalar(item_text))
	return result

func _parse_yaml_block_scalar(state: Dictionary, indent: int, style: String) -> String:
	var parts: Array[String] = []
	while int(state.get("index", 0)) < state.get("lines", []).size():
		var line: Dictionary = state.get("lines", [])[int(state.get("index", 0))]
		var line_indent: int = int(line.get("indent", 0))
		if line_indent <= indent:
			break
		parts.append(String(line.get("text", "")).strip_edges())
		state["index"] = int(state.get("index", 0)) + 1
	if style.begins_with(">"):
		return " ".join(parts)
	return "\n".join(parts)

func _parse_yaml_scalar(value: String) -> Variant:
	var trimmed: String = value.strip_edges()
	if trimmed.is_empty():
		return ""
	if trimmed == "true":
		return true
	if trimmed == "false":
		return false
	if trimmed == "null" or trimmed == "~":
		return null
	if (trimmed.begins_with("\"") and trimmed.ends_with("\"")) or (trimmed.begins_with("'") and trimmed.ends_with("'")):
		return trimmed.substr(1, trimmed.length() - 2)
	if trimmed.begins_with("[") and trimmed.ends_with("]"):
		return _parse_flow_array(trimmed)
	if _is_integer_literal(trimmed):
		return int(trimmed)
	if _is_float_literal(trimmed):
		return float(trimmed)
	return trimmed

func _parse_flow_array(value: String) -> Array:
	var inner: String = value.substr(1, value.length() - 2).strip_edges()
	if inner.is_empty():
		return []
	var parts: Array = inner.split(",", false)
	var result: Array = []
	for part in parts:
		result.append(_parse_yaml_scalar(String(part).strip_edges()))
	return result

func _split_mapping_entry(text: String) -> Array:
	var delimiter_index: int = text.find(":")
	if delimiter_index == -1:
		return [text.strip_edges(), ""]
	var key: String = text.substr(0, delimiter_index).strip_edges()
	var remainder: String = text.substr(delimiter_index + 1).strip_edges()
	return [key, remainder]

func _looks_like_mapping_entry(text: String) -> bool:
	var delimiter_index: int = text.find(":")
	if delimiter_index <= 0:
		return false
	return true

func _list_files(directory_path: String, extensions: Array) -> Array:
	return _list_relative_files(directory_path, extensions)

func _list_relative_files(directory_path: String, extensions: Array) -> Array:
	var relative_paths: Array = []
	if not DirAccess.dir_exists_absolute(directory_path):
		return relative_paths
	var dir := DirAccess.open(directory_path)
	if dir == null:
		return relative_paths
	var root_name: String = directory_path.get_file()
	dir.list_dir_begin()
	while true:
		var name := dir.get_next()
		if name.is_empty():
			break
		if name == "." or name == "..":
			continue
		if dir.current_is_dir():
			continue
		for extension in extensions:
			if String(name).to_lower().ends_with(String(extension).to_lower()):
				relative_paths.append(root_name.path_join(name))
				break
	dir.list_dir_end()
	relative_paths.sort()
	return relative_paths

func _index_records(records: Array, id_key: String) -> Dictionary:
	var index: Dictionary = {}
	for record in records:
		if not bool(record.get("ok", false)):
			continue
		var data: Dictionary = record.get("data", {})
		var record_id: String = String(data.get(id_key, ""))
		if not record_id.is_empty():
			index[record_id] = record
	return index

func _coach_config_record(context: Dictionary) -> Dictionary:
	var records: Array = context.get("coaches", [])
	if records.is_empty():
		return {}
	return records[0]

func _record_paths(records: Array) -> Array:
	var paths: Array = []
	for record in records:
		paths.append(String(record.get("path", "")))
	return paths

func _sql_paths(sql_files: Array) -> Array:
	var paths: Array = []
	for sql_file in sql_files:
		paths.append(String(sql_file.get("path", "")))
	return paths

func _package_file_exists(package_dir: String, relative_path: String) -> bool:
	return FileAccess.file_exists(package_dir.path_join(relative_path))

func _path_has_allowed_extension(path: String, allowed_extensions: Array) -> bool:
	var normalized_path: String = path.to_lower()
	for extension in allowed_extensions:
		if normalized_path.ends_with(String(extension).to_lower()):
			return true
	return false

func _base_counts(context: Dictionary) -> Dictionary:
	return {
		"songCount": context.get("songs", []).size(),
		"chartCount": context.get("charts", []).size(),
		"setCount": context.get("sets", []).size(),
		"coachConfigCount": context.get("coaches", []).size(),
		"environmentCount": context.get("environments", []).size(),
		"sqlFileCount": context.get("sql", []).size(),
	}

func _family_label(family: String) -> String:
	return family.left(1).to_upper() + family.substr(1)

func _report(subject: String, package_dir: String, issues: Array, counts: Dictionary, artifacts: Dictionary, sections: Dictionary) -> Dictionary:
	return {
		"ok": issues.is_empty(),
		"valid": issues.is_empty(),
		"subject": subject,
		"packageDir": package_dir,
		"issueCount": issues.size(),
		"warningCount": 0,
		"issues": issues,
		"warnings": [],
		"counts": counts,
		"artifacts": artifacts,
		"sections": sections,
	}

func _issue(code: String, message: String, path: String, subject: String, record_id: String = "", field: String = "", reference: Dictionary = {}) -> Dictionary:
	var issue: Dictionary = {
		"code": code,
		"severity": "error",
		"message": message,
		"path": path,
		"subject": subject,
		"reference": reference,
	}
	if not record_id.is_empty():
		issue["recordId"] = record_id
	if not field.is_empty():
		issue["field"] = field
	return issue

func _validate_song_timing(path: String, song: Dictionary) -> Array:
	var issues: Array = []
	if not song.has("timing"):
		return issues
	var timing_value: Variant = song.get("timing")
	if not (timing_value is Dictionary):
		issues.append(_issue("song_timing_invalid_type", "Song timing must be a dictionary.", path, "songs", String(song.get("songId", "")), "timing"))
		return issues
	var timing: Dictionary = timing_value
	if timing.has("bpm"):
		issues.append(_issue("song_timing_bpm_shortcut_forbidden", "Song timing must use tempoSegments and must not include a timing.bpm shortcut.", path, "songs", String(song.get("songId", "")), "timing.bpm"))
	for field in SONG_TIMING_REQUIRED_FIELDS:
		if not timing.has(field):
			issues.append(_issue("song_timing_missing_field", "Song timing is missing required field '%s'." % field, path, "songs", String(song.get("songId", "")), "timing.%s" % field))
	if timing.has("anchorMs") and not _is_integer_number(timing.get("anchorMs")):
		issues.append(_issue("song_timing_anchor_invalid_type", "Song timing anchorMs must be an integer millisecond value.", path, "songs", String(song.get("songId", "")), "timing.anchorMs"))
	issues.append_array(_validate_tempo_segments(path, song, timing))
	issues.append_array(_validate_stop_segments(path, song, timing))
	issues.append_array(_validate_time_signature_segments(path, song, timing))
	return issues

func _validate_tempo_segments(path: String, song: Dictionary, timing: Dictionary) -> Array:
	var issues: Array = []
	if not timing.has("tempoSegments"):
		return issues
	var segments_value: Variant = timing.get("tempoSegments")
	if not (segments_value is Array):
		issues.append(_issue("song_tempo_segments_invalid_type", "Song timing tempoSegments must be an array.", path, "songs", String(song.get("songId", "")), "timing.tempoSegments"))
		return issues
	for index in range(segments_value.size()):
		var segment_value: Variant = segments_value[index]
		if not (segment_value is Dictionary):
			issues.append(_issue("song_tempo_segment_invalid_type", "Song tempo segment entries must be dictionaries.", path, "songs", String(song.get("songId", "")), "timing.tempoSegments[%d]" % index))
			continue
		var segment: Dictionary = segment_value
		for field in ["startBeat", "bpm"]:
			if not segment.has(field):
				issues.append(_issue("song_tempo_segment_missing_field", "Song tempo segment is missing required field '%s'." % field, path, "songs", String(song.get("songId", "")), "timing.tempoSegments[%d].%s" % [index, field]))
	return issues

func _validate_stop_segments(path: String, song: Dictionary, timing: Dictionary) -> Array:
	var issues: Array = []
	if not timing.has("stopSegments"):
		return issues
	var segments_value: Variant = timing.get("stopSegments")
	if not (segments_value is Array):
		issues.append(_issue("song_stop_segments_invalid_type", "Song timing stopSegments must be an array.", path, "songs", String(song.get("songId", "")), "timing.stopSegments"))
		return issues
	for index in range(segments_value.size()):
		var segment_value: Variant = segments_value[index]
		if not (segment_value is Dictionary):
			issues.append(_issue("song_stop_segment_invalid_type", "Song stop segment entries must be dictionaries.", path, "songs", String(song.get("songId", "")), "timing.stopSegments[%d]" % index))
			continue
		var segment: Dictionary = segment_value
		for field in ["startBeat", "durationMs"]:
			if not segment.has(field):
				issues.append(_issue("song_stop_segment_missing_field", "Song stop segment is missing required field '%s'." % field, path, "songs", String(song.get("songId", "")), "timing.stopSegments[%d].%s" % [index, field]))
	return issues

func _validate_time_signature_segments(path: String, song: Dictionary, timing: Dictionary) -> Array:
	var issues: Array = []
	if not timing.has("timeSignatureSegments"):
		return issues
	var segments_value: Variant = timing.get("timeSignatureSegments")
	if not (segments_value is Array):
		issues.append(_issue("song_time_signature_segments_invalid_type", "Song timing timeSignatureSegments must be an array.", path, "songs", String(song.get("songId", "")), "timing.timeSignatureSegments"))
		return issues
	for index in range(segments_value.size()):
		var segment_value: Variant = segments_value[index]
		if not (segment_value is Dictionary):
			issues.append(_issue("song_time_signature_segment_invalid_type", "Song time-signature segment entries must be dictionaries.", path, "songs", String(song.get("songId", "")), "timing.timeSignatureSegments[%d]" % index))
			continue
		var segment: Dictionary = segment_value
		for field in ["startBeat", "numerator", "denominator"]:
			if not segment.has(field):
				issues.append(_issue("song_time_signature_segment_missing_field", "Song time-signature segment is missing required field '%s'." % field, path, "songs", String(song.get("songId", "")), "timing.timeSignatureSegments[%d].%s" % [index, field]))
	return issues

func _is_missing_value(value: Variant) -> bool:
	if value == null:
		return true
	if value is String:
		return String(value).is_empty()
	if value is Array:
		return value.is_empty()
	if value is Dictionary:
		return value.is_empty()
	return false

func _is_integer_number(value: Variant) -> bool:
	return value is int or (value is float and floor(value) == value)

func _is_integer_literal(value: String) -> bool:
	return value.is_valid_int()

func _is_float_literal(value: String) -> bool:
	if value.find(".") == -1:
		return false
	return value.is_valid_float()
