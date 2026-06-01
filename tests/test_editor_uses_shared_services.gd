extends RefCounted

const AeroContentAuthoring = preload("../src/AeroContentAuthoring.gd")
const ContentAuthoringPlugin = preload("../editor/plugins/content_authoring_plugin.gd")
const WorkoutPackageValidationService = preload("../services/validation/workout_package_validation_service.gd")
const BuildContentPackageService = preload("../services/packaging/build_content_package_service.gd")
const RefreshContentIndexService = preload("../services/registry/refresh_content_index_service.gd")
const WorkoutPackageWorkflowService = preload("../services/workflow/workout_package_workflow_service.gd")

static func run() -> Dictionary:
	var runtime := AeroContentAuthoring.new()
	var registry: Dictionary = runtime.get_service_registry()
	var plugin_registry: Dictionary = ContentAuthoringPlugin.build_service_registry()
	var validate_service: Variant = registry.get("validate_package")
	var build_service: Variant = registry.get("build_content_package")
	var refresh_service: Variant = registry.get("refresh_content_index")
	var workflow_service: Variant = registry.get("package_workflow")
	var runtime_keys: Array = registry.keys()
	var plugin_keys: Array = plugin_registry.keys()
	runtime_keys.sort()
	plugin_keys.sort()
	var passed := runtime.is_initialized() \
		and validate_service is WorkoutPackageValidationService \
		and build_service is BuildContentPackageService \
		and refresh_service is RefreshContentIndexService \
		and workflow_service is WorkoutPackageWorkflowService \
		and runtime_keys == plugin_keys
	return {
		"name": "test_editor_uses_shared_services",
		"passed": passed,
		"details": {
			"serviceKeys": registry.keys(),
			"pluginServiceKeys": plugin_registry.keys(),
		},
	}
