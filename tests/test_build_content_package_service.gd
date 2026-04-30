extends RefCounted

const BuildContentPackageService = preload("../services/packaging/build_content_package_service.gd")
const TestSupport = preload("test_support.gd")

static func run() -> Dictionary:
	var fixture_dir: String = TestSupport.demo_package_dir()
	var output_dir: String = ProjectSettings.globalize_path("res://tmp/build_content_package_service")
	TestSupport.ensure_clean_dir(output_dir)
	var result: Dictionary = BuildContentPackageService.new().build_package(fixture_dir, output_dir)
	var workout_exists := FileAccess.file_exists(output_dir.path_join("workout.yaml"))
	var chart_exists := FileAccess.file_exists(output_dir.path_join("charts/ab-chart-neon-stride-boxing-medium.yaml"))
	var media_exists := FileAccess.file_exists(output_dir.path_join("media/audio/neon-stride.ogg"))
	var sql_exists := FileAccess.file_exists(output_dir.path_join("sql/workouts.db.schema.sql"))
	var copied_files: Array = result.get("copiedFiles", [])
	var passed: bool = bool(result.get("ok", false)) and workout_exists and chart_exists and media_exists and sql_exists and copied_files.has("workout.yaml")
	return {
		"name": "test_build_content_package_service",
		"passed": passed,
		"details": {
			"fixtureDir": fixture_dir,
			"outputDir": output_dir,
			"result": result,
		},
	}
