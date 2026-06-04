class_name WorkoutPackageValidationService
extends RefCounted

const ValidatePackageService = preload("validate_package_service.gd")
const WorkoutPackageYamlCodec = preload("../workflow/workout_package_yaml_codec.gd")

const CORE_VALIDATOR_PATHS := [
	"res://addons/aerobeat-content-core/validators/content_package_validator.gd",
	"res://../../aerobeat-content-core/validators/content_package_validator.gd",
]

var _local_validate_package_service: ValidatePackageService = ValidatePackageService.new()
var _codec: WorkoutPackageYamlCodec = WorkoutPackageYamlCodec.new()

func validate_path(package_dir: String, subject: String = "package") -> Dictionary:
	if subject != "package":
		return _local_validate_package_service.validate_path(package_dir, subject)

	var bridge: Dictionary = _bridge_package_dir(package_dir)
	var validation_path: String = String(bridge.get("validationPath", package_dir)).simplify_path()
	var local_report: Dictionary = _local_validate_package_service.validate_path(validation_path, "package")
	var authoring_issues: Array = _preferred_fallback_environment_issues(validation_path)
	var core_report: Dictionary = _validate_with_content_core(validation_path)
	var merged_issues: Array = _merge_issue_arrays(local_report.get("issues", []), authoring_issues)
	merged_issues = _merge_issue_arrays(merged_issues, core_report.get("issues", []))
	var report: Dictionary = local_report.duplicate(true)
	report["packageDir"] = package_dir
	report["valid"] = merged_issues.is_empty()
	report["issues"] = merged_issues
	report["issueCount"] = merged_issues.size()
	report["delegatedValidator"] = String(core_report.get("validator", bridge.get("validator", "local")))
	report["validationPath"] = validation_path
	if not core_report.is_empty():
		report["coreValidation"] = core_report
	_cleanup_bridge(bridge)
	return report

func _bridge_package_dir(package_dir: String) -> Dictionary:
	var context: Dictionary = _local_validate_package_service._load_package_context(package_dir)
	var requires_bridge := false
	for record in context.get("sets", []):
		var data: Dictionary = Dictionary(record.get("data", {}))
		if data.is_empty():
			continue
		var preferred_environment_id: String = String(data.get("preferredEnvironmentId", data.get("environmentId", ""))).strip_edges()
		if not preferred_environment_id.is_empty() and String(data.get("environmentId", "")).strip_edges().is_empty():
			requires_bridge = true
			break
	if not requires_bridge:
		return {
			"validationPath": package_dir,
			"validator": "local",
		}
	var loaded: Dictionary = _codec.load_package_state(package_dir)
	if not bool(loaded.get("ok", false)):
		return {
			"validationPath": package_dir,
			"validator": "local",
		}
	var bridge_dir: String = OS.get_user_data_dir().path_join("aerobeat_tool_content_authoring/validation_bridge_%s" % Time.get_unix_time_from_system())
	var write_result: Dictionary = _codec.write_package_state(Dictionary(loaded.get("state", {})), bridge_dir)
	if not bool(write_result.get("ok", false)):
		_cleanup_path(bridge_dir)
		return {
			"validationPath": package_dir,
			"validator": "local",
		}
	return {
		"validationPath": bridge_dir,
		"bridgeDir": bridge_dir,
		"validator": "local+bridge",
	}

func _preferred_fallback_environment_issues(package_dir: String) -> Array:
	var issues: Array = []
	var context: Dictionary = _local_validate_package_service._load_package_context(package_dir)
	for record in context.get("sets", []):
		var path: String = String(record.get("path", "sets/")).strip_edges()
		var data: Dictionary = Dictionary(record.get("data", {}))
		if data.is_empty():
			continue
		var set_id: String = String(data.get("setId", "")).strip_edges()
		var preferred_environment_id: String = String(data.get("preferredEnvironmentId", data.get("environmentId", ""))).strip_edges()
		var fallback_environment_id: String = String(data.get("fallbackEnvironmentId", "")).strip_edges()
		if preferred_environment_id.is_empty():
			issues.append(_issue("missing_preferred_environment_ref", "Set must declare preferredEnvironmentId.", path, set_id, "preferredEnvironmentId"))
		if fallback_environment_id.is_empty():
			issues.append(_issue("missing_fallback_environment_ref", "Set must declare fallbackEnvironmentId.", path, set_id, "fallbackEnvironmentId"))
	return issues

func _validate_with_content_core(package_dir: String) -> Dictionary:
	var script: Variant = _load_core_validator_script()
	if script == null:
		return {}
	var validator = script.new()
	var result = validator.validate_fixture_package(package_dir)
	return _normalize_core_result(result)

func _load_core_validator_script():
	# aerobeat-content-core's validator currently assumes it is the project root.
	# Prefer it only when that layout is actually available; otherwise stay on the
	# local validator bridge without trying to parse an unsupported addon path.
	if not FileAccess.file_exists(ProjectSettings.globalize_path("res://validators/content_package_validator.gd")):
		return null
	if not FileAccess.file_exists(ProjectSettings.globalize_path("res://globals/aero_content_schema.gd")):
		return null
	for candidate_path in CORE_VALIDATOR_PATHS:
		if ResourceLoader.exists(candidate_path):
			var script: Variant = load(candidate_path)
			if script != null and script.has_method("new"):
				return script
	return null

func _normalize_core_result(result) -> Dictionary:
	var dict_result: Dictionary = {}
	if result != null and result.has_method("to_dict"):
		dict_result = result.to_dict()
	elif result is Dictionary:
		dict_result = Dictionary(result).duplicate(true)
	var issues: Array = []
	if dict_result.has("issues") and dict_result.get("issues") is Array:
		for issue in dict_result.get("issues", []):
			issues.append(_normalize_core_issue(issue))
	return {
		"validator": "aerobeat-content-core",
		"valid": issues.is_empty(),
		"issueCount": issues.size(),
		"issues": issues,
		"raw": dict_result,
	}

func _normalize_core_issue(issue: Variant) -> Dictionary:
	var data: Dictionary = Dictionary(issue)
	return {
		"code": String(data.get("code", "content_core_issue")),
		"message": String(data.get("message", "Content contract issue.")),
		"path": String(data.get("path", "")),
		"subject": "package",
		"recordId": String(Dictionary(data.get("reference", {})).get("id", "")),
		"field": String(Dictionary(data.get("reference", {})).get("field", "")),
		"reference": Dictionary(data.get("reference", {})).duplicate(true),
	}

func _merge_issue_arrays(left: Array, right: Array) -> Array:
	var merged: Array = []
	var seen: Dictionary = {}
	for issue in left:
		_append_issue(merged, seen, issue)
	for issue in right:
		_append_issue(merged, seen, issue)
	return merged

func _append_issue(target: Array, seen: Dictionary, issue: Variant) -> void:
	if not (issue is Dictionary):
		return
	var data: Dictionary = Dictionary(issue)
	var key: String = "%s|%s|%s|%s" % [String(data.get("code", "")), String(data.get("path", "")), String(data.get("field", "")), JSON.stringify(data.get("reference", {}))]
	if seen.has(key):
		return
		
	seen[key] = true
	target.append(data.duplicate(true))

func _issue(code: String, message: String, path: String, record_id: String, field: String) -> Dictionary:
	return {
		"code": code,
		"message": message,
		"path": path,
		"subject": "package",
		"recordId": record_id,
		"field": field,
		"reference": {
			"field": field,
			"id": record_id,
		},
	}

func _cleanup_bridge(bridge: Dictionary) -> void:
	var bridge_dir: String = String(bridge.get("bridgeDir", "")).strip_edges()
	if bridge_dir.is_empty():
		return
	_cleanup_path(bridge_dir)

func _cleanup_path(path: String) -> void:
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
			_cleanup_path(child_path)
			DirAccess.remove_absolute(child_path)
		else:
			DirAccess.remove_absolute(child_path)
	dir.list_dir_end()
	DirAccess.remove_absolute(path)
