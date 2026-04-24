extends RefCounted

const AeroBeatContentAuthoringCli = preload("../cli/main.gd")
const ValidatePackageService = preload("../services/validation/validate_package_service.gd")

static func run() -> Dictionary:
	var fixture_dir: String = _fixture_dir("package_minimal_boxing")
	var output_dir: String = ProjectSettings.globalize_path("res://tmp/author_command")
	_ensure_clean_dir(output_dir)
	_copy_tree(fixture_dir, output_dir)

	var input_path: String = output_dir.path_join("incoming-chart.json")
	_write_json(input_path, {
		"chartId": "chart_demo_boxing_pro",
		"chartName": "Demo Boxing Pro",
		"songId": "song_demo",
		"routineId": "routine_demo_boxing",
		"mode": "boxing",
		"difficulty": "pro",
		"interactionFamily": "gesture_2d",
		"events": [
			{"beat": 1, "type": "jab_left"},
			{"beat": 2, "type": "cross_right"},
			{"beat": 3, "type": "uppercut_left"},
		],
	})

	var result: Dictionary = AeroBeatContentAuthoringCli.new().run_cli([
		"author",
		"chart",
		"upsert",
		output_dir,
		"--from",
		input_path,
		"--json",
	])
	var validation: Dictionary = ValidatePackageService.new().validate_path(output_dir)
	var chart_path := output_dir.path_join("charts/song-demo-boxing-pro.json")
	var routine: Dictionary = _load_json(output_dir.path_join("routines/song-demo-boxing.json"))
	var passed := bool(result.get("ok", false)) \
		and int(result.get("exitCode", 1)) == 0 \
		and FileAccess.file_exists(chart_path) \
		and Array(routine.get("charts", [])).has("chart_demo_boxing_pro") \
		and not routine.has("title") \
		and bool(validation.get("valid", false))
	return {
		"name": "test_author_command",
		"passed": passed,
		"details": {
			"fixtureDir": fixture_dir,
			"outputDir": output_dir,
			"inputPath": input_path,
			"result": result,
			"validation": validation,
			"routine": routine,
		},
	}

static func _fixture_dir(name: String) -> String:
	return ProjectSettings.globalize_path("res://../../aerobeat-content-core/fixtures/%s" % name)

static func _load_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if parsed == null or not (parsed is Dictionary):
		return {}
	return parsed

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
