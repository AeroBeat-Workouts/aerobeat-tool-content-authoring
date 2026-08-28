class_name BoxingPrototypeConversionService
extends RefCounted

const CONTRACT_ID := "aerobeat.boxing.prototype.v1"
const RECIPE_ROW := "row_family_balanced_height_v1"
const RECIPE_CUT := "cut_family_source_height_v1"
const RULESET_SEMANTIC := "boxing_semantic_track_v1"
const RULESET_SPATIAL := "boxing_spatial_grid_v1"
const RECIPE_VERSION := "1.0.0"
const RULESET_VERSION := "1.0.0"
const TIMING_WINDOW_MS := 180
const FRESHNESS_MS := 150
const STRAIGHT_QUALIFICATION_MS := 100
const PUNCH_MIN_SPACING_MS := 360
const GUARD_PAIRS := [[0, 1], [1, 2], [2, 3], [4, 5], [5, 6], [6, 7], [8, 9], [9, 10], [10, 11]]
const REACH_SUBCELLS_PER_BEAT := {"Easy": 3.0, "Normal": 3.5, "Hard": 4.0, "Expert": 5.0, "ExpertPlus": 6.0}

func recipe_definitions() -> Array[Dictionary]:
	return [
		{
			"contractId": CONTRACT_ID,
			"recipeId": RECIPE_ROW,
			"version": RECIPE_VERSION,
			"label": "Row Family / Balanced Height",
			"familyRule": {"top": "uppercut", "middle": "straight", "bottom": "hook"},
			"heightRule": "balance_generated_rows",
			"punchMinSpacingMs": PUNCH_MIN_SPACING_MS,
			"guardTimingWindowMs": TIMING_WINDOW_MS,
			"obstacleTimingWindowMs": TIMING_WINDOW_MS,
			"freshnessMs": FRESHNESS_MS,
			"straightQualificationMs": STRAIGHT_QUALIFICATION_MS,
			"reachSubcellsPerBeat": REACH_SUBCELLS_PER_BEAT,
			"initialWristCells": {"left": 5, "right": 6},
		},
		{
			"contractId": CONTRACT_ID,
			"recipeId": RECIPE_CUT,
			"version": RECIPE_VERSION,
			"label": "Cut Family / Source Height",
			"familyRule": {"up": "uppercut", "horizontal": "hook", "other": "straight"},
			"heightRule": "prefer_source_row_promote_bottom_uppercut",
			"normalizeOutwardHooks": true,
			"punchMinSpacingMs": PUNCH_MIN_SPACING_MS,
			"guardTimingWindowMs": TIMING_WINDOW_MS,
			"obstacleTimingWindowMs": TIMING_WINDOW_MS,
			"freshnessMs": FRESHNESS_MS,
			"straightQualificationMs": STRAIGHT_QUALIFICATION_MS,
			"reachSubcellsPerBeat": REACH_SUBCELLS_PER_BEAT,
			"initialWristCells": {"left": 5, "right": 6},
		},
	]

func ruleset_definitions() -> Array[Dictionary]:
	return [
		{
			"contractId": CONTRACT_ID,
			"rulesetId": RULESET_SEMANTIC,
			"version": RULESET_VERSION,
			"timingWindowMs": TIMING_WINDOW_MS,
			"evidenceFreshnessMs": FRESHNESS_MS,
			"straightQualificationMs": STRAIGHT_QUALIFICATION_MS,
			"hookAndUppercutQualification": "target-cell-and-cardinal-direction",
			"semanticClassifiers": "authoritative",
		},
		{
			"contractId": CONTRACT_ID,
			"rulesetId": RULESET_SPATIAL,
			"version": RULESET_VERSION,
			"timingWindowMs": TIMING_WINDOW_MS,
			"evidenceFreshnessMs": FRESHNESS_MS,
			"straightQualificationMs": STRAIGHT_QUALIFICATION_MS,
			"hookAndUppercutQualification": "target-cell-and-cardinal-direction",
			"semanticClassifiers": "shadow-only",
			"subgrid": {"columns": 8, "rows": 6, "cellOrder": "top-left-row-major"},
		},
	]

func convert_matrix(source_summary: Dictionary, difficulty: String, song_token: String, bpm: float, options: Dictionary = {}) -> Dictionary:
	var source_hash := _sha256(_canonical_json(source_summary))
	var all_charts: Array = []
	var all_traces: Array = []
	for recipe in recipe_definitions():
		var generated := _generate_events(source_summary, difficulty, bpm, recipe, options)
		for ruleset_id in [RULESET_SEMANTIC, RULESET_SPATIAL]:
			var chart := _chart_for(generated, difficulty, song_token, recipe, ruleset_id, source_hash, options)
			all_charts.append(chart)
			all_traces.append({
				"chartId": String(chart.get("chartId", "")),
				"difficulty": difficulty,
				"bpm": bpm,
				"recipeId": String(recipe.get("recipeId", "")),
				"rulesetId": ruleset_id,
				"sourceHash": source_hash,
				"contentHash": Dictionary(chart.get("prototype", {})).get("contentHash", ""),
				"optimizer": Dictionary(generated.get("optimizer", {})).duplicate(true),
				"events": Array(generated.get("trace", [])).duplicate(true),
			})
	return {"charts": all_charts, "traces": all_traces, "sourceHash": source_hash, "recipes": recipe_definitions(), "rulesets": ruleset_definitions()}

func _chart_for(generated: Dictionary, difficulty: String, song_token: String, recipe: Dictionary, ruleset_id: String, source_hash: String, options: Dictionary) -> Dictionary:
	var recipe_id := String(recipe.get("recipeId", ""))
	var recipe_short := "row-family" if recipe_id == RECIPE_ROW else "cut-family"
	var ruleset_short := "semantic-track" if ruleset_id == RULESET_SEMANTIC else "spatial-grid"
	var beats: Array = Array(generated.get("beats", [])).duplicate(true)
	var recipe_hash := _sha256(_canonical_json(recipe))
	var ruleset_definition := {}
	for candidate in ruleset_definitions():
		if String(candidate.get("rulesetId", "")) == ruleset_id:
			ruleset_definition = candidate
			break
	var ruleset_hash := _sha256(_canonical_json(ruleset_definition))
	var identity_payload := {"beats": beats, "recipeId": recipe_id, "rulesetId": ruleset_id, "sourceHash": source_hash}
	var content_hash := _sha256(_canonical_json(identity_payload))
	var modifiers: Array = Array(options.get("modifiers", [])).duplicate(true)
	for beat_variant in beats:
		var event_modifier := String(Dictionary(beat_variant).get("modifier", ""))
		if not event_modifier.is_empty() and not modifiers.has(event_modifier):
			modifiers.append(event_modifier)
	modifiers.sort()
	var chart := {
		"schemaId": "aerobeat.chart.boxing.v1",
		"schemaVersion": 1,
		"recordVersion": 1,
		"chartId": "ab-chart-%s-boxing-%s-%s-%s" % [song_token, difficulty.to_lower(), ruleset_short, recipe_short],
		"chartName": "%s %s Boxing - %s / %s" % [_titleize(song_token), difficulty, _titleize(ruleset_short), _titleize(recipe_short)],
		"mode": "boxing",
		"difficulty": difficulty,
		"prototype": {
			"contractId": CONTRACT_ID,
			"recipeId": recipe_id,
			"recipeVersion": RECIPE_VERSION,
			"rulesetId": ruleset_id,
			"rulesetVersion": RULESET_VERSION,
			"sourceHash": source_hash,
			"recipeHash": recipe_hash,
			"rulesetHash": ruleset_hash,
			"contentHash": content_hash,
			"modifiers": modifiers,
			"regenerationRequiredFor": ["punchMinSpacingMs", "reachSubcellsPerBeat", "familyBalance", "guardRelocation"],
		},
		"beats": beats,
	}
	if options.has("presentationSuggestion"):
		chart["presentationSuggestion"] = Dictionary(options.get("presentationSuggestion", {})).duplicate(true)
	return chart

func _generate_events(source_summary: Dictionary, difficulty: String, bpm: float, recipe: Dictionary, options: Dictionary) -> Dictionary:
	var trace: Array = []
	var modifiers: Array = Array(options.get("modifiers", []))
	var obstacle_windows := _obstacle_windows(Array(source_summary.get("obstacles", [])), bpm)
	var groups := _note_groups(Array(source_summary.get("colorNotes", [])))
	var candidates: Array = []
	var row_counts := {0: 0, 1: 0, 2: 0}
	for key in groups.keys():
		var raw_group: Array = Array(groups[key])
		var group: Array = _collapse_same_hand(raw_group)
		var source_ids := _source_ids(raw_group, "note")
		var retained_ids := _source_ids(group, "note")
		for source_id in source_ids:
			if not retained_ids.has(source_id):
				trace.append({"sourceEventIds": [source_id], "start": float(key), "action": "drop", "reason": "same_hand_simultaneous_stable_tiebreak"})
		if _has_both_hands(group):
			candidates.append({"kind": "guard", "start": float(key), "notes": group, "sourceEventIds": source_ids, "stableId": _join_strings(source_ids, "+")})
			continue
		if group.is_empty():
			continue
		var note: Dictionary = Dictionary(group[0])
		var family := _family_for(note, String(recipe.get("recipeId", RECIPE_ROW)))
		var row := _target_row(note, family, String(recipe.get("recipeId", RECIPE_ROW)), row_counts)
		row_counts[row] = int(row_counts.get(row, 0)) + 1
		candidates.append({"kind": "punch", "start": float(key), "note": note, "family": family, "targetRow": row, "sourceEventIds": source_ids, "stableId": _join_strings(source_ids, "+")})
	candidates.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		if not is_equal_approx(float(a.get("start", 0.0)), float(b.get("start", 0.0))):
			return float(a.get("start", 0.0)) < float(b.get("start", 0.0))
		return String(a.get("stableId", "")) < String(b.get("stableId", ""))
	)
	var guard_center_times_ms: Array[float] = []
	for candidate_variant in candidates:
		var candidate: Dictionary = Dictionary(candidate_variant)
		if String(candidate.get("kind", "")) == "guard":
			guard_center_times_ms.append(_beat_to_ms(float(candidate.get("start", 0.0)), bpm))
	var optimizer_result := _select_spacing_optimized_punches(candidates, bpm, obstacle_windows, difficulty, guard_center_times_ms)
	var optimizer_selection: Dictionary = Dictionary(optimizer_result.get("selected", {}))
	var optimizer_infeasible: Dictionary = Dictionary(optimizer_result.get("infeasible", {}))
	var beats: Array = []
	var last_punch_ms := -1000000000.0
	var previous_hand := ""
	var wrist_subcell := {"left": _seed_subcell(5), "right": _seed_subcell(6)}
	var wrist_beat := {"left": 0.0, "right": 0.0}
	var family_counts := {"straight": 0, "hook": 0, "uppercut": 0}
	for candidate_variant in candidates:
		var candidate: Dictionary = candidate_variant
		var start := float(candidate.get("start", 0.0))
		var start_ms := _beat_to_ms(start, bpm)
		if String(candidate.get("kind", "")) == "guard":
			var guard_result := _emit_guard(candidate, obstacle_windows, wrist_subcell, wrist_beat, difficulty, bpm, String(recipe.get("recipeId", "")))
			trace.append(guard_result.get("trace", {}))
			if bool(guard_result.get("ok", false)):
				var guard_beat: Dictionary = Dictionary(guard_result.get("beat", {}))
				beats.append(guard_beat)
				var target: Dictionary = Dictionary(guard_beat.get("guardTarget", {}))
				wrist_subcell["left"] = _seed_subcell(int(target.get("leftCell", 5)))
				wrist_subcell["right"] = _seed_subcell(int(target.get("rightCell", 6)))
				wrist_beat["left"] = start
				wrist_beat["right"] = start
			continue
		if not optimizer_selection.has(String(candidate.get("stableId", ""))):
			var optimizer_reason := String(optimizer_infeasible.get(String(candidate.get("stableId", "")), "spacing_optimizer_rejected"))
			trace.append(_drop_trace(candidate, optimizer_reason, {"priorityOrder": ["retained_punches", "hand_alternation", "family_balance", "source_order", "stable_event_id"]}))
			continue
		var note: Dictionary = Dictionary(candidate.get("note", {}))
		var hand := String(note.get("hand", "left"))
		var family := String(candidate.get("family", "straight"))
		var spatial := _spatial_target(family, hand, int(candidate.get("targetRow", 1)))
		var blocked := _blocked_subcells_at(start_ms, obstacle_windows)
		var accepted: Array = Array(spatial.get("acceptedSubcells", []))
		var safe_subcells: Array = []
		for subcell in accepted:
			if not blocked.has(int(subcell)):
				safe_subcells.append(int(subcell))
		if safe_subcells.is_empty():
			trace.append(_drop_trace(candidate, "spatial_target_blocked"))
			continue
		spatial["acceptedSubcells"] = safe_subcells
		var target_subcell := -1
		var delta_beats := maxf(start - float(wrist_beat.get(hand, 0.0)), 0.0)
		for safe_subcell in safe_subcells:
			if _reachable(int(wrist_subcell.get(hand, _seed_subcell(5 if hand == "left" else 6))), int(safe_subcell), delta_beats, float(REACH_SUBCELLS_PER_BEAT.get(difficulty, 3.0)), blocked):
				target_subcell = int(safe_subcell)
				break
		if target_subcell < 0:
			trace.append(_drop_trace(candidate, "unreachable_after_optimizer"))
			continue
		if start_ms - last_punch_ms < PUNCH_MIN_SPACING_MS:
			trace.append(_drop_trace(candidate, "punch_min_spacing", {"previousHand": previous_hand, "spacingMs": start_ms - last_punch_ms}))
			continue
		var beat_type := "%s_%s" % [family, hand]
		var event_id := _event_id(String(recipe.get("recipeId", "")), String(candidate.get("stableId", "")), beat_type)
		var beat := {
			"start": start,
			"type": beat_type,
			"eventId": event_id,
			"sourceEventIds": Array(candidate.get("sourceEventIds", [])).duplicate(true),
			"spatialTarget": spatial,
			"timingWindowMs": TIMING_WINDOW_MS,
			"evidenceFreshnessMs": FRESHNESS_MS,
		}
		if modifiers.has("any_punch"):
			beat["modifier"] = "any_punch"
		elif modifiers.has("cross_body"):
			beat["modifier"] = "cross_body"
		beats.append(beat)
		last_punch_ms = start_ms
		previous_hand = hand
		family_counts[family] = int(family_counts.get(family, 0)) + 1
		wrist_subcell[hand] = target_subcell
		wrist_beat[hand] = start
		trace.append({"sourceEventIds": beat.get("sourceEventIds"), "eventId": event_id, "start": start, "action": "emit", "kind": "punch", "family": family, "hand": hand, "sourceDirection": int(note.get("direction", 8)), "generatedDirection": spatial.get("entryDirection", "semantic_straight"), "target": spatial.duplicate(true)})
	for obstacle_variant in obstacle_windows:
		var window: Dictionary = obstacle_variant
		var blocked_cells: Array = Array(window.get("blockedCells", [])).duplicate(true)
		var obstacle_type := _obstacle_type(blocked_cells)
		var source_id := "obstacle-%03d" % int(window.get("sourceIndex", 0))
		if (obstacle_type == "squat" and modifiers.has("no_squats")) or (obstacle_type.begins_with("weave_") and modifiers.has("no_weaves")):
			trace.append({"sourceEventIds": [source_id], "start": float(window.get("startBeat", 0.0)), "action": "drop", "reason": "disabled_by_modifier", "type": obstacle_type})
			continue
		var safe_cells: Array = []
		for cell in range(12):
			if not blocked_cells.has(cell):
				safe_cells.append(cell)
		beats.append({
			"start": float(window.get("startBeat", 0.0)),
			"type": obstacle_type,
			"eventId": _event_id(String(recipe.get("recipeId", "")), source_id, obstacle_type),
			"sourceEventIds": [source_id],
			"checkpoint": {"kind": "instantaneous", "freshnessMs": FRESHNESS_MS, "timingWindowMs": TIMING_WINDOW_MS, "noseSafeCells": safe_cells},
			"blockedCells": blocked_cells,
		})
		trace.append({"sourceEventIds": [source_id], "start": float(window.get("startBeat", 0.0)), "action": "emit", "kind": "obstacle_checkpoint", "type": obstacle_type, "blockedCells": blocked_cells, "noseSafeCells": safe_cells})
	beats.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		if not is_equal_approx(float(a.get("start", 0.0)), float(b.get("start", 0.0))):
			return float(a.get("start", 0.0)) < float(b.get("start", 0.0))
		return String(a.get("eventId", "")) < String(b.get("eventId", ""))
	)
	return {
		"beats": beats,
		"trace": trace,
		"familyCounts": family_counts,
		"optimizer": {
			"priorityOrder": ["retained_punches", "hand_alternation", "family_balance", "source_order", "stable_event_id"],
			"punchMinSpacingMs": PUNCH_MIN_SPACING_MS,
			"selectedStableIds": optimizer_selection.keys(),
		},
	}

func _select_spacing_optimized_punches(candidates: Array, bpm: float, obstacles: Array, difficulty: String, guard_center_times_ms: Array[float]) -> Dictionary:
	var punches: Array = []
	var infeasible := {}
	for candidate_variant in candidates:
		var candidate: Dictionary = candidate_variant
		if String(candidate.get("kind", "")) != "punch":
			continue
		var static_reason := _static_infeasibility_reason(candidate, bpm, obstacles, difficulty, guard_center_times_ms)
		if not static_reason.is_empty():
			infeasible[String(candidate.get("stableId", ""))] = static_reason
			continue
		punches.append(candidate)
	punches.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		if not is_equal_approx(float(a.get("start", 0.0)), float(b.get("start", 0.0))):
			return float(a.get("start", 0.0)) < float(b.get("start", 0.0))
		return String(a.get("stableId", "")) < String(b.get("stableId", ""))
	)
	var best: Array = [[]]
	for index in range(punches.size()):
		var candidate: Dictionary = punches[index]
		var compatible_index := -1
		var candidate_ms := _beat_to_ms(float(candidate.get("start", 0.0)), bpm)
		for prior_index in range(index - 1, -1, -1):
			var prior: Dictionary = punches[prior_index]
			if candidate_ms - _beat_to_ms(float(prior.get("start", 0.0)), bpm) >= PUNCH_MIN_SPACING_MS:
				compatible_index = prior_index
				break
		var take: Array = Array(best[compatible_index + 1]).duplicate()
		take.append(candidate)
		var skip: Array = Array(best[index]).duplicate()
		best.append(take if _optimizer_sequence_is_better(take, skip) else skip)
	var selected := {}
	for candidate_variant in Array(best[best.size() - 1]):
		selected[String(Dictionary(candidate_variant).get("stableId", ""))] = true
	return {"selected": selected, "infeasible": infeasible}

func _static_infeasibility_reason(candidate: Dictionary, bpm: float, obstacles: Array, difficulty: String, guard_center_times_ms: Array[float]) -> String:
	var candidate_time_ms := _beat_to_ms(float(candidate.get("start", 0.0)), bpm)
	for guard_center_ms in guard_center_times_ms:
		if absf(candidate_time_ms - guard_center_ms) <= float(TIMING_WINDOW_MS) + 0.0001:
			return "guard_window_reserved_before_optimizer"
	var note: Dictionary = Dictionary(candidate.get("note", {}))
	var hand := String(note.get("hand", "left"))
	var family := String(candidate.get("family", "straight"))
	var spatial := _spatial_target(family, hand, int(candidate.get("targetRow", 1)))
	var start := float(candidate.get("start", 0.0))
	var blocked := _blocked_subcells_at(_beat_to_ms(start, bpm), obstacles)
	var has_safe_target := false
	var has_reachable_target := false
	var seed_cell := 5 if hand == "left" else 6
	for subcell in Array(spatial.get("acceptedSubcells", [])):
		if blocked.has(int(subcell)):
			continue
		has_safe_target = true
		if _reachable(_seed_subcell(seed_cell), int(subcell), start, float(REACH_SUBCELLS_PER_BEAT.get(difficulty, 3.0)), blocked):
			has_reachable_target = true
			break
	if not has_safe_target:
		return "spatial_target_blocked_before_optimizer"
	if not has_reachable_target:
		return "unreachable_before_optimizer"
	return ""

func _optimizer_sequence_is_better(left: Array, right: Array) -> bool:
	if left.size() != right.size():
		return left.size() > right.size()
	var left_alternations := _alternation_count(left)
	var right_alternations := _alternation_count(right)
	if left_alternations != right_alternations:
		return left_alternations > right_alternations
	var left_balance := _family_imbalance(left)
	var right_balance := _family_imbalance(right)
	if left_balance != right_balance:
		return left_balance < right_balance
	for index in range(left.size()):
		var left_candidate: Dictionary = left[index]
		var right_candidate: Dictionary = right[index]
		var left_start := float(left_candidate.get("start", 0.0))
		var right_start := float(right_candidate.get("start", 0.0))
		if not is_equal_approx(left_start, right_start):
			return left_start < right_start
		var left_id := String(left_candidate.get("stableId", ""))
		var right_id := String(right_candidate.get("stableId", ""))
		if left_id != right_id:
			return left_id < right_id
	return false

func _alternation_count(sequence: Array) -> int:
	var count := 0
	var previous := ""
	for candidate_variant in sequence:
		var note: Dictionary = Dictionary(Dictionary(candidate_variant).get("note", {}))
		var hand := String(note.get("hand", "left"))
		if not previous.is_empty() and hand != previous:
			count += 1
		previous = hand
	return count

func _family_imbalance(sequence: Array) -> int:
	var counts := {"straight": 0, "hook": 0, "uppercut": 0}
	for candidate_variant in sequence:
		var family := String(Dictionary(candidate_variant).get("family", "straight"))
		counts[family] = int(counts.get(family, 0)) + 1
	var values := [int(counts.get("straight", 0)), int(counts.get("hook", 0)), int(counts.get("uppercut", 0))]
	return int(values.max()) - int(values.min())

func _emit_guard(candidate: Dictionary, obstacles: Array, wrist_subcell: Dictionary, wrist_beat: Dictionary, difficulty: String, bpm: float, recipe_id: String) -> Dictionary:
	var notes: Array = Array(candidate.get("notes", []))
	var left_note := _note_for_hand(notes, "left")
	var right_note := _note_for_hand(notes, "right")
	var crossed := int(left_note.get("cell", 5)) % 4 > int(right_note.get("cell", 6)) % 4
	var source_pair := [_top_left_cell(int(left_note.get("cell", 5))), _top_left_cell(int(right_note.get("cell", 6)))]
	var start := float(candidate.get("start", 0.0))
	var blocked_subcells := _blocked_subcells_at(_beat_to_ms(start, bpm), obstacles)
	var pair := _choose_guard_pair(source_pair, crossed, blocked_subcells, start, wrist_subcell, wrist_beat, difficulty)
	if pair.is_empty():
		return {"ok": false, "trace": _drop_trace(candidate, "guard_no_legal_pair")}
	var left_cell := int(pair[1] if crossed else pair[0])
	var right_cell := int(pair[0] if crossed else pair[1])
	var source_ids: Array = Array(candidate.get("sourceEventIds", [])).duplicate(true)
	var event_id := _event_id(recipe_id, String(candidate.get("stableId", "")), "guard")
	var beat := {
		"start": start,
		"type": "guard",
		"eventId": event_id,
		"sourceEventIds": source_ids,
		"guardTarget": {"leftCell": left_cell, "rightCell": right_cell, "crossed": crossed, "sourcePair": source_pair},
		"checkpoint": {"kind": "instantaneous", "freshnessMs": FRESHNESS_MS, "timingWindowMs": TIMING_WINDOW_MS},
		"timingWindowMs": TIMING_WINDOW_MS,
		"evidenceFreshnessMs": FRESHNESS_MS,
	}
	if crossed:
		beat["modifier"] = "crossed_guard"
	return {"ok": true, "beat": beat, "trace": {"sourceEventIds": source_ids, "eventId": event_id, "start": start, "action": "emit", "kind": "guard", "sourcePair": source_pair, "generatedPair": pair, "crossed": crossed}}

func _choose_guard_pair(source_pair: Array, crossed: bool, blocked_subcells: Dictionary, start: float, wrist_subcell: Dictionary, wrist_beat: Dictionary, difficulty: String) -> Array:
	var source_sorted := source_pair.duplicate()
	source_sorted.sort()
	var candidates: Array = []
	for pair_variant in GUARD_PAIRS:
		var pair: Array = Array(pair_variant).duplicate()
		var pair_subcells := [_seed_subcell(int(pair[0])), _seed_subcell(int(pair[1]))]
		if blocked_subcells.has(pair_subcells[0]) or blocked_subcells.has(pair_subcells[1]):
			continue
		var left_target: int = int(pair_subcells[1] if crossed else pair_subcells[0])
		var right_target: int = int(pair_subcells[0] if crossed else pair_subcells[1])
		var left_delta := maxf(start - float(wrist_beat.get("left", 0.0)), 0.0)
		var right_delta := maxf(start - float(wrist_beat.get("right", 0.0)), 0.0)
		var rate := float(REACH_SUBCELLS_PER_BEAT.get(difficulty, 3.0))
		if not _reachable(int(wrist_subcell.get("left", _seed_subcell(5))), int(left_target), left_delta, rate, blocked_subcells):
			continue
		if not _reachable(int(wrist_subcell.get("right", _seed_subcell(6))), int(right_target), right_delta, rate, blocked_subcells):
			continue
		var source_row := int(source_sorted[0]) / 4 if source_sorted.size() == 2 and int(source_sorted[0]) / 4 == int(source_sorted[1]) / 4 else 1
		var pair_row := int(pair[0]) / 4
		var source_mid := (float(source_sorted[0]) + float(source_sorted[1])) * 0.5
		var pair_mid := (float(pair[0]) + float(pair[1])) * 0.5
		candidates.append({"pair": pair, "row": abs(pair_row - source_row), "mid": abs(pair_mid - source_mid), "center": abs(pair_mid - 5.5), "id": int(pair[0])})
	candidates.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		for key in ["row", "mid", "center", "id"]:
			if float(a.get(key, 0.0)) != float(b.get(key, 0.0)):
				return float(a.get(key, 0.0)) < float(b.get(key, 0.0))
		return false
	)
	return [] if candidates.is_empty() else Array(Dictionary(candidates[0]).get("pair", [])).duplicate()

func _spatial_target(family: String, hand: String, row: int) -> Dictionary:
	var column := 1 if hand == "left" else 2
	var target_row := clampi(row, 0, 2)
	var direction := ""
	var source_cell := -1
	if family == "hook":
		column = 2 if hand == "left" else 1
		direction = "right" if hand == "left" else "left"
		source_cell = target_row * 4 + (1 if hand == "left" else 2)
	elif family == "uppercut":
		target_row = mini(target_row, 1)
		direction = "up"
		source_cell = (target_row + 1) * 4 + column
	var target_cell := target_row * 4 + column
	var result := {"targetCell": target_cell, "acceptedSubcells": _accepted_subcells(target_cell, family, hand), "sourceCell": source_cell}
	if not direction.is_empty():
		result["entryDirection"] = direction
	if family == "straight":
		result["qualificationMs"] = STRAIGHT_QUALIFICATION_MS
		result["semanticQualification"] = "straight"
	return result

func _accepted_subcells(cell: int, family: String, hand: String) -> Array:
	var row := cell / 4
	var column := cell % 4
	var result: Array = []
	for sub_row in [row * 2, row * 2 + 1]:
		for sub_column in [column * 2, column * 2 + 1]:
			result.append(sub_row * 8 + sub_column)
		if family == "straight":
			var margin_column := column * 2 + 2 if hand == "left" else column * 2 - 1
			if margin_column >= 0 and margin_column < 8:
				result.append(sub_row * 8 + margin_column)
	result.sort()
	return result

func _family_for(note: Dictionary, recipe_id: String) -> String:
	if recipe_id == RECIPE_ROW:
		var row := _top_left_row(int(note.get("cell", 0)))
		return "uppercut" if row == 0 else ("straight" if row == 1 else "hook")
	var direction := int(note.get("direction", 8))
	if direction == 0:
		return "uppercut"
	if direction == 2 or direction == 3:
		return "hook"
	return "straight"

func _target_row(note: Dictionary, family: String, recipe_id: String, row_counts: Dictionary) -> int:
	var source_row := _top_left_row(int(note.get("cell", 0)))
	if recipe_id == RECIPE_CUT:
		return 1 if family == "uppercut" and source_row == 2 else source_row
	var allowed := [0, 1] if family == "uppercut" else [0, 1, 2]
	allowed.sort_custom(func(a: int, b: int) -> bool:
		if int(row_counts.get(a, 0)) != int(row_counts.get(b, 0)):
			return int(row_counts.get(a, 0)) < int(row_counts.get(b, 0))
		return a < b
	)
	return int(allowed[0])

func _note_groups(notes: Array) -> Dictionary:
	var result := {}
	for note_variant in notes:
		var note: Dictionary = Dictionary(note_variant)
		var key := str(snappedf(float(note.get("start", 0.0)), 0.001))
		if not result.has(key):
			result[key] = []
		result[key].append(note.duplicate(true))
	return result

func _collapse_same_hand(notes: Array) -> Array:
	var by_hand := {}
	for note_variant in notes:
		var note: Dictionary = Dictionary(note_variant)
		var hand := String(note.get("hand", "left"))
		if not by_hand.has(hand):
			by_hand[hand] = []
		by_hand[hand].append(note)
	var result: Array = []
	for hand in ["left", "right"]:
		var entries: Array = Array(by_hand.get(hand, []))
		if entries.is_empty():
			continue
		entries.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
			if int(a.get("cell", 0)) != int(b.get("cell", 0)):
				return int(a.get("cell", 0)) < int(b.get("cell", 0))
			return int(a.get("sourceIndex", 0)) < int(b.get("sourceIndex", 0))
		)
		result.append(Dictionary(entries[0]).duplicate(true))
	return result

func _source_ids(notes: Array, prefix: String) -> Array:
	var ids: Array = []
	for note_variant in notes:
		var note: Dictionary = Dictionary(note_variant)
		ids.append("%s-%03d" % [prefix, int(note.get("sourceIndex", 0))])
	ids.sort()
	return ids

func _has_both_hands(notes: Array) -> bool:
	return not _note_for_hand(notes, "left").is_empty() and not _note_for_hand(notes, "right").is_empty()

func _note_for_hand(notes: Array, hand: String) -> Dictionary:
	for note_variant in notes:
		var note: Dictionary = Dictionary(note_variant)
		if String(note.get("hand", "left")) == hand:
			return note
	return {}

func _obstacle_windows(obstacles: Array, bpm: float) -> Array:
	var result: Array = []
	for obstacle_variant in obstacles:
		var obstacle: Dictionary = Dictionary(obstacle_variant)
		var start := float(obstacle.get("start", 0.0))
		var finish := start + maxf(float(obstacle.get("duration", 0.0)), 0.0)
		var cells := _cells_for_obstacle(obstacle)
		result.append({"startBeat": start, "endBeat": finish, "startMs": _beat_to_ms(start, bpm) - TIMING_WINDOW_MS, "endMs": _beat_to_ms(finish, bpm) + TIMING_WINDOW_MS, "blockedCells": cells, "sourceIndex": int(obstacle.get("sourceIndex", result.size()))})
	return result

func _cells_for_obstacle(obstacle: Dictionary) -> Array:
	var x := clampi(int(obstacle.get("x", 0)), 0, 3)
	var width := clampi(int(obstacle.get("width", 1)), 1, 4 - x)
	var y := clampi(int(obstacle.get("y", 0)), 0, 2)
	var height := clampi(int(obstacle.get("height", 3)), 1, 3 - y)
	var cells: Array = []
	for source_row in range(y, y + height):
		var top_left_row := 2 - source_row
		for column in range(x, x + width):
			cells.append(top_left_row * 4 + column)
	cells.sort()
	return cells

func _blocked_subcells_at(time_ms: float, windows: Array) -> Dictionary:
	var blocked := {}
	for window_variant in windows:
		var window: Dictionary = Dictionary(window_variant)
		if time_ms < float(window.get("startMs", 0.0)) or time_ms > float(window.get("endMs", 0.0)):
			continue
		for cell in Array(window.get("blockedCells", [])):
			for subcell in _accepted_subcells(int(cell), "cell", "left"):
				blocked[int(subcell)] = true
	return blocked

func _reachable(start_subcell: int, target_subcell: int, delta_beats: float, rate: float, blocked: Dictionary) -> bool:
	if target_subcell < 0 or target_subcell >= 48 or blocked.has(target_subcell):
		return false
	var distances: Array[float] = []
	var visited := {}
	for _index in range(48):
		distances.append(INF)
	distances[clampi(start_subcell, 0, 47)] = 0.0
	for _step in range(48):
		var current := -1
		var current_distance := INF
		for candidate in range(48):
			if not visited.has(candidate) and distances[candidate] < current_distance:
				current = candidate
				current_distance = distances[candidate]
		if current < 0 or current == target_subcell:
			break
		visited[current] = true
		var current_x := current % 8
		var current_y := int(current / 8)
		for delta_y in range(-1, 2):
			for delta_x in range(-1, 2):
				if delta_x == 0 and delta_y == 0:
					continue
				var next_x := current_x + delta_x
				var next_y := current_y + delta_y
				if next_x < 0 or next_x >= 8 or next_y < 0 or next_y >= 6:
					continue
				var next := next_y * 8 + next_x
				if blocked.has(next):
					continue
				var edge_cost := sqrt(2.0) if delta_x != 0 and delta_y != 0 else 1.0
				distances[next] = minf(distances[next], current_distance + edge_cost)
	return distances[target_subcell] <= maxf(delta_beats * rate, 0.0) + 0.0001

func _top_left_row(source_cell: int) -> int:
	return 2 - clampi(int(source_cell / 4), 0, 2)

func _top_left_cell(source_cell: int) -> int:
	return _top_left_row(source_cell) * 4 + clampi(source_cell % 4, 0, 3)

func _seed_subcell(cell: int) -> int:
	var row := clampi(cell / 4, 0, 2)
	var column := clampi(cell % 4, 0, 3)
	return (row * 2 + 1) * 8 + column * 2 + 1

func _obstacle_type(cells: Array) -> String:
	var left := 0
	var right := 0
	for cell in cells:
		if int(cell) % 4 <= 1:
			left += 1
		else:
			right += 1
	if left > right:
		return "weave_right"
	if right > left:
		return "weave_left"
	return "squat"

func _drop_trace(candidate: Dictionary, reason: String, extra: Dictionary = {}) -> Dictionary:
	var trace := {"sourceEventIds": Array(candidate.get("sourceEventIds", [])).duplicate(true), "start": float(candidate.get("start", 0.0)), "action": "drop", "reason": reason}
	trace.merge(extra, true)
	return trace

func _event_id(recipe_id: String, source_id: String, kind: String) -> String:
	return "boxing-%s-%s" % [kind.replace("_", "-"), _sha256("%s|%s|%s" % [recipe_id, source_id, kind]).substr(7, 12)]

func _beat_to_ms(beat: float, bpm: float) -> float:
	return beat * 60000.0 / maxf(bpm, 1.0)

func _canonical_json(value: Variant) -> String:
	if value is Dictionary:
		var dictionary: Dictionary = value
		var keys: Array = dictionary.keys()
		keys.sort_custom(func(a: Variant, b: Variant) -> bool: return String(a) < String(b))
		var parts: Array[String] = []
		for key in keys:
			parts.append("%s:%s" % [JSON.stringify(String(key)), _canonical_json(dictionary[key])])
		return "{%s}" % ",".join(parts)
	if value is Array:
		var parts: Array[String] = []
		for entry in value:
			parts.append(_canonical_json(entry))
		return "[%s]" % ",".join(parts)
	return JSON.stringify(value)

func _sha256(value: String) -> String:
	return "sha256:%s" % value.sha256_text()

func _join_strings(values: Array, separator: String) -> String:
	var strings := PackedStringArray()
	for value in values:
		strings.append(String(value))
	return separator.join(strings)

func _titleize(value: String) -> String:
	var words := value.replace("_", "-").split("-", false)
	var result: Array[String] = []
	for word in words:
		result.append(String(word).capitalize())
	return " ".join(result)
