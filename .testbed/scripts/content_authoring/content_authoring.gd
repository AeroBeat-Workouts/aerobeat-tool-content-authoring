extends Control

const AeroContentAuthoring = preload("res://addons/aerobeat-tool-content-authoring/src/AeroContentAuthoring.gd")

@onready var _runtime: AeroContentAuthoring = $AuthoringRuntime
@onready var _tab_container: TabContainer = %WorkflowTabs
@onready var _status_label: Label = %StatusLabel
@onready var _validation_label: Label = %ValidationLabel
@onready var _loaded_package_label: Label = %LoadedPackageLabel
@onready var _save_button: Button = %SaveWorkoutButton
@onready var _load_button: Button = %LoadWorkoutButton
@onready var _save_dialog: FileDialog = %SaveWorkoutDialog
@onready var _load_dialog: FileDialog = %LoadWorkoutDialog
@onready var _workout_id_edit: LineEdit = %WorkoutIdEdit
@onready var _workout_name_edit: LineEdit = %WorkoutNameEdit
@onready var _package_version_edit: LineEdit = %PackageVersionEdit
@onready var _coach_config_id_edit: LineEdit = %CoachConfigIdEdit
@onready var _description_edit: TextEdit = %DescriptionEdit
@onready var _coach_enabled_check: CheckButton = %CoachEnabledCheck
@onready var _coach_config_name_edit: LineEdit = %CoachConfigNameEdit
@onready var _warmup_video_path_edit: LineEdit = %WarmupVideoPathEdit
@onready var _cooldown_video_path_edit: LineEdit = %CooldownVideoPathEdit
@onready var _sets_summary_label: Label = %SetsSummaryLabel
@onready var _set_order_list: ItemList = %SetOrderList

var _is_syncing_ui: bool = false

func _ready() -> void:
	_tab_container.current_tab = 0
	_connect_runtime()
	_connect_ui()
	if not _runtime.is_initialized():
		_runtime.initialize()
	_apply_state(_runtime.get_current_package_state())
	_set_status("Content authoring shell ready.")

func _connect_runtime() -> void:
	if not _runtime.authoring_state_changed.is_connected(_on_runtime_state_changed):
		_runtime.authoring_state_changed.connect(_on_runtime_state_changed)
	if not _runtime.authoring_state_reset.is_connected(_on_runtime_state_reset):
		_runtime.authoring_state_reset.connect(_on_runtime_state_reset)
	if not _runtime.package_loaded.is_connected(_on_runtime_package_loaded):
		_runtime.package_loaded.connect(_on_runtime_package_loaded)
	if not _runtime.package_saved.is_connected(_on_runtime_package_saved):
		_runtime.package_saved.connect(_on_runtime_package_saved)
	if not _runtime.package_validated.is_connected(_on_runtime_package_validated):
		_runtime.package_validated.connect(_on_runtime_package_validated)

func _connect_ui() -> void:
	_save_button.pressed.connect(_on_save_pressed)
	_load_button.pressed.connect(_on_load_pressed)
	_save_dialog.dir_selected.connect(_on_save_dir_selected)
	_load_dialog.dir_selected.connect(_on_load_dir_selected)

	_workout_id_edit.text_changed.connect(_on_metadata_field_changed)
	_workout_name_edit.text_changed.connect(_on_metadata_field_changed)
	_package_version_edit.text_changed.connect(_on_metadata_field_changed)
	_coach_config_id_edit.text_changed.connect(_on_metadata_field_changed)
	_description_edit.text_changed.connect(_on_description_changed)
	_coach_enabled_check.toggled.connect(_on_coach_config_changed)
	_coach_config_name_edit.text_changed.connect(_on_coach_config_text_changed)
	_warmup_video_path_edit.text_changed.connect(_on_coach_config_text_changed)
	_cooldown_video_path_edit.text_changed.connect(_on_coach_config_text_changed)

func _apply_state(state: Dictionary) -> void:
	_is_syncing_ui = true
	var workout: Dictionary = Dictionary(state.get("workout", {}))
	var coach_config: Dictionary = Dictionary(state.get("coachConfig", {}))
	var warmup_video: Dictionary = Dictionary(coach_config.get("warmupVideo", {}))
	var cooldown_video: Dictionary = Dictionary(coach_config.get("cooldownVideo", {}))

	_workout_id_edit.text = String(workout.get("workoutId", ""))
	_workout_name_edit.text = String(workout.get("workoutName", ""))
	_package_version_edit.text = String(state.get("packageVersion", workout.get("packageVersion", "1.0.0")))
	_coach_config_id_edit.text = String(workout.get("coachConfigId", coach_config.get("coachConfigId", "")))
	_description_edit.text = String(workout.get("description", ""))
	_coach_enabled_check.button_pressed = bool(coach_config.get("enabled", false))
	_coach_config_name_edit.text = String(coach_config.get("coachConfigName", ""))
	_warmup_video_path_edit.text = String(warmup_video.get("path", warmup_video.get("resourcePath", "")))
	_cooldown_video_path_edit.text = String(cooldown_video.get("path", cooldown_video.get("resourcePath", "")))
	_loaded_package_label.text = _loaded_package_text(state)
	_validation_label.text = _validation_summary_for_state(state)
	_refresh_sets_summary(state)
	_is_syncing_ui = false

func _loaded_package_text(state: Dictionary) -> String:
	var loaded_dir: String = String(state.get("loadedPackageDir", "")).strip_edges()
	if loaded_dir.is_empty():
		return "Loaded package: draft / unsaved"
	return "Loaded package: %s" % loaded_dir

func _validation_summary_for_state(state: Dictionary) -> String:
	var set_count: int = Array(state.get("sets", [])).size()
	var song_count: int = Array(state.get("songs", [])).size()
	var env_count: int = Array(state.get("environments", [])).size()
	return "Current draft tracks %d set(s), %d song(s), and %d environment(s)." % [set_count, song_count, env_count]

func _refresh_sets_summary(state: Dictionary) -> void:
	_set_order_list.clear()
	var workout: Dictionary = Dictionary(state.get("workout", {}))
	var set_order: Array = Array(workout.get("setOrder", []))
	var set_records: Array = Array(state.get("sets", []))
	var set_lookup: Dictionary = {}
	for set_record_variant in set_records:
		var set_record: Dictionary = Dictionary(set_record_variant)
		set_lookup[String(set_record.get("setId", ""))] = set_record
	for set_id_variant in set_order:
		var set_id: String = String(set_id_variant)
		var set_record: Dictionary = Dictionary(set_lookup.get(set_id, {}))
		var set_name: String = String(set_record.get("setName", "")).strip_edges()
		var label: String = set_id if set_name.is_empty() else "%s — %s" % [set_id, set_name]
		_set_order_list.add_item(label)
	if _set_order_list.item_count == 0:
		for set_record_variant in set_records:
			var set_record: Dictionary = Dictionary(set_record_variant)
			var set_id: String = String(set_record.get("setId", "")).strip_edges()
			var set_name: String = String(set_record.get("setName", "")).strip_edges()
			if set_id.is_empty() and set_name.is_empty():
				continue
			_set_order_list.add_item(set_id if set_name.is_empty() else "%s — %s" % [set_id, set_name])
	_sets_summary_label.text = "Task 6 seam: build rich set authoring here. Current draft exposes %d authored set(s)." % Array(state.get("sets", [])).size()

func _on_metadata_field_changed(_value: String) -> void:
	_commit_metadata_state()

func _on_description_changed() -> void:
	_commit_metadata_state()

func _on_coach_config_changed(_enabled: bool) -> void:
	_commit_metadata_state()

func _on_coach_config_text_changed(_value: String) -> void:
	_commit_metadata_state()

func _commit_metadata_state() -> void:
	if _is_syncing_ui:
		return
	var state: Dictionary = _runtime.get_current_package_state()
	var workout: Dictionary = Dictionary(state.get("workout", {})).duplicate(true)
	workout["workoutId"] = _workout_id_edit.text.strip_edges()
	workout["workoutName"] = _workout_name_edit.text.strip_edges()
	workout["description"] = _description_edit.text.strip_edges()
	workout["packageVersion"] = _package_version_edit.text.strip_edges()
	workout["coachConfigId"] = _coach_config_id_edit.text.strip_edges()
	state["packageVersion"] = _package_version_edit.text.strip_edges()
	state["workout"] = workout

	var coach_config: Dictionary = Dictionary(state.get("coachConfig", {})).duplicate(true)
	var should_enable_coach_config: bool = _coach_enabled_check.button_pressed \
		or not _coach_config_name_edit.text.strip_edges().is_empty() \
		or not _warmup_video_path_edit.text.strip_edges().is_empty() \
		or not _cooldown_video_path_edit.text.strip_edges().is_empty() \
		or not _coach_config_id_edit.text.strip_edges().is_empty()
	if should_enable_coach_config:
		coach_config["enabled"] = true
		coach_config["schemaId"] = String(coach_config.get("schemaId", "aerobeat.coach-config.v1")).strip_edges()
		coach_config["schemaVersion"] = int(coach_config.get("schemaVersion", 1))
		coach_config["recordVersion"] = int(coach_config.get("recordVersion", 1))
		coach_config["coachConfigId"] = _coach_config_id_edit.text.strip_edges()
		coach_config["coachConfigName"] = _coach_config_name_edit.text.strip_edges()
		if not coach_config.has("featuredCoaches") or not (coach_config.get("featuredCoaches") is Array):
			coach_config["featuredCoaches"] = []
		if not coach_config.has("overlayAudio") or not (coach_config.get("overlayAudio") is Array):
			coach_config["overlayAudio"] = []
		var warmup_video: Dictionary = Dictionary(coach_config.get("warmupVideo", {})).duplicate(true)
		warmup_video["path"] = _warmup_video_path_edit.text.strip_edges()
		coach_config["warmupVideo"] = warmup_video
		var cooldown_video: Dictionary = Dictionary(coach_config.get("cooldownVideo", {})).duplicate(true)
		cooldown_video["path"] = _cooldown_video_path_edit.text.strip_edges()
		coach_config["cooldownVideo"] = cooldown_video
	else:
		coach_config = {"enabled": false}
	state["coachConfig"] = coach_config
	_runtime.set_current_package_state(state)
	_apply_state(state)

func _on_save_pressed() -> void:
	_set_status("Choose a destination folder for the authored workout export.")
	_save_dialog.popup_centered_ratio(0.75)

func _on_load_pressed() -> void:
	_set_status("Choose an unzipped workout folder to load.")
	_load_dialog.popup_centered_ratio(0.75)

func _on_save_dir_selected(destination_dir: String) -> void:
	_set_status("Saving workout package…")
	var result: Dictionary = _runtime.save_current_package(destination_dir)
	if bool(result.get("ok", false)):
		var output_dir: String = String(result.get("outputDir", destination_dir))
		var zip_path: String = String(result.get("zipPath", ""))
		_set_status("Saved workout folder to %s and sibling zip to %s." % [output_dir, zip_path])
		_apply_validation_report(_runtime.validate_current_package())
	else:
		_set_status("Save failed: %s" % String(result.get("errorCode", "unknown_error")))

func _on_load_dir_selected(package_dir: String) -> void:
	_set_status("Loading workout package…")
	var result: Dictionary = _runtime.load_workout_package_folder(package_dir)
	if bool(result.get("ok", false)):
		_apply_state(_runtime.get_current_package_state())
		_apply_validation_report(_runtime.validate_current_package())
		_set_status("Loaded workout package from %s." % package_dir)
	else:
		_set_status("Load failed: %s" % String(result.get("errorCode", "unknown_error")))

func _on_runtime_state_changed(state: Dictionary) -> void:
	_apply_state(state)

func _on_runtime_state_reset(state: Dictionary) -> void:
	_apply_state(state)
	_set_status("Authoring state reset.")

func _on_runtime_package_loaded(_package_dir: String, state: Dictionary) -> void:
	_apply_state(state)

func _on_runtime_package_saved(_output_dir: String, _zip_path: String) -> void:
	_apply_state(_runtime.get_current_package_state())

func _on_runtime_package_validated(report: Dictionary) -> void:
	_apply_validation_report(report)

func _apply_validation_report(report: Dictionary) -> void:
	if bool(report.get("valid", false)):
		_validation_label.text = "Validation: package is currently valid."
		return
	var issues: Array = Array(report.get("issues", []))
	if issues.is_empty():
		_validation_label.text = "Validation: package is incomplete."
		return
	var first_issue: Dictionary = Dictionary(issues[0])
	_validation_label.text = "Validation: %d issue(s). First: %s" % [issues.size(), String(first_issue.get("code", "unknown_issue"))]

func _set_status(message: String) -> void:
	_status_label.text = message
