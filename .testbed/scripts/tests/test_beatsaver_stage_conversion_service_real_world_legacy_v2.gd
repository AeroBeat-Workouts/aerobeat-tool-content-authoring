extends RefCounted

const AeroContentAuthoring = preload("res://addons/aerobeat-tool-content-authoring/src/AeroContentAuthoring.gd")

static func run() -> Dictionary:
	var runtime := AeroContentAuthoring.new()
	runtime.initialize()
	var stage_dir := ProjectSettings.globalize_path("res://assets/fixtures/beatsaver_stage_real_world_legacy_v2")
	var convert_result: Dictionary = runtime.convert_beatsaver_stage_to_current_package(stage_dir)
	var details: Dictionary = Dictionary(convert_result.get("details", {}))
	var passed := not bool(convert_result.get("ok", true)) \
		and String(convert_result.get("errorCode", "")) == "legacy_beatmap_object_normalization_pending" \
		and String(details.get("path", "")) == "Hard.dat" \
		and String(details.get("version", "")) == "2.0.0" \
		and String(details.get("versionFamily", "")) == "legacy_v2"
	return {
		"name": "test_beatsaver_stage_conversion_service_real_world_legacy_v2",
		"passed": passed,
		"details": {
			"convertResult": convert_result,
			"stageDir": stage_dir,
		}
	}
