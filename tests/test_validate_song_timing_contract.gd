extends RefCounted

const ValidatePackageService = preload("../services/validation/validate_package_service.gd")

static func run() -> Dictionary:
	var base_fixture_dir: String = _fixture_dir("package_minimal_boxing")
	var invalid_dir: String = ProjectSettings.globalize_path("res://tmp/validate_song_timing_contract_invalid")
	_ensure_clean_dir(invalid_dir)
	_copy_tree(base_fixture_dir, invalid_dir)
	_write_json(invalid_dir.path_join("songs/song-demo.json"), {
		"schema": "aerobeat.content.song.v1",
		"songId": "song_demo",
		"songName": "Demo Song",
		"durationSec": 180,
		"audio": {
			"resourcePath": "audio/demo-song.ogg"
		},
		"timing": {
			"anchorMs": 0,
			"bpm": 128,
			"tempoSegments": [
				{"startBeat": 0, "bpm": 128}
			],
			"stopSegments": [],
			"timeSignatureSegments": [
				{"startBeat": 0, "numerator": 4, "denominator": 4}
			]
		}
	})

	var report: Dictionary = ValidatePackageService.new().validate_path(invalid_dir)
	var issue_codes := _issue_codes(report.get("issues", []))
	var passed := not bool(report.get("valid", true)) \
		and issue_codes.has("song_timing_bpm_shortcut_forbidden")
	return {
		"name": "test_validate_song_timing_contract",
		"passed": passed,
		"details": {
			"fixtureDir": invalid_dir,
			"report": report,
			"issueCodes": issue_codes,
		},
	}

static func _fixture_dir(name: String) -> String:
	return ProjectSettings.globalize_path("res://../../aerobeat-content-core/fixtures/%s" % name)

static func _issue_codes(issues: Array) -> Array:
	var codes: Array = []
	for issue in issues:
		codes.append(String(issue.get("code", "")))
	return codes

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
