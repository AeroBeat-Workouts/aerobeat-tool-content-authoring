extends RefCounted

const ContentAuthoringPlugin = preload("../editor/plugins/content_authoring_plugin.gd")
const ValidatePackageService = preload("../services/validation/validate_package_service.gd")
const BuildContentPackageService = preload("../services/packaging/build_content_package_service.gd")
const ChartAuthoringService = preload("../services/authoring/chart_authoring_service.gd")

static func run() -> Dictionary:
	var registry: Dictionary = ContentAuthoringPlugin.build_service_registry()
	var validate_service: Variant = registry.get("validate_package")
	var build_service: Variant = registry.get("build_content_package")
	var chart_authoring_service: Variant = registry.get("chart_authoring")
	var passed := validate_service is ValidatePackageService \
		and build_service is BuildContentPackageService \
		and chart_authoring_service is ChartAuthoringService
	return {
		"name": "test_editor_uses_shared_services",
		"passed": passed,
		"details": {
			"serviceKeys": registry.keys(),
		},
	}
