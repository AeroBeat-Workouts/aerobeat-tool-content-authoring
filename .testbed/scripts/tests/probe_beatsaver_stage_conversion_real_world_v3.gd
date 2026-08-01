extends SceneTree

const AeroContentAuthoring = preload("res://addons/aerobeat-tool-content-authoring/src/AeroContentAuthoring.gd")
const ValidateChartService = preload("res://addons/aerobeat-tool-content-authoring/src/services/validation/validate_chart_service.gd")

const STAGE_DIR := "res://../../aerobeat-vendor-beatsaver/.testbed/.artifacts/qa_live/524b6/e93accd8cfd9265c80141cead1c74dea2faf70ec"

func _initialize() -> void:
	var runtime := AeroContentAuthoring.new()
	runtime.initialize()
	var stage_dir := ProjectSettings.globalize_path(STAGE_DIR)
	var result: Dictionary = {
		"name": "probe_beatsaver_stage_conversion_real_world_v3",
		"stageDir": stage_dir,
	}
	if not DirAccess.dir_exists_absolute(stage_dir):
		result["passed"] = false
		result["reason"] = "missing_stage_dir"
		print(JSON.stringify(result, "  "))
		quit(1)
		return
	var convert_result: Dictionary = runtime.convert_beatsaver_stage_to_current_package(stage_dir)
	var state: Dictionary = Dictionary(convert_result.get("state", {}))
	var charts: Array = Array(state.get("charts", []))
	var package_validation: Dictionary = runtime.validate_current_package()
	var flow_counts := {}
	var boxing_counts := {}
	var flow_chart_valid := true
	for chart_variant in charts:
		var chart: Dictionary = Dictionary(chart_variant)
		var mode := String(chart.get("mode", ""))
		var beats: Array = Array(chart.get("beats", []))
		if mode == "flow":
			for beat_variant in beats:
				var beat_type := String(Dictionary(beat_variant).get("type", ""))
				flow_counts[beat_type] = int(flow_counts.get(beat_type, 0)) + 1
			flow_chart_valid = flow_chart_valid and bool(ValidateChartService.new().validate_chart_record(chart, "state://charts/%s" % String(chart.get("chartId", "flow"))).get("valid", false))
		elif mode == "boxing":
			for beat_variant in beats:
				var beat_type := String(Dictionary(beat_variant).get("type", ""))
				boxing_counts[beat_type] = int(boxing_counts.get(beat_type, 0)) + 1
	result["convertSummary"] = convert_result.get("summary", {})
	result["packageValidation"] = package_validation
	result["flowCounts"] = flow_counts
	result["boxingCounts"] = boxing_counts
	result["passed"] = bool(convert_result.get("ok", false)) \
		and bool(package_validation.get("valid", false)) \
		and String(package_validation.get("delegatedValidator", "")) == "aerobeat-content-core" \
		and flow_chart_valid \
		and int(Array(state.get("charts", [])).size()) == 6 \
		and int(flow_counts.get("note", 0)) >= 1900 \
		and int(flow_counts.get("obstacle", 0)) >= 650 \
		and int(flow_counts.get("arc", 0)) >= 350 \
		and int(flow_counts.get("burst", 0)) >= 20 \
		and int(boxing_counts.get("guard", 0)) >= 60 \
		and int(boxing_counts.get("straight_left", 0)) >= 200 \
		and int(boxing_counts.get("uppercut_right", 0)) >= 400 \
		and int(boxing_counts.get("weave_left", 0)) >= 30
	print(JSON.stringify(result, "  "))
	quit(0 if bool(result.get("passed", false)) else 1)
