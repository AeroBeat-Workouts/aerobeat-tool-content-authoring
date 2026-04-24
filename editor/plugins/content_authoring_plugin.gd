@tool
class_name ContentAuthoringPlugin
extends EditorPlugin

const ValidatePackageService = preload("../../services/validation/validate_package_service.gd")
const BuildContentPackageService = preload("../../services/packaging/build_content_package_service.gd")
const RefreshContentIndexService = preload("../../services/registry/refresh_content_index_service.gd")
const ChartAuthoringService = preload("../../services/authoring/chart_authoring_service.gd")

static func build_service_registry() -> Dictionary:
	return {
		"validate_package": ValidatePackageService.new(),
		"build_content_package": BuildContentPackageService.new(),
		"refresh_content_index": RefreshContentIndexService.new(),
		"chart_authoring": ChartAuthoringService.new(),
	}

func _enter_tree() -> void:
	pass

func _exit_tree() -> void:
	pass
