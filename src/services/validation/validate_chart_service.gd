class_name ValidateChartService
extends RefCounted

const VALID_FEATURES := ["boxing", "flow"]
const VALID_DIFFICULTIES := ["Easy", "Normal", "Hard", "Expert", "ExpertPlus"]
const LEGACY_DIFFICULTY_MAP := {
	"easy": "Easy",
	"medium": "Normal",
	"normal": "Normal",
	"hard": "Hard",
	"pro": "Expert",
	"expert": "Expert",
	"expertplus": "ExpertPlus",
	"expert_plus": "ExpertPlus",
}

func validate_chart_record(chart_data: Dictionary, path: String = "") -> Dictionary:
	return validate_record(chart_data, path)

func validate_record(chart_data: Dictionary, path: String = "") -> Dictionary:
	var issues: Array = []
	var feature: String = String(chart_data.get("feature", "")).strip_edges()
	if feature.is_empty() or not VALID_FEATURES.has(feature):
		issues.append(_issue("invalid_feature", "Chart feature must be 'boxing' or 'flow'.", path, {"feature": feature}))
	var difficulty: String = _normalize_difficulty_label(String(chart_data.get("difficulty", "")).strip_edges())
	if difficulty.is_empty() or not VALID_DIFFICULTIES.has(difficulty):
		issues.append(_issue("invalid_difficulty", "Chart difficulty must be one of Easy/Normal/Hard/Expert/ExpertPlus.", path, {"difficulty": String(chart_data.get("difficulty", "")).strip_edges()}))
	var beats_value: Variant = chart_data.get("beats", chart_data.get("events", []))
	if not (beats_value is Array) or Array(beats_value).is_empty():
		issues.append(_issue("beats_missing", "Chart must include a non-empty beats/events array.", path, {}))
	else:
		for index in range(Array(beats_value).size()):
			var beat: Variant = Array(beats_value)[index]
			if beat is Dictionary and feature == "boxing":
				issues.append_array(_validate_boxing_beat(Dictionary(beat), index, path))
			elif beat is Dictionary and feature == "flow":
				issues.append_array(_validate_flow_beat(Dictionary(beat), index, path))
	return {
		"ok": issues.is_empty(),
		"valid": issues.is_empty(),
		"issues": issues,
		"issueCount": issues.size(),
	}

func _normalize_difficulty_label(value: String) -> String:
	if value.is_empty():
		return value
	if LEGACY_DIFFICULTY_MAP.has(value):
		return String(LEGACY_DIFFICULTY_MAP[value])
	return value

func _issue(code: String, message: String, path: String, reference: Dictionary) -> Dictionary:
	return {
		"severity": "error",
		"code": code,
		"message": message,
		"path": path,
		"reference": reference,
	}

func _validate_boxing_beat(beat: Dictionary, index: int, path: String) -> Array:
	var issues: Array = []
	var beat_type := String(beat.get("type", "")).strip_edges()
	var allowed := ["straight_left", "straight_right", "hook_left", "hook_right", "uppercut_left", "uppercut_right", "guard", "squat", "weave_left", "weave_right"]
	if beat_type.is_empty() or not allowed.has(beat_type):
		issues.append(_issue("invalid_boxing_type", "Boxing beat type must be a canonical AeroBeat Boxing gesture.", path, {"index": index, "type": beat_type}))
	if beat.has("portal"):
		issues.append(_issue("invalid_boxing_portal", "Boxing beats may not use stale portal fields.", path, {"index": index}))
	if beat.has("end"):
		issues.append(_issue("invalid_boxing_end", "Only Flow burst beats may declare an end field.", path, {"index": index}))
	return issues

func _validate_flow_beat(beat: Dictionary, index: int, path: String) -> Array:
	var issues: Array = []
	if beat.has("portal"):
		issues.append(_issue("invalid_flow_portal", "Flow beat portal fields are stale. The current Flow direction is direct calibrated 4x3 gameplay rather than portal-based authored placement.", path, {"index": index}))
	var type := String(beat.get("type", "")).strip_edges()
	var allowed_types := ["note", "burst", "bomb", "obstacle", "arc"]
	if not allowed_types.has(type):
		issues.append(_issue("invalid_flow_type", "Flow beat type '%s' is not part of the canonical authored chart contract. Allowed types: note, burst, bomb, obstacle, arc." % type, path, {"index": index, "type": type}))
		return issues
	match type:
		"note":
			issues.append_array(_validate_flow_note(beat, index, path))
		"burst":
			issues.append_array(_validate_flow_burst(beat, index, path))
		"bomb":
			issues.append_array(_validate_flow_bomb(beat, index, path))
		"obstacle":
			issues.append_array(_validate_flow_obstacle(beat, index, path))
		"arc":
			issues.append_array(_validate_flow_arc(beat, index, path))
	return issues

func _validate_flow_note(beat: Dictionary, index: int, path: String) -> Array:
	var issues: Array = []
	issues.append_array(_require_flow_hand(beat, index, path, "flow_note", "note"))
	issues.append_array(_require_flow_int_field(beat, "placement", index, path, "flow_note", "note", "placement cell"))
	if not beat.has("requiresDirection"):
		issues.append(_issue("flow_note_missing_requires_direction", "Flow note beats must declare requiresDirection.", path, {"index": index}))
	elif not (beat.get("requiresDirection") is bool):
		issues.append(_issue("flow_note_invalid_requires_direction", "Flow note requiresDirection must be a boolean.", path, {"index": index}))
	else:
		var requires_direction := bool(beat.get("requiresDirection"))
		if requires_direction and not beat.has("direction"):
			issues.append(_issue("flow_note_missing_direction", "Flow note beats with requiresDirection=true must declare a direction.", path, {"index": index}))
		elif requires_direction and not (beat.get("direction") is int):
			issues.append(_issue("flow_note_invalid_direction", "Flow note direction must be an integer value when required.", path, {"index": index}))
		elif not requires_direction and beat.has("direction"):
			issues.append(_issue("flow_note_unexpected_direction", "Flow note beats with requiresDirection=false must not declare a direction.", path, {"index": index}))
	if beat.has("angleOffset") and not _is_number(beat.get("angleOffset")):
		issues.append(_issue("flow_note_invalid_angle_offset", "Flow note angleOffset must be numeric when present.", path, {"index": index}))
	return issues

func _validate_flow_burst(beat: Dictionary, index: int, path: String) -> Array:
	var issues: Array = []
	if not beat.has("end"):
		issues.append(_issue("flow_burst_missing_end", "Flow burst beats must declare an end beat value.", path, {"index": index}))
	issues.append_array(_require_flow_hand(beat, index, path, "flow_burst", "burst"))
	issues.append_array(_require_flow_int_field(beat, "placement", index, path, "flow_burst", "burst", "head placement cell"))
	issues.append_array(_require_flow_int_field(beat, "direction", index, path, "flow_burst", "burst", "head direction value"))
	issues.append_array(_require_flow_int_field(beat, "tailPlacement", index, path, "flow_burst", "burst", "tail placement cell"))
	if not beat.has("checkpointCount"):
		issues.append(_issue("flow_burst_missing_checkpoint_count", "Flow burst beats must declare a checkpointCount.", path, {"index": index}))
	elif not (beat.get("checkpointCount") is int) or int(beat.get("checkpointCount")) < 1:
		issues.append(_issue("flow_burst_invalid_checkpoint_count", "Flow burst checkpointCount must be a positive integer.", path, {"index": index}))
	if beat.has("spacingBias") and not _is_number(beat.get("spacingBias")):
		issues.append(_issue("flow_burst_invalid_spacing_bias", "Flow burst spacingBias must be numeric when present.", path, {"index": index}))
	return issues

func _validate_flow_bomb(beat: Dictionary, index: int, path: String) -> Array:
	var issues: Array = []
	issues.append_array(_require_flow_int_field(beat, "placement", index, path, "flow_bomb", "bomb", "placement cell"))
	if beat.has("end"):
		issues.append(_issue("flow_bomb_unexpected_end", "Flow bomb beats must not declare an end beat value.", path, {"index": index}))
	return issues

func _validate_flow_obstacle(beat: Dictionary, index: int, path: String) -> Array:
	var issues: Array = []
	if not beat.has("end"):
		issues.append(_issue("flow_obstacle_missing_end", "Flow obstacle beats must declare an end beat value.", path, {"index": index}))
	if not beat.has("cells"):
		issues.append(_issue("flow_obstacle_missing_cells", "Flow obstacle beats must declare occupied cells.", path, {"index": index}))
	elif not (beat.get("cells") is Array):
		issues.append(_issue("flow_obstacle_invalid_cells", "Flow obstacle cells must be an array of integer cell values.", path, {"index": index}))
	else:
		var cells: Array = beat.get("cells", [])
		if cells.is_empty():
			issues.append(_issue("flow_obstacle_empty_cells", "Flow obstacle cells must not be empty.", path, {"index": index}))
		else:
			for cell_index in range(cells.size()):
				if not (cells[cell_index] is int):
					issues.append(_issue("flow_obstacle_invalid_cell", "Flow obstacle cells must contain only integer cell values.", path, {"index": index, "cellIndex": cell_index}))
	return issues

func _validate_flow_arc(beat: Dictionary, index: int, path: String) -> Array:
	var issues: Array = []
	if not beat.has("end"):
		issues.append(_issue("flow_arc_missing_end", "Flow arc beats must declare an end beat value.", path, {"index": index}))
	issues.append_array(_require_flow_hand(beat, index, path, "flow_arc", "arc"))
	issues.append_array(_require_flow_int_field(beat, "startPlacement", index, path, "flow_arc", "arc", "start placement cell"))
	issues.append_array(_require_flow_int_field(beat, "endPlacement", index, path, "flow_arc", "arc", "end placement cell"))
	issues.append_array(_require_flow_int_field(beat, "startDirection", index, path, "flow_arc", "arc", "start direction value"))
	issues.append_array(_require_flow_int_field(beat, "endDirection", index, path, "flow_arc", "arc", "end direction value"))
	issues.append_array(_require_flow_numeric_field(beat, "headCurveMultiplier", index, path, "flow_arc", "arc", "headCurveMultiplier"))
	issues.append_array(_require_flow_numeric_field(beat, "tailCurveMultiplier", index, path, "flow_arc", "arc", "tailCurveMultiplier"))
	issues.append_array(_require_flow_int_field(beat, "midAnchorMode", index, path, "flow_arc", "arc", "midAnchorMode"))
	if beat.has("startNoteRef") and not _is_non_empty_string(beat.get("startNoteRef")):
		issues.append(_issue("flow_arc_invalid_start_note_ref", "Flow arc startNoteRef must be a non-empty string when present.", path, {"index": index}))
	if beat.has("endNoteRef") and not _is_non_empty_string(beat.get("endNoteRef")):
		issues.append(_issue("flow_arc_invalid_end_note_ref", "Flow arc endNoteRef must be a non-empty string when present.", path, {"index": index}))
	return issues

func _require_flow_hand(beat: Dictionary, index: int, path: String, prefix: String, label: String) -> Array:
	var issues: Array = []
	var hand := String(beat.get("hand", "")).strip_edges()
	if hand.is_empty():
		issues.append(_issue("%s_missing_hand" % prefix, "Flow %s beats must declare a hand." % label, path, {"index": index}))
	elif not ["left", "right"].has(hand):
		issues.append(_issue("%s_invalid_hand" % prefix, "Flow %s hand must be 'left' or 'right'." % label, path, {"index": index, "hand": hand}))
	return issues

func _require_flow_int_field(beat: Dictionary, field_name: String, index: int, path: String, prefix: String, label: String, field_label: String) -> Array:
	var issues: Array = []
	if not beat.has(field_name):
		issues.append(_issue("%s_missing_%s" % [prefix, _snake_field_name(field_name)], "Flow %s beats must declare a %s." % [label, field_label], path, {"index": index, "field": field_name}))
	elif not (beat.get(field_name) is int):
		issues.append(_issue("%s_invalid_%s" % [prefix, _snake_field_name(field_name)], "Flow %s %s must be an integer value." % [label, field_name], path, {"index": index, "field": field_name}))
	return issues

func _require_flow_numeric_field(beat: Dictionary, field_name: String, index: int, path: String, prefix: String, label: String, field_label: String) -> Array:
	var issues: Array = []
	if not beat.has(field_name):
		issues.append(_issue("%s_missing_%s" % [prefix, _snake_field_name(field_name)], "Flow %s beats must declare %s." % [label, field_label], path, {"index": index, "field": field_name}))
	elif not _is_number(beat.get(field_name)):
		issues.append(_issue("%s_invalid_%s" % [prefix, _snake_field_name(field_name)], "Flow %s %s must be numeric." % [label, field_name], path, {"index": index, "field": field_name}))
	return issues

func _snake_field_name(field_name: String) -> String:
	var snake := ""
	for character in field_name:
		var char_text := String(character)
		if char_text == char_text.to_upper() and not snake.is_empty():
			snake += "_"
		snake += char_text.to_lower()
	return snake

func _is_non_empty_string(value: Variant) -> bool:
	return value is String and String(value).strip_edges() != ""

func _is_number(value: Variant) -> bool:
	return value is int or value is float
