class_name ValidateChartService
extends RefCounted

const VALID_FEATURES := ["boxing", "dance", "step", "flow"]
const VALID_DIFFICULTIES := ["easy", "medium", "hard", "pro"]

func validate_chart_record(chart_data: Dictionary, path: String = "") -> Array:
	var issues: Array = []
	for field in ["schemaId", "schemaVersion", "recordVersion", "chartId", "chartName", "feature", "difficulty", "beats"]:
		if _is_missing_value(chart_data.get(field, null)):
			issues.append(_issue("required_field_missing", "%s is missing required field '%s'." % [path if not path.is_empty() else "chart", field], path, {"field": field}))
	var feature: String = String(chart_data.get("feature", ""))
	if not feature.is_empty() and not VALID_FEATURES.has(feature):
		issues.append(_issue("invalid_feature", "Chart feature must be one of the canonical content features.", path, {"feature": feature}))
	var difficulty: String = String(chart_data.get("difficulty", ""))
	if not difficulty.is_empty() and not VALID_DIFFICULTIES.has(difficulty):
		issues.append(_issue("invalid_difficulty", "Chart difficulty must be one of easy/medium/hard/pro.", path, {"difficulty": difficulty}))
	if chart_data.has("beats") and not (chart_data.get("beats") is Array):
		issues.append(_issue("invalid_beats_type", "Chart beats must be an array.", path, {"field": "beats"}))
	return issues

func _issue(code: String, message: String, path: String, reference: Dictionary = {}) -> Dictionary:
	return {
		"code": code,
		"severity": "error",
		"message": message,
		"path": path,
		"subject": "charts",
		"reference": reference,
	}

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
