extends RefCounted

const AeroContentAuthoring = preload("res://addons/aerobeat-tool-content-authoring/src/AeroContentAuthoring.gd")

static func run() -> Dictionary:
	var runtime := AeroContentAuthoring.new()
	runtime.initialize()
	var v1_stage_dir := ProjectSettings.globalize_path("res://assets/fixtures/beatsaver_stage_legacy_v1_synthetic")
	var v2_stage_dir := ProjectSettings.globalize_path("res://assets/fixtures/beatsaver_stage_real_world_legacy_v2")
	var v1_inspect: Dictionary = runtime.inspect_beatsaver_stage_source(v1_stage_dir)
	var v2_inspect: Dictionary = runtime.inspect_beatsaver_stage_source(v2_stage_dir)
	var v1_metadata: Dictionary = Dictionary(v1_inspect.get("metadata", {}))
	var v2_metadata: Dictionary = Dictionary(v2_inspect.get("metadata", {}))
	var v1_difficulties: Array = Array(v1_inspect.get("difficulties", []))
	var v2_difficulties: Array = Array(v2_inspect.get("difficulties", []))
	var v1_first: Dictionary = Dictionary(v1_difficulties[0]) if not v1_difficulties.is_empty() else {}
	var v1_second: Dictionary = Dictionary(v1_difficulties[1]) if v1_difficulties.size() > 1 else {}
	var v2_first: Dictionary = Dictionary(v2_difficulties[0]) if not v2_difficulties.is_empty() else {}
	var v1_passed := bool(v1_inspect.get("ok", false)) \
		and String(v1_metadata.get("songName", "")) == "Synthetic Legacy V1 Demo" \
		and is_equal_approx(float(v1_metadata.get("bpm", 0.0)), 128.0) \
		and String(v1_metadata.get("songFilename", "")) == "legacy-v1-demo.ogg" \
		and String(v1_metadata.get("coverImageFilename", "")) == "legacy-cover.png" \
		and v1_difficulties.size() == 2 \
		and String(v1_first.get("difficulty", "")) == "Hard" \
		and int(v1_first.get("difficultyRank", -1)) == 5 \
		and String(v1_first.get("path", "")) == "Hard.dat" \
		and String(v1_first.get("beatmapVersion", "")) == "1.5.0" \
		and String(v1_first.get("beatmapVersionFamily", "")) == "legacy_v1" \
		and String(v1_second.get("difficulty", "")) == "ExpertPlus" \
		and int(v1_second.get("difficultyRank", -1)) == 9 \
		and String(v1_second.get("path", "")) == "ExpertPlus.dat" \
		and String(v1_second.get("beatmapVersionFamily", "")) == "legacy_v1"
	var v2_passed := bool(v2_inspect.get("ok", false)) \
		and String(v2_metadata.get("songName", "")) == "me & u" \
		and is_equal_approx(float(v2_metadata.get("bpm", 0.0)), 80.0) \
		and String(v2_metadata.get("songFilename", "")) == "me & u.egg" \
		and String(v2_metadata.get("coverImageFilename", "")) == "cover.jpg" \
		and v2_difficulties.size() == 1 \
		and String(v2_first.get("difficulty", "")) == "Hard" \
		and int(v2_first.get("difficultyRank", -1)) == 5 \
		and String(v2_first.get("path", "")) == "Hard.dat" \
		and String(v2_first.get("beatmapVersion", "")) == "2.0.0" \
		and String(v2_first.get("beatmapVersionFamily", "")) == "legacy_v2"
	return {
		"name": "test_beatsaver_stage_legacy_metadata_normalization",
		"passed": v1_passed and v2_passed,
		"details": {
			"v1Inspect": v1_inspect,
			"v2Inspect": v2_inspect,
		}
	}
