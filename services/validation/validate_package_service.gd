class_name ValidatePackageService
extends RefCounted

const ValidateChartService = preload("validate_chart_service.gd")

const VALID_SUBJECTS := ["package", "workout", "songs", "charts", "sets", "coaches", "environments", "assets", "sql"]
const RECORD_FAMILY_ORDER := ["songs", "charts", "sets", "coaches", "environments", "assets", "sql"]
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
		"requiredFields": ["schemaId", "schemaVersion", "recordVersion", "chartId", "chartName", "feature", "difficulty", "beats"],
	},
	"sets": {
		"dir": "sets",
		"extension": ".yaml",
		"idKey": "setId",
		"requiredFields": ["schemaId", "schemaVersion", "recordVersion", "setId", "setName", "songId", "chartId", "environmentId"],
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
		"requiredFields": ["schemaId", "schemaVersion", "recordVersion", "environmentId", "environmentName", "scenePath"],
	},
	"assets": {
		"dir": "assets",
		"extension": ".yaml",
		"idKey": "assetId",
		"requiredFields": ["schemaId", "schemaVersion", "recordVersion", "assetId", "assetName", "assetType", "resourcePath"],
	},
}
const VALID_ASSET_SELECTION_TYPES := ["gloves", "targets", "obstacles", "trails"]
const VALID_ASSET_TYPES := ["gloves", "targets", "obstacles", "trails"]
const SONG_TIMING_REQUIRED_FIELDS := ["anchorMs", "tempoSegments", "stopSegments", "timeSignatureSegments"]

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
		"workout":
			return _validate_workout(context)
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
		"assets":
			return _validate_assets(context)
		"sql":
			return _validate_sql(context)
		_:
			return _report(subject, package_dir, [], {}, {}, {})

func _validate_package(context: Dictionary) -> Dictionary:
	var package_dir: String = String(context.get("packageDir", ""))
	var sections: Dictionary = {}
	var all_issues: Array = []
	sections["workout"] = _validate_workout(context)
	all_issues.append_array(sections["workout"].get("issues", []))
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
			"assets":
				section_report = _validate_assets(context)
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

func _validate_workout(context: Dictionary) -> Dictionary:
	var package_dir: String = String(context.get("packageDir", ""))
	var issues: Array = []
	var workout: Dictionary = context.get("workout", {})
	var path: String = String(workout.get("path", "workout.yaml"))
	if not bool(workout.get("exists", false)):
		issues.append(_issue("workout_missing", "Package root workout.yaml is required.", path, "workout"))
		return _report("workout", package_dir, issues, {"fileCount": 0}, {"workout": path}, {})
	if not bool(workout.get("ok", false)):
		issues.append(_issue("workout_invalid_yaml", "workout.yaml could not be parsed as YAML.", path, "workout", "", "", {"error": workout.get("error", "")}))
		return _report("workout", package_dir, issues, {"fileCount": 1}, {"workout": path}, {})
	var data: Dictionary = workout.get("data", {})
	for field in ["schemaId", "schemaVersion", "recordVersion", "workoutId", "workoutName", "packageVersion", "coachConfigId", "setOrder"]:
		if _is_missing_value(data.get(field, null)):
			issues.append(_issue("required_field_missing", "Workout is missing required field '%s'." % field, path, "workout", String(data.get("workoutId", "")), field))
	if data.has("preview"):
		if not (data.get("preview") is Dictionary):
			issues.append(_issue("preview_invalid_type", "Workout preview must be a dictionary when present.", path, "workout", String(data.get("workoutId", "")), "preview"))
		else:
			var preview: Dictionary = data.get("preview", {})
			var cover_art_path: String = String(preview.get("coverArtPath", ""))
			if cover_art_path.is_empty():
				issues.append(_issue("preview_cover_missing", "Workout preview.coverArtPath is required when preview is present.", path, "workout", String(data.get("workoutId", "")), "preview.coverArtPath"))
			elif not _package_file_exists(package_dir, cover_art_path):
				issues.append(_issue("missing_file", "Workout preview.coverArtPath does not resolve inside the package.", path, "workout", String(data.get("workoutId", "")), "preview.coverArtPath", {"pathValue": cover_art_path}))
	if data.has("setOrder") and not (data.get("setOrder") is Array):
		issues.append(_issue("set_order_invalid_type", "Workout setOrder must be an array of set ids.", path, "workout", String(data.get("workoutId", "")), "setOrder"))
	return _report("workout", package_dir, issues, {"fileCount": 1}, {"workout": path}, {})

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
		issues.append(_issue("coach_config_missing", "Package must contain coaches/coach-config.yaml.", "coaches/coach-config.yaml", "coaches"))
		return _report("coaches", package_dir, issues, {"fileCount": 0}, {"files": []}, {})
	if records.size() != 1 or String(records[0].get("path", "")) != "coaches/coach-config.yaml":
		issues.append(_issue("coach_config_count_invalid", "Package must contain exactly one coaches/coach-config.yaml and no alternate coach config files.", "coaches/", "coaches"))
	var record: Dictionary = records[0]
	var path: String = String(record.get("path", "coaches/coach-config.yaml"))
	if not bool(record.get("ok", false)):
		issues.append(_issue("coach_config_invalid_yaml", "Coach config could not be parsed as YAML.", path, "coaches", "", "", {"error": record.get("error", "")}))
		return _report("coaches", package_dir, issues, {"fileCount": records.size()}, {"files": _record_paths(records)}, {})
	var data: Dictionary = record.get("data", {})
	if not data.has("enabled") or not (data.get("enabled") is bool):
		issues.append(_issue("coach_config_enabled_missing", "Coach config must declare boolean enabled.", path, "coaches", String(data.get("coachConfigId", "")), "enabled"))
		return _report("coaches", package_dir, issues, {"fileCount": records.size()}, {"files": _record_paths(records)}, {})
	if not bool(data.get("enabled", false)):
		var keys: Array = data.keys()
		if keys.size() != 1 or not data.has("enabled"):
			issues.append(_issue("coach_config_disabled_not_minimal", "Disabled coach config must be minimal and contain only enabled: false.", path, "coaches", String(data.get("coachConfigId", ""))))
		return _report("coaches", package_dir, issues, {"fileCount": records.size()}, {"files": _record_paths(records)}, {})
	for field in ["schemaId", "schemaVersion", "recordVersion", "coachConfigId", "coachConfigName", "featuredCoaches", "warmupVideo", "cooldownVideo", "overlayAudio"]:
		if _is_missing_value(data.get(field, null)):
			issues.append(_issue("required_field_missing", "Coach config is missing required field '%s'." % field, path, "coaches", String(data.get("coachConfigId", "")), field))
	var featured_coaches: Array = data.get("featuredCoaches", []) if data.get("featuredCoaches") is Array else []
	if not (data.get("featuredCoaches") is Array):
		issues.append(_issue("featured_coaches_invalid_type", "Coach config featuredCoaches must be an array.", path, "coaches", String(data.get("coachConfigId", "")), "featuredCoaches"))
	var coach_ids: Dictionary = {}
	for index in range(featured_coaches.size()):
		var coach_value: Variant = featured_coaches[index]
		if not (coach_value is Dictionary):
			issues.append(_issue("featured_coach_invalid_type", "featuredCoaches entries must be dictionaries.", path, "coaches", String(data.get("coachConfigId", "")), "featuredCoaches[%d]" % index))
			continue
		var coach: Dictionary = coach_value
		for field in ["coachId", "coachName"]:
			if _is_missing_value(coach.get(field, null)):
				issues.append(_issue("required_field_missing", "Featured coach is missing required field '%s'." % field, path, "coaches", String(data.get("coachConfigId", "")), "featuredCoaches[%d].%s" % [index, field]))
		var coach_id: String = String(coach.get("coachId", ""))
		if not coach_id.is_empty():
			if coach_ids.has(coach_id):
				issues.append(_issue("duplicate_id", "Duplicate featured coach id '%s'." % coach_id, path, "coaches", coach_id, "featuredCoaches"))
			else:
				coach_ids[coach_id] = true
	issues.append_array(_validate_media_reference(package_dir, path, "warmupVideo", data.get("warmupVideo", null), "coaches", String(data.get("coachConfigId", ""))))
	issues.append_array(_validate_media_reference(package_dir, path, "cooldownVideo", data.get("cooldownVideo", null), "coaches", String(data.get("coachConfigId", ""))))
	var overlay_audio: Array = data.get("overlayAudio", []) if data.get("overlayAudio") is Array else []
	if not (data.get("overlayAudio") is Array):
		issues.append(_issue("overlay_audio_invalid_type", "Coach config overlayAudio must be an array.", path, "coaches", String(data.get("coachConfigId", "")), "overlayAudio"))
	var overlay_ids: Dictionary = {}
	for index in range(overlay_audio.size()):
		var overlay_value: Variant = overlay_audio[index]
		if not (overlay_value is Dictionary):
			issues.append(_issue("overlay_audio_entry_invalid_type", "overlayAudio entries must be dictionaries.", path, "coaches", String(data.get("coachConfigId", "")), "overlayAudio[%d]" % index))
			continue
		var overlay: Dictionary = overlay_value
		for field in ["overlayId", "coachId", "mediaId", "path"]:
			if _is_missing_value(overlay.get(field, null)):
				issues.append(_issue("required_field_missing", "Coach overlay is missing required field '%s'." % field, path, "coaches", String(data.get("coachConfigId", "")), "overlayAudio[%d].%s" % [index, field]))
		var overlay_id: String = String(overlay.get("overlayId", ""))
		if not overlay_id.is_empty():
			if overlay_ids.has(overlay_id):
				issues.append(_issue("duplicate_id", "Duplicate coach overlay id '%s'." % overlay_id, path, "coaches", overlay_id, "overlayAudio"))
			else:
				overlay_ids[overlay_id] = true
		var overlay_coach_id: String = String(overlay.get("coachId", ""))
		if not overlay_coach_id.is_empty() and not coach_ids.has(overlay_coach_id):
			issues.append(_issue("missing_coach_ref", "Coach overlay references coachId that is not present in featuredCoaches.", path, "coaches", overlay_id, "overlayAudio[%d].coachId" % index, {"coachId": overlay_coach_id}))
		var media_path: String = String(overlay.get("path", ""))
		if not media_path.is_empty() and not _package_file_exists(package_dir, media_path):
			issues.append(_issue("missing_file", "Coach overlay path does not resolve inside the package.", path, "coaches", overlay_id, "overlayAudio[%d].path" % index, {"pathValue": media_path}))
	return _report("coaches", package_dir, issues, {"fileCount": records.size(), "overlayCount": overlay_audio.size()}, {"files": _record_paths(records)}, {})

func _validate_environments(context: Dictionary) -> Dictionary:
	return _validate_record_family(context, "environments")

func _validate_assets(context: Dictionary) -> Dictionary:
	return _validate_record_family(context, "assets")

func _validate_sql(context: Dictionary) -> Dictionary:
	var package_dir: String = String(context.get("packageDir", ""))
	var issues: Array = []
	var sql_files: Array = context.get("sql", [])
	if sql_files.is_empty():
		issues.append(_issue("sql_schema_missing", "Package must include at least one sql/*.schema.sql file.", "sql/", "sql"))
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
				issues.append_array(_chart_validator.validate_chart_record(data, path))
			"sets":
				issues.append_array(_validate_set_record(path, data))
			"environments":
				issues.append_array(_validate_environment_record(package_dir, path, data))
			"assets":
				issues.append_array(_validate_asset_record(package_dir, path, data))
	return _report(family, package_dir, issues, {"fileCount": records.size()}, {"files": _record_paths(records)}, {})

func _validate_song_record(package_dir: String, path: String, song: Dictionary) -> Array:
	var issues: Array = []
	var song_id: String = String(song.get("songId", ""))
	if not (song.get("audio") is Dictionary):
		issues.append(_issue("song_audio_invalid_type", "Song audio must be a dictionary.", path, "songs", song_id, "audio"))
	else:
		var audio: Dictionary = song.get("audio", {})
		var file_path: String = String(audio.get("filePath", ""))
		if file_path.is_empty():
			issues.append(_issue("song_audio_file_missing", "Song audio.filePath is required.", path, "songs", song_id, "audio.filePath"))
		elif not _package_file_exists(package_dir, file_path):
			issues.append(_issue("missing_file", "Song audio.filePath does not resolve inside the package.", path, "songs", song_id, "audio.filePath", {"pathValue": file_path}))
	issues.append_array(_validate_song_timing(path, song))
	return issues

func _validate_set_record(path: String, set_data: Dictionary) -> Array:
	var issues: Array = []
	var set_id: String = String(set_data.get("setId", ""))
	if set_data.has("assetSelections"):
		if not (set_data.get("assetSelections") is Dictionary):
			issues.append(_issue("asset_selections_invalid_type", "Set assetSelections must be a dictionary when present.", path, "sets", set_id, "assetSelections"))
		else:
			var asset_selections: Dictionary = set_data.get("assetSelections", {})
			for key in asset_selections.keys():
				var asset_type: String = String(key)
				var asset_id: String = String(asset_selections.get(key, ""))
				if not VALID_ASSET_SELECTION_TYPES.has(asset_type):
					issues.append(_issue("invalid_asset_selection_type", "Set assetSelections key '%s' is not allowed." % asset_type, path, "sets", set_id, "assetSelections.%s" % asset_type))
				if asset_id.is_empty():
					issues.append(_issue("asset_selection_missing_id", "Set assetSelections.%s must reference a non-empty asset id." % asset_type, path, "sets", set_id, "assetSelections.%s" % asset_type))
	return issues

func _validate_environment_record(package_dir: String, path: String, environment: Dictionary) -> Array:
	var issues: Array = []
	var environment_id: String = String(environment.get("environmentId", ""))
	var scene_path: String = String(environment.get("scenePath", ""))
	if not scene_path.is_empty() and not _package_file_exists(package_dir, scene_path):
		issues.append(_issue("missing_file", "Environment scenePath does not resolve inside the package.", path, "environments", environment_id, "scenePath", {"pathValue": scene_path}))
	return issues

func _validate_asset_record(package_dir: String, path: String, asset: Dictionary) -> Array:
	var issues: Array = []
	var asset_id: String = String(asset.get("assetId", ""))
	var asset_type: String = String(asset.get("assetType", ""))
	if not asset_type.is_empty() and not VALID_ASSET_TYPES.has(asset_type):
		issues.append(_issue("invalid_asset_type", "Asset assetType must be one of gloves/targets/obstacles/trails.", path, "assets", asset_id, "assetType"))
	var resource_path: String = String(asset.get("resourcePath", ""))
	if not resource_path.is_empty() and not _package_file_exists(package_dir, resource_path):
		issues.append(_issue("missing_file", "Asset resourcePath does not resolve inside the package.", path, "assets", asset_id, "resourcePath", {"pathValue": resource_path}))
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
	var issues: Array = []
	var workout: Dictionary = context.get("workout", {}).get("data", {}) if bool(context.get("workout", {}).get("ok", false)) else {}
	var songs_by_id: Dictionary = _index_records(context.get("songs", []), "songId")
	var charts_by_id: Dictionary = _index_records(context.get("charts", []), "chartId")
	var sets_by_id: Dictionary = _index_records(context.get("sets", []), "setId")
	var environments_by_id: Dictionary = _index_records(context.get("environments", []), "environmentId")
	var assets_by_id: Dictionary = _index_records(context.get("assets", []), "assetId")
	var coach_config: Dictionary = _coach_config_record(context)
	var coach_data: Dictionary = coach_config.get("data", {}) if bool(coach_config.get("ok", false)) else {}
	var coach_enabled: bool = bool(coach_data.get("enabled", false)) if not coach_data.is_empty() else false
	var overlay_ids: Dictionary = {}
	if coach_enabled:
		for overlay_value in coach_data.get("overlayAudio", []):
			if overlay_value is Dictionary:
				overlay_ids[String(overlay_value.get("overlayId", ""))] = true
	if not workout.is_empty():
		if not coach_data.is_empty() and String(workout.get("coachConfigId", "")) != String(coach_data.get("coachConfigId", "")):
			issues.append(_issue("missing_coach_config_ref", "workout.yaml coachConfigId does not match coaches/coach-config.yaml.", "workout.yaml", "package", String(workout.get("workoutId", "")), "coachConfigId", {"coachConfigId": workout.get("coachConfigId", "")}))
		if workout.get("setOrder") is Array:
			var seen_set_order: Dictionary = {}
			for index in range(workout.get("setOrder", []).size()):
				var set_id: String = String(workout.get("setOrder", [])[index])
				if set_id.is_empty():
					issues.append(_issue("set_order_entry_missing", "workout.yaml setOrder entries must be non-empty set ids.", "workout.yaml", "package", String(workout.get("workoutId", "")), "setOrder[%d]" % index))
				elif seen_set_order.has(set_id):
					issues.append(_issue("duplicate_set_order_id", "workout.yaml setOrder contains duplicate set id '%s'." % set_id, "workout.yaml", "package", String(workout.get("workoutId", "")), "setOrder[%d]" % index))
				else:
					seen_set_order[set_id] = true
				if not sets_by_id.has(set_id):
					issues.append(_issue("missing_set_ref", "workout.yaml setOrder references a setId that is not present in the package.", "workout.yaml", "package", String(workout.get("workoutId", "")), "setOrder[%d]" % index, {"setId": set_id}))
	for set_record in context.get("sets", []):
		if not bool(set_record.get("ok", false)):
			continue
		var path: String = String(set_record.get("path", ""))
		var set_data: Dictionary = set_record.get("data", {})
		var set_id: String = String(set_data.get("setId", ""))
		var song_id: String = String(set_data.get("songId", ""))
		var chart_id: String = String(set_data.get("chartId", ""))
		var environment_id: String = String(set_data.get("environmentId", ""))
		var coaching_overlay_id: String = String(set_data.get("coachingOverlayId", ""))
		if not song_id.is_empty() and not songs_by_id.has(song_id):
			issues.append(_issue("missing_song_ref", "Set references a songId that is not present in the package.", path, "package", set_id, "songId", {"songId": song_id}))
		if not chart_id.is_empty() and not charts_by_id.has(chart_id):
			issues.append(_issue("missing_chart_ref", "Set references a chartId that is not present in the package.", path, "package", set_id, "chartId", {"chartId": chart_id}))
		if not environment_id.is_empty() and not environments_by_id.has(environment_id):
			issues.append(_issue("missing_environment_ref", "Set references an environmentId that is not present in the package.", path, "package", set_id, "environmentId", {"environmentId": environment_id}))
		if not coaching_overlay_id.is_empty():
			if not coach_enabled:
				issues.append(_issue("unexpected_coaching_overlay_ref", "Set references coachingOverlayId while coaching is disabled or unavailable.", path, "package", set_id, "coachingOverlayId", {"coachingOverlayId": coaching_overlay_id}))
			elif not overlay_ids.has(coaching_overlay_id):
				issues.append(_issue("missing_coaching_overlay_ref", "Set references a coachingOverlayId that is not present in coaches/coach-config.yaml.", path, "package", set_id, "coachingOverlayId", {"coachingOverlayId": coaching_overlay_id}))
		if set_data.get("assetSelections") is Dictionary:
			var asset_selections: Dictionary = set_data.get("assetSelections", {})
			for key in asset_selections.keys():
				var asset_id: String = String(asset_selections.get(key, ""))
				if not asset_id.is_empty() and not assets_by_id.has(asset_id):
					issues.append(_issue("missing_asset_ref", "Set assetSelections references an assetId that is not present in the package.", path, "package", set_id, "assetSelections.%s" % String(key), {"assetId": asset_id}))
	return _report("package", package_dir, issues, {"crossCheckCount": 1}, context.get("artifacts", {}), {})

func _load_package_context(package_dir: String) -> Dictionary:
	var workout_path: String = package_dir.path_join("workout.yaml")
	var workout_record: Dictionary = {
		"path": "workout.yaml",
		"absolutePath": workout_path,
		"exists": FileAccess.file_exists(workout_path),
		"ok": false,
		"data": {},
		"error": "",
	}
	if workout_record["exists"]:
		var parsed_workout: Dictionary = _load_yaml_file(workout_path)
		workout_record["ok"] = bool(parsed_workout.get("ok", false))
		workout_record["data"] = parsed_workout.get("data", {})
		workout_record["error"] = String(parsed_workout.get("error", ""))
	var context: Dictionary = {
		"packageDir": package_dir,
		"workout": workout_record,
		"songs": _load_yaml_records(package_dir, "songs"),
		"charts": _load_yaml_records(package_dir, "charts"),
		"sets": _load_yaml_records(package_dir, "sets"),
		"coaches": _load_yaml_records(package_dir, "coaches"),
		"environments": _load_yaml_records(package_dir, "environments"),
		"assets": _load_yaml_records(package_dir, "assets"),
		"sql": _load_sql_files(package_dir),
	}
	context["artifacts"] = {
		"workout": "workout.yaml",
		"songs": _record_paths(context.get("songs", [])),
		"charts": _record_paths(context.get("charts", [])),
		"sets": _record_paths(context.get("sets", [])),
		"coaches": _record_paths(context.get("coaches", [])),
		"environments": _record_paths(context.get("environments", [])),
		"assets": _record_paths(context.get("assets", [])),
		"sql": _sql_paths(context.get("sql", [])),
	}
	return context

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

func _base_counts(context: Dictionary) -> Dictionary:
	return {
		"songCount": context.get("songs", []).size(),
		"chartCount": context.get("charts", []).size(),
		"setCount": context.get("sets", []).size(),
		"coachConfigCount": context.get("coaches", []).size(),
		"environmentCount": context.get("environments", []).size(),
		"assetCount": context.get("assets", []).size(),
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
