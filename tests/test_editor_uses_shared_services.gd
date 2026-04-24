extends RefCounted

const ContentAuthoringPlugin = preload("../editor/plugins/content_authoring_plugin.gd")
const ValidatePackageService = preload("../services/validation/validate_package_service.gd")
const BuildContentPackageService = preload("../services/packaging/build_content_package_service.gd")

static func run() -> Dictionary:
	var registry: Dictionary = ContentAuthoringPlugin.build_service_registry()
	var validate_service: Variant = registry.get("validate_package")
	var build_service: Variant = registry.get("build_content_package")
	var passed := validate_service is ValidatePackageService and build_service is BuildContentPackageService
	return {
		"name": "test_editor_uses_shared_services",
		"passed": passed,
		"details": {
			"serviceKeys": registry.keys(),
		},
	}
