extends RefCounted

const ADDON_VALIDATE_PACKAGE_SERVICE_PATH := "res://addons/aerobeat-tool-content-authoring/src/services/validation/validate_package_service.gd"
const ADDON_SONG_PACKAGE_VALIDATION_SERVICE_PATH := "res://addons/aerobeat-tool-content-authoring/src/services/validation/song_package_validation_service.gd"
const TestSupport = preload("test_support.gd")

static func run() -> Dictionary:
	var base_fixture_dir: String = TestSupport.demo_package_dir()
	var base_tmp_dir: String = TestSupport.tmp_dir("test_validate_package_failure_modes")
	TestSupport.ensure_clean_dir(base_tmp_dir)
	var scenarios: Array = [
		_orphan_chart_record_scenario(base_fixture_dir, base_tmp_dir),
		_missing_chart_reference_scenario(base_fixture_dir, base_tmp_dir),
		_forbidden_song_package_legacy_fields_scenario(base_fixture_dir, base_tmp_dir),
		_forbidden_song_package_set_ids_scenario(base_fixture_dir, base_tmp_dir),
		_sets_directory_not_supported_scenario(base_fixture_dir, base_tmp_dir),
		_missing_chart_path_scenario(base_fixture_dir, base_tmp_dir),
		_assets_directory_not_supported_scenario(base_fixture_dir, base_tmp_dir),
		_dance_chart_rejected_scenario(base_fixture_dir, base_tmp_dir),
		_step_chart_rejected_scenario(base_fixture_dir, base_tmp_dir),
		_forbidden_song_composition_links_scenario(base_fixture_dir, base_tmp_dir),
		_forbidden_chart_composition_links_scenario(base_fixture_dir, base_tmp_dir),
		_invalid_sql_schema_scenario(base_fixture_dir, base_tmp_dir),
		_invalid_environment_type_scenario(base_fixture_dir, base_tmp_dir),
		_content_core_package_validator_unavailable_scenario(base_fixture_dir, base_tmp_dir),
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

static func _orphan_chart_record_scenario(base_fixture_dir: String, base_tmp_dir: String) -> Dictionary:
	var scenario_dir: String = base_tmp_dir.path_join("chart_descriptor_mode_mismatch")
	TestSupport.ensure_clean_dir(scenario_dir)
	TestSupport.copy_tree(base_fixture_dir, scenario_dir)
	var root_path: String = scenario_dir.path_join("song.package.yaml")
	var root_text: String = TestSupport.read_text(root_path)
	root_text = root_text.replace("mode: boxing", "mode: flow")
	TestSupport.write_text(root_path, root_text)
	var report: Dictionary = load(ADDON_VALIDATE_PACKAGE_SERVICE_PATH).new().validate_path(scenario_dir, "package")
	var codes: Array = TestSupport.issue_codes(report.get("issues", []))
	return {"name": "chart_descriptor_mode_mismatch", "passed": codes.has("chart_descriptor_mode_mismatch"), "codes": codes}

static func _missing_chart_reference_scenario(base_fixture_dir: String, base_tmp_dir: String) -> Dictionary:
	var scenario_dir: String = base_tmp_dir.path_join("missing_chart_reference")
	TestSupport.ensure_clean_dir(scenario_dir)
	TestSupport.copy_tree(base_fixture_dir, scenario_dir)
	var root_path: String = scenario_dir.path_join("song.package.yaml")
	var root_text: String = TestSupport.read_text(root_path)
	root_text = root_text.replace("chartId: ab-chart-splat-demo-boxing-normal", "chartId: ab-chart-does-not-exist")
	TestSupport.write_text(root_path, root_text)
	var report: Dictionary = load(ADDON_VALIDATE_PACKAGE_SERVICE_PATH).new().validate_path(scenario_dir, "package")
	var codes: Array = TestSupport.issue_codes(report.get("issues", []))
	return {"name": "missing_chart_reference", "passed": codes.has("missing_chart_ref"), "codes": codes}

static func _forbidden_song_package_legacy_fields_scenario(base_fixture_dir: String, base_tmp_dir: String) -> Dictionary:
	var scenario_dir: String = base_tmp_dir.path_join("forbidden_song_package_legacy_fields")
	TestSupport.ensure_clean_dir(scenario_dir)
	TestSupport.copy_tree(base_fixture_dir, scenario_dir)
	var root_path: String = scenario_dir.path_join("song.package.yaml")
	var root_text: String = TestSupport.read_text(root_path)
	root_text += "\nworkoutId: ab-workout-legacy\ncoachConfigId: ab-coach-config-legacy\n"
	TestSupport.write_text(root_path, root_text)
	var report: Dictionary = load(ADDON_VALIDATE_PACKAGE_SERVICE_PATH).new().validate_path(scenario_dir, "package")
	var codes: Array = TestSupport.issue_codes(report.get("issues", []))
	return {"name": "forbidden_song_package_legacy_fields", "passed": codes.has("song_package_forbidden_field"), "codes": codes}

static func _forbidden_song_package_set_ids_scenario(base_fixture_dir: String, base_tmp_dir: String) -> Dictionary:
	var scenario_dir: String = base_tmp_dir.path_join("forbidden_song_package_set_ids")
	TestSupport.ensure_clean_dir(scenario_dir)
	TestSupport.copy_tree(base_fixture_dir, scenario_dir)
	var root_path: String = scenario_dir.path_join("song.package.yaml")
	var root_text: String = TestSupport.read_text(root_path)
	root_text += "\nsetIds:\n  - ab-set-splat-demo-boxing-normal\n"
	TestSupport.write_text(root_path, root_text)
	var report: Dictionary = load(ADDON_VALIDATE_PACKAGE_SERVICE_PATH).new().validate_path(scenario_dir, "package")
	var codes: Array = TestSupport.issue_codes(report.get("issues", []))
	return {"name": "forbidden_song_package_set_ids", "passed": codes.has("song_package_forbidden_field"), "codes": codes}

static func _sets_directory_not_supported_scenario(base_fixture_dir: String, base_tmp_dir: String) -> Dictionary:
	var scenario_dir: String = base_tmp_dir.path_join("sets_directory_not_supported")
	TestSupport.ensure_clean_dir(scenario_dir)
	TestSupport.copy_tree(base_fixture_dir, scenario_dir)
	var sets_dir: String = scenario_dir.path_join("sets")
	DirAccess.make_dir_recursive_absolute(sets_dir)
	_write_legacy_set_file(sets_dir.path_join("ab-set-splat-demo-boxing-normal.yaml"), {})
	var report: Dictionary = load(ADDON_VALIDATE_PACKAGE_SERVICE_PATH).new().validate_path(scenario_dir, "package")
	var codes: Array = TestSupport.issue_codes(report.get("issues", []))
	return {"name": "sets_directory_not_supported", "passed": codes.has("sets_directory_not_supported"), "codes": codes}

static func _missing_chart_path_scenario(base_fixture_dir: String, base_tmp_dir: String) -> Dictionary:
	var scenario_dir: String = base_tmp_dir.path_join("missing_chart_path")
	TestSupport.ensure_clean_dir(scenario_dir)
	TestSupport.copy_tree(base_fixture_dir, scenario_dir)
	var root_path: String = scenario_dir.path_join("song.package.yaml")
	var root_text: String = TestSupport.read_text(root_path)
	root_text = root_text.replace("path: charts/ab-chart-splat-demo-boxing-normal.yaml", "path: charts/ab-chart-does-not-exist.yaml")
	TestSupport.write_text(root_path, root_text)
	var report: Dictionary = load(ADDON_VALIDATE_PACKAGE_SERVICE_PATH).new().validate_path(scenario_dir, "package")
	var codes: Array = TestSupport.issue_codes(report.get("issues", []))
	return {"name": "missing_chart_path", "passed": codes.has("missing_chart_path"), "codes": codes}

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
	chart_text = chart_text.replace("mode: boxing", "mode: dance")
	TestSupport.write_text(chart_path, chart_text)
	var report: Dictionary = load(ADDON_VALIDATE_PACKAGE_SERVICE_PATH).new().validate_path(scenario_dir, "charts")
	var codes: Array = TestSupport.issue_codes(report.get("issues", []))
	return {"name": "dance_chart_rejected", "passed": codes.has("invalid_mode"), "codes": codes}

static func _step_chart_rejected_scenario(base_fixture_dir: String, base_tmp_dir: String) -> Dictionary:
	var scenario_dir: String = base_tmp_dir.path_join("step_chart_rejected")
	TestSupport.ensure_clean_dir(scenario_dir)
	TestSupport.copy_tree(base_fixture_dir, scenario_dir)
	var chart_path: String = scenario_dir.path_join("charts/ab-chart-splat-demo-boxing-normal.yaml")
	var chart_text: String = TestSupport.read_text(chart_path)
	chart_text = chart_text.replace("mode: boxing", "mode: step")
	TestSupport.write_text(chart_path, chart_text)
	var report: Dictionary = load(ADDON_VALIDATE_PACKAGE_SERVICE_PATH).new().validate_path(scenario_dir, "charts")
	var codes: Array = TestSupport.issue_codes(report.get("issues", []))
	return {"name": "step_chart_rejected", "passed": codes.has("invalid_mode"), "codes": codes}

static func _forbidden_song_composition_links_scenario(base_fixture_dir: String, base_tmp_dir: String) -> Dictionary:
	var scenario_dir: String = base_tmp_dir.path_join("forbidden_song_composition_links")
	TestSupport.ensure_clean_dir(scenario_dir)
	TestSupport.copy_tree(base_fixture_dir, scenario_dir)
	var song_package_path: String = scenario_dir.path_join("song.package.yaml")
	var song_package_text: String = TestSupport.read_text(song_package_path)
	song_package_text = song_package_text.replace(
		"song:\n  durationSec: 90\n",
		"song:\n  chartId: ab-chart-splat-demo-boxing-normal\n  setId: ab-set-splat-demo-boxing-normal\n  workoutId: ab-workout-legacy\n  durationSec: 90\n"
	)
	TestSupport.write_text(song_package_path, song_package_text)
	var report: Dictionary = load(ADDON_VALIDATE_PACKAGE_SERVICE_PATH).new().validate_path(scenario_dir, "package")
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

static func _content_core_package_validator_unavailable_scenario(base_fixture_dir: String, base_tmp_dir: String) -> Dictionary:
	var scenario_dir: String = base_tmp_dir.path_join("content_core_package_validator_unavailable")
	TestSupport.ensure_clean_dir(scenario_dir)
	TestSupport.copy_tree(base_fixture_dir, scenario_dir)
	var service = load(ADDON_SONG_PACKAGE_VALIDATION_SERVICE_PATH).new().set_core_validator_paths([
		"res://addons/does-not-exist/validators/content_package_validator.gd",
	])
	var report: Dictionary = service.validate_path(scenario_dir, "package")
	var codes: Array = TestSupport.issue_codes(report.get("issues", []))
	return {
		"name": "content_core_package_validator_unavailable",
		"passed": not bool(report.get("valid", true)) \
			and String(report.get("delegatedValidator", "")) == "unavailable" \
			and codes.has("content_core_package_validator_unavailable"),
		"codes": codes,
		"delegatedValidator": report.get("delegatedValidator", ""),
	}

static func _write_legacy_set_file(path: String, extras: Dictionary) -> void:
	var lines := [
		"schemaId: aerobeat.set.v1",
		"schemaVersion: 1",
		"recordVersion: 1",
		"setId: ab-set-splat-demo-boxing-normal",
		"setName: Splat Demo Boxing Normal",
		"songId: ab-song-splat-demo",
		"chartId: ab-chart-splat-demo-boxing-normal",
	]
	if extras.has("assetSelections"):
		lines.append("assetSelections:")
		for key_variant in Dictionary(extras.get("assetSelections", {})).keys():
			lines.append("  %s: %s" % [String(key_variant), String(Dictionary(extras.get("assetSelections", {})).get(key_variant, ""))])
	TestSupport.write_text(path, "\n".join(lines) + "\n")

static func _count_code(codes: Array, code: String) -> int:
	var count: int = 0
	for value in codes:
		if String(value) == code:
			count += 1
	return count
