extends RefCounted

const AeroContentAuthoring = preload("res://addons/aerobeat-tool-content-authoring/src/AeroContentAuthoring.gd")
const ValidateChartService = preload("res://addons/aerobeat-tool-content-authoring/src/services/validation/validate_chart_service.gd")
const TestSupport = preload("test_support.gd")

static func run() -> Dictionary:
	var runtime := AeroContentAuthoring.new()
	runtime.initialize()
	var stage_dir := ProjectSettings.globalize_path("res://assets/fixtures/beatsaver_stage_legacy_v26_sliders_synthetic")
	var convert_result: Dictionary = runtime.convert_beatsaver_stage_to_current_package(stage_dir)
	var state: Dictionary = Dictionary(convert_result.get("state", {}))
	var summary: Dictionary = Dictionary(convert_result.get("summary", {}))
	var songs: Array = Array(state.get("songs", []))
	var song_record: Dictionary = Dictionary(songs[0]) if not songs.is_empty() else {}
	var song_audio: Dictionary = Dictionary(song_record.get("audio", {}))
	var chart_ids: Array = []
	for chart_variant in Array(state.get("charts", [])):
		chart_ids.append(String(Dictionary(chart_variant).get("chartId", "")))
	chart_ids.sort()
	var validation: Dictionary = runtime.validate_current_package()
	var save_parent := TestSupport.tmp_dir("beatsaver_stage_conversion_service_legacy_v26_sliders")
	TestSupport.ensure_clean_dir(save_parent)
	var save_result: Dictionary = runtime.save_current_package(save_parent)
	var output_dir := String(save_result.get("outputDir", ""))
	var report_path := output_dir.path_join(".artifacts/conversion-report.json")
	var report_text := TestSupport.read_text(report_path) if FileAccess.file_exists(report_path) else ""
	var package_validation := runtime.get_validate_package_service().validate_path(output_dir, "package") if not output_dir.is_empty() else {"valid": false}
	var charts: Array = Array(state.get("charts", []))
	var boxing_chart := _find_chart(charts, "boxing")
	var flow_chart := _find_chart(charts, "flow")
	var boxing_types: Array = []
	for beat_variant in Array(boxing_chart.get("beats", [])):
		boxing_types.append(String(Dictionary(beat_variant).get("type", "")))
	var flow_beats: Array = Array(flow_chart.get("beats", []))
	var flow_types: Array = []
	for beat_variant in flow_beats:
		flow_types.append(String(Dictionary(beat_variant).get("type", "")))
	var flow_chart_validation: Dictionary = ValidateChartService.new().validate_chart_record(flow_chart, "state://charts/flow")
	var arc_beat := _find_flow_beat(flow_beats, "arc", 1.0)
	var passed := bool(convert_result.get("ok", false)) \
		and bool(validation.get("valid", false)) \
		and bool(save_result.get("ok", false)) \
		and bool(package_validation.get("valid", false)) \
		and String(package_validation.get("delegatedValidator", "")) == "aerobeat-content-core" \
		and bool(flow_chart_validation.get("valid", false)) \
		and String(flow_chart_validation.get("delegatedValidator", "")) == "aerobeat-content-core" \
		and chart_ids == TestSupport.expected_beatsaver_matrix_chart_ids("synthetic-legacy-v26-slider-demo", "Hard") \
		and TestSupport.boxing_prototype_matrix_valid(charts) \
		and TestSupport.unique_set_ids(state) \
		and String(song_audio.get("filePath", "")) == "media/audio/synthetic-legacy-v26-slider-demo.ogg" \
		and boxing_types.size() > 0 \
		and flow_types == ["note", "arc", "note", "note"] \
		and String(arc_beat.get("startNoteRef", "")).begins_with("flow-note-") \
		and String(arc_beat.get("endNoteRef", "")).begins_with("flow-note-") \
		and int(arc_beat.get("startPlacement", -1)) == 4 \
		and int(arc_beat.get("endPlacement", -1)) == 11 \
		and int(arc_beat.get("startDirection", -1)) == 1 \
		and int(arc_beat.get("endDirection", -1)) == 5 \
		and int(arc_beat.get("midAnchorMode", -1)) == 2 \
		and is_equal_approx(float(arc_beat.get("headCurveMultiplier", 0.0)), 1.25) \
		and is_equal_approx(float(arc_beat.get("tailCurveMultiplier", 0.0)), 0.75) \
		and report_text.contains('"sourceFamily": "slider"') \
		and report_text.contains('"type": "arc"') \
		and int(summary.get("chartCount", 0)) == 5
	return {
		"name": "test_beatsaver_stage_conversion_service_legacy_v26_sliders",
		"passed": passed,
		"details": {
			"convertResult": convert_result,
			"validation": validation,
			"saveResult": save_result,
			"packageValidation": package_validation,
			"flowChartValidation": flow_chart_validation,
			"chartIds": chart_ids,
			"boxingTypes": boxing_types,
			"flowBeats": flow_beats,
			"reportPath": report_path,
			"songAudio": song_audio,
		}
	}

static func _find_chart(charts: Array, mode: String) -> Dictionary:
	for chart_variant in charts:
		var chart: Dictionary = Dictionary(chart_variant)
		if String(chart.get("mode", "")) == mode:
			return chart
	return {}

static func _find_flow_beat(flow_beats: Array, beat_type: String, start: float) -> Dictionary:
	for beat_variant in flow_beats:
		var beat: Dictionary = Dictionary(beat_variant)
		if String(beat.get("type", "")) != beat_type:
			continue
		if is_equal_approx(float(beat.get("start", -9999.0)), start):
			return beat
	return {}
