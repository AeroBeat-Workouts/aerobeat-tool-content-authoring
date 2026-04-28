extends SceneTree

func _initialize() -> void:
	var script_dir: String = get_script().resource_path.get_base_dir()
	var test_scripts: Array = [
		load(script_dir.path_join("test_validate_command.gd")),
		load(script_dir.path_join("test_build_content_package_service.gd")),
		load(script_dir.path_join("test_chart_authoring_service.gd")),
		load(script_dir.path_join("test_author_command.gd")),
		load(script_dir.path_join("test_audio_metadata_import_service.gd")),
		load(script_dir.path_join("test_validate_song_timing_contract.gd")),
		load(script_dir.path_join("test_editor_uses_shared_services.gd")),
	]
	var results: Array = []
	var has_failures := false
	for test_script in test_scripts:
		var test_result: Dictionary = test_script.run()
		results.append(test_result)
		if not bool(test_result.get("passed", false)):
			has_failures = true
	print(JSON.stringify({
		"passed": not has_failures,
		"results": results,
	}, "  "))
	quit(1 if has_failures else 0)
