extends RefCounted

const AeroContentAuthoring = preload("res://addons/aerobeat-tool-content-authoring/src/AeroContentAuthoring.gd")
const TestSupport = preload("test_support.gd")

static func run() -> Dictionary:
	var runtime := AeroContentAuthoring.new()
	var create_result: Dictionary = runtime.create_new_workout_package({
		"workoutId": "ab-workout-seeded-smoke",
		"workoutName": "Seeded Smoke Workout",
		"packageVersion": "2.0.0",
	})
	var seeded_state: Dictionary = create_result.get("state", {})
	var workout: Dictionary = Dictionary(seeded_state.get("workout", {}))
	var coach_config: Dictionary = Dictionary(seeded_state.get("coachConfig", {}))
	var sets: Array = Array(seeded_state.get("sets", []))
	var songs: Array = Array(seeded_state.get("songs", []))
	var charts: Array = Array(seeded_state.get("charts", []))
	var environments: Array = Array(seeded_state.get("environments", []))
	var sql_files: Array = Array(seeded_state.get("sqlFiles", []))
	var first_set: Dictionary = Dictionary(sets[0]) if not sets.is_empty() else {}
	var first_song: Dictionary = Dictionary(songs[0]) if not songs.is_empty() else {}
	var first_chart: Dictionary = Dictionary(charts[0]) if not charts.is_empty() else {}
	var first_environment: Dictionary = Dictionary(environments[0]) if not environments.is_empty() else {}
	var first_overlay: Dictionary = Dictionary(Array(coach_config.get("overlayAudio", []))[0]) if Array(coach_config.get("overlayAudio", [])).size() > 0 else {}

	var seeded_linkage_passed := bool(create_result.get("ok", false)) \
		and String(workout.get("workoutId", "")) == "ab-workout-seeded-smoke" \
		and String(workout.get("workoutName", "")) == "Seeded Smoke Workout" \
		and String(workout.get("packageVersion", "")) == "2.0.0" \
		and String(workout.get("coachConfigId", "")) == String(coach_config.get("coachConfigId", "")) \
		and Array(workout.get("setOrder", [])).size() == 1 \
		and String(first_set.get("setId", "")) == String(Array(workout.get("setOrder", []))[0]) \
		and String(first_set.get("songId", "")) == String(first_song.get("songId", "")) \
		and String(first_set.get("chartId", "")) == String(first_chart.get("chartId", "")) \
		and String(first_set.get("preferredEnvironmentId", "")) == String(first_environment.get("environmentId", "")) \
		and String(first_set.get("fallbackEnvironmentId", "")) == String(first_environment.get("environmentId", "")) \
		and String(first_set.get("environmentId", "")) == String(first_environment.get("environmentId", "")) \
		and String(first_set.get("coachingOverlayId", "")) == String(first_overlay.get("overlayId", "")) \
		and bool(coach_config.get("enabled", false)) \
		and sql_files.has("sql/workouts.schema.sql")

	var create_validation: Dictionary = runtime.validate_current_package()
	var create_validation_passed := bool(create_validation.get("valid", false))

	var save_parent: String = TestSupport.tmp_dir("blank_new_package_seed_save_reload")
	TestSupport.ensure_clean_dir(save_parent)
	var save_result: Dictionary = runtime.save_current_package(save_parent)
	var output_dir: String = String(save_result.get("outputDir", ""))
	var zip_path: String = String(save_result.get("zipPath", ""))
	var required_paths := [
		"workout.yaml",
		"songs/ab-song-001.yaml",
		"charts/ab-chart-001.yaml",
		"sets/ab-set-001.yaml",
		"environments/ab-environment-001.yaml",
		"coaches/coach-config.yaml",
		"sql/workouts.schema.sql",
		"media/audio/blank-song.ogg",
		"media/coaching/blank-overlay.ogg",
		"media/coaching/blank-coaching-video.mp4",
		"media/environments/blank-environment.png",
	]
	var written_files_passed := bool(save_result.get("ok", false)) and DirAccess.dir_exists_absolute(output_dir) and FileAccess.file_exists(zip_path)
	for relative_path in required_paths:
		written_files_passed = written_files_passed and FileAccess.file_exists(output_dir.path_join(relative_path))
	var sql_text: String = TestSupport.read_text(output_dir.path_join("sql/workouts.schema.sql"))
	var sql_passed := sql_text.contains("CREATE TABLE") and sql_text.contains("CREATE INDEX")

	var reloaded_runtime := AeroContentAuthoring.new()
	var load_result: Dictionary = reloaded_runtime.load_workout_package_folder(output_dir)
	var reloaded_state: Dictionary = reloaded_runtime.get_current_package_state()
	var reload_validation: Dictionary = reloaded_runtime.validate_current_package()
	var package_validation: Dictionary = reloaded_runtime.get_validate_package_service().validate_path(output_dir, "package")
	var reloaded_workout: Dictionary = Dictionary(reloaded_state.get("workout", {}))
	var reload_passed := bool(load_result.get("ok", false)) \
		and String(reloaded_workout.get("workoutId", "")) == "ab-workout-seeded-smoke" \
		and Array(reloaded_state.get("songs", [])).size() == 1 \
		and Array(reloaded_state.get("charts", [])).size() == 1 \
		and Array(reloaded_state.get("sets", [])).size() == 1 \
		and Array(reloaded_state.get("environments", [])).size() == 1 \
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
