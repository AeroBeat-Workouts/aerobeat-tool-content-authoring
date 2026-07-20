extends RefCounted

const AeroContentAuthoring = preload("res://addons/aerobeat-tool-content-authoring/src/AeroContentAuthoring.gd")
const TestSupport = preload("test_support.gd")

static func run() -> Dictionary:
	var runtime := AeroContentAuthoring.new()
	runtime.initialize()
	var stage_dir := ProjectSettings.globalize_path("res://assets/fixtures/beatsaver_stage_minimal")
	var convert_result: Dictionary = runtime.convert_beatsaver_stage_to_current_package(stage_dir)
	var state: Dictionary = Dictionary(convert_result.get("state", {}))
	var summary: Dictionary = Dictionary(convert_result.get("summary", {}))
	var chart_ids: Array = []
	for chart_variant in Array(state.get("charts", [])):
		chart_ids.append(String(Dictionary(chart_variant).get("chartId", "")))
	chart_ids.sort()
	var validation: Dictionary = runtime.validate_current_package()
	var save_parent := TestSupport.tmp_dir("beatsaver_stage_conversion_service")
	TestSupport.ensure_clean_dir(save_parent)
	var save_result: Dictionary = runtime.save_current_package(save_parent)
	var output_dir := String(save_result.get("outputDir", ""))
	var report_path := output_dir.path_join(".artifacts/beatsaver/conversion/report.json")
	var report_text := TestSupport.read_text(report_path) if FileAccess.file_exists(report_path) else ""
	var package_validation := runtime.get_validate_package_service().validate_path(output_dir, "package") if not output_dir.is_empty() else {"valid": false}
	var charts: Array = Array(state.get("charts", []))
	var boxing_chart := _find_chart(charts, "boxing")
	var flow_chart := _find_chart(charts, "flow")
	var boxing_types: Array = []
	for beat_variant in Array(boxing_chart.get("beats", [])):
		boxing_types.append(String(Dictionary(beat_variant).get("type", "")))
	var flow_beats: Array = Array(flow_chart.get("beats", []))
	var passed := bool(convert_result.get("ok", false)) \
		and bool(validation.get("valid", false)) \
		and bool(save_result.get("ok", false)) \
		and bool(package_validation.get("valid", false)) \
		and chart_ids == ["ab-chart-synthetic-beatsaver-demo-boxing-hard", "ab-chart-synthetic-beatsaver-demo-flow-hard"] \
		and boxing_types == ["straight_left", "guard", "uppercut_right", "hook_left", "squat", "hook_left", "straight_right", "uppercut_left"] \
		and flow_beats.size() == 1 \
		and String(flow_beats[0].get("type", "")) == "burst" \
		and report_text.contains("artifact_only_contract_gap") \
		and report_text.contains("burstSlider") \
		and int(summary.get("chartCount", 0)) == 2
	return {
		"name": "test_beatsaver_stage_conversion_service",
		"passed": passed,
		"details": {
			"convertResult": convert_result,
			"validation": validation,
			"saveResult": save_result,
			"packageValidation": package_validation,
			"chartIds": chart_ids,
			"boxingTypes": boxing_types,
			"flowBeats": flow_beats,
			"reportPath": report_path,
		}
	}

static func _find_chart(charts: Array, feature: String) -> Dictionary:
	for chart_variant in charts:
		var chart: Dictionary = Dictionary(chart_variant)
		if String(chart.get("feature", "")) == feature:
			return chart
	return {}
