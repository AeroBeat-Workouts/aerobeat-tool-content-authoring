class_name AeroToolManager
extends Node

const ValidatePackageService = preload("../services/validation/validate_package_service.gd")
const BuildContentPackageService = preload("../services/packaging/build_content_package_service.gd")
const ChartAuthoringService = preload("../services/authoring/chart_authoring_service.gd")
const ContentAuthoringPlugin = preload("../editor/plugins/content_authoring_plugin.gd")

signal initialized

const VERSION: String = "0.1.0"

@export var is_active: bool = true

var _is_initialized: bool = false
var _service_registry: Dictionary = {}

func _ready() -> void:
	_initialize()

func _initialize() -> void:
	if _is_initialized:
		return
	_service_registry = ContentAuthoringPlugin.build_service_registry()
	_is_initialized = true
	initialized.emit()

func get_validate_package_service() -> ValidatePackageService:
	return _service_registry.get("validate_package") as ValidatePackageService

func get_build_content_package_service() -> BuildContentPackageService:
	return _service_registry.get("build_content_package") as BuildContentPackageService

func get_chart_authoring_service() -> ChartAuthoringService:
	return _service_registry.get("chart_authoring") as ChartAuthoringService
