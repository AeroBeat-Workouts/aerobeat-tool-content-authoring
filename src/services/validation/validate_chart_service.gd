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
const CORE_FLOW_CHART_PATHS := [
	"res://addons/aerobeat-content-core/data_types/chart.gd",
	"res://../../aerobeat-content-core/data_types/chart.gd",
]

func validate_chart_record(chart_data: Dictionary, path: String = "") -> Dictionary:
	return validate_record(chart_data, path)

func validate_record(chart_data: Dictionary, path: String = "") -> Dictionary:
	var issues: Array = []
	var delegated_validator := "local"
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
		var beats: Array = Array(beats_value)
		match feature:
			"boxing":
				for index in range(beats.size()):
					var beat: Variant = beats[index]
					if beat is Dictionary:
						issues.append_array(_validate_boxing_beat(Dictionary(beat), index, path))
			"flow":
				var flow_report := _validate_flow_chart_via_content_core(chart_data, beats, path)
				delegated_validator = String(flow_report.get("delegatedValidator", "unavailable"))
				issues.append_array(Array(flow_report.get("issues", [])))
	return {
		"ok": issues.is_empty(),
		"valid": issues.is_empty(),
		"issues": issues,
		"issueCount": issues.size(),
		"delegatedValidator": delegated_validator,
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
		issues.append(_issue("invalid_boxing_end", "Only Flow burst, obstacle, and arc beats may declare an end field.", path, {"index": index}))
	return issues

func _validate_flow_chart_via_content_core(chart_data: Dictionary, beats: Array, path: String) -> Dictionary:
	var load_result: Dictionary = _load_core_flow_chart_script()
	var chart_script: Variant = load_result.get("script", null)
	if chart_script == null or not bool(load_result.get("ok", false)):
		var unavailable_reference := {"validator": "aerobeat-content-core"}
		var load_error: String = String(load_result.get("error", "")).strip_edges()
		if not load_error.is_empty():
			unavailable_reference["loadError"] = load_error
		return {
			"delegatedValidator": "unavailable",
			"issues": [
				_issue(
					"flow_validator_unavailable",
					"Flow chart validation requires the shared aerobeat-content-core Chart contract to be runtime-loadable.",
					path,
					unavailable_reference
				)
			],
		}
	var normalized_chart := chart_data.duplicate(true)
	normalized_chart["beats"] = beats.duplicate(true)
	var raw_issues: Array = Array(chart_script.call("validate_contract", normalized_chart))
	var issues: Array = []
	for issue in raw_issues:
		issues.append(_normalize_core_issue(issue, path))
	return {
		"delegatedValidator": "aerobeat-content-core",
		"issues": issues,
	}

func _load_core_flow_chart_script() -> Dictionary:
	var required_dependency := "res://addons/aerobeat-content-core/data_types/chart_envelope.gd"
	for candidate_path in CORE_FLOW_CHART_PATHS:
		if candidate_path.begins_with("res://../../") and not ResourceLoader.exists(required_dependency):
			continue
		if not ResourceLoader.exists(candidate_path):
			continue
		var script: Variant = load(candidate_path)
		if script == null:
			continue
		if script.has_method("validate_contract"):
			return {"ok": true, "script": script, "path": candidate_path}
		return {
			"ok": false,
			"script": null,
			"path": candidate_path,
			"error": "Loaded Chart contract script is missing validate_contract, usually because a dependency failed to parse or resolve.",
		}
	return {"ok": false, "script": null, "error": "No runtime-loadable aerobeat-content-core Chart contract script was found."}

func _normalize_core_issue(issue: Variant, path: String) -> Dictionary:
	var data: Dictionary = Dictionary(issue)
	var reference: Dictionary = {}
	if data.has("index"):
		reference["index"] = int(data.get("index", -1))
	if data.has("field"):
		reference["field"] = String(data.get("field", ""))
	return _issue(
		String(data.get("code", "flow_contract_issue")),
		String(data.get("message", "Flow chart contract issue.")),
		path,
		reference
	)
