extends RefCounted

static func demo_package_dir() -> String:
	return ProjectSettings.globalize_path("res://../../aerobeat-content-core/fixtures/song_package_yaml_valid_splat")

static func tmp_root_dir() -> String:
	return ProjectSettings.globalize_path("user://content_authoring_testbed")

static func tmp_dir(name: String) -> String:
	return tmp_root_dir().path_join(name)

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

static func expected_beatsaver_matrix_chart_ids(song_token: String, difficulty: String) -> Array:
	var prefix := "ab-chart-%s-boxing-%s" % [song_token, difficulty.to_lower()]
	return [
		"%s-semantic-track-cut-family" % prefix,
		"%s-semantic-track-row-family" % prefix,
		"%s-spatial-grid-cut-family" % prefix,
		"%s-spatial-grid-row-family" % prefix,
		"ab-chart-%s-flow-%s" % [song_token, difficulty.to_lower()],
	]

static func boxing_prototype_matrix_valid(charts: Array) -> bool:
	var identities := {}
	var boxing_count := 0
	for chart_variant in charts:
		var chart: Dictionary = Dictionary(chart_variant)
		if String(chart.get("mode", "")) != "boxing":
			continue
		boxing_count += 1
		var prototype: Dictionary = Dictionary(chart.get("prototype", {}))
		if String(prototype.get("contractId", "")) != "aerobeat.boxing.prototype.v1":
			return false
		for field in ["sourceHash", "recipeHash", "rulesetHash", "contentHash"]:
			if not String(prototype.get(field, "")).begins_with("sha256:"):
				return false
		var identity := "%s|%s" % [prototype.get("recipeId", ""), prototype.get("rulesetId", "")]
		identities[identity] = true
		for beat_variant in Array(chart.get("beats", [])):
			var beat: Dictionary = Dictionary(beat_variant)
			if String(beat.get("eventId", "")).is_empty() or Array(beat.get("sourceEventIds", [])).is_empty():
				return false
			var beat_type := String(beat.get("type", ""))
			if beat_type == "guard":
				if not beat.has("guardTarget") or String(Dictionary(beat.get("checkpoint", {})).get("kind", "")) != "instantaneous":
					return false
			elif beat_type in ["squat", "weave_left", "weave_right"]:
				if String(Dictionary(beat.get("checkpoint", {})).get("kind", "")) != "instantaneous":
					return false
			elif not beat.has("spatialTarget"):
				return false
	return boxing_count == 4 and identities.size() == 4 \
		and identities.has("row_family_balanced_height_v1|boxing_semantic_track_v1") \
		and identities.has("row_family_balanced_height_v1|boxing_spatial_grid_v1") \
		and identities.has("cut_family_source_height_v1|boxing_semantic_track_v1") \
		and identities.has("cut_family_source_height_v1|boxing_spatial_grid_v1")

static func unique_set_ids(state: Dictionary) -> bool:
	var ids := {}
	for set_variant in Array(state.get("sets", [])):
		ids[String(Dictionary(set_variant).get("setId", ""))] = true
	return ids.size() == Array(state.get("sets", [])).size()
