extends RefCounted

const ValidatePackageService = preload("../services/validation/validate_package_service.gd")
const TestSupport = preload("test_support.gd")

static func run() -> Dictionary:
	var base_fixture_dir: String = TestSupport.demo_package_dir()
	var base_tmp_dir: String = ProjectSettings.globalize_path("res://tmp/test_validate_package_failure_modes")
	TestSupport.ensure_clean_dir(base_tmp_dir)
	var scenarios: Array = [
		_duplicate_song_id_scenario(base_fixture_dir, base_tmp_dir),
		_missing_set_reference_scenario(base_fixture_dir, base_tmp_dir),
		_invalid_coaching_path_scenario(base_fixture_dir, base_tmp_dir),
		_missing_required_coaching_overlay_scenario(base_fixture_dir, base_tmp_dir),
		_invalid_asset_selection_key_scenario(base_fixture_dir, base_tmp_dir),
		_asset_selection_type_mismatch_scenario(base_fixture_dir, base_tmp_dir),
		_forbidden_song_composition_links_scenario(base_fixture_dir, base_tmp_dir),
		_forbidden_chart_composition_links_scenario(base_fixture_dir, base_tmp_dir),
		_invalid_sql_schema_scenario(base_fixture_dir, base_tmp_dir),
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
	var original_path: String = scenario_dir.path_join("songs/ab-song-neon-stride.yaml")
	var duplicate_path: String = scenario_dir.path_join("songs/ab-song-neon-stride-duplicate.yaml")
	TestSupport.write_text(duplicate_path, TestSupport.read_text(original_path).replace("songName: Neon Stride", "songName: Neon Stride Duplicate"))
	var report: Dictionary = ValidatePackageService.new().validate_path(scenario_dir, "songs")
	var codes: Array = TestSupport.issue_codes(report.get("issues", []))
	return {
		"name": "duplicate_song_id",
		"passed": codes.has("duplicate_id"),
		"codes": codes,
	}

static func _missing_set_reference_scenario(base_fixture_dir: String, base_tmp_dir: String) -> Dictionary:
	var scenario_dir: String = base_tmp_dir.path_join("missing_set_reference")
	TestSupport.ensure_clean_dir(scenario_dir)
	TestSupport.copy_tree(base_fixture_dir, scenario_dir)
	var set_path: String = scenario_dir.path_join("sets/ab-set-neon-stride-opening-round.yaml")
	var set_text: String = TestSupport.read_text(set_path)
	set_text = set_text.replace("chartId: ab-chart-neon-stride-boxing-medium", "chartId: ab-chart-does-not-exist")
	TestSupport.write_text(set_path, set_text)
	var report: Dictionary = ValidatePackageService.new().validate_path(scenario_dir, "package")
	var codes: Array = TestSupport.issue_codes(report.get("issues", []))
	return {
		"name": "missing_set_reference",
		"passed": codes.has("missing_chart_ref"),
		"codes": codes,
	}

static func _invalid_coaching_path_scenario(base_fixture_dir: String, base_tmp_dir: String) -> Dictionary:
	var scenario_dir: String = base_tmp_dir.path_join("invalid_coaching_path")
	TestSupport.ensure_clean_dir(scenario_dir)
	TestSupport.copy_tree(base_fixture_dir, scenario_dir)
	var coach_path: String = scenario_dir.path_join("coaches/coach-config.yaml")
	var coach_text: String = TestSupport.read_text(coach_path)
	coach_text = coach_text.replace("path: media/coaching/warmup-breathing-intro.mp4", "path: media/coaching/missing-warmup.mp4")
	TestSupport.write_text(coach_path, coach_text)
	var report: Dictionary = ValidatePackageService.new().validate_path(scenario_dir, "coaches")
	var codes: Array = TestSupport.issue_codes(report.get("issues", []))
	return {
		"name": "invalid_coaching_path",
		"passed": codes.has("missing_file"),
		"codes": codes,
	}

static func _missing_required_coaching_overlay_scenario(base_fixture_dir: String, base_tmp_dir: String) -> Dictionary:
	var scenario_dir: String = base_tmp_dir.path_join("missing_required_coaching_overlay")
	TestSupport.ensure_clean_dir(scenario_dir)
	TestSupport.copy_tree(base_fixture_dir, scenario_dir)
	var set_path: String = scenario_dir.path_join("sets/ab-set-neon-stride-flow-round.yaml")
	var set_text: String = TestSupport.read_text(set_path)
	set_text = set_text.replace("coachingOverlayId: ab-overlay-aria-neon-stride-cue\n", "")
	TestSupport.write_text(set_path, set_text)
	var report: Dictionary = ValidatePackageService.new().validate_path(scenario_dir, "package")
	var codes: Array = TestSupport.issue_codes(report.get("issues", []))
	return {
		"name": "missing_required_coaching_overlay",
		"passed": codes.has("missing_required_coaching_overlay_ref"),
		"codes": codes,
	}

static func _invalid_asset_selection_key_scenario(base_fixture_dir: String, base_tmp_dir: String) -> Dictionary:
	var scenario_dir: String = base_tmp_dir.path_join("invalid_asset_selection_key")
	TestSupport.ensure_clean_dir(scenario_dir)
	TestSupport.copy_tree(base_fixture_dir, scenario_dir)
	var set_path: String = scenario_dir.path_join("sets/ab-set-neon-stride-opening-round.yaml")
	var set_text: String = TestSupport.read_text(set_path)
	set_text += "\n  confetti: ab-asset-gloves-neon-pulse\n"
	TestSupport.write_text(set_path, set_text)
	var report: Dictionary = ValidatePackageService.new().validate_path(scenario_dir, "sets")
	var codes: Array = TestSupport.issue_codes(report.get("issues", []))
	return {
		"name": "invalid_asset_selection_key",
		"passed": codes.has("invalid_asset_selection_type"),
		"codes": codes,
	}

static func _asset_selection_type_mismatch_scenario(base_fixture_dir: String, base_tmp_dir: String) -> Dictionary:
	var scenario_dir: String = base_tmp_dir.path_join("asset_selection_type_mismatch")
	TestSupport.ensure_clean_dir(scenario_dir)
	TestSupport.copy_tree(base_fixture_dir, scenario_dir)
	var set_path: String = scenario_dir.path_join("sets/ab-set-neon-stride-opening-round.yaml")
	var set_text: String = TestSupport.read_text(set_path)
	set_text = set_text.replace("gloves: ab-asset-gloves-neon-pulse", "gloves: ab-asset-targets-holo-rings")
	TestSupport.write_text(set_path, set_text)
	var report: Dictionary = ValidatePackageService.new().validate_path(scenario_dir, "package")
	var codes: Array = TestSupport.issue_codes(report.get("issues", []))
	return {
		"name": "asset_selection_type_mismatch",
		"passed": codes.has("asset_selection_type_mismatch"),
		"codes": codes,
	}

static func _forbidden_song_composition_links_scenario(base_fixture_dir: String, base_tmp_dir: String) -> Dictionary:
	var scenario_dir: String = base_tmp_dir.path_join("forbidden_song_composition_links")
	TestSupport.ensure_clean_dir(scenario_dir)
	TestSupport.copy_tree(base_fixture_dir, scenario_dir)
	var song_path: String = scenario_dir.path_join("songs/ab-song-neon-stride.yaml")
	var song_text: String = TestSupport.read_text(song_path)
	song_text += "\nchartId: ab-chart-neon-stride-boxing-medium\nsetId: ab-set-neon-stride-opening-round\nworkoutId: ab-workout-demo-neon-boxing-bootcamp\n"
	TestSupport.write_text(song_path, song_text)
	var report: Dictionary = ValidatePackageService.new().validate_path(scenario_dir, "songs")
	var codes: Array = TestSupport.issue_codes(report.get("issues", []))
	return {
		"name": "forbidden_song_composition_links",
		"passed": _count_code(codes, "forbidden_composition_link_field") >= 3,
		"codes": codes,
	}

static func _forbidden_chart_composition_links_scenario(base_fixture_dir: String, base_tmp_dir: String) -> Dictionary:
	var scenario_dir: String = base_tmp_dir.path_join("forbidden_chart_composition_links")
	TestSupport.ensure_clean_dir(scenario_dir)
	TestSupport.copy_tree(base_fixture_dir, scenario_dir)
	var chart_path: String = scenario_dir.path_join("charts/ab-chart-neon-stride-boxing-medium.yaml")
	var chart_text: String = TestSupport.read_text(chart_path)
	chart_text += "\nsongId: ab-song-neon-stride\nsetId: ab-set-neon-stride-opening-round\nworkoutId: ab-workout-demo-neon-boxing-bootcamp\n"
	TestSupport.write_text(chart_path, chart_text)
	var report: Dictionary = ValidatePackageService.new().validate_path(scenario_dir, "charts")
	var codes: Array = TestSupport.issue_codes(report.get("issues", []))
	return {
		"name": "forbidden_chart_composition_links",
		"passed": _count_code(codes, "forbidden_composition_link_field") >= 3,
		"codes": codes,
	}

static func _invalid_sql_schema_scenario(base_fixture_dir: String, base_tmp_dir: String) -> Dictionary:
	var scenario_dir: String = base_tmp_dir.path_join("invalid_sql_schema")
	TestSupport.ensure_clean_dir(scenario_dir)
	TestSupport.copy_tree(base_fixture_dir, scenario_dir)
	var sql_path: String = scenario_dir.path_join("sql/workouts.db.schema.sql")
	TestSupport.write_text(sql_path, "SELECT 1;\n")
	var report: Dictionary = ValidatePackageService.new().validate_path(scenario_dir, "sql")
	var codes: Array = TestSupport.issue_codes(report.get("issues", []))
	return {
		"name": "invalid_sql_schema",
		"passed": codes.has("sql_schema_missing_create_table") and codes.has("sql_schema_missing_create_index"),
		"codes": codes,
	}

static func _count_code(codes: Array, code: String) -> int:
	var count: int = 0
	for value in codes:
		if String(value) == code:
			count += 1
	return count
