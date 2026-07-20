class_name BuildContentPackageService
extends "../../interfaces/package_build_service.gd"

const SongPackageValidationService = preload("../validation/song_package_validation_service.gd")

var _validate_package_service: SongPackageValidationService = SongPackageValidationService.new()

func build_package(source_dir: String, output_dir: String) -> Dictionary:
	var validation: Dictionary = _validate_package_service.validate_path(source_dir, "package")
	if not bool(validation.get("valid", false)):
		return {
			"ok": false,
			"sourceDir": source_dir,
			"outputDir": output_dir,
			"zipPath": "%s.zip" % output_dir,
			"validation": validation,
			"copiedFiles": [],
		}

	_remove_tree(output_dir)
	DirAccess.make_dir_recursive_absolute(output_dir)
	var copied_files: Array = []
	_copy_tree(source_dir, output_dir, copied_files)
	var zip_path: String = "%s.zip" % output_dir
	var zip_result: Dictionary = _zip_directory(output_dir, zip_path)
	return {
		"ok": bool(zip_result.get("ok", false)),
		"sourceDir": source_dir,
		"outputDir": output_dir,
		"zipPath": zip_path,
		"validation": validation,
		"copiedFiles": copied_files,
		"zipResult": zip_result,
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

func _zip_directory(source_dir: String, zip_path: String) -> Dictionary:
	DirAccess.remove_absolute(zip_path)
	var zipper := ZIPPacker.new()
	var open_error := zipper.open(zip_path)
	if open_error != OK:
		return {"ok": false, "errorCode": "zip_open_failed", "error": open_error}
	var files: Array = []
	var zip_error: int = _zip_directory_recursive(zipper, source_dir, source_dir, files)
	zipper.close()
	return {
		"ok": zip_error == OK,
		"errorCode": "" if zip_error == OK else "zip_write_failed",
		"error": zip_error,
		"files": files,
	}

func _zip_directory_recursive(zipper: ZIPPacker, root_dir: String, current_dir: String, files: Array) -> int:
	var dir := DirAccess.open(current_dir)
	if dir == null:
		return ERR_CANT_OPEN
	dir.list_dir_begin()
	while true:
		var name := dir.get_next()
		if name.is_empty():
			break
		if name == "." or name == ".." or name.begins_with("."):
			continue
		var absolute_path: String = current_dir.path_join(name)
		if dir.current_is_dir():
			var nested_error: int = _zip_directory_recursive(zipper, root_dir, absolute_path, files)
			if nested_error != OK:
				return nested_error
			continue
		var relative_path: String = absolute_path.trim_prefix(root_dir.path_join(""))
		var start_error := zipper.start_file(relative_path)
		if start_error != OK:
			return start_error
		zipper.write_file(FileAccess.get_file_as_bytes(absolute_path))
		zipper.close_file()
		files.append(relative_path)
	dir.list_dir_end()
	return OK

func _remove_tree(path: String) -> void:
	if not DirAccess.dir_exists_absolute(path):
		return
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
			_remove_tree(child_path)
			DirAccess.remove_absolute(child_path)
		else:
			DirAccess.remove_absolute(child_path)
	dir.list_dir_end()
	DirAccess.remove_absolute(path)
