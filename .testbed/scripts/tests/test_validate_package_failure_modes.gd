extends RefCounted

const ADDON_VALIDATE_PACKAGE_SERVICE_PATH := "res://addons/aerobeat-tool-content-authoring/src/services/validation/validate_package_service.gd"
const TestSupport = preload("test_support.gd")

static func run() -> Dictionary:
	var base_fixture_dir: String = TestSupport.demo_package_dir()
	var base_tmp_dir: String = TestSupport.tmp_dir("test_validate_package_failure_modes")
	TestSupport.ensure_clean_dir(base_tmp_dir)
	var scenarios: Array = [
		_duplicate_song_id_scenario(base_fixture_dir, base_tmp_dir),
		_missing_set_reference_scenario(base_fixture_dir, base_tmp_dir),
		_forbidden_song_package_legacy_fields_scenario(base_fixture_dir, base_tmp_dir),
		_forbidden_set_legacy_fields_scenario(base_fixture_dir, base_tmp_dir),
		_asset_selections_not_supported_scenario(base_fixture_dir, base_tmp_dir),
		_assets_directory_not_supported_scenario(base_fixture_dir, base_tmp_dir),
		_dance_chart_rejected_scenario(base_fixture_dir, base_tmp_dir),
		_step_chart_rejected_scenario(base_fixture_dir, base_tmp_dir),
		_forbidden_song_composition_links_scenario(base_fixture_dir, base_tmp_dir),
		_forbidden_chart_composition_links_scenario(base_fixture_dir, base_tmp_dir),
		_invalid_sql_schema_scenario(base_fixture_dir, base_tmp_dir),
		_invalid_environment_type_scenario(base_fixture_dir, base_tmp_dir),
	]
	var passed: bool = true
	for scenario in scenarios:
		if not bool(scenario.get("passed", false)):
			passed = false
	return {
		"name": "test_validate_package_failure_modes",
		"passed": passed,
		"details": {
			"scenarios": scenarios,
		},
	}

static func _duplicate_song_id_scenario(base_fixture_dir: String, base_tmp_dir: String) -> Dictionary:
	var scenario_dir: String = base_tmp_dir.path_join("duplicate_song_id")
	TestSupport.ensure_clean_dir(scenario_dir)
	TestSupport.copy_tree(base_fixture_dir, scenario_dir)
	var original_path: String = scenario_dir.path_join("songs/ab-song-splat-demo.yaml")
	var duplicate_path: String = scenario_dir.path_join("songs/ab-song-splat-demo-duplicate.yaml")
	TestSupport.write_text(duplicate_path, TestSupport.read_text(original_path).replace("songName: Splat Demo Song", "songName: Splat Demo Song Duplicate"))
	var report: Dictionary = load(ADDON_VALIDATE_PACKAGE_SERVICE_PATH).new().validate_path(scenario_dir, "songs")
	var codes: Array = TestSupport.issue_codes(report.get("issues", []))
	return {"name": "duplicate_song_id", "passed": codes.has("duplicate_id"), "codes": codes}

static func _missing_set_reference_scenario(base_fixture_dir: String, base_tmp_dir: String) -> Dictionary:
	var scenario_dir: String = base_tmp_dir.path_join("missing_set_reference")
	TestSupport.ensure_clean_dir(scenario_dir)
	TestSupport.copy_tree(base_fixture_dir, scenario_dir)
	var root_path: String = scenario_dir.path_join("song-package.yaml")
	var root_text: String = TestSupport.read_text(root_path)
	root_text = root_text.replace("- ab-set-splat-demo-boxing-hard", "- ab-set-does-not-exist")
	TestSupport.write_text(root_path, root_text)
	var report: Dictionary = load(ADDON_VALIDATE_PACKAGE_SERVICE_PATH).new().validate_path(scenario_dir, "package")
	var codes: Array = TestSupport.issue_codes(report.get("issues", []))
	return {"name": "missing_set_reference", "passed": codes.has("missing_set_ref"), "codes": codes}

static func _forbidden_song_package_legacy_fields_scenario(base_fixture_dir: String, base_tmp_dir: String) -> Dictionary:
	var scenario_dir: String = base_tmp_dir.path_join("forbidden_song_package_legacy_fields")
	TestSupport.ensure_clean_dir(scenario_dir)
	TestSupport.copy_tree(base_fixture_dir, scenario_dir)
	var root_path: String = scenario_dir.path_join("song-package.yaml")
	var root_text: String = TestSupport.read_text(root_path)
	root_text += "\nworkoutId: ab-workout-legacy\ncoachConfigId: ab-coach-config-legacy\n"
	TestSupport.write_text(root_path, root_text)
	var report: Dictionary = load(ADDON_VALIDATE_PACKAGE_SERVICE_PATH).new().validate_path(scenario_dir, "package")
	var codes: Array = TestSupport.issue_codes(report.get("issues", []))
	return {"name": "forbidden_song_package_legacy_fields", "passed": codes.has("song_package_forbidden_field"), "codes": codes}

static func _forbidden_set_legacy_fields_scenario(base_fixture_dir: String, base_tmp_dir: String) -> Dictionary:
	var scenario_dir: String = base_tmp_dir.path_join("forbidden_set_legacy_fields")
	TestSupport.ensure_clean_dir(scenario_dir)
	TestSupport.copy_tree(base_fixture_dir, scenario_dir)
	var set_path: String = scenario_dir.path_join("sets/ab-set-splat-demo-boxing-normal.yaml")
	var set_text: String = TestSupport.read_text(set_path)
	set_text += "\nenvironmentId: ab-environment-legacy\ncoachingOverlayId: ab-overlay-legacy\n"
	TestSupport.write_text(set_path, set_text)
	var report: Dictionary = load(ADDON_VALIDATE_PACKAGE_SERVICE_PATH).new().validate_path(scenario_dir, "package")
	var codes: Array = TestSupport.issue_codes(report.get("issues", []))
	return {"name": "forbidden_set_legacy_fields", "passed": _count_code(codes, "set_forbidden_field") >= 2, "codes": codes}

static func _asset_selections_not_supported_scenario(base_fixture_dir: String, base_tmp_dir: String) -> Dictionary:
	var scenario_dir: String = base_tmp_dir.path_join("asset_selections_not_supported")
	TestSupport.ensure_clean_dir(scenario_dir)
	TestSupport.copy_tree(base_fixture_dir, scenario_dir)
	var set_path: String = scenario_dir.path_join("sets/ab-set-splat-demo-boxing-normal.yaml")
	var set_text: String = TestSupport.read_text(set_path)
	set_text += "\nassetSelections:\n  gloves: ab-asset-gloves-neon-pulse\n"
	TestSupport.write_text(set_path, set_text)
	var report: Dictionary = load(ADDON_VALIDATE_PACKAGE_SERVICE_PATH).new().validate_path(scenario_dir, "sets")
	var codes: Array = TestSupport.issue_codes(report.get("issues", []))
	return {"name": "asset_selections_not_supported", "passed": codes.has("asset_selections_not_supported"), "codes": codes}

static func _assets_directory_not_supported_scenario(base_fixture_dir: String, base_tmp_dir: String) -> Dictionary:
	var scenario_dir: String = base_tmp_dir.path_join("assets_directory_not_supported")
	TestSupport.ensure_clean_dir(scenario_dir)
	TestSupport.copy_tree(base_fixture_dir, scenario_dir)
	var assets_dir: String = scenario_dir.path_join("assets")
	DirAccess.make_dir_recursive_absolute(assets_dir)
	TestSupport.write_text(assets_dir.path_join("ab-asset-gloves-neon-pulse.yaml"), "schemaId: aerobeat.asset.v1\nschemaVersion: 1\nrecordVersion: 1\nassetId: ab-asset-gloves-neon-pulse\n")
	var report: Dictionary = load(ADDON_VALIDATE_PACKAGE_SERVICE_PATH).new().validate_path(scenario_dir, "package")
	var codes: Array = TestSupport.issue_codes(report.get("issues", []))
	return {"name": "assets_directory_not_supported", "passed": codes.has("assets_directory_not_supported"), "codes": codes}

static func _dance_chart_rejected_scenario(base_fixture_dir: String, base_tmp_dir: String) -> Dictionary:
	var scenario_dir: String = base_tmp_dir.path_join("dance_chart_rejected")
	TestSupport.ensure_clean_dir(scenario_dir)
	TestSupport.copy_tree(base_fixture_dir, scenario_dir)
	var chart_path: String = scenario_dir.path_join("charts/ab-chart-splat-demo-boxing-normal.yaml")
	var chart_text: String = TestSupport.read_text(chart_path)
	chart_text = chart_text.replace("feature: boxing", "feature: dance")
	TestSupport.write_text(chart_path, chart_text)
	var report: Dictionary = load(ADDON_VALIDATE_PACKAGE_SERVICE_PATH).new().validate_path(scenario_dir, "charts")
	var codes: Array = TestSupport.issue_codes(report.get("issues", []))
	return {"name": "dance_chart_rejected", "passed": codes.has("invalid_feature"), "codes": codes}

static func _step_chart_rejected_scenario(base_fixture_dir: String, base_tmp_dir: String) -> Dictionary:
	var scenario_dir: String = base_tmp_dir.path_join("step_chart_rejected")
	TestSupport.ensure_clean_dir(scenario_dir)
	TestSupport.copy_tree(base_fixture_dir, scenario_dir)
	var chart_path: String = scenario_dir.path_join("charts/ab-chart-splat-demo-boxing-normal.yaml")
	var chart_text: String = TestSupport.read_text(chart_path)
	chart_text = chart_text.replace("feature: boxing", "feature: step")
	TestSupport.write_text(chart_path, chart_text)
	var report: Dictionary = load(ADDON_VALIDATE_PACKAGE_SERVICE_PATH).new().validate_path(scenario_dir, "charts")
	var codes: Array = TestSupport.issue_codes(report.get("issues", []))
	return {"name": "step_chart_rejected", "passed": codes.has("invalid_feature"), "codes": codes}

static func _forbidden_song_composition_links_scenario(base_fixture_dir: String, base_tmp_dir: String) -> Dictionary:
	var scenario_dir: String = base_tmp_dir.path_join("forbidden_song_composition_links")
	TestSupport.ensure_clean_dir(scenario_dir)
	TestSupport.copy_tree(base_fixture_dir, scenario_dir)
	var song_path: String = scenario_dir.path_join("songs/ab-song-splat-demo.yaml")
	var song_text: String = TestSupport.read_text(song_path)
	song_text += "\nchartId: ab-chart-splat-demo-boxing-normal\nsetId: ab-set-splat-demo-boxing-normal\nworkoutId: ab-workout-legacy\n"
	TestSupport.write_text(song_path, song_text)
	var report: Dictionary = load(ADDON_VALIDATE_PACKAGE_SERVICE_PATH).new().validate_path(scenario_dir, "songs")
	var codes: Array = TestSupport.issue_codes(report.get("issues", []))
	return {"name": "forbidden_song_composition_links", "passed": _count_code(codes, "forbidden_composition_link_field") >= 3, "codes": codes}

static func _forbidden_chart_composition_links_scenario(base_fixture_dir: String, base_tmp_dir: String) -> Dictionary:
	var scenario_dir: String = base_tmp_dir.path_join("forbidden_chart_composition_links")
	TestSupport.ensure_clean_dir(scenario_dir)
	TestSupport.copy_tree(base_fixture_dir, scenario_dir)
	var chart_path: String = scenario_dir.path_join("charts/ab-chart-splat-demo-boxing-normal.yaml")
	var chart_text: String = TestSupport.read_text(chart_path)
	chart_text += "\nsongId: ab-song-splat-demo\nsetId: ab-set-splat-demo-boxing-normal\nworkoutId: ab-workout-legacy\n"
	TestSupport.write_text(chart_path, chart_text)
	var report: Dictionary = load(ADDON_VALIDATE_PACKAGE_SERVICE_PATH).new().validate_path(scenario_dir, "charts")
	var codes: Array = TestSupport.issue_codes(report.get("issues", []))
	return {"name": "forbidden_chart_composition_links", "passed": _count_code(codes, "forbidden_composition_link_field") >= 3, "codes": codes}

static func _invalid_sql_schema_scenario(base_fixture_dir: String, base_tmp_dir: String) -> Dictionary:
	var scenario_dir: String = base_tmp_dir.path_join("invalid_sql_schema")
	TestSupport.ensure_clean_dir(scenario_dir)
	TestSupport.copy_tree(base_fixture_dir, scenario_dir)
	var sql_path: String = scenario_dir.path_join("sql/workouts.schema.sql")
	TestSupport.write_text(sql_path, "SELECT 1;\n")
	var report: Dictionary = load(ADDON_VALIDATE_PACKAGE_SERVICE_PATH).new().validate_path(scenario_dir, "sql")
	var codes: Array = TestSupport.issue_codes(report.get("issues", []))
	return {"name": "invalid_sql_schema", "passed": codes.has("sql_schema_missing_create_table") and codes.has("sql_schema_missing_create_index"), "codes": codes}

static func _invalid_environment_type_scenario(base_fixture_dir: String, base_tmp_dir: String) -> Dictionary:
	var scenario_dir: String = base_tmp_dir.path_join("invalid_environment_type")
	TestSupport.ensure_clean_dir(scenario_dir)
	TestSupport.copy_tree(base_fixture_dir, scenario_dir)
	var env_dir: String = scenario_dir.path_join("environments")
	DirAccess.make_dir_recursive_absolute(env_dir)
	var environment_path: String = env_dir.path_join("ab-environment-sunrise-studio.yaml")
	TestSupport.write_text(environment_path, "schemaId: aerobeat.environment.v1\nschemaVersion: 1\nrecordVersion: 1\nenvironmentId: ab-environment-sunrise-studio\nenvironmentName: Sunrise Studio\ntype: godot_scene\nresourcePath: media/environments/sunrise-studio.png\n")
	DirAccess.make_dir_recursive_absolute(scenario_dir.path_join("media/environments"))
	TestSupport.write_text(scenario_dir.path_join("media/environments/sunrise-studio.png"), "placeholder\n")
	var report: Dictionary = load(ADDON_VALIDATE_PACKAGE_SERVICE_PATH).new().validate_path(scenario_dir, "environments")
	var codes: Array = TestSupport.issue_codes(report.get("issues", []))
	return {"name": "invalid_environment_type", "passed": codes.has("invalid_environment_type"), "codes": codes}

static func _count_code(codes: Array, code: String) -> int:
	var count: int = 0
	for value in codes:
		if String(value) == code:
			count += 1
	return count
