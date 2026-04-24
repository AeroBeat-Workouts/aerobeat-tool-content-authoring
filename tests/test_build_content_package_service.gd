extends RefCounted

const BuildContentPackageService = preload("../services/packaging/build_content_package_service.gd")

static func run() -> Dictionary:
	var fixture_dir: String = _fixture_dir("package_minimal_boxing")
	var output_dir: String = ProjectSettings.globalize_path("res://tmp/build_content_package_service")
	_ensure_clean_dir(output_dir)
	var result: Dictionary = BuildContentPackageService.new().build_package(fixture_dir, output_dir)
	var manifest_exists := FileAccess.file_exists(output_dir.path_join("manifest.json"))
	var copied_files: Array = result.get("copiedFiles", [])
	var passed := bool(result.get("ok", false)) and manifest_exists and copied_files.has("manifest.json")
	return {
		"name": "test_build_content_package_service",
		"passed": passed,
		"details": {
			"fixtureDir": fixture_dir,
			"outputDir": output_dir,
			"result": result,
		},
	}

static func _fixture_dir(name: String) -> String:
	return ProjectSettings.globalize_path("res://../../aerobeat-content-core/fixtures/%s" % name)

static func _ensure_clean_dir(path: String) -> void:
	var absolute_path: String = ProjectSettings.globalize_path(path)
	if DirAccess.dir_exists_absolute(absolute_path):
		_delete_tree(absolute_path)
	DirAccess.make_dir_recursive_absolute(absolute_path)

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
