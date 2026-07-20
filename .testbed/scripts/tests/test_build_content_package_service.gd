extends RefCounted

const BuildContentPackageService = preload("res://addons/aerobeat-tool-content-authoring/src/services/packaging/build_content_package_service.gd")
const SongPackageWorkflowService = preload("res://addons/aerobeat-tool-content-authoring/src/services/workflow/song_package_workflow_service.gd")
const TestSupport = preload("test_support.gd")

static func run() -> Dictionary:
	var fixture_dir: String = TestSupport.demo_package_dir()
	var workflow := SongPackageWorkflowService.new()
	var loaded: Dictionary = workflow.load_package_folder(fixture_dir)
	var state: Dictionary = Dictionary(loaded.get("state", {})).duplicate(true)
	var source_dir: String = TestSupport.tmp_dir("build_content_package_service/source")
	workflow.write_package_state(state, source_dir)
	var output_dir: String = TestSupport.tmp_dir("build_content_package_service/demo-song-package")
	var result: Dictionary = BuildContentPackageService.new().build_package(source_dir, output_dir)
	var song_package_exists := FileAccess.file_exists(output_dir.path_join("song-package.yaml"))
	var chart_exists := FileAccess.file_exists(output_dir.path_join("charts/ab-chart-splat-demo-boxing-normal.yaml"))
	var zip_exists := FileAccess.file_exists("%s.zip" % output_dir)
	var copied_files: Array = result.get("copiedFiles", [])
	var passed: bool = bool(result.get("ok", false)) and song_package_exists and chart_exists and zip_exists and copied_files.has("song-package.yaml")
	return {
		"name": "test_build_content_package_service",
		"passed": passed,
		"details": result,
	}
