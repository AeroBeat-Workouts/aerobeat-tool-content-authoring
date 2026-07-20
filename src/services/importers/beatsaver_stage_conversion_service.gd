class_name BeatSaverStageConversionService
extends RefCounted

const STAGE_MANIFEST_NAME := "source_material_manifest.json"
const BOXING_INTERVAL_MS_BY_DIFFICULTY := {
	"Easy": 1500,
	"Normal": 1250,
	"Hard": 1000,
	"Expert": 750,
	"ExpertPlus": 500,
}
const CENTER_GUARD_CELL_SETS := {
	"1,2": true,
	"5,6": true,
	"9,10": true,
}
const LEFT_SIDE_CELLS := {0: true, 1: true, 4: true, 5: true, 8: true, 9: true}
const RIGHT_SIDE_CELLS := {2: true, 3: true, 6: true, 7: true, 10: true, 11: true}

func convert_stage(stage_dir: String, options: Dictionary = {}) -> Dictionary:
	var absolute_stage_dir := ProjectSettings.globalize_path(stage_dir).simplify_path()
	var manifest_path := absolute_stage_dir.path_join(STAGE_MANIFEST_NAME)
	if not FileAccess.file_exists(manifest_path):
		return _error("stage_manifest_missing", "Missing staged BeatSaver manifest: %s" % manifest_path)
	var manifest_parse := _read_json_file(manifest_path)
	if not bool(manifest_parse.get("ok", false)):
		return _error("stage_manifest_invalid", "Could not parse staged BeatSaver manifest.", {"manifestPath": manifest_path, "parse": manifest_parse})
	var manifest: Dictionary = Dictionary(manifest_parse.get("data", {}))
	var archive_path := _resolve_archive_path(absolute_stage_dir, manifest)
	if archive_path.is_empty() or not FileAccess.file_exists(archive_path):
		return _error("archive_missing", "Could not resolve staged BeatSaver archive.", {"archivePath": archive_path, "stageDir": absolute_stage_dir})
	var archive := ZIPReader.new()
	var open_error := archive.open(archive_path)
	if open_error != OK:
		return _error("archive_open_failed", "Failed to open staged BeatSaver archive.", {"archivePath": archive_path, "error": error_string(open_error)})

	var info_dat_path := _resolve_info_dat_path(manifest, archive)
	if info_dat_path.is_empty():
		archive.close()
		return _error("info_dat_missing", "The staged BeatSaver archive does not contain Info.dat.")
	var info_parse := _read_archive_json(archive, info_dat_path)
	if not bool(info_parse.get("ok", false)):
		archive.close()
		return _error("info_dat_invalid", "Could not parse Info.dat from staged BeatSaver archive.", {"path": info_dat_path, "parse": info_parse})
	var info_dat: Dictionary = Dictionary(info_parse.get("data", {}))

	var standard_difficulties := _select_standard_difficulties(manifest, info_dat)
	if standard_difficulties.is_empty():
		archive.close()
		return _error("standard_difficulty_missing", "No Standard BeatSaver difficulty entries were found in the staged source.")

	var package_token := _slug(String(manifest.get("map_key", manifest.get("map_id", "beatsaver-stage"))))
	if package_token.is_empty():
		package_token = "beatsaver-stage"
	var song_name := _resolve_song_name(manifest, info_dat)
	var song_token := _slug(song_name if not song_name.is_empty() else package_token)
	if song_token.is_empty():
		song_token = package_token
	var extraction_root := _prepare_conversion_workspace(package_token)
	var audio_entry_path := _resolve_song_filename(manifest, info_dat)
	var extracted_audio_path := ""
	if not audio_entry_path.is_empty():
		extracted_audio_path = extraction_root.path_join("audio").path_join(audio_entry_path.get_file())
		_extract_archive_file(archive, audio_entry_path, extracted_audio_path)

	var audio_extension := audio_entry_path.get_extension().to_lower()
	if audio_extension.is_empty():
		audio_extension = "ogg"
	var authored_audio_relative_path := "media/audio/%s.%s" % [song_token, audio_extension]
	var draft_asset_sources := {}
	if not extracted_audio_path.is_empty() and FileAccess.file_exists(extracted_audio_path):
		draft_asset_sources[authored_audio_relative_path] = extracted_audio_path
	var archive_copy_path := extraction_root.path_join(archive_path.get_file())
		
	DirAccess.make_dir_recursive_absolute(archive_copy_path.get_base_dir())
	DirAccess.copy_absolute(archive_path, archive_copy_path)
	draft_asset_sources[".artifacts/beatsaver/source/%s" % archive_path.get_file()] = archive_copy_path

	var charts: Array = []
	var sets: Array = []
	var set_ids: Array = []
	var boxing_trace: Array = []
	var flow_trace: Array = []
	var conversion_warnings: Array = []

	for difficulty_entry_variant in standard_difficulties:
		var difficulty_entry: Dictionary = Dictionary(difficulty_entry_variant)
		var difficulty_path := String(difficulty_entry.get("path", "")).strip_edges()
		if difficulty_path.is_empty():
			continue
		var beatmap_parse := _read_archive_json(archive, difficulty_path)
		if not bool(beatmap_parse.get("ok", false)):
			archive.close()
			return _error("difficulty_parse_failed", "Could not parse BeatSaver difficulty file.", {"path": difficulty_path, "parse": beatmap_parse})
		var beatmap: Dictionary = Dictionary(beatmap_parse.get("data", {}))
		var version_text := _beatmap_version(beatmap)
		if not version_text.begins_with("3") and not version_text.begins_with("4"):
			archive.close()
			return _error("unsupported_beatmap_version", "Only BeatSaver v3/v4 Standard maps are supported by this first converter foundation.", {"path": difficulty_path, "version": version_text})

		var difficulty_label := _normalize_difficulty_label(String(difficulty_entry.get("difficulty", "Normal")))
		var source_summary := _normalize_source_summary(beatmap)
		var boxing_chart := _convert_boxing_chart(source_summary, difficulty_label, song_token)
		var flow_chart := _convert_flow_chart(source_summary, difficulty_label, song_token)
		charts.append(boxing_chart.get("chart"))
		charts.append(flow_chart.get("chart"))
		boxing_trace.append(boxing_chart.get("trace"))
		flow_trace.append(flow_chart.get("trace"))

		for chart_record_variant in [boxing_chart.get("chart"), flow_chart.get("chart")]:
			var chart_record: Dictionary = Dictionary(chart_record_variant)
			var set_id := "ab-set-%s-%s-%s" % [song_token, String(chart_record.get("feature", "chart")), String(chart_record.get("difficulty", "normal")).to_lower()]
			set_ids.append(set_id)
			sets.append({
				"schemaId": "aerobeat.set.v1",
				"schemaVersion": 1,
				"recordVersion": 1,
				"setId": set_id,
				"setName": "%s %s %s" % [_titleize(song_token), String(chart_record.get("difficulty", "Normal")), _titleize(String(chart_record.get("feature", "chart")))],
				"songId": "ab-song-%s" % song_token,
				"chartId": String(chart_record.get("chartId", "")),
			})

	var draft_text_sources := {
		".artifacts/beatsaver/source/%s" % STAGE_MANIFEST_NAME: JSON.stringify(manifest, "  ") + "\n",
		".artifacts/beatsaver/source/%s" % info_dat_path: JSON.stringify(info_dat, "  ") + "\n",
		".artifacts/beatsaver/conversion/report.json": JSON.stringify({
			"source": {
				"provider": String(manifest.get("provider", "beatsaver")),
				"mapId": String(manifest.get("map_id", "")),
				"mapKey": String(manifest.get("map_key", "")),
				"mapName": String(manifest.get("map_name", "")),
				"archivePath": archive_path,
				"stageDir": absolute_stage_dir,
			},
			"warnings": conversion_warnings,
			"boxing": boxing_trace,
			"flow": flow_trace,
		}, "  ") + "\n",
	}
	for difficulty_entry_variant in standard_difficulties:
		var difficulty_entry: Dictionary = Dictionary(difficulty_entry_variant)
		var difficulty_path := String(difficulty_entry.get("path", "")).strip_edges()
		if difficulty_path.is_empty():
			continue
		var raw_text := archive.read_file(difficulty_path).get_string_from_utf8()
		draft_text_sources[".artifacts/beatsaver/source/%s" % difficulty_path] = raw_text + ("\n" if not raw_text.ends_with("\n") else "")
	archive.close()

	var bpm := _resolve_bpm(info_dat, manifest)
	var duration_sec := _estimate_song_duration_sec_from_charts(charts, bpm)
	if song_name.is_empty():
		song_name = "Imported BeatSaver Song"
	var song_state := {
		"schemaId": "aerobeat.song.v1",
		"schemaVersion": 1,
		"recordVersion": 1,
		"songId": "ab-song-%s" % song_token,
		"songName": song_name,
		"durationSec": duration_sec,
		"audio": {"filePath": authored_audio_relative_path},
		"timing": {
			"anchorMs": 0,
			"tempoSegments": [{"startBeat": 0, "bpm": bpm}],
			"stopSegments": [],
			"timeSignatureSegments": [{"startBeat": 0, "numerator": 4, "denominator": 4}],
		},
	}
	return {
		"ok": true,
		"state": {
			"packageVersion": "1.0.0",
			"sourcePackageDir": "",
			"loadedPackageDir": "",
			"passthroughDirectories": [],
			"passthroughFiles": [],
			"draftAssetSources": draft_asset_sources,
			"draftTextSources": draft_text_sources,
			"songPackage": {
				"schemaId": "aerobeat.song-package.v1",
				"schemaVersion": 1,
				"recordVersion": 1,
				"songPackageId": "ab-songpkg-%s-beatsaver-import" % package_token,
				"songPackageName": "%s BeatSaver Import" % song_state.get("songName"),
				"description": "Imported from staged BeatSaver source with authored Boxing output, shared-contract Flow output, and preserved provenance artifacts.",
				"packageVersion": "1.0.0",
				"setIds": set_ids,
			},
			"songs": [song_state],
			"charts": charts,
			"sets": sets,
			"environments": [],
			"coachConfig": {},
			"sqlFiles": [],
		},
		"summary": {
			"chartCount": charts.size(),
			"setCount": sets.size(),
			"difficultyCount": standard_difficulties.size(),
			"warnings": conversion_warnings,
		},
	}

func _convert_boxing_chart(source_summary: Dictionary, difficulty_label: String, song_token: String) -> Dictionary:
	var trace_events: Array = []
	var authored_candidates := {}
	var note_groups := _group_notes_by_start(Array(source_summary.get("colorNotes", [])))
	var next_dual_keep_hand := "right"
	for start_key in note_groups.keys():
		var notes: Array = note_groups[start_key]
		var normalized_group := _collapse_same_hand_clusters(notes)
		var note_trace := {"start": float(start_key), "sourceFamily": "notes", "notes": normalized_group.duplicate(true)}
		if _is_guard_pair(normalized_group):
			_authored_candidate_add(authored_candidates, float(start_key), {"start": float(start_key), "type": "guard", "_priority": 2})
			note_trace["result"] = {"action": "emit", "type": "guard"}
		else:
			var retained := _pick_dual_or_single_retained_note(normalized_group, next_dual_keep_hand)
			if normalized_group.size() > 1:
				note_trace["trackerBefore"] = next_dual_keep_hand
				next_dual_keep_hand = "left" if next_dual_keep_hand == "right" else "right"
				note_trace["trackerAfter"] = next_dual_keep_hand
			if not retained.is_empty():
				var beat_type := _boxing_type_for_row_and_hand(int(retained.get("cell", 0)), String(retained.get("hand", "left")))
				_authored_candidate_add(authored_candidates, float(start_key), {"start": float(start_key), "type": beat_type, "_priority": 1})
				note_trace["result"] = {"action": "emit", "type": beat_type, "retained": retained.duplicate(true)}
		trace_events.append(note_trace)
	for obstacle_trace in _normalize_obstacle_windows(Array(source_summary.get("obstacles", []))):
		var obstacle_start := float(obstacle_trace.get("start", 0.0))
		var left_count := int(obstacle_trace.get("leftCount", 0))
		var right_count := int(obstacle_trace.get("rightCount", 0))
		var obstacle_type := "squat"
		if left_count > right_count:
			obstacle_type = "weave_right"
		elif right_count > left_count:
			obstacle_type = "weave_left"
		_authored_candidate_add(authored_candidates, obstacle_start, {"start": obstacle_start, "type": obstacle_type, "_priority": 1})
		obstacle_trace["result"] = {"action": "emit", "type": obstacle_type}
		trace_events.append(obstacle_trace)
	for bomb in Array(source_summary.get("bombNotes", [])):
		trace_events.append({"start": float(bomb.get("start", 0.0)), "sourceFamily": "bomb", "result": {"action": "artifact_only"}, "bomb": bomb.duplicate(true)})
	for slider in Array(source_summary.get("sliders", [])):
		trace_events.append({"start": float(slider.get("start", 0.0)), "sourceFamily": "slider", "result": {"action": "artifact_only_guidance"}, "slider": slider.duplicate(true)})
	for burst in Array(source_summary.get("burstSliders", [])):
		var emitted := _emit_boxing_burst(burst, difficulty_label)
		for beat in Array(emitted.get("beats", [])):
			var priority_beat: Dictionary = Dictionary(beat).duplicate(true)
			priority_beat["_priority"] = 3
			_authored_candidate_add(authored_candidates, float(priority_beat.get("start", 0.0)), priority_beat)
		trace_events.append({"start": float(burst.get("start", 0.0)), "sourceFamily": "burstSlider", "source": burst.duplicate(true), "result": {"action": "emit", "beats": emitted.get("beats", [])}})
	var beats := _flatten_authored_candidates(authored_candidates)
	return {
		"chart": {
			"schemaId": "aerobeat.chart.boxing.v1",
			"schemaVersion": 1,
			"recordVersion": 1,
			"chartId": "ab-chart-%s-boxing-%s" % [song_token, difficulty_label.to_lower()],
			"chartName": "%s %s Boxing" % [_titleize(song_token), difficulty_label],
			"feature": "boxing",
			"difficulty": difficulty_label,
			"beats": beats,
		},
		"trace": {
			"difficulty": difficulty_label,
			"events": trace_events,
		},
	}

func _convert_flow_chart(source_summary: Dictionary, difficulty_label: String, song_token: String) -> Dictionary:
	var beats: Array = []
	var trace_events: Array = []
	var note_ref_lookup := _build_flow_note_ref_lookup(Array(source_summary.get("colorNotes", [])))
	for note in Array(source_summary.get("colorNotes", [])):
		var note_beat := _emit_flow_note(note)
		beats.append(note_beat)
		trace_events.append({"start": float(note.get("start", 0.0)), "sourceFamily": "note", "result": {"action": "emit", "beat": note_beat.duplicate(true), "noteRef": _flow_note_ref(note)}, "note": note.duplicate(true)})
	for bomb in Array(source_summary.get("bombNotes", [])):
		var bomb_beat := {
			"start": float(bomb.get("start", 0.0)),
			"type": "bomb",
			"placement": int(bomb.get("cell", 0)),
		}
		beats.append(bomb_beat)
		trace_events.append({"start": float(bomb.get("start", 0.0)), "sourceFamily": "bomb", "result": {"action": "emit", "beat": bomb_beat.duplicate(true)}, "bomb": bomb.duplicate(true)})
	for obstacle in Array(source_summary.get("obstacles", [])):
		var cells := _sorted_cell_list(_cells_for_obstacle(obstacle))
		var obstacle_beat := {
			"start": float(obstacle.get("start", 0.0)),
			"end": float(obstacle.get("start", 0.0)) + float(obstacle.get("duration", 0.0)),
			"type": "obstacle",
			"cells": cells,
		}
		beats.append(obstacle_beat)
		trace_events.append({"start": float(obstacle.get("start", 0.0)), "sourceFamily": "obstacle", "result": {"action": "emit", "beat": obstacle_beat.duplicate(true)}, "obstacle": obstacle.duplicate(true)})
	for slider in Array(source_summary.get("sliders", [])):
		var arc_beat := _emit_flow_arc(slider, note_ref_lookup)
		beats.append(arc_beat)
		trace_events.append({"start": float(slider.get("start", 0.0)), "sourceFamily": "slider", "result": {"action": "emit", "beat": arc_beat.duplicate(true)}, "slider": slider.duplicate(true)})
	for burst in Array(source_summary.get("burstSliders", [])):
		var burst_beat := {
			"start": float(burst.get("start", 0.0)),
			"end": float(burst.get("end", burst.get("start", 0.0))),
			"type": "burst",
			"hand": String(burst.get("hand", "left")),
			"placement": int(burst.get("cell", 0)),
			"direction": int(burst.get("direction", 8)),
			"tailPlacement": int(burst.get("tailCell", burst.get("cell", 0))),
			"checkpointCount": max(int(burst.get("sliceCount", 1)), 1),
		}
		if burst.has("spacingBias"):
			burst_beat["spacingBias"] = float(burst.get("spacingBias"))
		beats.append(burst_beat)
		trace_events.append({"start": float(burst.get("start", 0.0)), "sourceFamily": "burstSlider", "result": {"action": "emit", "beat": burst_beat.duplicate(true)}, "source": burst.duplicate(true)})
	_sort_flow_beats(beats)
	return {
		"chart": {
			"schemaId": "aerobeat.chart.flow.v1",
			"schemaVersion": 1,
			"recordVersion": 1,
			"chartId": "ab-chart-%s-flow-%s" % [song_token, difficulty_label.to_lower()],
			"chartName": "%s %s Flow" % [_titleize(song_token), difficulty_label],
			"feature": "flow",
			"difficulty": difficulty_label,
			"beats": beats,
		},
		"trace": {
			"difficulty": difficulty_label,
			"events": trace_events,
		},
	}

func _normalize_source_summary(beatmap: Dictionary) -> Dictionary:
	var version_text := _beatmap_version(beatmap)
	if version_text.begins_with("4"):
		return {
			"colorNotes": _normalize_v4_color_notes(beatmap),
			"bombNotes": _normalize_v4_bomb_notes(beatmap),
			"obstacles": _normalize_v4_obstacles(beatmap),
			"sliders": _normalize_v4_arcs(beatmap),
			"burstSliders": _normalize_v4_chains(beatmap),
		}
	return {
		"colorNotes": _normalize_color_notes(beatmap),
		"bombNotes": _normalize_bomb_notes(beatmap),
		"obstacles": _normalize_obstacles(beatmap),
		"sliders": _normalize_sliders(beatmap),
		"burstSliders": _normalize_burst_sliders(beatmap),
	}

func _normalize_v4_color_notes(beatmap: Dictionary) -> Array:
	var notes: Array = []
	var note_data: Array = _array_value(beatmap, ["colorNotesData"])
	var source_index := 0
	for note_variant in _array_value(beatmap, ["colorNotes"]):
		var note: Dictionary = Dictionary(note_variant)
		var metadata := _v4_metadata_entry(note_data, int(note.get("i", -1)))
		var x := _v4_int_field(note, metadata, "x", 0)
		var y := _v4_int_field(note, metadata, "y", 0)
		var color := _v4_int_field(note, metadata, "c", 0)
		var direction := _v4_int_field(note, metadata, "d", 8)
		var angle_offset := _v4_float_field(note, metadata, "a", 0.0)
		notes.append({
			"sourceIndex": source_index,
			"start": _variant_to_float(note.get("b", 0.0)),
			"x": x,
			"y": y,
			"cell": _cell_from_xy(x, y),
			"color": color,
			"hand": _hand_from_color(color),
			"direction": direction,
			"angleOffset": angle_offset,
			"hasAngleOffset": note.has("a") or metadata.has("a"),
		})
		source_index += 1
	return notes

func _normalize_v4_bomb_notes(beatmap: Dictionary) -> Array:
	var bombs: Array = []
	var bomb_data: Array = _array_value(beatmap, ["bombNotesData"])
	for bomb_variant in _array_value(beatmap, ["bombNotes"]):
		var bomb: Dictionary = Dictionary(bomb_variant)
		var metadata := _v4_metadata_entry(bomb_data, int(bomb.get("i", -1)))
		var x := _v4_int_field(bomb, metadata, "x", 0)
		var y := _v4_int_field(bomb, metadata, "y", 0)
		bombs.append({
			"start": _variant_to_float(bomb.get("b", 0.0)),
			"x": x,
			"y": y,
			"cell": _cell_from_xy(x, y),
		})
	return bombs

func _normalize_v4_obstacles(beatmap: Dictionary) -> Array:
	var obstacles: Array = []
	var obstacle_data: Array = _array_value(beatmap, ["obstaclesData"])
	for obstacle_variant in _array_value(beatmap, ["obstacles"]):
		var obstacle: Dictionary = Dictionary(obstacle_variant)
		var metadata := _v4_metadata_entry(obstacle_data, int(obstacle.get("i", -1)))
		obstacles.append({
			"start": _variant_to_float(obstacle.get("b", 0.0)),
			"duration": _v4_float_field(obstacle, metadata, "d", 0.0),
			"x": _v4_int_field(obstacle, metadata, "x", 0),
			"y": _v4_int_field(obstacle, metadata, "y", 0),
			"width": _v4_int_field(obstacle, metadata, "w", 1),
			"height": _v4_int_field(obstacle, metadata, "h", 1),
		})
	return obstacles

func _normalize_v4_arcs(beatmap: Dictionary) -> Array:
	var arcs: Array = []
	var note_data: Array = _array_value(beatmap, ["colorNotesData"])
	var arc_data: Array = _array_value(beatmap, ["arcsData"])
	for arc_variant in _array_value(beatmap, ["arcs"]):
		var arc: Dictionary = Dictionary(arc_variant)
		var head_metadata := _v4_metadata_entry(note_data, int(arc.get("hi", -1)))
		var tail_metadata := _v4_metadata_entry(note_data, int(arc.get("ti", -1)))
		var metadata := _v4_metadata_entry(arc_data, int(arc.get("ai", -1)))
		var color := _v4_int_field(head_metadata, {}, "c", 0)
		arcs.append({
			"start": _variant_to_float(arc.get("hb", 0.0)),
			"end": _variant_to_float(arc.get("tb", arc.get("hb", 0.0))),
			"cell": _cell_from_xy(_v4_int_field(head_metadata, {}, "x", 0), _v4_int_field(head_metadata, {}, "y", 0)),
			"tailCell": _cell_from_xy(_v4_int_field(tail_metadata, {}, "x", 0), _v4_int_field(tail_metadata, {}, "y", 0)),
			"hand": _hand_from_color(color),
			"direction": _v4_int_field(head_metadata, {}, "d", 8),
			"tailDirection": _v4_int_field(tail_metadata, {}, "d", 8),
			"headCurveMultiplier": _v4_float_field(metadata, {}, "m", 1.0),
			"tailCurveMultiplier": _v4_float_field(metadata, {}, "tm", 1.0),
			"midAnchorMode": _v4_int_field(metadata, {}, "a", 0),
		})
	return arcs

func _normalize_v4_chains(beatmap: Dictionary) -> Array:
	var bursts: Array = []
	var note_data: Array = _array_value(beatmap, ["colorNotesData"])
	var chain_data: Array = _array_value(beatmap, ["chainsData"])
	for chain_variant in _array_value(beatmap, ["chains"]):
		var chain: Dictionary = Dictionary(chain_variant)
		var head_metadata := _v4_metadata_entry(note_data, int(chain.get("i", -1)))
		var metadata := _v4_metadata_entry(chain_data, int(chain.get("ci", -1)))
		var color := _v4_int_field(head_metadata, {}, "c", 0)
		var normalized := {
			"start": _variant_to_float(chain.get("hb", 0.0)),
			"end": _variant_to_float(chain.get("tb", chain.get("hb", 0.0))),
			"cell": _cell_from_xy(_v4_int_field(head_metadata, {}, "x", 0), _v4_int_field(head_metadata, {}, "y", 0)),
			"tailCell": _cell_from_xy(_v4_int_field(metadata, {}, "tx", 0), _v4_int_field(metadata, {}, "ty", 0)),
			"hand": _hand_from_color(color),
			"direction": _v4_int_field(head_metadata, {}, "d", 8),
			"sliceCount": max(_v4_int_field(metadata, {}, "c", 1), 1),
		}
		if metadata.has("s"):
			normalized["spacingBias"] = _variant_to_float(metadata.get("s"))
		bursts.append(normalized)
	return bursts

func _normalize_color_notes(beatmap: Dictionary) -> Array:
	var notes: Array = []
	var source_index := 0
	for note_variant in _array_value(beatmap, ["colorNotes"]):
		var note: Dictionary = Dictionary(note_variant)
		var cell := _cell_from_xy(int(note.get("x", 0)), int(note.get("y", 0)))
		notes.append({
			"sourceIndex": source_index,
			"start": _variant_to_float(note.get("b", 0.0)),
			"x": int(note.get("x", 0)),
			"y": int(note.get("y", 0)),
			"cell": cell,
			"color": int(note.get("c", 0)),
			"hand": _hand_from_color(int(note.get("c", 0))),
			"direction": int(note.get("d", 8)),
			"angleOffset": _variant_to_float(note.get("a", 0.0)),
			"hasAngleOffset": note.has("a"),
		})
		source_index += 1
	return notes

func _normalize_bomb_notes(beatmap: Dictionary) -> Array:
	var bombs: Array = []
	for bomb_variant in _array_value(beatmap, ["bombNotes"]):
		var bomb: Dictionary = Dictionary(bomb_variant)
		bombs.append({
			"start": _variant_to_float(bomb.get("b", 0.0)),
			"x": int(bomb.get("x", 0)),
			"y": int(bomb.get("y", 0)),
			"cell": _cell_from_xy(int(bomb.get("x", 0)), int(bomb.get("y", 0))),
		})
	return bombs

func _normalize_obstacles(beatmap: Dictionary) -> Array:
	var obstacles: Array = []
	for obstacle_variant in _array_value(beatmap, ["obstacles"]):
		var obstacle: Dictionary = Dictionary(obstacle_variant)
		obstacles.append({
			"start": _variant_to_float(obstacle.get("b", 0.0)),
			"duration": _variant_to_float(obstacle.get("d", 0.0)),
			"x": int(obstacle.get("x", 0)),
			"y": int(obstacle.get("y", 0)),
			"width": int(obstacle.get("w", 1)),
			"height": int(obstacle.get("h", 1)),
		})
	return obstacles

func _normalize_sliders(beatmap: Dictionary) -> Array:
	var sliders: Array = []
	for slider_variant in _array_value(beatmap, ["sliders"]):
		var slider: Dictionary = Dictionary(slider_variant)
		sliders.append({
			"start": _variant_to_float(slider.get("b", 0.0)),
			"end": _variant_to_float(slider.get("tb", slider.get("b", 0.0))),
			"cell": _cell_from_xy(int(slider.get("x", 0)), int(slider.get("y", 0))),
			"tailCell": _cell_from_xy(int(slider.get("tx", 0)), int(slider.get("ty", 0))),
			"hand": _hand_from_color(int(slider.get("c", 0))),
			"direction": int(slider.get("d", 8)),
			"tailDirection": int(slider.get("tc", slider.get("d", 8))),
			"headCurveMultiplier": _variant_to_float(slider.get("mu", 1.0), 1.0),
			"tailCurveMultiplier": _variant_to_float(slider.get("tmu", 1.0), 1.0),
			"midAnchorMode": int(slider.get("m", 0)),
		})
	return sliders

func _normalize_burst_sliders(beatmap: Dictionary) -> Array:
	var bursts: Array = []
	for burst_variant in _array_value(beatmap, ["burstSliders"]):
		var burst: Dictionary = Dictionary(burst_variant)
		var normalized := {
			"start": _variant_to_float(burst.get("b", 0.0)),
			"end": _variant_to_float(burst.get("tb", burst.get("b", 0.0))),
			"cell": _cell_from_xy(int(burst.get("x", 0)), int(burst.get("y", 0))),
			"tailCell": _cell_from_xy(int(burst.get("tx", 0)), int(burst.get("ty", 0))),
			"hand": _hand_from_color(int(burst.get("c", 0))),
			"direction": int(burst.get("d", 8)),
			"sliceCount": max(int(burst.get("sc", 1)), 1),
		}
		if burst.has("s"):
			normalized["spacingBias"] = _variant_to_float(burst.get("s"))
		bursts.append(normalized)
	return bursts

func _normalize_obstacle_windows(obstacles: Array) -> Array:
	var windows: Array = []
	for obstacle_variant in obstacles:
		var obstacle: Dictionary = Dictionary(obstacle_variant)
		var occupied_cells := _cells_for_obstacle(obstacle)
		var merged := false
		for index in range(windows.size()):
			var window: Dictionary = Dictionary(windows[index])
			var window_start := _variant_to_float(window.get("start", 0.0))
			var window_end := _variant_to_float(window.get("end", 0.0))
			var obstacle_start := _variant_to_float(obstacle.get("start", 0.0))
			var obstacle_end := obstacle_start + _variant_to_float(obstacle.get("duration", 0.0))
			if obstacle_start > window_end or obstacle_end < window_start:
				continue
			window["start"] = min(window_start, obstacle_start)
			window["end"] = max(window_end, obstacle_end)
			var merged_cells: Dictionary = Dictionary(window.get("occupiedCells", {})).duplicate(true)
			for cell_key in occupied_cells.keys():
				merged_cells[int(cell_key)] = true
			window["occupiedCells"] = merged_cells
			windows[index] = window
			merged = true
			break
		if not merged:
			windows.append({
				"sourceFamily": "obstacle",
				"start": _variant_to_float(obstacle.get("start", 0.0)),
				"end": _variant_to_float(obstacle.get("start", 0.0)) + _variant_to_float(obstacle.get("duration", 0.0)),
				"occupiedCells": occupied_cells,
			})
	for index in range(windows.size()):
		var window: Dictionary = Dictionary(windows[index])
		var left_count := 0
		var right_count := 0
		for cell_key in Dictionary(window.get("occupiedCells", {})).keys():
			var cell := int(cell_key)
			if LEFT_SIDE_CELLS.has(cell):
				left_count += 1
			if RIGHT_SIDE_CELLS.has(cell):
				right_count += 1
		window["leftCount"] = left_count
		window["rightCount"] = right_count
		windows[index] = window
	return windows

func _emit_boxing_burst(burst: Dictionary, difficulty_label: String) -> Dictionary:
	var beats: Array = []
	var start := _variant_to_float(burst.get("start", 0.0))
	var finish := max(_variant_to_float(burst.get("end", start)), start)
	var interval_ms := int(BOXING_INTERVAL_MS_BY_DIFFICULTY.get(difficulty_label, 1000))
	var interval_beats := (float(interval_ms) / 1000.0) * (120.0 / 60.0)
	if interval_beats <= 0.0:
		interval_beats = 1.0
	var emitted_hand := String(burst.get("hand", "left"))
	var time := start
	while time <= finish + 0.0001:
		var alpha := 0.0 if finish <= start else clampf((time - start) / (finish - start), 0.0, 1.0)
		var sample_y := lerpf(_cell_y(int(burst.get("cell", 0))), _cell_y(int(burst.get("tailCell", 0))), alpha)
		var row := _row_from_y(sample_y)
		beats.append({
			"start": snappedf(time, 0.001),
			"type": _boxing_type_for_row_and_hand(_cell_from_xy(0, row), emitted_hand),
		})
		emitted_hand = "right" if emitted_hand == "left" else "left"
		time += interval_beats
	return {"beats": beats}

func _emit_flow_note(note: Dictionary) -> Dictionary:
	var direction := int(note.get("direction", 8))
	var beat := {
		"start": float(note.get("start", 0.0)),
		"type": "note",
		"hand": String(note.get("hand", "left")),
		"placement": int(note.get("cell", 0)),
		"requiresDirection": direction != 8,
		"angleOffset": float(note.get("angleOffset", 0.0)),
	}
	if direction != 8:
		beat["direction"] = direction
	return beat

func _emit_flow_arc(slider: Dictionary, note_ref_lookup: Dictionary) -> Dictionary:
	var arc := {
		"start": float(slider.get("start", 0.0)),
		"end": float(slider.get("end", slider.get("start", 0.0))),
		"type": "arc",
		"hand": String(slider.get("hand", "left")),
		"startPlacement": int(slider.get("cell", 0)),
		"endPlacement": int(slider.get("tailCell", slider.get("cell", 0))),
		"startDirection": int(slider.get("direction", 8)),
		"endDirection": int(slider.get("tailDirection", slider.get("direction", 8))),
		"headCurveMultiplier": float(slider.get("headCurveMultiplier", 1.0)),
		"tailCurveMultiplier": float(slider.get("tailCurveMultiplier", 1.0)),
		"midAnchorMode": int(slider.get("midAnchorMode", 0)),
	}
	var start_key := _flow_note_lookup_key(float(slider.get("start", 0.0)), String(slider.get("hand", "left")), int(slider.get("cell", 0)))
	if note_ref_lookup.has(start_key):
		arc["startNoteRef"] = String(note_ref_lookup[start_key])
	var end_key := _flow_note_lookup_key(float(slider.get("end", slider.get("start", 0.0))), String(slider.get("hand", "left")), int(slider.get("tailCell", slider.get("cell", 0))))
	if note_ref_lookup.has(end_key):
		arc["endNoteRef"] = String(note_ref_lookup[end_key])
	return arc

func _build_flow_note_ref_lookup(notes: Array) -> Dictionary:
	var lookup := {}
	for note_variant in notes:
		var note: Dictionary = Dictionary(note_variant)
		var key := _flow_note_lookup_key(float(note.get("start", 0.0)), String(note.get("hand", "left")), int(note.get("cell", 0)))
		if not lookup.has(key):
			lookup[key] = _flow_note_ref(note)
	return lookup

func _flow_note_lookup_key(start: float, hand: String, cell: int) -> String:
	return "%s|%0.3f|%d" % [hand, snappedf(start, 0.001), cell]

func _flow_note_ref(note: Dictionary) -> String:
	return "flow-note-%03d-%s-%d-%0.3f" % [int(note.get("sourceIndex", 0)), String(note.get("hand", "left")), int(note.get("cell", 0)), snappedf(float(note.get("start", 0.0)), 0.001)]

func _sorted_cell_list(cells_by_key: Dictionary) -> Array:
	var cells: Array = []
	for cell_key in cells_by_key.keys():
		cells.append(int(cell_key))
	cells.sort()
	return cells

func _sort_flow_beats(beats: Array) -> void:
	var order := {"note": 0, "bomb": 1, "obstacle": 2, "arc": 3, "burst": 4}
	beats.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var a_start := float(a.get("start", 0.0))
		var b_start := float(b.get("start", 0.0))
		if not is_equal_approx(a_start, b_start):
			return a_start < b_start
		var a_order := int(order.get(String(a.get("type", "")), 99))
		var b_order := int(order.get(String(b.get("type", "")), 99))
		if a_order != b_order:
			return a_order < b_order
		return JSON.stringify(a, "") < JSON.stringify(b, "")
	)

func _group_notes_by_start(notes: Array) -> Dictionary:
	var grouped := {}
	for note_variant in notes:
		var note: Dictionary = Dictionary(note_variant)
		var key := str(snappedf(_variant_to_float(note.get("start", 0.0)), 0.001))
		if not grouped.has(key):
			grouped[key] = []
		var grouped_notes: Array = Array(grouped[key])
		grouped_notes.append(note.duplicate(true))
		grouped[key] = grouped_notes
	return grouped

func _collapse_same_hand_clusters(notes: Array) -> Array:
	var by_hand := {}
	for note_variant in notes:
		var note: Dictionary = Dictionary(note_variant)
		var hand := String(note.get("hand", "left"))
		if not by_hand.has(hand):
			by_hand[hand] = []
		var hand_entries: Array = Array(by_hand[hand])
		hand_entries.append(note)
		by_hand[hand] = hand_entries
	var normalized: Array = []
	for hand_variant in by_hand.keys():
		var hand_notes: Array = Array(by_hand[hand_variant])
		var dominant_row := _dominant_same_hand_cluster_row(hand_notes)
		hand_notes.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
			var a_row := _row_from_cell(int(a.get("cell", 0)))
			var b_row := _row_from_cell(int(b.get("cell", 0)))
			if a_row == dominant_row and b_row != dominant_row:
				return true
			if b_row == dominant_row and a_row != dominant_row:
				return false
			if a_row == b_row:
				return int(a.get("cell", 0)) < int(b.get("cell", 0))
			return a_row < b_row
		)
		normalized.append(Dictionary(hand_notes[0]).duplicate(true))
	normalized.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return String(a.get("hand", "left")) < String(b.get("hand", "left"))
	)
	return normalized

func _dominant_same_hand_cluster_row(notes: Array) -> int:
	var row_counts := {0: 0, 1: 0, 2: 0}
	for note_variant in notes:
		var note: Dictionary = Dictionary(note_variant)
		var row := _row_from_cell(int(note.get("cell", 0)))
		row_counts[row] = int(row_counts.get(row, 0)) + 1
	var best_row := 2
	var best_count := -1
	for row in [0, 1, 2]:
		var count := int(row_counts.get(row, 0))
		if count > best_count:
			best_count = count
			best_row = row
	return best_row

func _is_guard_pair(notes: Array) -> bool:
	if notes.size() != 2:
		return false
	var cells := [int(Dictionary(notes[0]).get("cell", 0)), int(Dictionary(notes[1]).get("cell", 0))]
	cells.sort()
	return CENTER_GUARD_CELL_SETS.has("%d,%d" % [cells[0], cells[1]])

func _pick_dual_or_single_retained_note(notes: Array, next_dual_keep_hand: String) -> Dictionary:
	if notes.is_empty():
		return {}
	if notes.size() == 1:
		return Dictionary(notes[0]).duplicate(true)
	for note_variant in notes:
		var note: Dictionary = Dictionary(note_variant)
		if String(note.get("hand", "left")) == next_dual_keep_hand:
			return note.duplicate(true)
	return Dictionary(notes[0]).duplicate(true)

func _authored_candidate_add(candidates: Dictionary, start: float, beat: Dictionary) -> void:
	var key := str(snappedf(start, 0.001))
	if not candidates.has(key):
		candidates[key] = []
	var bucket: Array = Array(candidates[key])
	bucket.append(beat)
	candidates[key] = bucket

func _flatten_authored_candidates(candidates: Dictionary) -> Array:
	var keys: Array = candidates.keys()
	keys.sort_custom(func(a: String, b: String) -> bool:
		return float(a) < float(b)
	)
	var beats: Array = []
	for key_variant in keys:
		var options: Array = Array(candidates[key_variant])
		options.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
			return int(a.get("_priority", 0)) > int(b.get("_priority", 0))
		)
		var chosen: Dictionary = Dictionary(options[0]).duplicate(true)
		chosen.erase("_priority")
		beats.append(chosen)
	return beats

func _boxing_type_for_row_and_hand(cell: int, hand: String) -> String:
	var row := _row_from_cell(cell)
	if row <= 0:
		return "uppercut_%s" % hand
	if row == 1:
		return "straight_%s" % hand
	return "hook_%s" % hand

func _row_from_cell(cell: int) -> int:
	return int(cell / 4)

func _row_from_y(y: float) -> int:
	if y >= 1.5:
		return 2
	if y >= 0.5:
		return 1
	return 0

func _cell_from_xy(x: int, y: int) -> int:
	return clampi(y, 0, 2) * 4 + clampi(x, 0, 3)

func _cell_y(cell: int) -> int:
	return int(cell / 4)

func _v4_metadata_entry(entries: Array, index: int) -> Dictionary:
	if index < 0 or index >= entries.size():
		return {}
	return Dictionary(entries[index])

func _v4_int_field(primary: Dictionary, fallback: Dictionary, key: String, default_value: int) -> int:
	if primary.has(key):
		return int(primary.get(key, default_value))
	if fallback.has(key):
		return int(fallback.get(key, default_value))
	return default_value

func _v4_float_field(primary: Dictionary, fallback: Dictionary, key: String, default_value: float) -> float:
	if primary.has(key):
		return _variant_to_float(primary.get(key), default_value)
	if fallback.has(key):
		return _variant_to_float(fallback.get(key), default_value)
	return default_value

func _cells_for_obstacle(obstacle: Dictionary) -> Dictionary:
	var cells := {}
	var x0 := int(obstacle.get("x", 0))
	var y0 := int(obstacle.get("y", 0))
	var width := max(int(obstacle.get("width", 1)), 1)
	var height := max(int(obstacle.get("height", 1)), 1)
	var x_start := clampi(x0, 0, 3)
	var x_end := clampi(x0 + width, 0, 4)
	if x_end <= x_start:
		x_end = min(x_start + 1, 4)
	var y_start := clampi(y0, 0, 2)
	var y_end := clampi(y0 + height, 0, 3)
	if y_end <= y_start:
		y_end = min(y_start + 1, 3)
	for x in range(x_start, x_end):
		for y in range(y_start, y_end):
			cells[_cell_from_xy(x, y)] = true
	return cells

func _resolve_archive_path(stage_dir: String, manifest: Dictionary) -> String:
	var manifest_archive_path := String(manifest.get("archive_path", manifest.get("archivePath", ""))).strip_edges()
	if manifest_archive_path.is_empty():
		return ""
	if manifest_archive_path.is_absolute_path():
		return manifest_archive_path
	return stage_dir.path_join(manifest_archive_path)

func _resolve_info_dat_path(manifest: Dictionary, archive: ZIPReader) -> String:
	var manifest_path := String(manifest.get("info_dat_path", manifest.get("infoDatPath", ""))).strip_edges()
	if not manifest_path.is_empty():
		return manifest_path
	for entry in archive.get_files():
		var path := String(entry)
		if path.get_file().to_lower() == "info.dat":
			return path
	return ""

func _resolve_song_name(manifest: Dictionary, info_dat: Dictionary) -> String:
	var v2_name := String(info_dat.get("_songName", info_dat.get("songName", ""))).strip_edges()
	if not v2_name.is_empty():
		return v2_name
	var song_info: Dictionary = Dictionary(info_dat.get("song", {}))
	var v4_name := String(song_info.get("title", manifest.get("map_name", ""))).strip_edges()
	if not v4_name.is_empty():
		return v4_name
	return String(manifest.get("map_name", "")).strip_edges()

func _resolve_bpm(info_dat: Dictionary, manifest: Dictionary) -> float:
	var legacy_bpm := _info_number(info_dat, ["_beatsPerMinute", "beatsPerMinute"], -1.0)
	if legacy_bpm > 0.0:
		return legacy_bpm
	var audio_info: Dictionary = Dictionary(info_dat.get("audio", {}))
	var v4_bpm := _info_number(audio_info, ["bpm"], -1.0)
	if v4_bpm > 0.0:
		return v4_bpm
	return _variant_to_float(manifest.get("bpm", 120.0), 120.0)

func _resolve_song_filename(manifest: Dictionary, info_dat: Dictionary) -> String:
	var info_song := String(info_dat.get("_songFilename", info_dat.get("songFilename", manifest.get("song_filename", "")))).strip_edges()
	if not info_song.is_empty():
		return info_song
	var audio_info: Dictionary = Dictionary(info_dat.get("audio", {}))
	var v4_song := String(audio_info.get("songFilename", "")).strip_edges()
	if not v4_song.is_empty():
		return v4_song
	for file_variant in Array(manifest.get("audio_files", [])):
		var file_entry: Dictionary = Dictionary(file_variant)
		var path := String(file_entry.get("path", "")).strip_edges()
		if not path.is_empty():
			return path
	return ""

func _select_standard_difficulties(manifest: Dictionary, info_dat: Dictionary) -> Array:
	var selected: Array = []
	for difficulty_variant in Array(manifest.get("difficulty_files", [])):
		var difficulty: Dictionary = Dictionary(difficulty_variant)
		if String(difficulty.get("characteristic", "")).strip_edges() == "Standard":
			selected.append(difficulty.duplicate(true))
	if not selected.is_empty():
		selected.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
			return int(a.get("difficulty_rank", 0)) < int(b.get("difficulty_rank", 0))
		)
		return selected
	for set_variant in Array(info_dat.get("_difficultyBeatmapSets", info_dat.get("difficultyBeatmapSets", []))):
		var set_entry: Dictionary = Dictionary(set_variant)
		var characteristic := String(set_entry.get("_beatmapCharacteristicName", set_entry.get("beatmapCharacteristicName", ""))).strip_edges()
		if characteristic != "Standard":
			continue
		for difficulty_variant in Array(set_entry.get("_difficultyBeatmaps", set_entry.get("difficultyBeatmaps", []))):
			var difficulty_entry: Dictionary = Dictionary(difficulty_variant)
			selected.append({
				"characteristic": characteristic,
				"difficulty": String(difficulty_entry.get("_difficulty", difficulty_entry.get("difficulty", "Normal"))),
				"difficulty_rank": int(difficulty_entry.get("_difficultyRank", difficulty_entry.get("difficultyRank", 0))),
				"path": String(difficulty_entry.get("_beatmapFilename", difficulty_entry.get("beatmapFilename", ""))),
			})
	if selected.is_empty():
		for difficulty_variant in Array(info_dat.get("difficultyBeatmaps", [])):
			var difficulty_entry: Dictionary = Dictionary(difficulty_variant)
			if String(difficulty_entry.get("characteristic", "")).strip_edges() != "Standard":
				continue
			selected.append({
				"characteristic": "Standard",
				"difficulty": String(difficulty_entry.get("difficulty", "Normal")),
				"difficulty_rank": _difficulty_rank_from_label(String(difficulty_entry.get("difficulty", "Normal"))),
				"path": String(difficulty_entry.get("beatmapDataFilename", difficulty_entry.get("path", ""))),
				"lightshowPath": String(difficulty_entry.get("lightshowDataFilename", "")),
			})
	selected.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return int(a.get("difficulty_rank", 0)) < int(b.get("difficulty_rank", 0))
	)
	return selected

func _read_json_file(path: String) -> Dictionary:
	var text := FileAccess.get_file_as_string(path)
	if text.is_empty() and not FileAccess.file_exists(path):
		return {"ok": false, "error": "file_missing"}
	var parsed = JSON.parse_string(text)
	return {"ok": parsed is Dictionary, "data": parsed if parsed is Dictionary else {}, "text": text}

func _read_archive_json(archive: ZIPReader, path: String) -> Dictionary:
	var bytes := archive.read_file(path)
	var text := bytes.get_string_from_utf8()
	var parsed = JSON.parse_string(text)
	return {"ok": parsed is Dictionary, "data": parsed if parsed is Dictionary else {}, "text": text}

func _extract_archive_file(archive: ZIPReader, entry_path: String, output_path: String) -> void:
	DirAccess.make_dir_recursive_absolute(output_path.get_base_dir())
	var file := FileAccess.open(output_path, FileAccess.WRITE)
	if file == null:
		return
	file.store_buffer(archive.read_file(entry_path))
	file.close()

func _prepare_conversion_workspace(package_token: String) -> String:
	var root := ProjectSettings.globalize_path("user://beatsaver_stage_conversion/%s" % package_token)
	if DirAccess.dir_exists_absolute(root):
		_remove_tree(root)
	DirAccess.make_dir_recursive_absolute(root)
	return root

func _remove_tree(path: String) -> void:
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

func _hand_from_color(color: int) -> String:
	return "left" if color == 0 else "right"

func _normalize_difficulty_label(value: String) -> String:
	match value.to_lower():
		"easy":
			return "Easy"
		"medium", "normal":
			return "Normal"
		"hard":
			return "Hard"
		"pro", "expert":
			return "Expert"
		"expertplus", "expert_plus":
			return "ExpertPlus"
		_:
			return value

func _difficulty_rank_from_label(value: String) -> int:
	match _normalize_difficulty_label(value):
		"Easy":
			return 1
		"Normal":
			return 3
		"Hard":
			return 5
		"Expert":
			return 7
		"ExpertPlus":
			return 9
		_:
			return 0

func _beatmap_version(beatmap: Dictionary) -> String:
	return String(beatmap.get("version", beatmap.get("_version", ""))).strip_edges()

func _array_value(data: Dictionary, keys: Array) -> Array:
	for key_variant in keys:
		var key := String(key_variant)
		if data.get(key) is Array:
			return Array(data.get(key))
	return []

func _info_number(data: Dictionary, keys: Array, fallback: float) -> float:
	for key_variant in keys:
		var key := String(key_variant)
		if data.has(key):
			return _variant_to_float(data.get(key), fallback)
	return fallback

func _estimate_song_duration_sec_from_charts(charts: Array, bpm: float) -> int:
	var max_beat := 0.0
	for chart_variant in charts:
		var chart: Dictionary = Dictionary(chart_variant)
		for beat_variant in Array(chart.get("beats", [])):
			var beat: Dictionary = Dictionary(beat_variant)
			var beat_end := _variant_to_float(beat.get("end", beat.get("start", 0.0)))
			max_beat = max(max_beat, beat_end)
	if bpm <= 0.0:
		return max(int(ceili(max_beat)), 1)
	var duration_sec := max_beat * (60.0 / bpm)
	return max(int(ceili(duration_sec)), 1)

func _variant_to_float(value: Variant, fallback: float = 0.0) -> float:
	if value is int or value is float:
		return float(value)
	var text := String(value).strip_edges()
	if text.is_valid_float():
		return text.to_float()
	if text.is_valid_int():
		return float(text.to_int())
	return fallback

func _slug(text: String) -> String:
	var lowered := text.to_lower()
	var result := ""
	for index in range(lowered.length()):
		var ch := lowered.unicode_at(index)
		var char_text := lowered.substr(index, 1)
		var is_alpha := ch >= 97 and ch <= 122
		var is_digit := ch >= 48 and ch <= 57
		if is_alpha or is_digit:
			result += char_text
		elif not result.ends_with("-"):
			result += "-"
	result = result.strip_edges()
	while result.ends_with("-"):
		result = result.left(result.length() - 1)
	while result.begins_with("-"):
		result = result.substr(1)
	return result

func _titleize(token: String) -> String:
	var pieces := token.split("-", false)
	for index in range(pieces.size()):
		var piece := String(pieces[index])
		if piece.is_empty():
			continue
		pieces[index] = piece.substr(0, 1).to_upper() + piece.substr(1)
	return " ".join(pieces)

func _error(code: String, message: String, details: Dictionary = {}) -> Dictionary:
	return {"ok": false, "errorCode": code, "message": message, "details": details}
