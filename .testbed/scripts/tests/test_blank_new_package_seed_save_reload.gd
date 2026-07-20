extends RefCounted

const AeroContentAuthoring = preload("res://addons/aerobeat-tool-content-authoring/src/AeroContentAuthoring.gd")
const TestSupport = preload("test_support.gd")

static func run() -> Dictionary:
	var runtime := AeroContentAuthoring.new()
	var create_result: Dictionary = runtime.create_new_song_package({
		"songPackageId": "ab-song-package-seeded-smoke",
		"songPackageName": "Seeded Smoke Song Package",
		"packageVersion": "2.0.0",
	})
	var seeded_state: Dictionary = create_result.get("state", {})
	var song_package: Dictionary = Dictionary(seeded_state.get("songPackage", {}))
	var sets: Array = Array(seeded_state.get("sets", []))
	var songs: Array = Array(seeded_state.get("songs", []))
	var charts: Array = Array(seeded_state.get("charts", []))
	var environments: Array = Array(seeded_state.get("environments", []))
	var sql_files: Array = Array(seeded_state.get("sqlFiles", []))
	var first_set: Dictionary = Dictionary(sets[0]) if not sets.is_empty() else {}
	var first_song: Dictionary = Dictionary(songs[0]) if not songs.is_empty() else {}
	var first_chart: Dictionary = Dictionary(charts[0]) if not charts.is_empty() else {}

	var seeded_linkage_passed := bool(create_result.get("ok", false)) \
		and String(song_package.get("songPackageId", "")) == "ab-song-package-seeded-smoke" \
		and String(song_package.get("songPackageName", "")) == "Seeded Smoke Song Package" \
		and String(song_package.get("packageVersion", "")) == "2.0.0" \
		and Array(song_package.get("setIds", [])).size() == 1 \
		and String(first_set.get("setId", "")) == String(Array(song_package.get("setIds", []))[0]) \
		and String(first_set.get("songId", "")) == String(first_song.get("songId", "")) \
		and String(first_set.get("chartId", "")) == String(first_chart.get("chartId", "")) \
		and environments.is_empty() \
		and sql_files.has("sql/workouts.schema.sql")

	var create_validation: Dictionary = runtime.validate_current_package()
	var create_validation_passed := bool(create_validation.get("valid", false))

	var save_parent: String = TestSupport.tmp_dir("blank_new_package_seed_save_reload")
	TestSupport.ensure_clean_dir(save_parent)
	var save_result: Dictionary = runtime.save_current_package(save_parent)
	var output_dir: String = String(save_result.get("outputDir", ""))
	var zip_path: String = String(save_result.get("zipPath", ""))
	var required_paths := [
		"song-package.yaml",
		"songs/ab-song-001.yaml",
		"charts/ab-chart-001.yaml",
		"sets/ab-set-001.yaml",
		"sql/workouts.schema.sql",
		"media/audio/blank-song.ogg",
	]
	var written_files_passed := bool(save_result.get("ok", false)) and DirAccess.dir_exists_absolute(output_dir) and FileAccess.file_exists(zip_path)
	for relative_path in required_paths:
		written_files_passed = written_files_passed and FileAccess.file_exists(output_dir.path_join(relative_path))
	var sql_text: String = TestSupport.read_text(output_dir.path_join("sql/workouts.schema.sql"))
	var sql_passed := sql_text.contains("CREATE TABLE") and sql_text.contains("CREATE INDEX")

	var reloaded_runtime := AeroContentAuthoring.new()
	var load_result: Dictionary = reloaded_runtime.load_song_package_folder(output_dir)
	var reloaded_state: Dictionary = reloaded_runtime.get_current_package_state()
	var reload_validation: Dictionary = reloaded_runtime.validate_current_package()
	var package_validation: Dictionary = reloaded_runtime.get_validate_package_service().validate_path(output_dir, "package")
	var reloaded_song_package: Dictionary = Dictionary(reloaded_state.get("songPackage", {}))
	var reload_passed := bool(load_result.get("ok", false)) \
		and String(reloaded_song_package.get("songPackageId", "")) == "ab-song-package-seeded-smoke" \
		and Array(reloaded_state.get("songs", [])).size() == 1 \
		and Array(reloaded_state.get("charts", [])).size() == 1 \
		and Array(reloaded_state.get("sets", [])).size() == 1 \
		and Array(reloaded_state.get("environments", [])).is_empty() \
		and bool(reload_validation.get("valid", false)) \
		and bool(package_validation.get("valid", false))

	var passed := seeded_linkage_passed and create_validation_passed and written_files_passed and sql_passed and reload_passed
	return {
		"name": "test_blank_new_package_seed_save_reload",
		"passed": passed,
		"details": {
			"createResult": create_result,
			"createValidation": create_validation,
			"saveResult": save_result,
			"loadResult": load_result,
			"reloadValidation": reload_validation,
			"packageValidation": package_validation,
			"outputDir": output_dir,
			"requiredPaths": required_paths,
			"sqlText": sql_text,
		},
	}
