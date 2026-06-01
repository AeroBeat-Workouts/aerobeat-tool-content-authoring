@tool
class_name AeroContentAuthoring
extends Node

const ValidatePackageService = preload("../services/validation/validate_package_service.gd")
const BuildContentPackageService = preload("../services/packaging/build_content_package_service.gd")
const RefreshContentIndexService = preload("../services/registry/refresh_content_index_service.gd")
const ChartAuthoringService = preload("../services/authoring/chart_authoring_service.gd")

signal initialized
signal reset

const VERSION: String = "0.2.0"

@export var auto_initialize: bool = true

var _is_initialized: bool = false
var _service_registry: Dictionary = {}

static func build_service_registry() -> Dictionary:
	return {
		"validate_package": ValidatePackageService.new(),
		"build_content_package": BuildContentPackageService.new(),
		"refresh_content_index": RefreshContentIndexService.new(),
		"chart_authoring": ChartAuthoringService.new(),
	}

func _ready() -> void:
	if auto_initialize:
		initialize()

func initialize() -> void:
	if _is_initialized:
		return
	_service_registry = build_service_registry()
	_is_initialized = true
	initialized.emit()

func reset_runtime_state() -> void:
	_service_registry = {}
	_is_initialized = false
	reset.emit()

func is_initialized() -> bool:
	return _is_initialized

func get_service_registry() -> Dictionary:
	if not _is_initialized:
		initialize()
	return _service_registry.duplicate(false)

func get_validate_package_service() -> ValidatePackageService:
	if not _is_initialized:
		initialize()
	return _service_registry.get("validate_package") as ValidatePackageService

func get_build_content_package_service() -> BuildContentPackageService:
	if not _is_initialized:
		initialize()
	return _service_registry.get("build_content_package") as BuildContentPackageService

func get_refresh_content_index_service() -> RefreshContentIndexService:
	if not _is_initialized:
		initialize()
	return _service_registry.get("refresh_content_index") as RefreshContentIndexService

func get_chart_authoring_service() -> ChartAuthoringService:
	if not _is_initialized:
		initialize()
	return _service_registry.get("chart_authoring") as ChartAuthoringService
