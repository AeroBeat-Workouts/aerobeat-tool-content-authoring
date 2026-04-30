extends RefCounted

static func demo_package_dir() -> String:
	return ProjectSettings.globalize_path("res://../../aerobeat-docs/docs/examples/workout-packages/demo-neon-boxing-bootcamp")

static func ensure_clean_dir(path: String) -> void:
	var absolute_path: String = ProjectSettings.globalize_path(path)
	if DirAccess.dir_exists_absolute(absolute_path):
		delete_tree(absolute_path)
	DirAccess.make_dir_recursive_absolute(absolute_path)

static func copy_tree(source_path: String, destination_path: String) -> void:
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
			copy_tree(source_child, destination_child)
		else:
			DirAccess.make_dir_recursive_absolute(destination_child.get_base_dir())
			var source_file := FileAccess.open(source_child, FileAccess.READ)
			var destination_file := FileAccess.open(destination_child, FileAccess.WRITE)
			if source_file != null and destination_file != null:
				destination_file.store_buffer(source_file.get_buffer(source_file.get_length()))
	source_dir.list_dir_end()

static func delete_tree(path: String) -> void:
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
			delete_tree(child_path)
			DirAccess.remove_absolute(child_path)
		else:
			DirAccess.remove_absolute(child_path)
	dir.list_dir_end()

static func read_text(path: String) -> String:
	return FileAccess.get_file_as_string(path)

static func write_text(path: String, text: String) -> void:
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file != null:
		file.store_string(text)

static func issue_codes(issues: Array) -> Array:
	var codes: Array = []
	for issue in issues:
		codes.append(String(issue.get("code", "")))
	return codes
