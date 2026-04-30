class_name BuildContentPackageService
extends "../../interfaces/package_build_service.gd"

const ValidatePackageService = preload("../validation/validate_package_service.gd")

var _validate_package_service: ValidatePackageService = ValidatePackageService.new()

func build_package(source_dir: String, output_dir: String) -> Dictionary:
	var validation: Dictionary = _validate_package_service.validate_path(source_dir, "package")
	if not bool(validation.get("valid", false)):
		return {
			"ok": false,
			"sourceDir": source_dir,
			"outputDir": output_dir,
			"validation": validation,
			"copiedFiles": [],
		}

	DirAccess.make_dir_recursive_absolute(output_dir)
	var copied_files: Array = []
	_copy_tree(source_dir, output_dir, copied_files)
	return {
		"ok": true,
		"sourceDir": source_dir,
		"outputDir": output_dir,
		"validation": validation,
		"copiedFiles": copied_files,
	}

func _copy_tree(source_dir: String, output_dir: String, copied_files: Array, relative_path: String = "") -> void:
	var current_source: String = source_dir if relative_path.is_empty() else source_dir.path_join(relative_path)
	var dir := DirAccess.open(current_source)
	if dir == null:
		return
	dir.list_dir_begin()
	while true:
		var name := dir.get_next()
		if name.is_empty():
			break
		if name == "." or name == ".." or name.begins_with("."):
			continue
		var child_relative: String = name if relative_path.is_empty() else relative_path.path_join(name)
		if dir.current_is_dir():
			if name == "cache":
				continue
			DirAccess.make_dir_recursive_absolute(output_dir.path_join(child_relative))
			_copy_tree(source_dir, output_dir, copied_files, child_relative)
		else:
			var source_path: String = source_dir.path_join(child_relative)
			var destination_path: String = output_dir.path_join(child_relative)
			DirAccess.make_dir_recursive_absolute(destination_path.get_base_dir())
			if DirAccess.copy_absolute(source_path, destination_path) == OK:
				copied_files.append(child_relative)
	dir.list_dir_end()
