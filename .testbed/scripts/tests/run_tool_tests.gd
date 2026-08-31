extends SceneTree

func _initialize() -> void:
	var script_dir: String = get_script().resource_path.get_base_dir()
	var test_scripts: Array = [
		load(script_dir.path_join("test_build_content_package_service.gd")),
		load(script_dir.path_join("test_chart_authoring_service.gd")),
		load(script_dir.path_join("test_song_package_authoring_service.gd")),
		load(script_dir.path_join("test_audio_metadata_import_service.gd")),
		load(script_dir.path_join("test_validate_song_timing_contract.gd")),
		load(script_dir.path_join("test_validate_package_failure_modes.gd")),
		load(script_dir.path_join("test_editor_uses_shared_services.gd")),
		load(script_dir.path_join("test_aero_content_authoring_workflow.gd")),
		load(script_dir.path_join("test_blank_new_package_seed_save_reload.gd")),
		load(script_dir.path_join("test_task6_set_authoring_runtime.gd")),
		load(script_dir.path_join("test_boxing_prototype_golden.gd")),
		load(script_dir.path_join("test_flow_orientation.gd")),
		load(script_dir.path_join("test_beatsaver_stage_conversion_service.gd")),
		load(script_dir.path_join("test_beatsaver_stage_cover_image_import_service.gd")),
		load(script_dir.path_join("test_beatsaver_stage_conversion_service_v4.gd")),
		load(script_dir.path_join("test_beatsaver_stage_conversion_service_v4_info_sidecars.gd")),
		load(script_dir.path_join("test_beatsaver_stage_legacy_metadata_normalization.gd")),
		load(script_dir.path_join("test_beatsaver_stage_conversion_service_legacy_v2_synthetic.gd")),
		load(script_dir.path_join("test_beatsaver_stage_conversion_service_real_world_legacy_v2.gd")),
		load(script_dir.path_join("test_beatsaver_stage_conversion_service_legacy_v26_sliders.gd")),
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
