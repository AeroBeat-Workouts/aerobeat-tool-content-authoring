class_name ValidateChartService
extends RefCounted

const VALID_FEATURES := ["boxing"]
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
		issues.append(_issue("invalid_feature", "Chart feature must be 'boxing'.", path, {"feature": feature}))
	var difficulty: String = _normalize_difficulty_label(String(chart_data.get("difficulty", "")).strip_edges())
	if difficulty.is_empty() or not VALID_DIFFICULTIES.has(difficulty):
		issues.append(_issue("invalid_difficulty", "Chart difficulty must be one of Easy/Normal/Hard/Expert/ExpertPlus.", path, {"difficulty": String(chart_data.get("difficulty", "")).strip_edges()}))
	var beats_value: Variant = chart_data.get("beats", chart_data.get("events", []))
	if not (beats_value is Array) or Array(beats_value).is_empty():
		issues.append(_issue("beats_missing", "Chart must include a non-empty beats/events array.", path, {}))
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
