extends RefCounted

const ADDON_PLUGIN_PATH := "res://addons/aerobeat-tool-content-authoring/editor/plugins/content_authoring_plugin.gd"
const ADDON_VALIDATE_PACKAGE_SERVICE_PATH := "res://addons/aerobeat-tool-content-authoring/services/validation/validate_package_service.gd"
const ADDON_BUILD_CONTENT_PACKAGE_SERVICE_PATH := "res://addons/aerobeat-tool-content-authoring/services/packaging/build_content_package_service.gd"
const ADDON_CHART_AUTHORING_SERVICE_PATH := "res://addons/aerobeat-tool-content-authoring/services/authoring/chart_authoring_service.gd"

static func run() -> Dictionary:
	var plugin_script: Script = load(ADDON_PLUGIN_PATH)
	var registry: Dictionary = plugin_script.build_service_registry()
	var validate_service: Variant = registry.get("validate_package")
	var build_service: Variant = registry.get("build_content_package")
	var chart_authoring_service: Variant = registry.get("chart_authoring")
	var passed: bool = validate_service != null \
		and String(validate_service.get_script().resource_path) == ADDON_VALIDATE_PACKAGE_SERVICE_PATH \
		and build_service != null \
		and String(build_service.get_script().resource_path) == ADDON_BUILD_CONTENT_PACKAGE_SERVICE_PATH \
		and chart_authoring_service != null \
		and String(chart_authoring_service.get_script().resource_path) == ADDON_CHART_AUTHORING_SERVICE_PATH
	return {
		"name": "test_editor_uses_shared_services",
		"passed": passed,
		"details": {
			"pluginPath": ADDON_PLUGIN_PATH,
			"serviceKeys": registry.keys(),
			"validateScript": String(validate_service.get_script().resource_path) if validate_service != null else "",
			"buildScript": String(build_service.get_script().resource_path) if build_service != null else "",
			"chartAuthoringScript": String(chart_authoring_service.get_script().resource_path) if chart_authoring_service != null else "",
		},
	}
