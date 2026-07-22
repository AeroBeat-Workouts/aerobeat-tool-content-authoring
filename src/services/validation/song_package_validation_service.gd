class_name SongPackageValidationService
extends RefCounted

const ValidatePackageService = preload("validate_package_service.gd")
const SongPackageYamlCodec = preload("../workflow/song_package_yaml_codec.gd")

const CORE_VALIDATOR_PATHS := [
	"res://addons/aerobeat-content-core/validators/content_package_validator.gd",
	"res://../../aerobeat-content-core/validators/content_package_validator.gd",
]

var _core_validator_paths: Array = CORE_VALIDATOR_PATHS.duplicate()
var _local_validate_package_service: ValidatePackageService = ValidatePackageService.new()
var _codec: SongPackageYamlCodec = SongPackageYamlCodec.new()

func validate_path(package_dir: String, subject: String = "package") -> Dictionary:
	if subject != "package":
		return _local_validate_package_service.validate_path(package_dir, subject)

	var validation_path: String = String(package_dir).simplify_path()
	var local_report: Dictionary = _local_validate_package_service.validate_path(validation_path, "package")
	var core_report: Dictionary = _validate_with_content_core(validation_path)
	var merged_issues: Array = Array(local_report.get("issues", [])).duplicate(true)
	if not Array(core_report.get("issues", [])).is_empty():
		merged_issues = _merge_issue_arrays(merged_issues, core_report.get("issues", []))
	var report: Dictionary = local_report.duplicate(true)
	report["packageDir"] = package_dir
	report["valid"] = merged_issues.is_empty()
	report["issues"] = merged_issues
	report["issueCount"] = merged_issues.size()
	report["delegatedValidator"] = String(core_report.get("delegatedValidator", "unavailable"))
	report["validationPath"] = validation_path
	report["validationBridgeMode"] = "direct"
	report["coreValidation"] = core_report
	return report

func set_core_validator_paths(paths: Array) -> SongPackageValidationService:
	_core_validator_paths = paths.duplicate()
	return self


func _validate_with_content_core(package_dir: String) -> Dictionary:
	var script: Variant = _load_core_validator_script()
	if script == null:
		return {
			"validator": "aerobeat-content-core",
			"delegatedValidator": "unavailable",
			"valid": false,
			"issueCount": 1,
			"issues": [
				_issue(
					"content_core_package_validator_unavailable",
					"Package validation requires the shared aerobeat-content-core validator to be runtime-loadable.",
					package_dir,
					"",
					"",
					{"validator": "aerobeat-content-core"}
				)
			],
			"raw": {},
		}
	var validator = script.new()
	var result = validator.validate_fixture_package(package_dir)
	return _normalize_core_result(result)

func _load_core_validator_script():
	var required_dependency := "res://addons/aerobeat-content-core/validators/content_validation_result.gd"
	for candidate_path in _core_validator_paths:
		if not ResourceLoader.exists(required_dependency):
			continue
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
		"delegatedValidator": "aerobeat-content-core",
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

func _issue(code: String, message: String, path: String, record_id: String, field: String, reference: Dictionary = {}) -> Dictionary:
	var issue_reference: Dictionary = {
		"field": field,
		"id": record_id,
	}
	for key in reference.keys():
		issue_reference[key] = reference.get(key)
	return {
		"code": code,
		"message": message,
		"path": path,
		"subject": "package",
		"recordId": record_id,
		"field": field,
		"reference": issue_reference,
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
