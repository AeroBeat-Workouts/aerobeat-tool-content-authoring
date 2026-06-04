class_name RefreshContentIndexService
extends RefCounted

func refresh_index(package_dir: String) -> Dictionary:
	var index := {
		"songs": _find_json_files(package_dir.path_join("songs")),
		"routines": _find_json_files(package_dir.path_join("routines")),
		"charts": _find_json_files(package_dir.path_join("charts")),
		"workouts": _find_json_files(package_dir.path_join("workouts")),
	}
	return {
		"ok": true,
		"packageDir": package_dir,
		"index": index,
	}

func _find_json_files(directory_path: String) -> Array:
	var files: Array = []
	var directory := DirAccess.open(directory_path)
	if directory == null:
		return files
	directory.list_dir_begin()
	while true:
		var name := directory.get_next()
		if name.is_empty():
			break
		if directory.current_is_dir():
			continue
		if name.ends_with(".json"):
			files.append(directory_path.path_join(name))
	directory.list_dir_end()
	files.sort()
	return files
