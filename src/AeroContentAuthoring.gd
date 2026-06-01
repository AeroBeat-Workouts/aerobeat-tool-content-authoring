@tool
class_name AeroContentAuthoring
extends Node

const WorkoutPackageValidationService = preload("../services/validation/workout_package_validation_service.gd")
const BuildContentPackageService = preload("../services/packaging/build_content_package_service.gd")
const RefreshContentIndexService = preload("../services/registry/refresh_content_index_service.gd")
const WorkoutPackageWorkflowService = preload("../services/workflow/workout_package_workflow_service.gd")

signal initialized
signal authoring_state_reset(state)
signal authoring_state_changed(state)
signal package_loaded(package_dir, state)
signal package_saved(output_dir, zip_path)
signal package_validated(report)

const VERSION: String = "0.3.0"

@export var auto_initialize: bool = true

var _is_initialized: bool = false
var _service_registry: Dictionary = {}
var _current_package_state: Dictionary = {}

static func build_service_registry() -> Dictionary:
	return {
		"validate_package": WorkoutPackageValidationService.new(),
		"build_content_package": BuildContentPackageService.new(),
		"refresh_content_index": RefreshContentIndexService.new(),
		"package_workflow": WorkoutPackageWorkflowService.new(),
	}

func _ready() -> void:
	if auto_initialize:
		initialize()

func initialize() -> void:
	if _is_initialized:
		return
	_service_registry = build_service_registry()
	_current_package_state = get_package_workflow_service().reset_package_state().get("state", {})
	_is_initialized = true
	initialized.emit()

func reset_runtime_state() -> void:
	_service_registry = {}
	_current_package_state = {}
	_is_initialized = false
	authoring_state_reset.emit({})

func reset_authoring_state(seed: Dictionary = {}) -> Dictionary:
	if not _is_initialized:
		initialize()
	var result: Dictionary = get_package_workflow_service().create_new_package_state(seed)
	if bool(result.get("ok", false)):
		_current_package_state = Dictionary(result.get("state", {})).duplicate(true)
		authoring_state_reset.emit(get_current_package_state())
	return result

func create_new_workout_package(seed: Dictionary = {}) -> Dictionary:
	return reset_authoring_state(seed)

func load_workout_package_folder(package_dir: String) -> Dictionary:
	if not _is_initialized:
		initialize()
	var result: Dictionary = get_package_workflow_service().load_package_folder(package_dir)
	if bool(result.get("ok", false)):
		_current_package_state = Dictionary(result.get("state", {})).duplicate(true)
		package_loaded.emit(package_dir, get_current_package_state())
		authoring_state_changed.emit(get_current_package_state())
	return result

func validate_current_package() -> Dictionary:
	if not _is_initialized:
		initialize()
	var state: Dictionary = get_current_package_state()
	if state.is_empty():
		return {
			"ok": false,
			"errorCode": "authoring_state_empty",
			"valid": false,
		}
	var staging_dir: String = _staging_dir("validate")
	var write_result: Dictionary = get_package_workflow_service().write_package_state(state, staging_dir)
	if not bool(write_result.get("ok", false)):
		return {
			"ok": false,
			"errorCode": String(write_result.get("errorCode", "write_failed")),
			"valid": false,
			"writeResult": write_result,
		}
	var report: Dictionary = get_validate_package_service().validate_path(staging_dir, "package")
	report["ok"] = bool(report.get("valid", false))
	report["state"] = state
	package_validated.emit(report)
	return report

func save_current_package(destination_dir: String) -> Dictionary:
	if not _is_initialized:
		initialize()
	var state: Dictionary = get_current_package_state()
	if state.is_empty():
		return {
			"ok": false,
			"errorCode": "authoring_state_empty",
		}
	var package_name: String = _package_folder_name(state)
	var staging_dir: String = _staging_dir("save")
	var write_result: Dictionary = get_package_workflow_service().write_package_state(state, staging_dir)
	if not bool(write_result.get("ok", false)):
		return {
			"ok": false,
			"errorCode": String(write_result.get("errorCode", "write_failed")),
			"writeResult": write_result,
		}
	DirAccess.make_dir_recursive_absolute(destination_dir)
	var output_dir: String = destination_dir.path_join(package_name)
	var build_result: Dictionary = get_build_content_package_service().build_package(staging_dir, output_dir)
	if bool(build_result.get("ok", false)):
		_current_package_state["loadedPackageDir"] = output_dir
		package_saved.emit(output_dir, String(build_result.get("zipPath", "")))
	return build_result

func set_current_package_state(state: Dictionary) -> void:
	if not _is_initialized:
		initialize()
	_current_package_state = state.duplicate(true)
	authoring_state_changed.emit(get_current_package_state())

func get_current_package_state() -> Dictionary:
	if not _is_initialized:
		initialize()
	return _current_package_state.duplicate(true)

func has_package_state() -> bool:
	return not get_current_package_state().is_empty()

func is_initialized() -> bool:
	return _is_initialized

func get_service_registry() -> Dictionary:
	if not _is_initialized:
		initialize()
	return _service_registry.duplicate(false)

func get_validate_package_service() -> WorkoutPackageValidationService:
	if not _is_initialized:
		initialize()
	return _service_registry.get("validate_package") as WorkoutPackageValidationService

func get_build_content_package_service() -> BuildContentPackageService:
	if not _is_initialized:
		initialize()
	return _service_registry.get("build_content_package") as BuildContentPackageService

func get_refresh_content_index_service() -> RefreshContentIndexService:
	if not _is_initialized:
		initialize()
	return _service_registry.get("refresh_content_index") as RefreshContentIndexService

func get_package_workflow_service() -> WorkoutPackageWorkflowService:
	if not _is_initialized:
		_service_registry = build_service_registry()
	return _service_registry.get("package_workflow") as WorkoutPackageWorkflowService

func _staging_dir(kind: String) -> String:
	return OS.get_user_data_dir().path_join("aerobeat_tool_content_authoring/%s_%s" % [kind, Time.get_unix_time_from_system()])

func _package_folder_name(state: Dictionary) -> String:
	var workout: Dictionary = Dictionary(state.get("workout", {}))
	var workout_id: String = String(workout.get("workoutId", "")).strip_edges()
	return workout_id if not workout_id.is_empty() else "workout-package"
