extends RefCounted

const AeroContentAuthoring = preload("res://addons/aerobeat-tool-content-authoring/src/AeroContentAuthoring.gd")
const Converter = preload("res://addons/aerobeat-tool-content-authoring/src/services/importers/boxing_prototype_conversion_service.gd")
const TestSupport = preload("test_support.gd")

static func run() -> Dictionary:
	var fixture_path := ProjectSettings.globalize_path("res://../assets/fixtures/boxing_prototype_golden_v1.json")
	var fixture_value: Variant = JSON.parse_string(FileAccess.get_file_as_string(fixture_path))
	var fixture: Dictionary = Dictionary(fixture_value if fixture_value is Dictionary else {})
	var converter := Converter.new()
	var runtime := AeroContentAuthoring.new()
	var first := converter.convert_matrix(
		Dictionary(fixture.get("sourceSummary", {})),
		String(fixture.get("difficulty", "Hard")),
		String(fixture.get("songToken", "sanitized-golden")),
		float(fixture.get("bpm", 120.0))
	)
	var second := converter.convert_matrix(
		Dictionary(fixture.get("sourceSummary", {})),
		String(fixture.get("difficulty", "Hard")),
		String(fixture.get("songToken", "sanitized-golden")),
		float(fixture.get("bpm", 120.0))
	)
	var requested_modifiers := ["no_squats", "no_weaves", "any_punch", "cross_body"]
	var modified := converter.convert_matrix(
		Dictionary(fixture.get("sourceSummary", {})),
		String(fixture.get("difficulty", "Hard")),
		String(fixture.get("songToken", "sanitized-golden")),
		float(fixture.get("bpm", 120.0)),
		{"modifiers": requested_modifiers, "presentationSuggestion": {"themeId": "golden-theme"}}
	)
	var cross_body_only := converter.convert_matrix(
		Dictionary(fixture.get("sourceSummary", {})),
		String(fixture.get("difficulty", "Hard")),
		"cross-body",
		float(fixture.get("bpm", 120.0)),
		{"modifiers": ["cross_body"]}
	)
	var squat_source := {
		"colorNotes": [],
		"obstacles": [{"start": 1.0, "duration": 1.0, "x": 0, "y": 0, "width": 4, "height": 1, "sourceIndex": 0}],
		"bombNotes": [], "sliders": [], "burstSliders": [],
	}
	var no_squat_result := converter.convert_matrix(squat_source, "Hard", "no-squat", 120.0, {"modifiers": ["no_squats"]})
	var boundary_source := {
		"colorNotes": [
			{"start": 1.0, "cell": 5, "hand": "left", "direction": 8, "sourceIndex": 0},
			{"start": 1.5, "cell": 10, "hand": "right", "direction": 8, "sourceIndex": 1},
		],
		"obstacles": [], "bombNotes": [], "sliders": [], "burstSliders": [],
	}
	var boundary_fast := converter.convert_matrix(boundary_source, "Hard", "boundary", 120.0)
	var boundary_slow := converter.convert_matrix(boundary_source, "Hard", "boundary", 60.0)
	var blocked_source: Dictionary = boundary_source.duplicate(true)
	blocked_source["obstacles"] = [{"start": 0.8, "duration": 1.0, "x": 1, "y": 1, "width": 2, "height": 1, "sourceIndex": 0}]
	var blocked_result := converter.convert_matrix(blocked_source, "Hard", "blocked", 120.0)
	var guard_source := {
		"colorNotes": [
			{"start": 1.0, "cell": 6, "hand": "left", "direction": 8, "sourceIndex": 0},
			{"start": 1.0, "cell": 5, "hand": "right", "direction": 8, "sourceIndex": 1},
		],
		"obstacles": [{"start": 0.8, "duration": 1.0, "x": 1, "y": 1, "width": 2, "height": 1, "sourceIndex": 0}],
		"bombNotes": [], "sliders": [], "burstSliders": [],
	}
	var guard_result := converter.convert_matrix(guard_source, "Hard", "guard-relocation", 120.0)
	var guard_window_source := {
		"colorNotes": [
			{"start": 1.0, "cell": 5, "hand": "left", "direction": 8, "sourceIndex": 0},
			{"start": 1.0, "cell": 6, "hand": "right", "direction": 8, "sourceIndex": 1},
			{"start": 1.35, "cell": 5, "hand": "left", "direction": 8, "sourceIndex": 2},
		],
		"obstacles": [], "bombNotes": [], "sliders": [], "burstSliders": [],
	}
	var guard_window_result := converter.convert_matrix(guard_window_source, "Hard", "guard-window", 120.0)
	var guard_window_chart := _find(Array(guard_window_result.get("charts", [])), "cut_family_source_height_v1", "boxing_semantic_track_v1")
	var charts: Array = Array(first.get("charts", []))
	var expected: Dictionary = Dictionary(fixture.get("expected", {}))
	var chart_ids: Array = []
	var content_hashes := {}
	for chart_variant in charts:
		var chart: Dictionary = Dictionary(chart_variant)
		chart_ids.append(String(chart.get("chartId", "")))
		var prototype: Dictionary = Dictionary(chart.get("prototype", {}))
		content_hashes["%s|%s" % [prototype.get("recipeId", ""), prototype.get("rulesetId", "")]] = prototype.get("contentHash", "")
	chart_ids.sort()
	var row_semantic := _find(charts, "row_family_balanced_height_v1", "boxing_semantic_track_v1")
	var row_spatial := _find(charts, "row_family_balanced_height_v1", "boxing_spatial_grid_v1")
	var cut_semantic := _find(charts, "cut_family_source_height_v1", "boxing_semantic_track_v1")
	var cut_spatial := _find(charts, "cut_family_source_height_v1", "boxing_spatial_grid_v1")
	var modified_row := _find(Array(modified.get("charts", [])), "row_family_balanced_height_v1", "boxing_semantic_track_v1")
	var cross_body_row := _find(Array(cross_body_only.get("charts", [])), "row_family_balanced_height_v1", "boxing_semantic_track_v1")
	var no_squat_row := _find(Array(no_squat_result.get("charts", [])), "row_family_balanced_height_v1", "boxing_semantic_track_v1")
	var fast_row := _find(Array(boundary_fast.get("charts", [])), "row_family_balanced_height_v1", "boxing_semantic_track_v1")
	var slow_row := _find(Array(boundary_slow.get("charts", [])), "row_family_balanced_height_v1", "boxing_semantic_track_v1")
	var blocked_row := _find(Array(blocked_result.get("charts", [])), "cut_family_source_height_v1", "boxing_semantic_track_v1")
	var relocated_row := _find(Array(guard_result.get("charts", [])), "row_family_balanced_height_v1", "boxing_semantic_track_v1")
	var relocated_guard := _find_type(Array(relocated_row.get("beats", [])), "guard")
	var row_types := _types(Array(row_semantic.get("beats", [])))
	var cut_types := _types(Array(cut_semantic.get("beats", [])))
	var row_event_ids := _event_ids(Array(row_semantic.get("beats", [])))
	var crossed_guard := _find_type(Array(row_semantic.get("beats", [])), "guard")
	var emitted_modifiers := _event_modifiers(Array(modified_row.get("beats", [])))
	var expected_modifier_identity := _modifier_union(requested_modifiers, emitted_modifiers)
	var actual_modifier_identity: Array = Array(Dictionary(modified_row.get("prototype", {})).get("modifiers", []))
	var row_recipe := _read_json("res://../assets/recipes/boxing-row-family-v1.json")
	var cut_recipe := _read_json("res://../assets/recipes/boxing-cut-family-v1.json")
	var semantic_ruleset := _read_json("res://../assets/rulesets/boxing-semantic-track-v1.json")
	var spatial_ruleset := _read_json("res://../assets/rulesets/boxing-spatial-grid-v1.json")
	var passed: bool = not fixture.is_empty() \
		and String(fixture.get("license", "")) == "synthetic-aerobeat-test-data" \
		and JSON.stringify(first) == JSON.stringify(second) \
		and String(first.get("sourceHash", "")) == String(expected.get("sourceHash", "")) \
		and content_hashes == Dictionary(expected.get("contentHashes", {})) \
		and row_types == Array(expected.get("rowTypes", [])) \
		and cut_types == Array(expected.get("cutTypes", [])) \
		and row_event_ids == Array(expected.get("rowEventIds", [])) \
		and chart_ids == [
			"ab-chart-sanitized-golden-boxing-hard-semantic-track-cut-family",
			"ab-chart-sanitized-golden-boxing-hard-semantic-track-row-family",
			"ab-chart-sanitized-golden-boxing-hard-spatial-grid-cut-family",
			"ab-chart-sanitized-golden-boxing-hard-spatial-grid-row-family",
		] \
		and TestSupport.boxing_prototype_matrix_valid(charts) \
		and Array(row_semantic.get("beats", [])) == Array(row_spatial.get("beats", [])) \
		and Array(cut_semantic.get("beats", [])) == Array(cut_spatial.get("beats", [])) \
		and row_types.slice(0, 3) == ["uppercut_left", "straight_right", "hook_left"] \
		and cut_types.slice(0, 3) == ["straight_left", "uppercut_right", "hook_left"] \
		and bool(Dictionary(crossed_guard.get("guardTarget", {})).get("crossed", false)) \
		and String(crossed_guard.get("modifier", "")) == "crossed_guard" \
		and row_types.has("weave_right") \
		and not _types(Array(modified_row.get("beats", []))).has("weave_right") \
		and emitted_modifiers == ["any_punch", "crossed_guard"] \
		and expected_modifier_identity == ["any_punch", "cross_body", "crossed_guard", "no_squats", "no_weaves"] \
		and actual_modifier_identity == expected_modifier_identity \
		and String(_first_punch(Array(modified_row.get("beats", []))).get("modifier", "")) == "any_punch" \
		and String(_first_punch(Array(cross_body_row.get("beats", []))).get("modifier", "")) == "cross_body" \
		and not _types(Array(no_squat_row.get("beats", []))).has("squat") \
		and _trace_has_reason(Array(no_squat_result.get("traces", [])), "disabled_by_modifier") \
		and String(Dictionary(modified_row.get("presentationSuggestion", {})).get("themeId", "")) == "golden-theme" \
		and _punch_count(Array(fast_row.get("beats", []))) == 1 \
		and _punch_count(Array(slow_row.get("beats", []))) == 2 \
		and Array(_first_punch(Array(blocked_row.get("beats", []))).get("sourceEventIds", [])) == ["note-001"] \
		and _trace_has_reason(Array(blocked_result.get("traces", [])), "spatial_target_blocked_before_optimizer") \
		and int(Dictionary(relocated_guard.get("guardTarget", {})).get("leftCell", -1)) == 10 \
		and int(Dictionary(relocated_guard.get("guardTarget", {})).get("rightCell", -1)) == 9 \
		and bool(Dictionary(relocated_guard.get("guardTarget", {})).get("crossed", false)) \
		and _punch_count(Array(guard_window_chart.get("beats", []))) == 0 \
		and _trace_has_reason(Array(guard_window_result.get("traces", [])), "guard_window_reserved_before_optimizer") \
		and converter._reachable(27, 27, 0.0, 4.0, {}) \
		and not converter._reachable(27, 28, 0.0, 4.0, {}) \
		and runtime.get_boxing_prototype_contract_id() == Converter.CONTRACT_ID \
		and runtime.list_boxing_prototype_recipes().size() == 2 \
		and runtime.list_boxing_prototype_rulesets().size() == 2 \
		and _semantic_equal(row_recipe, converter.recipe_definitions()[0]) \
		and _semantic_equal(cut_recipe, converter.recipe_definitions()[1]) \
		and _semantic_equal(semantic_ruleset, converter.ruleset_definitions()[0]) \
		and _semantic_equal(spatial_ruleset, converter.ruleset_definitions()[1]) \
		and int(row_recipe.get("punchMinSpacingMs", 0)) == Converter.PUNCH_MIN_SPACING_MS \
		and int(cut_recipe.get("straightQualificationMs", 0)) == Converter.STRAIGHT_QUALIFICATION_MS
	return {
		"name": "test_boxing_prototype_golden",
		"passed": passed,
		"details": {
			"chartIds": chart_ids,
			"contentHashes": content_hashes,
			"rowTypes": row_types,
			"cutTypes": cut_types,
			"rowEventIds": row_event_ids,
			"expected": expected,
			"crossedGuard": crossed_guard,
			"modifierIdentityRule": {
				"requested": requested_modifiers,
				"emitted": emitted_modifiers,
				"expectedUnion": expected_modifier_identity,
				"actual": actual_modifier_identity,
			},
			"fastPunchCount": _punch_count(Array(fast_row.get("beats", []))),
			"slowPunchCount": _punch_count(Array(slow_row.get("beats", []))),
			"blockedFirstPunch": _first_punch(Array(blocked_row.get("beats", []))),
			"blockedTraceMatched": _trace_has_reason(Array(blocked_result.get("traces", [])), "spatial_target_blocked_before_optimizer"),
			"relocatedGuard": relocated_guard,
			"guardWindowBeats": guard_window_chart.get("beats", []),
			"guardWindowReserved": _trace_has_reason(Array(guard_window_result.get("traces", [])), "guard_window_reserved_before_optimizer"),
			"zeroBeatAdjacentReachable": converter._reachable(27, 28, 0.0, 4.0, {}),
			"traces": first.get("traces", []),
		},
	}

static func _find(charts: Array, recipe_id: String, ruleset_id: String) -> Dictionary:
	for chart_variant in charts:
		var chart: Dictionary = Dictionary(chart_variant)
		var prototype: Dictionary = Dictionary(chart.get("prototype", {}))
		if String(prototype.get("recipeId", "")) == recipe_id and String(prototype.get("rulesetId", "")) == ruleset_id:
			return chart
	return {}

static func _event_modifiers(beats: Array) -> Array:
	var result: Array = []
	for beat_variant in beats:
		var modifier := String(Dictionary(beat_variant).get("modifier", ""))
		if not modifier.is_empty() and not result.has(modifier):
			result.append(modifier)
	result.sort()
	return result

static func _modifier_union(requested: Array, emitted: Array) -> Array:
	var result: Array = requested.duplicate()
	for modifier_variant in emitted:
		var modifier := String(modifier_variant)
		if not result.has(modifier):
			result.append(modifier)
	result.sort()
	return result

static func _types(beats: Array) -> Array:
	var result: Array = []
	for beat_variant in beats:
		result.append(String(Dictionary(beat_variant).get("type", "")))
	return result

static func _punch_count(beats: Array) -> int:
	var count := 0
	for beat_variant in beats:
		var beat_type := String(Dictionary(beat_variant).get("type", ""))
		if beat_type.begins_with("straight_") or beat_type.begins_with("hook_") or beat_type.begins_with("uppercut_"):
			count += 1
	return count

static func _first_punch(beats: Array) -> Dictionary:
	for beat_variant in beats:
		var beat: Dictionary = Dictionary(beat_variant)
		var beat_type := String(beat.get("type", ""))
		if beat_type.begins_with("straight_") or beat_type.begins_with("hook_") or beat_type.begins_with("uppercut_"):
			return beat
	return {}

static func _trace_has_reason(traces: Array, reason: String) -> bool:
	for trace_variant in traces:
		for event_variant in Array(Dictionary(trace_variant).get("events", [])):
			if String(Dictionary(event_variant).get("reason", "")) == reason:
				return true
	return false

static func _event_ids(beats: Array) -> Array:
	var result: Array = []
	for beat_variant in beats:
		result.append(String(Dictionary(beat_variant).get("eventId", "")))
	return result

static func _find_type(beats: Array, beat_type: String) -> Dictionary:
	for beat_variant in beats:
		var beat: Dictionary = Dictionary(beat_variant)
		if String(beat.get("type", "")) == beat_type:
			return beat
	return {}

static func _semantic_equal(left: Variant, right: Variant) -> bool:
	if (left is int or left is float) and (right is int or right is float):
		return is_equal_approx(float(left), float(right))
	if left is Dictionary and right is Dictionary:
		var left_dictionary: Dictionary = left
		var right_dictionary: Dictionary = right
		if left_dictionary.size() != right_dictionary.size():
			return false
		for key in left_dictionary.keys():
			if not right_dictionary.has(key) or not _semantic_equal(left_dictionary[key], right_dictionary[key]):
				return false
		return true
	if left is Array and right is Array:
		var left_array: Array = left
		var right_array: Array = right
		if left_array.size() != right_array.size():
			return false
		for index in range(left_array.size()):
			if not _semantic_equal(left_array[index], right_array[index]):
				return false
		return true
	return left == right

static func _read_json(path: String) -> Dictionary:
	var absolute_path := ProjectSettings.globalize_path(path)
	var value: Variant = JSON.parse_string(FileAccess.get_file_as_string(absolute_path))
	return Dictionary(value if value is Dictionary else {})
