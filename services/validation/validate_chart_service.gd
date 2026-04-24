class_name ValidateChartService
extends RefCounted

const VALID_MODES := ["boxing", "dance", "step", "flow"]
const VALID_DIFFICULTIES := ["easy", "medium", "hard", "pro"]
const VALID_INTERACTION_FAMILIES := ["gesture_2d", "tracked_6dof", "hybrid"]

func validate_chart_record(chart_data: Dictionary, path: String = "") -> Array:
	var issues: Array = []
	for field in ["schema", "chartId", "routineId", "songId", "mode", "difficulty", "interactionFamily"]:
		if String(chart_data.get(field, "")).is_empty():
			issues.append(_issue("required_field_missing", "%s is missing required field '%s'." % [path if not path.is_empty() else "chart", field], path, {"field": field}))
	if not chart_data.get("mode", "") in VALID_MODES:
		issues.append(_issue("invalid_mode", "Chart mode must be one of the canonical content modes.", path, {"mode": chart_data.get("mode", "")}))
	if not chart_data.get("difficulty", "") in VALID_DIFFICULTIES:
		issues.append(_issue("invalid_difficulty", "Chart difficulty must be one of easy/medium/hard/pro.", path, {"difficulty": chart_data.get("difficulty", "")}))
	if not chart_data.get("interactionFamily", "") in VALID_INTERACTION_FAMILIES:
		issues.append(_issue("invalid_interaction_family", "Chart interactionFamily must be one of the canonical interaction families.", path, {"interactionFamily": chart_data.get("interactionFamily", "")}))
	return issues

func _issue(code: String, message: String, path: String, reference: Dictionary = {}) -> Dictionary:
	return {
		"code": code,
		"severity": "error",
		"message": message,
		"path": path,
		"reference": reference,
	}
