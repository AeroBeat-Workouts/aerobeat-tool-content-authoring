class_name BuildContentPackageService
extends "../../interfaces/package_build_service.gd"

const ValidatePackageService = preload("../validation/validate_package_service.gd")

var _validate_package_service: ValidatePackageService = ValidatePackageService.new()

func build_package(source_dir: String, output_dir: String) -> Dictionary:
	var validation: Dictionary = _validate_package_service.validate_path(source_dir)
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
	copied_files.append_array(_copy_entries(source_dir, output_dir, validation.get("manifest", {}).get("songs", [])))
	copied_files.append_array(_copy_entries(source_dir, output_dir, validation.get("manifest", {}).get("routines", [])))
	copied_files.append_array(_copy_entries(source_dir, output_dir, validation.get("manifest", {}).get("charts", [])))
	copied_files.append_array(_copy_entries(source_dir, output_dir, validation.get("manifest", {}).get("workouts", [])))
	var manifest_path: String = source_dir.path_join("manifest.json")
	var output_manifest_path: String = output_dir.path_join("manifest.json")
	DirAccess.make_dir_recursive_absolute(output_manifest_path.get_base_dir())
	var manifest_copy_error: int = DirAccess.copy_absolute(manifest_path, output_manifest_path)
	if manifest_copy_error == OK:
		copied_files.append("manifest.json")
	return {
		"ok": manifest_copy_error == OK,
		"sourceDir": source_dir,
		"outputDir": output_dir,
		"validation": validation,
		"copiedFiles": copied_files,
	}

func _copy_entries(source_dir: String, output_dir: String, manifest_entries: Array) -> Array:
	var copied: Array = []
	for entry in manifest_entries:
		var relative_path: String = String(entry.get("path", ""))
		if relative_path.is_empty():
			continue
		var source_path: String = source_dir.path_join(relative_path)
		var destination_path: String = output_dir.path_join(relative_path)
		DirAccess.make_dir_recursive_absolute(destination_path.get_base_dir())
		if DirAccess.copy_absolute(source_path, destination_path) == OK:
			copied.append(relative_path)
	return copied
