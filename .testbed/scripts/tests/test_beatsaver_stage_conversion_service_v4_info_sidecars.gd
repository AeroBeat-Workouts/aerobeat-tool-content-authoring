extends RefCounted

const AeroContentAuthoring = preload("res://addons/aerobeat-tool-content-authoring/src/AeroContentAuthoring.gd")
const ValidateChartService = preload("res://addons/aerobeat-tool-content-authoring/src/services/validation/validate_chart_service.gd")
const TestSupport = preload("test_support.gd")

static func run() -> Dictionary:
	var runtime := AeroContentAuthoring.new()
	runtime.initialize()
	var stage_dir := ProjectSettings.globalize_path("res://assets/fixtures/beatsaver_stage_v4_info_sidecars")
	var convert_result: Dictionary = runtime.convert_beatsaver_stage_to_current_package(stage_dir)
	var state: Dictionary = Dictionary(convert_result.get("state", {}))
	var songs: Array = Array(state.get("songs", []))
	var song_record: Dictionary = Dictionary(songs[0]) if not songs.is_empty() else {}
	var summary: Dictionary = Dictionary(convert_result.get("summary", {}))
	var chart_ids: Array = []
	for chart_variant in Array(state.get("charts", [])):
		chart_ids.append(String(Dictionary(chart_variant).get("chartId", "")))
	chart_ids.sort()
	var validation: Dictionary = runtime.validate_current_package()
	var save_parent := TestSupport.tmp_dir("beatsaver_stage_conversion_service_v4_info_sidecars")
	TestSupport.ensure_clean_dir(save_parent)
	var save_result: Dictionary = runtime.save_current_package(save_parent)
	var output_dir := String(save_result.get("outputDir", ""))
	var report_path := output_dir.path_join(".artifacts/beatsaver/conversion/report.json")
	var report_text := TestSupport.read_text(report_path) if FileAccess.file_exists(report_path) else ""
	var package_validation := runtime.get_validate_package_service().validate_path(output_dir, "package") if not output_dir.is_empty() else {"valid": false}
	var charts: Array = Array(state.get("charts", []))
	var boxing_chart := _find_chart(charts, "boxing")
	var flow_chart := _find_chart(charts, "flow")
	var flow_beats: Array = Array(flow_chart.get("beats", []))
	var flow_types: Array = []
	for beat_variant in flow_beats:
		flow_types.append(String(Dictionary(beat_variant).get("type", "")))
	var flow_chart_validation: Dictionary = ValidateChartService.new().validate_chart_record(flow_chart, "state://charts/flow")
	var draft_asset_sources: Dictionary = Dictionary(state.get("draftAssetSources", {}))
	var source_keys: Array = draft_asset_sources.keys()
	source_keys.sort()
	var saved_main_audio := output_dir.path_join("media/audio/synthetic-beatsaver-v4-info-demo.egg")
	var saved_preview_audio := output_dir.path_join("media/audio/preview.ogg")
	var passed := bool(convert_result.get("ok", false)) \
		and bool(validation.get("valid", false)) \
		and bool(save_result.get("ok", false)) \
		and bool(package_validation.get("valid", false)) \
		and String(package_validation.get("delegatedValidator", "")) == "aerobeat-content-core" \
		and bool(flow_chart_validation.get("valid", false)) \
		and String(flow_chart_validation.get("delegatedValidator", "")) == "aerobeat-content-core" \
		and chart_ids == ["ab-chart-synthetic-beatsaver-v4-info-demo-boxing-hard", "ab-chart-synthetic-beatsaver-v4-info-demo-flow-hard"] \
		and int(summary.get("chartCount", 0)) == 2 \
		and String(song_record.get("songName", "")) == "Synthetic BeatSaver V4 Info Demo" \
		and int(song_record.get("durationSec", 0)) == 8 \
		and String(Dictionary(song_record.get("audio", {})).get("filePath", "")) == "media/audio/synthetic-beatsaver-v4-info-demo.egg" \
		and source_keys.has("media/audio/synthetic-beatsaver-v4-info-demo.egg") \
		and not source_keys.has("media/audio/preview.ogg") \
		and FileAccess.file_exists(saved_main_audio) \
		and not FileAccess.file_exists(saved_preview_audio) \
		and flow_types == ["note", "note", "note", "note", "note", "note", "note", "obstacle", "obstacle", "bomb", "note", "arc", "note", "burst"] \
		and report_text.contains('"sourceFamily": "burstSlider"') \
		and report_text.contains('"sourceFamily": "slider"')
	return {
		"name": "test_beatsaver_stage_conversion_service_v4_info_sidecars",
		"passed": passed,
		"details": {
			"convertResult": convert_result,
			"validation": validation,
			"saveResult": save_result,
			"packageValidation": package_validation,
			"flowChartValidation": flow_chart_validation,
			"chartIds": chart_ids,
			"draftAssetSourceKeys": source_keys,
			"songRecord": song_record,
			"reportPath": report_path,
		}
	}

static func _find_chart(charts: Array, feature: String) -> Dictionary:
	for chart_variant in charts:
		var chart: Dictionary = Dictionary(chart_variant)
		if String(chart.get("feature", "")) == feature:
			return chart
	return {}
