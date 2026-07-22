extends RefCounted

const AeroContentAuthoring = preload("res://addons/aerobeat-tool-content-authoring/src/AeroContentAuthoring.gd")
const TestSupport = preload("test_support.gd")

static func run() -> Dictionary:
	var runtime := AeroContentAuthoring.new()
	var fixture_dir: String = TestSupport.demo_package_dir()
	var create_result: Dictionary = runtime.create_new_song_package({
		"songId": "ab-song-draft",
		"songName": "Draft Song",
		"packageVersion": "1.0.0",
	})
	var draft_state: Dictionary = create_result.get("state", {})
	var draft_sets: Array = Array(draft_state.get("sets", []))
	var draft_songs: Array = Array(draft_state.get("songs", []))
	var draft_charts: Array = Array(draft_state.get("charts", []))
	var draft_environments: Array = Array(draft_state.get("environments", []))
	var draft_song_package: Dictionary = Dictionary(draft_state.get("songPackage", {}))
	var create_passed := bool(create_result.get("ok", false)) \
		and String(draft_song_package.get("songId", "")) == "ab-song-draft" \
		and String(draft_song_package.get("songName", "")) == "Draft Song" \
		and draft_sets.size() == 1 \
		and draft_songs.size() == 1 \
		and draft_charts.size() == 1 \
		and draft_environments.is_empty()

	var load_result: Dictionary = runtime.load_song_package_folder(fixture_dir)
	var loaded_state: Dictionary = runtime.get_current_package_state()
	var load_passed := bool(load_result.get("ok", false)) and String(loaded_state.get("songPackage", {}).get("songId", "")) == "ab-song-splat-demo"

	var validate_result: Dictionary = runtime.validate_current_package()
	var validate_passed := bool(validate_result.get("valid", false))

	var repaired_state: Dictionary = loaded_state.duplicate(true)
	var repaired_validation: Dictionary = validate_result
	var repaired_passed := bool(repaired_validation.get("valid", false))

	var invalid_fixture_dir: String = TestSupport.tmp_dir("aero_content_authoring_workflow_invalid_fixture")
	TestSupport.ensure_clean_dir(invalid_fixture_dir)
	TestSupport.copy_tree(fixture_dir, invalid_fixture_dir)
	var invalid_root_path: String = invalid_fixture_dir.path_join("song.package.yaml")
	TestSupport.write_text(invalid_root_path, TestSupport.read_text(invalid_root_path) + "\nrecordVersion: 1\n")
	var invalid_validation: Dictionary = runtime.get_validate_package_service().validate_path(invalid_fixture_dir, "package")
	var invalid_codes: Array = []
	for issue in invalid_validation.get("issues", []):
		invalid_codes.append(String(issue.get("code", "")))
	invalid_codes.sort()
	var legacy_field_rule_passed := not bool(invalid_validation.get("valid", true)) and invalid_codes.has("song_package_forbidden_field")
	var save_parent: String = TestSupport.tmp_dir("aero_content_authoring_workflow")
	var save_result: Dictionary = runtime.save_current_package(save_parent)
	var output_dir: String = String(save_result.get("outputDir", ""))
	var zip_path: String = String(save_result.get("zipPath", ""))
	var save_passed := bool(save_result.get("ok", false)) and DirAccess.dir_exists_absolute(output_dir) and FileAccess.file_exists(zip_path)

	runtime.reset_authoring_state()
	var reset_state: Dictionary = runtime.get_current_package_state()
	var reset_validation: Dictionary = runtime.validate_current_package()
	var reset_passed := not String(reset_state.get("songPackage", {}).get("songId", "")).is_empty() and bool(reset_validation.get("valid", false))

	var passed := create_passed and load_passed and validate_passed and repaired_passed and legacy_field_rule_passed and save_passed and reset_passed
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
			"resetValidation": reset_validation,
		},
	}
