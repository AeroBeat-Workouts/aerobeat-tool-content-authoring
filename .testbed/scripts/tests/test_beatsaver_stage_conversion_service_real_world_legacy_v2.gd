extends RefCounted

const AeroContentAuthoring = preload("res://addons/aerobeat-tool-content-authoring/src/AeroContentAuthoring.gd")
const ValidateChartService = preload("res://addons/aerobeat-tool-content-authoring/src/services/validation/validate_chart_service.gd")
const TestSupport = preload("test_support.gd")

static func run() -> Dictionary:
	var runtime := AeroContentAuthoring.new()
	runtime.initialize()
	var stage_dir := ProjectSettings.globalize_path("res://assets/fixtures/beatsaver_stage_real_world_legacy_v2")
	var convert_result: Dictionary = runtime.convert_beatsaver_stage_to_current_package(stage_dir)
	var state: Dictionary = Dictionary(convert_result.get("state", {}))
	var songs: Array = Array(state.get("songs", []))
	var song_record: Dictionary = Dictionary(songs[0]) if not songs.is_empty() else {}
	var song_audio: Dictionary = Dictionary(song_record.get("audio", {}))
	var summary: Dictionary = Dictionary(convert_result.get("summary", {}))
	var chart_ids: Array = []
	for chart_variant in Array(state.get("charts", [])):
		chart_ids.append(String(Dictionary(chart_variant).get("chartId", "")))
	chart_ids.sort()
	var validation: Dictionary = runtime.validate_current_package()
	var save_parent := TestSupport.tmp_dir("beatsaver_stage_conversion_service_real_world_legacy_v2")
	TestSupport.ensure_clean_dir(save_parent)
	var save_result: Dictionary = runtime.save_current_package(save_parent)
	var output_dir := String(save_result.get("outputDir", ""))
	var report_path := output_dir.path_join(".artifacts/conversion-report.json")
	var report_text := TestSupport.read_text(report_path) if FileAccess.file_exists(report_path) else ""
	var package_validation := runtime.get_validate_package_service().validate_path(output_dir, "package") if not output_dir.is_empty() else {"valid": false}
	var charts: Array = Array(state.get("charts", []))
	var boxing_chart := _find_chart(charts, "boxing")
	var flow_chart := _find_chart(charts, "flow")
	var boxing_counts := _beat_counts(Array(boxing_chart.get("beats", [])))
	var flow_counts := _beat_counts(Array(flow_chart.get("beats", [])))
	var flow_chart_validation: Dictionary = ValidateChartService.new().validate_chart_record(flow_chart, "state://charts/flow")
	var first_bomb := _find_flow_beat(Array(flow_chart.get("beats", [])), "bomb", 163.125)
	var passed := bool(convert_result.get("ok", false)) \
		and bool(validation.get("valid", false)) \
		and bool(save_result.get("ok", false)) \
		and bool(package_validation.get("valid", false)) \
		and String(package_validation.get("delegatedValidator", "")) == "aerobeat-content-core" \
		and bool(flow_chart_validation.get("valid", false)) \
		and String(flow_chart_validation.get("delegatedValidator", "")) == "aerobeat-content-core" \
		and chart_ids == ["ab-chart-me-u-boxing-hard", "ab-chart-me-u-flow-hard"] \
		and String(song_record.get("songName", "")) == "me & u" \
		and String(song_audio.get("filePath", "")) == "media/audio/me-u.egg" \
		and is_equal_approx(float(song_audio.get("previewStartTime", -1.0)), 88.0) \
		and is_equal_approx(float(song_audio.get("previewDuration", -1.0)), 15.0) \
		and String(song_audio.get("previewMode", "")) == "song_file_clip" \
		and int(summary.get("chartCount", 0)) == 2 \
		and int(flow_counts.get("note", 0)) == 337 \
		and int(flow_counts.get("bomb", 0)) == 28 \
		and int(flow_counts.get("obstacle", 0)) == 11 \
		and int(boxing_counts.get("guard", 0)) == 18 \
		and int(boxing_counts.get("uppercut_left", 0)) == 87 \
		and int(boxing_counts.get("uppercut_right", 0)) == 68 \
		and int(boxing_counts.get("weave_left", 0)) == 1 \
		and int(boxing_counts.get("weave_right", 0)) == 1 \
		and int(first_bomb.get("placement", -1)) == 0 \
		and report_text.contains('"sourceFamily": "bomb"') \
		and report_text.contains('"sourceFamily": "obstacle"') \
		and not report_text.contains("legacy_beatmap_object_normalization_pending")
	return {
		"name": "test_beatsaver_stage_conversion_service_real_world_legacy_v2",
		"passed": passed,
		"details": {
			"convertResult": convert_result,
			"validation": validation,
			"saveResult": save_result,
			"packageValidation": package_validation,
			"flowChartValidation": flow_chart_validation,
			"chartIds": chart_ids,
			"boxingCounts": boxing_counts,
			"flowCounts": flow_counts,
			"reportPath": report_path,
			"songRecord": song_record,
			"songAudio": song_audio,
		}
	}

static func _find_chart(charts: Array, feature: String) -> Dictionary:
	for chart_variant in charts:
		var chart: Dictionary = Dictionary(chart_variant)
		if String(chart.get("feature", "")) == feature:
			return chart
	return {}

static func _beat_counts(beats: Array) -> Dictionary:
	var counts := {}
	for beat_variant in beats:
		var beat_type := String(Dictionary(beat_variant).get("type", ""))
		counts[beat_type] = int(counts.get(beat_type, 0)) + 1
	return counts

static func _find_flow_beat(flow_beats: Array, beat_type: String, start: float) -> Dictionary:
	for beat_variant in flow_beats:
		var beat: Dictionary = Dictionary(beat_variant)
		if String(beat.get("type", "")) != beat_type:
			continue
		if is_equal_approx(float(beat.get("start", -9999.0)), start):
			return beat
	return {}
