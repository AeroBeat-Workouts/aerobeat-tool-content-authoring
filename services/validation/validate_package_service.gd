class_name ValidatePackageService
extends RefCounted

const ValidateChartService = preload("validate_chart_service.gd")

const REQUIRED_MANIFEST_FIELDS := ["schema", "packageId", "packageVersion"]
const REQUIRED_RECORD_FIELDS := {
	"song": ["schema", "songId", "songName", "timing"],
	"routine": ["schema", "routineId", "songId", "mode", "charts"],
	"chart": ["schema", "chartId", "routineId", "songId", "mode", "difficulty", "interactionFamily"],
	"workout": ["schema", "workoutId", "workoutName", "steps"],
}
const SONG_TIMING_REQUIRED_FIELDS := ["anchorMs", "tempoSegments", "stopSegments", "timeSignatureSegments"]

var _chart_validator: ValidateChartService = ValidateChartService.new()

func validate_path(package_dir: String) -> Dictionary:
	var manifest_path: String = package_dir.path_join("manifest.json")
	var issues: Array = []
	if not FileAccess.file_exists(manifest_path):
		issues.append(_issue("manifest_missing", "Package manifest could not be loaded.", manifest_path))
		return _report(package_dir, {}, {}, issues)

	var manifest: Dictionary = _load_json(manifest_path)
	if manifest.is_empty():
		issues.append(_issue("manifest_invalid", "Package manifest is empty or invalid JSON.", manifest_path))
		return _report(package_dir, {}, {}, issues)

	for field in REQUIRED_MANIFEST_FIELDS:
		if String(manifest.get(field, "")).is_empty():
			issues.append(_issue("manifest_missing_field", "Manifest is missing required field '%s'." % field, "manifest", {"field": field}))

	var record_sets: Dictionary = {
		"songs": _load_records(package_dir, manifest.get("songs", []), "song"),
		"routines": _load_records(package_dir, manifest.get("routines", []), "routine"),
		"charts": _load_records(package_dir, manifest.get("charts", []), "chart"),
		"workouts": _load_records(package_dir, manifest.get("workouts", []), "workout"),
	}

	issues.append_array(_validate_record_shapes(record_sets.get("songs", []), "song"))
	issues.append_array(_validate_record_shapes(record_sets.get("routines", []), "routine"))
	issues.append_array(_validate_record_shapes(record_sets.get("charts", []), "chart"))
	issues.append_array(_validate_record_shapes(record_sets.get("workouts", []), "workout"))
	issues.append_array(_validate_references(record_sets))

	return _report(package_dir, manifest, record_sets, issues)

func _validate_record_shapes(records: Array, kind: String) -> Array:
	var issues: Array = []
	var id_key: String = _id_key_for_kind(kind)
	var seen_ids: Dictionary = {}
	for record in records:
		var path: String = String(record.get("path", kind))
		var data: Dictionary = record.get("data", {})
		if data.is_empty():
			issues.append(_issue("record_invalid_json", "%s JSON could not be loaded." % kind.capitalize(), path, {"kind": kind}))
			continue
		for field in REQUIRED_RECORD_FIELDS.get(kind, []):
			if _is_missing_value(data.get(field, null)):
				issues.append(_issue("required_field_missing", "%s is missing required field '%s'." % [kind.capitalize(), field], path, {"kind": kind, "field": field}))
		var record_id: String = String(data.get(id_key, ""))
		if record_id.is_empty():
			issues.append(_issue("invalid_uid", "%s field '%s' must be present." % [kind.capitalize(), id_key], path, {"kind": kind}))
		elif seen_ids.has(record_id):
			issues.append(_issue("duplicate_id", "Duplicate %s id '%s'." % [kind, record_id], path, {"kind": kind, "id": record_id}))
		else:
			seen_ids[record_id] = true
		if kind == "song":
			issues.append_array(_validate_song_timing(path, data))
		if kind == "chart":
			issues.append_array(_chart_validator.validate_chart_record(data, path))
	return issues

func _validate_song_timing(path: String, song: Dictionary) -> Array:
	var issues: Array = []
	if not song.has("timing"):
		return issues
	var timing_value: Variant = song.get("timing")
	if not (timing_value is Dictionary):
		issues.append(_issue("song_timing_invalid_type", "Song timing must be a dictionary.", path, {"field": "timing"}))
		return issues
	var timing: Dictionary = timing_value
	if timing.has("bpm"):
		issues.append(_issue("song_timing_bpm_shortcut_forbidden", "Song timing must use tempoSegments and must not include a timing.bpm shortcut.", path, {"field": "timing.bpm"}))
	for field in SONG_TIMING_REQUIRED_FIELDS:
		if not timing.has(field):
			issues.append(_issue("song_timing_missing_field", "Song timing is missing required field '%s'." % field, path, {"field": "timing.%s" % field}))
	if timing.has("anchorMs") and not _is_integer_number(timing.get("anchorMs")):
		issues.append(_issue("song_timing_anchor_invalid_type", "Song timing anchorMs must be an integer millisecond value.", path, {"field": "timing.anchorMs"}))
	issues.append_array(_validate_tempo_segments(path, timing))
	issues.append_array(_validate_stop_segments(path, timing))
	issues.append_array(_validate_time_signature_segments(path, timing))
	return issues

func _validate_tempo_segments(path: String, timing: Dictionary) -> Array:
	var issues: Array = []
	if not timing.has("tempoSegments"):
		return issues
	var segments_value: Variant = timing.get("tempoSegments")
	if not (segments_value is Array):
		issues.append(_issue("song_tempo_segments_invalid_type", "Song timing tempoSegments must be an array.", path, {"field": "timing.tempoSegments"}))
		return issues
	for index in range(segments_value.size()):
		var segment_value: Variant = segments_value[index]
		if not (segment_value is Dictionary):
			issues.append(_issue("song_tempo_segment_invalid_type", "Song tempo segment entries must be dictionaries.", path, {"field": "timing.tempoSegments[%d]" % index, "index": index}))
			continue
		var segment: Dictionary = segment_value
		for field in ["startBeat", "bpm"]:
			if not segment.has(field):
				issues.append(_issue("song_tempo_segment_missing_field", "Song tempo segment is missing required field '%s'." % field, path, {"field": "timing.tempoSegments[%d].%s" % [index, field], "index": index}))
	return issues

func _validate_stop_segments(path: String, timing: Dictionary) -> Array:
	var issues: Array = []
	if not timing.has("stopSegments"):
		return issues
	var segments_value: Variant = timing.get("stopSegments")
	if not (segments_value is Array):
		issues.append(_issue("song_stop_segments_invalid_type", "Song timing stopSegments must be an array.", path, {"field": "timing.stopSegments"}))
		return issues
	for index in range(segments_value.size()):
		var segment_value: Variant = segments_value[index]
		if not (segment_value is Dictionary):
			issues.append(_issue("song_stop_segment_invalid_type", "Song stop segment entries must be dictionaries.", path, {"field": "timing.stopSegments[%d]" % index, "index": index}))
			continue
		var segment: Dictionary = segment_value
		for field in ["startBeat", "durationMs"]:
			if not segment.has(field):
				issues.append(_issue("song_stop_segment_missing_field", "Song stop segment is missing required field '%s'." % field, path, {"field": "timing.stopSegments[%d].%s" % [index, field], "index": index}))
	return issues

func _validate_time_signature_segments(path: String, timing: Dictionary) -> Array:
	var issues: Array = []
	if not timing.has("timeSignatureSegments"):
		return issues
	var segments_value: Variant = timing.get("timeSignatureSegments")
	if not (segments_value is Array):
		issues.append(_issue("song_time_signature_segments_invalid_type", "Song timing timeSignatureSegments must be an array.", path, {"field": "timing.timeSignatureSegments"}))
		return issues
	for index in range(segments_value.size()):
		var segment_value: Variant = segments_value[index]
		if not (segment_value is Dictionary):
			issues.append(_issue("song_time_signature_segment_invalid_type", "Song time-signature segment entries must be dictionaries.", path, {"field": "timing.timeSignatureSegments[%d]" % index, "index": index}))
			continue
		var segment: Dictionary = segment_value
		for field in ["startBeat", "numerator", "denominator"]:
			if not segment.has(field):
				issues.append(_issue("song_time_signature_segment_missing_field", "Song time-signature segment is missing required field '%s'." % field, path, {"field": "timing.timeSignatureSegments[%d].%s" % [index, field], "index": index}))
	return issues

func _validate_references(record_sets: Dictionary) -> Array:
	var issues: Array = []
	var songs_by_id: Dictionary = _index_records(record_sets.get("songs", []), "songId")
	var routines_by_id: Dictionary = _index_records(record_sets.get("routines", []), "routineId")
	var charts_by_id: Dictionary = _index_records(record_sets.get("charts", []), "chartId")

	for routine_record in record_sets.get("routines", []):
		var path: String = String(routine_record.get("path", ""))
		var routine: Dictionary = routine_record.get("data", {})
		if not songs_by_id.has(String(routine.get("songId", ""))):
			issues.append(_issue("missing_song_ref", "Routine references a songId that is not present in the package.", path, {"songId": routine.get("songId", "")}))
		for chart_id in routine.get("charts", []):
			if not charts_by_id.has(String(chart_id)):
				issues.append(_issue("missing_chart_ref", "Routine charts list references a chartId that is not present in the package.", path, {"chartId": chart_id}))

	for chart_record in record_sets.get("charts", []):
		var path: String = String(chart_record.get("path", ""))
		var chart: Dictionary = chart_record.get("data", {})
		if not routines_by_id.has(String(chart.get("routineId", ""))):
			issues.append(_issue("missing_routine_ref", "Chart references a routineId that is not present in the package.", path, {"routineId": chart.get("routineId", "")}))
		if not songs_by_id.has(String(chart.get("songId", ""))):
			issues.append(_issue("missing_song_ref", "Chart references a songId that is not present in the package.", path, {"songId": chart.get("songId", "")}))

	for workout_record in record_sets.get("workouts", []):
		var path: String = String(workout_record.get("path", ""))
		var workout: Dictionary = workout_record.get("data", {})
		for step in workout.get("steps", []):
			if not charts_by_id.has(String(step.get("chartId", ""))):
				issues.append(_issue("missing_chart_ref", "Workout step references a chartId that is not present in the package.", path, {"chartId": step.get("chartId", "")}))
	return issues

func _load_records(package_dir: String, manifest_entries: Array, kind: String) -> Array:
	var records: Array = []
	for entry in manifest_entries:
		var relative_path: String = String(entry.get("path", ""))
		var absolute_path: String = package_dir.path_join(relative_path)
		records.append({
			"kind": kind,
			"path": relative_path,
			"absolutePath": absolute_path,
			"data": _load_json(absolute_path),
		})
	return records

func _load_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var text: String = FileAccess.get_file_as_string(path)
	var parsed: Variant = JSON.parse_string(text)
	if parsed == null or not (parsed is Dictionary):
		return {}
	return parsed

func _index_records(records: Array, id_key: String) -> Dictionary:
	var index: Dictionary = {}
	for record in records:
		var data: Dictionary = record.get("data", {})
		var record_id: String = String(data.get(id_key, ""))
		if not record_id.is_empty():
			index[record_id] = record
	return index

func _id_key_for_kind(kind: String) -> String:
	match kind:
		"song":
			return "songId"
		"routine":
			return "routineId"
		"chart":
			return "chartId"
		"workout":
			return "workoutId"
		_:
			return "id"

func _report(package_dir: String, manifest: Dictionary, record_sets: Dictionary, issues: Array) -> Dictionary:
	return {
		"ok": issues.is_empty(),
		"valid": issues.is_empty(),
		"packageDir": package_dir,
		"manifest": manifest,
		"recordSets": record_sets,
		"issueCount": issues.size(),
		"issues": issues,
	}

func _issue(code: String, message: String, path: String, reference: Dictionary = {}) -> Dictionary:
	return {
		"code": code,
		"severity": "error",
		"message": message,
		"path": path,
		"reference": reference,
	}

func _is_missing_value(value: Variant) -> bool:
	if value == null:
		return true
	if value is String:
		return String(value).is_empty()
	if value is Array:
		return value.is_empty()
	return false

func _is_integer_number(value: Variant) -> bool:
	return value is int or (value is float and floor(value) == value)
