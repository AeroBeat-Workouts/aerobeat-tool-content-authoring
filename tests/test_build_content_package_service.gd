extends RefCounted

const BuildContentPackageService = preload("../services/packaging/build_content_package_service.gd")
const WorkoutPackageWorkflowService = preload("../services/workflow/workout_package_workflow_service.gd")
const TestSupport = preload("test_support.gd")

static func run() -> Dictionary:
	var fixture_dir: String = TestSupport.demo_package_dir()
	var workflow := WorkoutPackageWorkflowService.new()
	var loaded: Dictionary = workflow.load_package_folder(fixture_dir)
	var state: Dictionary = Dictionary(loaded.get("state", {})).duplicate(true)
	for set_record in state.get("sets", []):
		var preferred_environment_id: String = String(Dictionary(set_record).get("preferredEnvironmentId", Dictionary(set_record).get("environmentId", ""))).strip_edges()
		if not preferred_environment_id.is_empty():
			Dictionary(set_record)["fallbackEnvironmentId"] = preferred_environment_id
	var source_dir: String = ProjectSettings.globalize_path("res://tmp/build_content_package_service/source")
	workflow.write_package_state(state, source_dir)
	var output_dir: String = ProjectSettings.globalize_path("res://tmp/build_content_package_service/demo-neon-boxing-bootcamp")
	var result: Dictionary = BuildContentPackageService.new().build_package(source_dir, output_dir)
	var workout_exists := FileAccess.file_exists(output_dir.path_join("workout.yaml"))
	var chart_exists := FileAccess.file_exists(output_dir.path_join("charts/ab-chart-neon-stride-boxing-medium.yaml"))
	var media_exists := FileAccess.file_exists(output_dir.path_join("media/audio/neon-stride.ogg"))
	var sql_exists := FileAccess.file_exists(output_dir.path_join("sql/workouts.db.schema.sql"))
	var zip_exists := FileAccess.file_exists("%s.zip" % output_dir)
	var copied_files: Array = result.get("copiedFiles", [])
	var passed: bool = bool(result.get("ok", false)) and workout_exists and chart_exists and media_exists and sql_exists and zip_exists and copied_files.has("workout.yaml")
	return {
		"name": "test_build_content_package_service",
		"passed": passed,
		"details": result,
	}
