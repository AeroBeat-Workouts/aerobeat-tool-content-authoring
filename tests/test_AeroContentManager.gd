extends RefCounted

const ADDON_AERO_CONTENT_MANAGER_PATH := "res://addons/aerobeat-tool-content-authoring/src/AeroContentManager.gd"
const ADDON_VALIDATE_PACKAGE_SERVICE_PATH := "res://addons/aerobeat-tool-content-authoring/services/validation/validate_package_service.gd"
const ADDON_BUILD_CONTENT_PACKAGE_SERVICE_PATH := "res://addons/aerobeat-tool-content-authoring/services/packaging/build_content_package_service.gd"
const ADDON_CHART_AUTHORING_SERVICE_PATH := "res://addons/aerobeat-tool-content-authoring/services/authoring/chart_authoring_service.gd"

static func run() -> Dictionary:
	var facade_script: Script = load(ADDON_AERO_CONTENT_MANAGER_PATH)
	var facade = facade_script.new()
	facade._initialize()
	var validate_service: Variant = facade.get_validate_package_service()
	var build_service: Variant = facade.get_build_content_package_service()
	var chart_authoring_service: Variant = facade.get_chart_authoring_service()
	var passed: bool = facade.is_active \
		and validate_service != null \
		and String(validate_service.get_script().resource_path) == ADDON_VALIDATE_PACKAGE_SERVICE_PATH \
		and build_service != null \
		and String(build_service.get_script().resource_path) == ADDON_BUILD_CONTENT_PACKAGE_SERVICE_PATH \
		and chart_authoring_service != null \
		and String(chart_authoring_service.get_script().resource_path) == ADDON_CHART_AUTHORING_SERVICE_PATH
	return {
		"name": "test_AeroContentManager",
		"passed": passed,
		"details": {
			"isActive": facade.is_active,
			"isInitialized": facade._is_initialized,
			"serviceKeys": facade._service_registry.keys(),
			"scriptPath": String(facade.get_script().resource_path),
		},
	}
