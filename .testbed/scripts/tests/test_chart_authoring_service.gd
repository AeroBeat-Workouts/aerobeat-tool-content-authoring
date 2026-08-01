extends RefCounted

const ADDON_CHART_AUTHORING_SERVICE_PATH := "res://addons/aerobeat-tool-content-authoring/src/services/authoring/chart_authoring_service.gd"
const TestSupport = preload("test_support.gd")

static func run() -> Dictionary:
	var fixture_dir: String = _fixture_dir("package_minimal_boxing")
	var output_dir: String = TestSupport.tmp_dir("chart_authoring_service")
	_ensure_clean_dir(output_dir)
	_copy_tree(fixture_dir, output_dir)
	_seed_legacy_routine_fixture(output_dir)

	var chart_input := {
		"packageDir": output_dir,
		"chartId": "chart_demo_boxing_hard",
		"chartName": " Demo Boxing Hard ",
		"songId": "song_demo",
		"routineId": "routine_demo_boxing",
		"mode": " Boxing ",
		"difficulty": " Hard ",
		"interactionFamily": " Gesture 2D ",
		"events": [
			{"beat": 1, "type": "jab_left"},
			{"beat": 2, "type": "cross_right"},
			{"beat": 4, "type": "hook_left"},
		],
	}
	var legacy_result: Dictionary = load(ADDON_CHART_AUTHORING_SERVICE_PATH).new().upsert_record(chart_input)
	var validation: Dictionary = legacy_result.get("validation", {})
	var chart_path: String = output_dir.path_join("charts/song-demo-boxing-hard.json")
	var manifest: Dictionary = _load_json(output_dir.path_join("manifest.json"))
	var routine: Dictionary = _load_json(output_dir.path_join("routines/song-demo-boxing.json"))
	var chart: Dictionary = _load_json(chart_path)
	var song: Dictionary = _load_json(output_dir.path_join("songs/song-demo.json"))
	var manifest_has_chart := _manifest_has_path(manifest.get("charts", []), "charts/song-demo-boxing-hard.json")
	var timing: Dictionary = song.get("timing", {})
	var legacy_passed := bool(legacy_result.get("ok", false)) \
		and FileAccess.file_exists(chart_path) \
		and manifest_has_chart \
		and Array(routine.get("charts", [])).has("chart_demo_boxing_hard") \
		and not routine.has("title") \
		and String(chart.get("difficulty", "")) == "hard" \
		and String(chart.get("interactionFamily", "")) == "gesture_2d" \
		and not chart.has("timing") \
		and int(timing.get("anchorMs", -1)) == 0 \
		and bool(validation.get("valid", false)) \
		and bool(validation.get("skipped", false)) \
		and String(validation.get("subject", "")) == "legacy_manifest_package"

	var current_package_dir: String = TestSupport.tmp_dir("chart_authoring_service_current_package")
	_ensure_clean_dir(current_package_dir)
	_copy_tree(TestSupport.demo_package_dir(), current_package_dir)
	var current_result: Dictionary = load(ADDON_CHART_AUTHORING_SERVICE_PATH).new().upsert_record({
		"packageDir": current_package_dir,
		"chartId": "chart_demo_boxing_hard",
		"chartName": "Demo Boxing Hard",
		"songId": "song_demo_neon_strike",
		"routineId": "routine_legacy_should_not_apply",
		"mode": "boxing",
		"difficulty": "hard",
		"interactionFamily": "gesture_2d",
		"events": [
			{"beat": 1, "type": "jab_left"},
		],
	})
	var current_passed := not bool(current_result.get("ok", false)) \
		and String(current_result.get("error", "")).find("song.package.yaml packages") != -1 \
		and String(current_result.get("expectedPackageContract", "")) == "song.package.yaml" \
		and bool(current_result.get("legacyCompatibilityOnly", false))

	return {
		"name": "test_chart_authoring_service",
		"passed": legacy_passed and current_passed,
		"details": {
			"fixtureDir": fixture_dir,
			"outputDir": output_dir,
			"legacyResult": legacy_result,
			"validation": validation,
			"manifest": manifest,
			"routine": routine,
			"chart": chart,
			"song": song,
			"currentPackageDir": current_package_dir,
			"currentResult": current_result,
		},
	}

static func _fixture_dir(name: String) -> String:
	return ProjectSettings.globalize_path("res://../../aerobeat-content-core/fixtures/%s" % name)

static func _manifest_has_path(entries: Array, expected_path: String) -> bool:
	for entry in entries:
		if String(entry.get("path", "")) == expected_path:
			return true
	return false

static func _load_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if parsed == null or not (parsed is Dictionary):
		return {}
	return parsed

static func _seed_legacy_routine_fixture(package_dir: String) -> void:
	var manifest_path: String = package_dir.path_join("manifest.json")
	var manifest: Dictionary = _load_json(manifest_path)
	manifest["routines"] = [{"path": "routines/song-demo-boxing.json"}]
	_write_json(package_dir.path_join("routines/song-demo-boxing.json"), {
		"schema": "aerobeat.content.routine.v1",
		"routineId": "routine_demo_boxing",
		"songId": "song_demo",
		"mode": "boxing",
		"charts": ["chart_demo_boxing_medium"],
	})
	_write_json(manifest_path, manifest)

static func _write_json(path: String, data: Dictionary) -> void:
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify(data, "  ") + "\n")

static func _ensure_clean_dir(path: String) -> void:
	var absolute_path: String = ProjectSettings.globalize_path(path)
	if DirAccess.dir_exists_absolute(absolute_path):
		_delete_tree(absolute_path)
	DirAccess.make_dir_recursive_absolute(absolute_path)

static func _copy_tree(source_path: String, destination_path: String) -> void:
	DirAccess.make_dir_recursive_absolute(destination_path)
	var source_dir := DirAccess.open(source_path)
	if source_dir == null:
		return
	source_dir.list_dir_begin()
	while true:
		var name := source_dir.get_next()
		if name.is_empty():
			break
		if name == "." or name == "..":
			continue
		var source_child: String = source_path.path_join(name)
		var destination_child: String = destination_path.path_join(name)
		if source_dir.current_is_dir():
			_copy_tree(source_child, destination_child)
		else:
			DirAccess.make_dir_recursive_absolute(destination_child.get_base_dir())
			var source_file := FileAccess.open(source_child, FileAccess.READ)
			var destination_file := FileAccess.open(destination_child, FileAccess.WRITE)
			if source_file != null and destination_file != null:
				destination_file.store_buffer(source_file.get_buffer(source_file.get_length()))
	source_dir.list_dir_end()

static func _delete_tree(path: String) -> void:
	var dir := DirAccess.open(path)
	if dir == null:
		return
	dir.list_dir_begin()
	while true:
		var name := dir.get_next()
		if name.is_empty():
			break
		if name == "." or name == "..":
			continue
		var child_path := path.path_join(name)
		if dir.current_is_dir():
			_delete_tree(child_path)
			DirAccess.remove_absolute(child_path)
		else:
			DirAccess.remove_absolute(child_path)
	dir.list_dir_end()
