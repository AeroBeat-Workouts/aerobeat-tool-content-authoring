@tool
class_name AeroContentAuthoring
extends Node

const WorkoutPackageValidationService = preload("../services/validation/workout_package_validation_service.gd")
const ValidatePackageService = preload("../services/validation/validate_package_service.gd")
const BuildContentPackageService = preload("../services/packaging/build_content_package_service.gd")
const RefreshContentIndexService = preload("../services/registry/refresh_content_index_service.gd")
const WorkoutPackageWorkflowService = preload("../services/workflow/workout_package_workflow_service.gd")

signal initialized
signal authoring_state_reset(state)
signal authoring_state_changed(state)
signal package_loaded(package_dir, state)
signal package_saved(output_dir, zip_path)
signal package_validated(report)

const VERSION: String = "0.4.0"
const DEFAULT_SET_ID := "ab-set-001"
const DEFAULT_SET_NAME := "Set 1"
const ENVIRONMENT_TYPE_BY_EXTENSION := {
	".png": "image_background",
	".jpg": "image_background",
	".jpeg": "image_background",
	".webp": "image_background",
	".mp4": "video_background",
	".webm": "video_background",
	".ogv": "video_background",
	".glb": "glb_environment",
	".compressed.ply": "splat",
	".ply": "splat",
	".splat": "splat",
	".sog": "splat",
}

@export var auto_initialize: bool = true

var _is_initialized: bool = false
var _service_registry: Dictionary = {}
var _current_package_state: Dictionary = {}
var _yaml_helper := ValidatePackageService.new()

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
	_current_package_state = _normalize_state_for_authoring(get_package_workflow_service().reset_package_state().get("state", {}))
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
		_current_package_state = _normalize_state_for_authoring(Dictionary(result.get("state", {})).duplicate(true))
		authoring_state_reset.emit(get_current_package_state())
		result["state"] = get_current_package_state()
	return result

func create_new_workout_package(seed: Dictionary = {}) -> Dictionary:
	return reset_authoring_state(seed)

func load_workout_package_folder(package_dir: String) -> Dictionary:
	if not _is_initialized:
		initialize()
	var result: Dictionary = get_package_workflow_service().load_package_folder(package_dir)
	if bool(result.get("ok", false)):
		_current_package_state = _normalize_state_for_authoring(Dictionary(result.get("state", {})).duplicate(true))
		package_loaded.emit(package_dir, get_current_package_state())
		authoring_state_changed.emit(get_current_package_state())
		result["state"] = get_current_package_state()
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
	_current_package_state = _normalize_state_for_authoring(state.duplicate(true))
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

func create_set(seed: Dictionary = {}) -> Dictionary:
	var state := get_current_package_state()
	var sets: Array = Array(state.get("sets", [])).duplicate(true)
	var workout: Dictionary = Dictionary(state.get("workout", {})).duplicate(true)
	var set_order: Array = Array(workout.get("setOrder", [])).duplicate(true)
	var next_index := max(sets.size() + 1, 1)
	var set_id: String = _unique_set_id(String(seed.get("setId", "")).strip_edges(), state, next_index)
	var set_record := {
		"schemaId": "aerobeat.set.v1",
		"schemaVersion": 1,
		"recordVersion": 1,
		"setId": set_id,
		"setName": String(seed.get("setName", "Set %d" % next_index)).strip_edges(),
		"songId": String(seed.get("songId", "")).strip_edges(),
		"chartId": String(seed.get("chartId", "")).strip_edges(),
		"preferredEnvironmentId": String(seed.get("preferredEnvironmentId", seed.get("environmentId", ""))).strip_edges(),
		"fallbackEnvironmentId": String(seed.get("fallbackEnvironmentId", "")).strip_edges(),
	}
	if not String(set_record.get("preferredEnvironmentId", "")).is_empty():
		set_record["environmentId"] = set_record["preferredEnvironmentId"]
	if not String(seed.get("coachingOverlayId", "")).strip_edges().is_empty():
		set_record["coachingOverlayId"] = String(seed.get("coachingOverlayId", "")).strip_edges()
	sets.append(set_record)
	if not set_order.has(set_id):
		set_order.append(set_id)
	workout["setOrder"] = set_order
	state["workout"] = workout
	state["sets"] = sets
	set_current_package_state(state)
	return {"ok": true, "set": set_record, "state": get_current_package_state()}

func delete_set(set_id: String) -> Dictionary:
	var normalized_set_id := set_id.strip_edges()
	if normalized_set_id.is_empty():
		return {"ok": false, "errorCode": "set_id_missing"}
	var state := get_current_package_state()
	var sets: Array = []
	var removed_set: Dictionary = {}
	for set_variant in Array(state.get("sets", [])):
		var set_record := Dictionary(set_variant).duplicate(true)
		if String(set_record.get("setId", "")) == normalized_set_id:
			removed_set = set_record
			continue
		sets.append(set_record)
	var workout: Dictionary = Dictionary(state.get("workout", {})).duplicate(true)
	var set_order: Array = []
	for ordered_set_id in Array(workout.get("setOrder", [])):
		if String(ordered_set_id) != normalized_set_id:
			set_order.append(String(ordered_set_id))
	workout["setOrder"] = set_order
	state["workout"] = workout
	state["sets"] = sets
	_cleanup_overlay_for_deleted_set(state, removed_set)
	if sets.is_empty():
		var created := create_set()
		state = Dictionary(created.get("state", get_current_package_state())).duplicate(true)
	else:
		set_current_package_state(state)
	return {"ok": not removed_set.is_empty(), "removedSet": removed_set, "state": get_current_package_state()}

func rename_set(set_id: String, set_name: String) -> Dictionary:
	return update_set_record(set_id, {"setName": set_name.strip_edges()})

func update_set_record(set_id: String, patch: Dictionary) -> Dictionary:
	var normalized_set_id := set_id.strip_edges()
	if normalized_set_id.is_empty():
		return {"ok": false, "errorCode": "set_id_missing"}
	var state := get_current_package_state()
	var sets: Array = Array(state.get("sets", [])).duplicate(true)
	var updated_set: Dictionary = {}
	for index in range(sets.size()):
		var set_record := Dictionary(sets[index]).duplicate(true)
		if String(set_record.get("setId", "")) != normalized_set_id:
			continue
		for key in patch.keys():
			set_record[String(key)] = patch.get(key)
		if String(set_record.get("preferredEnvironmentId", "")).strip_edges().is_empty():
			set_record.erase("environmentId")
		else:
			set_record["environmentId"] = String(set_record.get("preferredEnvironmentId", "")).strip_edges()
		if String(set_record.get("coachingOverlayId", "")).strip_edges().is_empty():
			set_record.erase("coachingOverlayId")
		sets[index] = set_record
		updated_set = set_record
		break
	state["sets"] = sets
	set_current_package_state(state)
	return {"ok": not updated_set.is_empty(), "set": updated_set, "state": get_current_package_state()}

func import_beatmap_for_set(set_id: String, source_path: String) -> Dictionary:
	var normalized_path := source_path.strip_edges()
	if normalized_path.is_empty() or not FileAccess.file_exists(normalized_path):
		return {"ok": false, "errorCode": "beatmap_missing", "sourcePath": normalized_path}
	var metadata := _load_structured_metadata(normalized_path)
	if metadata.is_empty():
		metadata = {
			"path": normalized_path,
			"fileName": normalized_path.get_file(),
			"extension": normalized_path.get_extension().to_lower(),
			"fileSizeBytes": FileAccess.get_file_as_bytes(normalized_path).size(),
		}
	var state := get_current_package_state()
	var current_set := get_set_record(set_id)
	if current_set.is_empty():
		return {"ok": false, "errorCode": "set_not_found", "sourcePath": normalized_path}
	var chart_id := String(metadata.get("chartId", current_set.get("chartId", ""))).strip_edges()
	if chart_id.is_empty():
		chart_id = _tokenized_id(normalized_path.get_file().get_basename(), "ab-chart")
	var chart_name := String(metadata.get("chartName", normalized_path.get_file().get_basename().capitalize())).strip_edges()
	var feature := String(metadata.get("feature", "boxing")).strip_edges()
	var difficulty := String(metadata.get("difficulty", "medium")).strip_edges()
	var chart_record := {
		"schemaId": "aerobeat.chart.boxing.v1",
		"schemaVersion": 1,
		"recordVersion": 1,
		"chartId": chart_id,
		"chartName": chart_name,
		"feature": feature,
		"difficulty": difficulty,
		"beats": _extract_beats(metadata),
		"sourcePath": normalized_path,
	}
	if not String(metadata.get("songId", current_set.get("songId", ""))).strip_edges().is_empty():
		chart_record["songId"] = String(metadata.get("songId", current_set.get("songId", ""))).strip_edges()
	state["charts"] = _upsert_record(Array(state.get("charts", [])).duplicate(true), chart_record, "chartId")
	var patch := {
		"chartId": chart_id,
	}
	if chart_record.has("songId"):
		patch["songId"] = String(chart_record.get("songId", ""))
	update_set_record(set_id, patch)
	return {"ok": true, "chart": chart_record, "metadata": metadata, "state": get_current_package_state()}

func assign_environment_to_set(set_id: String, role: String, source_path: String) -> Dictionary:
	var normalized_role := role.strip_edges().to_lower()
	var normalized_path := source_path.strip_edges()
	if normalized_role != "preferred" and normalized_role != "fallback":
		return {"ok": false, "errorCode": "invalid_environment_role", "role": normalized_role}
	if normalized_path.is_empty() or not FileAccess.file_exists(normalized_path):
		return {"ok": false, "errorCode": "environment_missing", "sourcePath": normalized_path}
	var state := get_current_package_state()
	var current_set := get_set_record(set_id)
	if current_set.is_empty():
		return {"ok": false, "errorCode": "set_not_found"}
	var package_path := _materialize_asset_reference(state, normalized_path, "media/environments")
	var config_source := _find_environment_config_source(normalized_path)
	var config_package_path := ""
	if not config_source.is_empty():
		config_package_path = _materialize_asset_reference(state, config_source, "media/environments")
	var environment_id := _tokenized_id("%s-%s" % [String(current_set.get("setId", "set")), normalized_role], "ab-environment")
	var environment_record := {
		"schemaId": "aerobeat.environment.v1",
		"schemaVersion": 1,
		"recordVersion": 1,
		"environmentId": environment_id,
		"environmentName": normalized_path.get_file().get_basename().capitalize(),
		"type": _environment_type_for_path(normalized_path),
		"resourcePath": package_path,
		"sourcePath": normalized_path,
	}
	if not config_package_path.is_empty():
		environment_record["configPath"] = config_package_path
		environment_record["configSourcePath"] = config_source
	state["environments"] = _upsert_record(Array(state.get("environments", [])).duplicate(true), environment_record, "environmentId")
	var patch := {}
	if normalized_role == "preferred":
		patch["preferredEnvironmentId"] = environment_id
	else:
		patch["fallbackEnvironmentId"] = environment_id
	set_current_package_state(state)
	update_set_record(set_id, patch)
	return {"ok": true, "environment": environment_record, "state": get_current_package_state()}

func assign_coaching_audio_to_set(set_id: String, source_path: String) -> Dictionary:
	var normalized_path := source_path.strip_edges()
	if normalized_path.is_empty() or not FileAccess.file_exists(normalized_path):
		return {"ok": false, "errorCode": "coaching_audio_missing", "sourcePath": normalized_path}
	var state := get_current_package_state()
	var current_set := get_set_record(set_id)
	if current_set.is_empty():
		return {"ok": false, "errorCode": "set_not_found"}
	var coach_config := _ensure_coach_config(Dictionary(state.get("coachConfig", {})).duplicate(true), state)
	var overlay_id := _tokenized_id("overlay-%s" % String(current_set.get("setId", "set")), "ab-overlay")
	var media_id := "%s-media" % overlay_id
	var package_path := _materialize_asset_reference(state, normalized_path, "media/coaching")
	var overlay_record := {
		"overlayId": overlay_id,
		"coachId": _default_featured_coach_id(coach_config),
		"mediaId": media_id,
		"path": package_path,
		"sourcePath": normalized_path,
	}
	coach_config["overlayAudio"] = _upsert_record(Array(coach_config.get("overlayAudio", [])).duplicate(true), overlay_record, "overlayId")
	state["coachConfig"] = coach_config
	set_current_package_state(state)
	update_set_record(set_id, {"coachingOverlayId": overlay_id})
	return {"ok": true, "overlayAudio": overlay_record, "state": get_current_package_state()}

func set_coach_video_source(slot_name: String, source_path: String) -> Dictionary:
	var normalized_path := source_path.strip_edges()
	if normalized_path.is_empty() or not FileAccess.file_exists(normalized_path):
		return {"ok": false, "errorCode": "coach_video_missing", "sourcePath": normalized_path}
	var slot_key := slot_name.strip_edges().to_lower()
	if slot_key != "warmup" and slot_key != "cooldown":
		return {"ok": false, "errorCode": "invalid_coach_video_slot", "slot": slot_key}
	var state := get_current_package_state()
	var coach_config := _ensure_coach_config(Dictionary(state.get("coachConfig", {})).duplicate(true), state)
	var package_path := _materialize_asset_reference(state, normalized_path, "media/coaching")
	var media_id := _tokenized_id("%s-%s" % [slot_key, normalized_path.get_file().get_basename()], "ab-%s" % slot_key)
	var payload := {
		"mediaId": media_id,
		"path": package_path,
		"sourcePath": normalized_path,
	}
	if slot_key == "warmup":
		coach_config["warmupVideo"] = payload
	else:
		coach_config["cooldownVideo"] = payload
	state["coachConfig"] = coach_config
	set_current_package_state(state)
	return {"ok": true, "video": payload, "state": get_current_package_state()}

func clear_coach_video_source(slot_name: String) -> Dictionary:
	var slot_key := slot_name.strip_edges().to_lower()
	var state := get_current_package_state()
	var coach_config := Dictionary(state.get("coachConfig", {})).duplicate(true)
	if slot_key == "warmup":
		coach_config["warmupVideo"] = {}
	elif slot_key == "cooldown":
		coach_config["cooldownVideo"] = {}
	state["coachConfig"] = coach_config
	set_current_package_state(state)
	return {"ok": true, "state": get_current_package_state()}

func get_set_record(set_id: String) -> Dictionary:
	var normalized_set_id := set_id.strip_edges()
	for set_variant in Array(get_current_package_state().get("sets", [])):
		var set_record := Dictionary(set_variant)
		if String(set_record.get("setId", "")) == normalized_set_id:
			return set_record.duplicate(true)
	return {}

func get_record_by_id(collection_name: String, id_field: String, record_id: String) -> Dictionary:
	for record_variant in Array(get_current_package_state().get(collection_name, [])):
		var record := Dictionary(record_variant)
		if String(record.get(id_field, "")) == record_id:
			return record.duplicate(true)
	return {}

func get_set_environment_record(set_id: String, role: String) -> Dictionary:
	var set_record := get_set_record(set_id)
	if set_record.is_empty():
		return {}
	var field_name := "preferredEnvironmentId" if role.strip_edges().to_lower() == "preferred" else "fallbackEnvironmentId"
	var environment_id := String(set_record.get(field_name, "")).strip_edges()
	if environment_id.is_empty():
		return {}
	return get_record_by_id("environments", "environmentId", environment_id)

func get_set_coaching_overlay_record(set_id: String) -> Dictionary:
	var set_record := get_set_record(set_id)
	if set_record.is_empty():
		return {}
	var overlay_id := String(set_record.get("coachingOverlayId", "")).strip_edges()
	if overlay_id.is_empty():
		return {}
	var coach_config := Dictionary(get_current_package_state().get("coachConfig", {}))
	for overlay_variant in Array(coach_config.get("overlayAudio", [])):
		var overlay_record := Dictionary(overlay_variant)
		if String(overlay_record.get("overlayId", "")) == overlay_id:
			return overlay_record.duplicate(true)
	return {}

func resolve_preview_path(path_value: String) -> String:
	var normalized := path_value.strip_edges()
	if normalized.is_empty():
		return ""
	if normalized.is_absolute_path():
		return normalized if FileAccess.file_exists(normalized) else ""
	var state := get_current_package_state()
	var draft_sources := Dictionary(state.get("draftAssetSources", {}))
	if draft_sources.has(normalized):
		var mapped := String(draft_sources.get(normalized, "")).strip_edges()
		if FileAccess.file_exists(mapped):
			return mapped
	var source_package_dir := String(state.get("sourcePackageDir", "")).strip_edges()
	if not source_package_dir.is_empty():
		var source_path := source_package_dir.path_join(normalized)
		if FileAccess.file_exists(source_path):
			return source_path
	var loaded_package_dir := String(state.get("loadedPackageDir", "")).strip_edges()
	if not loaded_package_dir.is_empty():
		var loaded_path := loaded_package_dir.path_join(normalized)
		if FileAccess.file_exists(loaded_path):
			return loaded_path
	return ""

func resolve_environment_preview_request(set_id: String, role: String = "preferred") -> Dictionary:
	var environment_record := get_set_environment_record(set_id, role)
	if environment_record.is_empty():
		return {"ok": false, "errorCode": "environment_not_linked", "role": role}
	var asset_path := resolve_preview_path(String(environment_record.get("resourcePath", environment_record.get("sourcePath", ""))))
	if asset_path.is_empty():
		return {"ok": false, "errorCode": "environment_asset_missing", "environment": environment_record}
	var config_path := resolve_preview_path(String(environment_record.get("configPath", environment_record.get("configSourcePath", ""))))
	return {
		"ok": true,
		"request": {
			"request_id": "%s-%s-preview" % [String(environment_record.get("environmentId", "environment")), role],
			"kind": _loader_kind_for_environment_type(String(environment_record.get("type", ""))),
			"asset_path": asset_path,
			"config_path": config_path,
			"fit_mode": _fit_mode_from_config(config_path),
			"context": {
				"source": "content_authoring",
				"setId": set_id,
				"role": role,
			},
			"metadata": environment_record.duplicate(true),
		},
		"environment": environment_record,
	}

func get_file_metadata(source_path: String) -> Dictionary:
	var normalized_path := source_path.strip_edges()
	if normalized_path.is_empty() or not FileAccess.file_exists(normalized_path):
		return {}
	return {
		"path": normalized_path,
		"fileName": normalized_path.get_file(),
		"extension": normalized_path.get_extension().to_lower(),
		"fileSizeBytes": FileAccess.get_file_as_bytes(normalized_path).size(),
	}

func _staging_dir(kind: String) -> String:
	return OS.get_user_data_dir().path_join("aerobeat_tool_content_authoring/%s_%s" % [kind, Time.get_unix_time_from_system()])

func _package_folder_name(state: Dictionary) -> String:
	var workout: Dictionary = Dictionary(state.get("workout", {}))
	var workout_id: String = String(workout.get("workoutId", "")).strip_edges()
	return workout_id if not workout_id.is_empty() else "workout-package"

func _normalize_state_for_authoring(state: Dictionary) -> Dictionary:
	var normalized := state.duplicate(true)
	if not normalized.has("draftAssetSources") or not (normalized.get("draftAssetSources") is Dictionary):
		normalized["draftAssetSources"] = {}
	if not normalized.has("draftTextSources") or not (normalized.get("draftTextSources") is Dictionary):
		normalized["draftTextSources"] = {}
	if not normalized.has("draftBeatmapSources") or not (normalized.get("draftBeatmapSources") is Dictionary):
		normalized["draftBeatmapSources"] = {}
	var coach_config := Dictionary(normalized.get("coachConfig", {})).duplicate(true)
	if bool(coach_config.get("enabled", false)):
		coach_config = _ensure_coach_config(coach_config, normalized)
	else:
		coach_config["enabled"] = false
	normalized["coachConfig"] = coach_config
	var workout := Dictionary(normalized.get("workout", {})).duplicate(true)
	var sets: Array = Array(normalized.get("sets", [])).duplicate(true)
	var set_order: Array = Array(workout.get("setOrder", [])).duplicate(true)
	if sets.is_empty():
		var default_set := {
			"schemaId": "aerobeat.set.v1",
			"schemaVersion": 1,
			"recordVersion": 1,
			"setId": DEFAULT_SET_ID,
			"setName": DEFAULT_SET_NAME,
			"songId": "",
			"chartId": "",
			"preferredEnvironmentId": "",
			"fallbackEnvironmentId": "",
		}
		sets.append(default_set)
		set_order = [DEFAULT_SET_ID]
	else:
		var normalized_sets: Array = []
		for set_variant in sets:
			var set_record := Dictionary(set_variant).duplicate(true)
			if not set_record.has("schemaId"):
				set_record["schemaId"] = "aerobeat.set.v1"
			if not set_record.has("schemaVersion"):
				set_record["schemaVersion"] = 1
			if not set_record.has("recordVersion"):
				set_record["recordVersion"] = 1
			if not set_record.has("preferredEnvironmentId") and set_record.has("environmentId"):
				set_record["preferredEnvironmentId"] = String(set_record.get("environmentId", ""))
			if not set_record.has("fallbackEnvironmentId"):
				set_record["fallbackEnvironmentId"] = String(set_record.get("fallbackEnvironmentId", ""))
			if not String(set_record.get("preferredEnvironmentId", "")).is_empty():
				set_record["environmentId"] = String(set_record.get("preferredEnvironmentId", ""))
			normalized_sets.append(set_record)
		sets = normalized_sets
		for set_record_variant in sets:
			var set_id := String(Dictionary(set_record_variant).get("setId", "")).strip_edges()
			if not set_id.is_empty() and not set_order.has(set_id):
				set_order.append(set_id)
	workout["setOrder"] = set_order
	normalized["workout"] = workout
	normalized["sets"] = sets
	return normalized

func _ensure_coach_config(coach_config: Dictionary, state: Dictionary) -> Dictionary:
	coach_config["enabled"] = true
	coach_config["schemaId"] = String(coach_config.get("schemaId", "aerobeat.coach-config.v1")).strip_edges()
	coach_config["schemaVersion"] = int(coach_config.get("schemaVersion", 1))
	coach_config["recordVersion"] = int(coach_config.get("recordVersion", 1))
	var workout := Dictionary(state.get("workout", {}))
	if String(coach_config.get("coachConfigId", "")).strip_edges().is_empty():
		var workout_id := String(workout.get("workoutId", "")).strip_edges()
		coach_config["coachConfigId"] = "ab-coach-config" if workout_id.is_empty() else "ab-coach-config-%s" % workout_id
	if String(coach_config.get("coachConfigName", "")).strip_edges().is_empty():
		coach_config["coachConfigName"] = "Workout Coaching"
	if not (coach_config.get("featuredCoaches") is Array) or Array(coach_config.get("featuredCoaches", [])).is_empty():
		coach_config["featuredCoaches"] = [{
			"coachId": "ab-coach-default",
			"coachName": "Coach Default",
		}]
	if not (coach_config.get("overlayAudio") is Array):
		coach_config["overlayAudio"] = []
	if not (coach_config.get("warmupVideo") is Dictionary):
		coach_config["warmupVideo"] = {}
	if not (coach_config.get("cooldownVideo") is Dictionary):
		coach_config["cooldownVideo"] = {}
	return coach_config

func _default_featured_coach_id(coach_config: Dictionary) -> String:
	var featured := Array(coach_config.get("featuredCoaches", []))
	if featured.is_empty():
		return "ab-coach-default"
	return String(Dictionary(featured[0]).get("coachId", "ab-coach-default")).strip_edges()

func _upsert_record(records: Array, record: Dictionary, id_field: String) -> Array:
	var target_id := String(record.get(id_field, "")).strip_edges()
	var updated := false
	for index in range(records.size()):
		var candidate := Dictionary(records[index])
		if String(candidate.get(id_field, "")).strip_edges() == target_id:
			records[index] = record
			updated = true
			break
	if not updated:
		records.append(record)
	return records

func _materialize_asset_reference(state: Dictionary, source_path: String, package_folder: String) -> String:
	var normalized_path := source_path.strip_edges()
	if normalized_path.is_empty():
		return ""
	var source_package_dir := String(state.get("sourcePackageDir", "")).strip_edges()
	if not source_package_dir.is_empty() and normalized_path.begins_with(source_package_dir.path_join("")):
		var relative_from_source := normalized_path.trim_prefix(source_package_dir.path_join(""))
		return relative_from_source.trim_prefix("/")
	var package_relative := package_folder.path_join(normalized_path.get_file())
	var draft_sources := Dictionary(state.get("draftAssetSources", {})).duplicate(true)
	draft_sources[package_relative] = normalized_path
	state["draftAssetSources"] = draft_sources
	return package_relative

func _find_environment_config_source(environment_source_path: String) -> String:
	for extension in [".config.yaml", ".config.yml", ".yaml", ".yml"]:
		var candidate := "%s%s" % [environment_source_path.get_basename(), extension]
		if FileAccess.file_exists(candidate):
			return candidate
	return ""

func _environment_type_for_path(source_path: String) -> String:
	var lower_path := source_path.to_lower()
	for extension in ENVIRONMENT_TYPE_BY_EXTENSION.keys():
		if lower_path.ends_with(String(extension)):
			return String(ENVIRONMENT_TYPE_BY_EXTENSION.get(extension, "image_background"))
	return "image_background"

func _loader_kind_for_environment_type(environment_type: String) -> String:
	match environment_type:
		"image_background":
			return "image"
		"video_background":
			return "video"
		"glb_environment":
			return "glb"
		"splat":
			return "splat"
		_:
			return "image"

func _fit_mode_from_config(config_path: String) -> String:
	if config_path.is_empty() or not FileAccess.file_exists(config_path):
		return "cover"
	var parsed := _yaml_helper._load_yaml_file(config_path)
	if not bool(parsed.get("ok", false)):
		return "cover"
	var data := Dictionary(parsed.get("data", {}))
	return String(data.get("fit_mode", "cover")).strip_edges()

func _load_structured_metadata(source_path: String) -> Dictionary:
	var text := FileAccess.get_file_as_string(source_path)
	var extension := source_path.get_extension().to_lower()
	if extension == "json":
		var parsed_json: Variant = JSON.parse_string(text)
		if parsed_json is Dictionary:
			var payload := Dictionary(parsed_json).duplicate(true)
			payload["path"] = source_path
			payload["fileName"] = source_path.get_file()
			payload["extension"] = extension
			payload["fileSizeBytes"] = FileAccess.get_file_as_bytes(source_path).size()
			return payload
	var parsed_yaml := _yaml_helper._load_yaml_file(source_path)
	if bool(parsed_yaml.get("ok", false)):
		var yaml_payload := Dictionary(parsed_yaml.get("data", {})).duplicate(true)
		yaml_payload["path"] = source_path
		yaml_payload["fileName"] = source_path.get_file()
		yaml_payload["extension"] = source_path.get_extension().to_lower()
		yaml_payload["fileSizeBytes"] = FileAccess.get_file_as_bytes(source_path).size()
		return yaml_payload
	return {}

func _extract_beats(metadata: Dictionary) -> Array:
	if metadata.get("beats") is Array:
		return Array(metadata.get("beats", [])).duplicate(true)
	if metadata.get("events") is Array:
		return Array(metadata.get("events", [])).duplicate(true)
	return []

func _cleanup_overlay_for_deleted_set(state: Dictionary, removed_set: Dictionary) -> void:
	var overlay_id := String(removed_set.get("coachingOverlayId", "")).strip_edges()
	if overlay_id.is_empty():
		return
	var coach_config := Dictionary(state.get("coachConfig", {})).duplicate(true)
	var overlays: Array = []
	for overlay_variant in Array(coach_config.get("overlayAudio", [])):
		var overlay_record := Dictionary(overlay_variant)
		if String(overlay_record.get("overlayId", "")).strip_edges() == overlay_id:
			continue
		overlays.append(overlay_record)
	coach_config["overlayAudio"] = overlays
	state["coachConfig"] = coach_config

func _unique_set_id(preferred_id: String, state: Dictionary, next_index: int) -> String:
	var candidate := preferred_id if not preferred_id.is_empty() else "ab-set-%03d" % next_index
	candidate = _tokenized_id(candidate, "ab-set")
	var existing_ids := []
	for set_variant in Array(state.get("sets", [])):
		existing_ids.append(String(Dictionary(set_variant).get("setId", "")))
	var suffix := next_index
	while existing_ids.has(candidate):
		suffix += 1
		candidate = "ab-set-%03d" % suffix
	return candidate

func _tokenized_id(value: String, prefix: String) -> String:
	var token := value.strip_edges().to_lower()
	for char_code in range(token.length()):
		var character := token[char_code]
	if token.is_empty():
		return prefix
	var sanitized := ""
	for index in range(token.length()):
		var character := token.substr(index, 1)
		if character.is_subsequence_of("abcdefghijklmnopqrstuvwxyz0123456789"):
			sanitized += character
		elif character == "-" or character == "_" or character == " ":
			sanitized += "-"
	while sanitized.contains("--"):
		sanitized = sanitized.replace("--", "-")
	sanitized = sanitized.strip_edges().trim_prefix("-").trim_suffix("-")
	if sanitized.is_empty():
		return prefix
	return sanitized if sanitized.begins_with("ab-") else "%s-%s" % [prefix, sanitized]
