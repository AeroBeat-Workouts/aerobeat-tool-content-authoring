extends RefCounted

const AeroContentAuthoring = preload("res://addons/aerobeat-tool-content-authoring/src/AeroContentAuthoring.gd")
const TestSupport = preload("test_support.gd")

static func run() -> Dictionary:
	var runtime := AeroContentAuthoring.new()
	var initial_state := runtime.get_current_package_state()
	var initial_sets: Array = Array(initial_state.get("sets", []))
	var initial_order: Array = Array(Dictionary(initial_state.get("workout", {})).get("setOrder", []))

	var fixture_dir := TestSupport.tmp_dir("task6_runtime_fixture")
	TestSupport.ensure_clean_dir(fixture_dir)
	var chart_path := fixture_dir.path_join("sample-chart.yaml")
	TestSupport.write_text(chart_path, "chartId: ab-chart-preview\nchartName: Preview Chart\nfeature: boxing\ndifficulty: hard\nsongId: ab-song-preview\nbeats:\n  - beat: 1\n")
	var environment_path := fixture_dir.path_join("preview-environment.ogv")
	var environment_config_path := fixture_dir.path_join("preview-environment.config.yaml")
	var audio_path := fixture_dir.path_join("coaching.ogg")
	var warmup_path := fixture_dir.path_join("warmup.ogv")
	var cooldown_path := fixture_dir.path_join("cooldown.ogv")
	var audio_bytes := PackedByteArray([0, 1, 2, 3])
	for asset_path in [environment_path, audio_path, warmup_path, cooldown_path]:
		var file := FileAccess.open(asset_path, FileAccess.WRITE)
		if file != null:
			file.store_buffer(audio_bytes)
	TestSupport.write_text(environment_config_path, "fit_mode: contain\nposition: [0, 0, 0]\n")

	var create_result := runtime.create_set({"setName": "Set 2"})
	var second_set_id := String(Dictionary(create_result.get("set", {})).get("setId", ""))
	var beatmap_result := runtime.import_beatmap_for_set(second_set_id, chart_path)
	var primary_environment_result := runtime.assign_environment_to_set(second_set_id, "preferred", environment_path)
	var fallback_environment_result := runtime.assign_environment_to_set(second_set_id, "fallback", environment_path)
	var coaching_audio_result := runtime.assign_coaching_audio_to_set(second_set_id, audio_path)
	var warmup_result := runtime.set_coach_video_source("warmup", warmup_path)
	var cooldown_result := runtime.set_coach_video_source("cooldown", cooldown_path)
	var preview_request_result := runtime.resolve_environment_preview_request(second_set_id)
	var delete_result := runtime.delete_set(second_set_id)
	var post_delete_state := Dictionary(delete_result.get("state", {}))

	var passed := initial_sets.size() == 1 \
		and initial_order.size() == 1 \
		and bool(beatmap_result.get("ok", false)) \
		and bool(primary_environment_result.get("ok", false)) \
		and bool(fallback_environment_result.get("ok", false)) \
		and bool(coaching_audio_result.get("ok", false)) \
		and bool(warmup_result.get("ok", false)) \
		and bool(cooldown_result.get("ok", false)) \
		and bool(preview_request_result.get("ok", false)) \
		and String(Dictionary(preview_request_result.get("request", {})).get("fit_mode", "")) == "contain" \
		and Array(post_delete_state.get("sets", [])).size() >= 1

	return {
		"name": "test_task6_set_authoring_runtime",
		"passed": passed,
		"details": {
			"initialState": initial_state,
			"createResult": create_result,
			"beatmapResult": beatmap_result,
			"primaryEnvironmentResult": primary_environment_result,
			"fallbackEnvironmentResult": fallback_environment_result,
			"coachingAudioResult": coaching_audio_result,
			"warmupResult": warmup_result,
			"cooldownResult": cooldown_result,
			"previewRequestResult": preview_request_result,
			"deleteResult": delete_result,
		},
	}
