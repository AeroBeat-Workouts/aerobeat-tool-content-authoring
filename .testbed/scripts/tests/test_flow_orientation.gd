extends RefCounted

const Converter = preload("res://addons/aerobeat-tool-content-authoring/src/services/importers/beatsaver_stage_conversion_service.gd")

static func run() -> Dictionary:
	var fixture_path := ProjectSettings.globalize_path("res://../assets/fixtures/flow_orientation_3c9d_easy_v1.json")
	var fixture_value: Variant = JSON.parse_string(FileAccess.get_file_as_string(fixture_path))
	var fixture: Dictionary = Dictionary(fixture_value if fixture_value is Dictionary else {})
	var source: Dictionary = Dictionary(fixture.get("source", {}))
	var expected: Dictionary = Dictionary(fixture.get("expected", {}))
	var source_notes: Array = []
	var expected_placements: Array = []
	for note_variant in Array(fixture.get("notes", [])):
		var note: Dictionary = Dictionary(note_variant)
		source_notes.append({
			"sourceIndex": int(note.get("sourceIndex", 0)),
			"start": float(note.get("beat", 0.0)),
			"x": int(note.get("x", 0)),
			"y": int(note.get("y", 0)),
			"cell": int(note.get("cell", 0)),
			"hand": String(note.get("hand", "left")),
			"direction": int(note.get("direction", 8)),
			"angleOffset": 0.0,
		})
		expected_placements.append(int(note.get("canonicalCell", -1)))
	var converter := Converter.new()
	var exact_summary := {
		"colorNotes": source_notes,
		"bombNotes": [],
		"obstacles": [],
		"sliders": [],
		"burstSliders": [],
	}
	var exact_first: Dictionary = converter._convert_flow_chart(exact_summary, "Easy", "3c9d")
	var exact_second: Dictionary = converter._convert_flow_chart(exact_summary, "Easy", "3c9d")
	var exact_chart: Dictionary = Dictionary(exact_first.get("chart", {}))
	var exact_chart_hash := "sha256:%s" % JSON.stringify(exact_chart).sha256_text()
	var exact_placements: Array = []
	for beat_variant in Array(exact_chart.get("beats", [])):
		exact_placements.append(int(Dictionary(beat_variant).get("placement", -1)))

	var matrix_summary := {
		"colorNotes": [
			{"sourceIndex": 0, "start": 1.0, "cell": 0, "hand": "left", "direction": 1, "angleOffset": 0.0},
			{"sourceIndex": 1, "start": 2.0, "cell": 4, "hand": "right", "direction": 1, "angleOffset": 0.0},
			{"sourceIndex": 2, "start": 3.0, "cell": 8, "hand": "left", "direction": 1, "angleOffset": 0.0},
			{"sourceIndex": 3, "start": 4.0, "cell": 11, "hand": "left", "direction": 1, "angleOffset": 0.0},
		],
		"bombNotes": [{"start": 5.0, "cell": 3}],
		"obstacles": [{"start": 6.0, "duration": 1.0, "x": 1, "y": 0, "width": 2, "height": 1}],
		"sliders": [{"start": 1.0, "end": 4.0, "cell": 0, "tailCell": 11, "hand": "left", "direction": 1, "tailDirection": 5}],
		"burstSliders": [{"start": 7.0, "end": 8.0, "cell": 8, "tailCell": 3, "hand": "left", "direction": 0, "sliceCount": 4}],
	}
	var matrix_result: Dictionary = converter._convert_flow_chart(matrix_summary, "Hard", "orientation-matrix")
	var matrix_beats: Array = Array(Dictionary(matrix_result.get("chart", {})).get("beats", []))
	var matrix_notes := _beats_of_type(matrix_beats, "note")
	var matrix_bomb := _first_beat(matrix_beats, "bomb")
	var matrix_obstacle := _first_beat(matrix_beats, "obstacle")
	var matrix_arc := _first_beat(matrix_beats, "arc")
	var matrix_burst := _first_beat(matrix_beats, "burst")

	var legacy_summary: Dictionary = converter._normalize_source_summary({
		"_version": "2.6.0",
		"_notes": [
			{"_time": 1.0, "_lineIndex": 0, "_lineLayer": 0, "_type": 0, "_cutDirection": 1},
			{"_time": 2.0, "_lineIndex": 0, "_lineLayer": 1, "_type": 0, "_cutDirection": 1},
			{"_time": 3.0, "_lineIndex": 0, "_lineLayer": 2, "_type": 0, "_cutDirection": 1},
		],
	})
	var v3_summary: Dictionary = converter._normalize_source_summary({
		"version": "3.3.0",
		"colorNotes": [
			{"b": 1.0, "x": 0, "y": 0, "c": 0, "d": 1},
			{"b": 2.0, "x": 0, "y": 1, "c": 0, "d": 1},
			{"b": 3.0, "x": 0, "y": 2, "c": 0, "d": 1},
		],
	})
	var v4_summary: Dictionary = converter._normalize_source_summary({
		"version": "4.0.0",
		"colorNotesData": [
			{"x": 0, "y": 0, "c": 0, "d": 1},
			{"x": 0, "y": 1, "c": 0, "d": 1},
			{"x": 0, "y": 2, "c": 0, "d": 1},
		],
		"colorNotes": [{"b": 1.0, "i": 0}, {"b": 2.0, "i": 1}, {"b": 3.0, "i": 2}],
	})
	var normalized_source_cells := [
		_source_cells(legacy_summary),
		_source_cells(v3_summary),
		_source_cells(v4_summary),
	]
	var passed := not fixture.is_empty() \
		and String(source.get("mapId", "")) == "3C9D" \
		and String(source.get("versionHash", "")) == "5662f64a12c76a3dd11a5f6ee22611608cd06760" \
		and String(source.get("characteristic", "")) == "Standard" \
		and String(source.get("difficulty", "")) == "Easy" \
		and String(source.get("coordinateConvention", "")) == "beat_saber_bottom_left_row_major" \
		and JSON.stringify(exact_first) == JSON.stringify(exact_second) \
		and exact_chart_hash == String(expected.get("flowChartHash", "")) \
		and exact_placements == expected_placements \
		and float(Dictionary(Array(exact_chart.get("beats", []))[0]).get("start", 0.0)) == 21.0 \
		and int(Dictionary(Array(exact_chart.get("beats", []))[0]).get("placement", -1)) == 11 \
		and normalized_source_cells == [[0, 4, 8], [0, 4, 8], [0, 4, 8]] \
		and _placements(matrix_notes) == [8, 4, 0, 3] \
		and int(matrix_bomb.get("placement", -1)) == 11 \
		and Array(matrix_obstacle.get("cells", [])) == [9, 10] \
		and int(matrix_arc.get("startPlacement", -1)) == 8 \
		and int(matrix_arc.get("endPlacement", -1)) == 3 \
		and String(matrix_arc.get("startNoteRef", "")).begins_with("flow-note-") \
		and String(matrix_arc.get("endNoteRef", "")).begins_with("flow-note-") \
		and int(matrix_burst.get("placement", -1)) == 0 \
		and int(matrix_burst.get("tailPlacement", -1)) == 11
	return {
		"name": "test_flow_orientation",
		"passed": passed,
		"details": {
			"source": source,
			"exactChartHash": exact_chart_hash,
			"exactPlacements": exact_placements,
			"expectedPlacements": expected_placements,
			"normalizedSourceCells": normalized_source_cells,
			"matrixBeats": matrix_beats,
		}
	}

static func _source_cells(summary: Dictionary) -> Array:
	var result: Array = []
	for note_variant in Array(summary.get("colorNotes", [])):
		result.append(int(Dictionary(note_variant).get("cell", -1)))
	return result

static func _beats_of_type(beats: Array, beat_type: String) -> Array:
	var result: Array = []
	for beat_variant in beats:
		var beat: Dictionary = Dictionary(beat_variant)
		if String(beat.get("type", "")) == beat_type:
			result.append(beat)
	return result

static func _first_beat(beats: Array, beat_type: String) -> Dictionary:
	var matches := _beats_of_type(beats, beat_type)
	return Dictionary(matches[0]) if not matches.is_empty() else {}

static func _placements(beats: Array) -> Array:
	var result: Array = []
	for beat_variant in beats:
		result.append(int(Dictionary(beat_variant).get("placement", -1)))
	return result
