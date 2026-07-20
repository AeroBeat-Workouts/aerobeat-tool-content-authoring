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
	if String(beat.get("type", "")).strip_edges() != "burst":
		issues.append(_issue("invalid_flow_type", "Flow authored chart beats must currently use the frozen 'burst' object shape.", path, {"index": index, "type": String(beat.get("type", "")).strip_edges()}))
		return issues
	if not beat.has("end"):
		issues.append(_issue("flow_burst_missing_end", "Flow burst beats must declare an end beat value.", path, {"index": index}))
	if not ["left", "right"].has(String(beat.get("hand", "")).strip_edges()):
		issues.append(_issue("flow_burst_invalid_hand", "Flow burst hand must be 'left' or 'right'.", path, {"index": index, "hand": String(beat.get("hand", "")).strip_edges()}))
	for required_field in ["placement", "direction", "tailPlacement", "checkpointCount"]:
		if not beat.has(required_field):
			issues.append(_issue("flow_burst_missing_field", "Flow burst beats must declare %s." % required_field, path, {"index": index, "field": required_field}))
	if beat.has("spacingBias") and not (beat.get("spacingBias") is int or beat.get("spacingBias") is float):
		issues.append(_issue("flow_burst_invalid_spacing_bias", "Flow burst spacingBias must be numeric when present.", path, {"index": index}))
	return issues
