extends RefCounted

const AeroContentAuthoring = preload("res://addons/aerobeat-tool-content-authoring/src/AeroContentAuthoring.gd")
const TestSupport = preload("test_support.gd")

const CASES := [
	{
		"name": "jpg",
		"stageDir": "res://assets/fixtures/beatsaver_stage_cover_jpg",
		"environmentId": "ab-environment-synthetic-beatsaver-jpg-cover-demo-cover",
		"resourcePath": "media/environments/synthetic-beatsaver-jpg-cover-demo-cover.jpg",
	},
	{
		"name": "jpeg",
		"stageDir": "res://assets/fixtures/beatsaver_stage_cover_jpeg",
		"environmentId": "ab-environment-synthetic-beatsaver-jpeg-cover-demo-cover",
		"resourcePath": "media/environments/synthetic-beatsaver-jpeg-cover-demo-cover.jpeg",
	},
]

static func run() -> Dictionary:
	var case_results: Array = []
	var passed := true
	for case_data in CASES:
		var result := _run_case(Dictionary(case_data))
		case_results.append(result)
		if not bool(result.get("passed", false)):
			passed = false
	return {
		"name": "test_beatsaver_stage_cover_image_import_service",
		"passed": passed,
		"details": {"cases": case_results},
	}

static func _run_case(case_data: Dictionary) -> Dictionary:
	var runtime := AeroContentAuthoring.new()
	runtime.initialize()
	var stage_dir := ProjectSettings.globalize_path(String(case_data.get("stageDir", "")))
	var convert_result: Dictionary = runtime.convert_beatsaver_stage_to_current_package(stage_dir)
	var state: Dictionary = Dictionary(convert_result.get("state", {}))
	var environments: Array = Array(state.get("environments", []))
	var environment_record: Dictionary = Dictionary(environments[0]) if environments.size() == 1 else {}
	var validation: Dictionary = runtime.validate_current_package()
	var save_parent := TestSupport.tmp_dir("beatsaver_stage_cover_image_import_%s" % String(case_data.get("name", "case")))
	TestSupport.ensure_clean_dir(save_parent)
	var save_result: Dictionary = runtime.save_current_package(save_parent)
	var output_dir := String(save_result.get("outputDir", ""))
	var zip_path := String(save_result.get("zipPath", ""))
	var expected_resource_path := String(case_data.get("resourcePath", ""))
	var saved_cover_path := output_dir.path_join(expected_resource_path)
	var package_validation := runtime.get_validate_package_service().validate_path(output_dir, "package") if not output_dir.is_empty() else {"valid": false}
	var zip_files := _zip_files(zip_path)
	var passed := bool(convert_result.get("ok", false)) \
		and environments.size() == 1 \
		and String(environment_record.get("environmentId", "")) == String(case_data.get("environmentId", "")) \
		and String(environment_record.get("type", "")) == "image_background" \
		and String(environment_record.get("resourcePath", "")) == expected_resource_path \
		and bool(validation.get("valid", false)) \
		and bool(save_result.get("ok", false)) \
		and bool(package_validation.get("valid", false)) \
		and FileAccess.file_exists(saved_cover_path) \
		and zip_files.has(expected_resource_path) \
		and zip_files.has("environments/%s.yaml" % String(case_data.get("environmentId", "")))
	return {
		"case": case_data,
		"passed": passed,
		"details": {
			"convertResult": convert_result,
			"validation": validation,
			"saveResult": save_result,
			"packageValidation": package_validation,
			"environmentRecord": environment_record,
			"zipFiles": zip_files,
		}
	}

static func _zip_files(zip_path: String) -> Array:
	if zip_path.is_empty() or not FileAccess.file_exists(zip_path):
		return []
	var reader := ZIPReader.new()
	if reader.open(zip_path) != OK:
		return []
	var files: Array = []
	for path_variant in reader.get_files():
		files.append(String(path_variant))
	reader.close()
	files.sort()
	return files
