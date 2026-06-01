extends RefCounted

const AeroContentAuthoring = preload("../src/AeroContentAuthoring.gd")
const TestSupport = preload("test_support.gd")

static func run() -> Dictionary:
	var runtime := AeroContentAuthoring.new()
	var fixture_dir: String = TestSupport.demo_package_dir()
	var create_result: Dictionary = runtime.create_new_workout_package({
		"workoutId": "ab-workout-draft",
		"workoutName": "Draft Workout",
		"packageVersion": "1.0.0",
	})
	var draft_state: Dictionary = create_result.get("state", {})
	var create_passed := bool(create_result.get("ok", false)) and String(draft_state.get("workout", {}).get("workoutId", "")) == "ab-workout-draft"

	var load_result: Dictionary = runtime.load_workout_package_folder(fixture_dir)
	var loaded_state: Dictionary = runtime.get_current_package_state()
	var load_passed := bool(load_result.get("ok", false)) and String(loaded_state.get("workout", {}).get("workoutId", "")) == "ab-workout-neon-boxing-bootcamp"

	var validate_result: Dictionary = runtime.validate_current_package()
	var validate_codes: Array = []
	for issue in validate_result.get("issues", []):
		validate_codes.append(String(issue.get("code", "")))
	validate_codes.sort()
	var validate_passed := not bool(validate_result.get("valid", true)) and validate_codes.has("missing_fallback_environment_ref")

	var repaired_state: Dictionary = loaded_state.duplicate(true)
	if repaired_state.get("sets", []) is Array:
		for set_record in repaired_state.get("sets", []):
			var preferred_environment_id: String = String(Dictionary(set_record).get("preferredEnvironmentId", Dictionary(set_record).get("environmentId", ""))).strip_edges()
			if not preferred_environment_id.is_empty():
				Dictionary(set_record)["fallbackEnvironmentId"] = preferred_environment_id
	runtime.set_current_package_state(repaired_state)
	var repaired_validation: Dictionary = runtime.validate_current_package()
	var repaired_passed := bool(repaired_validation.get("valid", false))

	var invalid_state: Dictionary = repaired_state.duplicate(true)
	if invalid_state.get("sets", []) is Array and invalid_state.get("sets", []).size() > 0:
		Dictionary(invalid_state.get("sets", [])[0]).erase("fallbackEnvironmentId")
	runtime.set_current_package_state(invalid_state)
	var invalid_validation: Dictionary = runtime.validate_current_package()
	var invalid_codes: Array = []
	for issue in invalid_validation.get("issues", []):
		invalid_codes.append(String(issue.get("code", "")))
	invalid_codes.sort()
	var fallback_rule_passed := not bool(invalid_validation.get("valid", true)) and invalid_codes.has("missing_fallback_environment_ref")

	runtime.set_current_package_state(repaired_state)
	var save_parent: String = ProjectSettings.globalize_path("res://tmp/aero_content_authoring_workflow")
	var save_result: Dictionary = runtime.save_current_package(save_parent)
	var output_dir: String = String(save_result.get("outputDir", ""))
	var zip_path: String = String(save_result.get("zipPath", ""))
	var save_passed := bool(save_result.get("ok", false)) and DirAccess.dir_exists_absolute(output_dir) and FileAccess.file_exists(zip_path)

	runtime.reset_authoring_state()
	var reset_state: Dictionary = runtime.get_current_package_state()
	var reset_passed := String(reset_state.get("workout", {}).get("workoutId", "")) == ""

	var passed := create_passed and load_passed and validate_passed and repaired_passed and fallback_rule_passed and save_passed and reset_passed
	return {
		"name": "test_aero_content_authoring_workflow",
		"passed": passed,
		"details": {
			"createResult": create_result,
			"loadResult": load_result,
			"validateResult": validate_result,
			"invalidValidation": invalid_validation,
			"repairedValidation": repaired_validation,
			"saveResult": save_result,
			"resetState": reset_state,
		},
	}
