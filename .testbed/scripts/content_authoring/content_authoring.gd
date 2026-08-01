extends Control

const AeroContentAuthoring = preload("res://addons/aerobeat-tool-content-authoring/src/AeroContentAuthoring.gd")
const AeroEnvironmentLoader = preload("res://addons/aerobeat-environment-loader/src/AeroEnvironmentLoader.gd")
const AeroVideoPlayerGodotBackendBridge = preload("res://addons/aerobeat-tool-video-player/src/AeroVideoPlayerGodotBackendBridge.gd")
const AeroAudioLoader = preload("res://addons/aerobeat-tool-audio-player/src/AeroAudioLoader.gd")

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
@onready var _margin_container: MarginContainer = $MarginContainer
@onready var _warmup_tab: VBoxContainer = $MarginContainer/RootVBox/WorkflowTabs/WarmUpCoachingTab
@onready var _sets_tab: VBoxContainer = $MarginContainer/RootVBox/WorkflowTabs/SetsTab
@onready var _cooldown_tab: VBoxContainer = $MarginContainer/RootVBox/WorkflowTabs/CoolDownCoachingTab

var _is_syncing_ui: bool = false
var _selected_set_id: String = ""
var _pending_picker: Dictionary = {}
var _dialogs: Dictionary = {}
var _set_editor_controls: Dictionary = {}
var _coaching_video_controls: Dictionary = {}
var _video_managers: Dictionary = {}
var _audio_loader: AeroAudioLoader
var _environment_loader: AeroEnvironmentLoader
var _environment_status_label: Label
var _preview_viewport: SubViewport
var _preview_world_root: Node3D
var _preview_canvas_root: Control

func _ready() -> void:
	_tab_container.current_tab = 0
	_build_task6_ui()
	_connect_runtime()
	_connect_ui()
	_initialize_preview_tools()
	if not _runtime.is_initialized():
		_runtime.initialize()
	_apply_state(_runtime.get_current_package_state())
	_set_status("Content authoring shell ready.")

func _build_task6_ui() -> void:
	_build_background_preview_layer()
	_build_picker_dialogs()
	_build_sets_editor_ui()
	_build_coaching_preview_ui(_warmup_tab, "warmup")
	_build_coaching_preview_ui(_cooldown_tab, "cooldown")

func _initialize_preview_tools() -> void:
	_environment_loader = AeroEnvironmentLoader.new()
	_environment_loader.name = "EnvironmentPreviewLoader"
	_environment_loader.canvas_root_path = NodePath("../CanvasLayer/CanvasRoot")
	_environment_loader.world_root_path = NodePath("../WorldRoot")
	_environment_loader.create_default_roots = false
	_environment_loader.environment_load_succeeded.connect(_on_environment_preview_loaded)
	_environment_loader.environment_load_failed.connect(_on_environment_preview_failed)
	_environment_loader.environment_cleared.connect(_on_environment_preview_cleared)
	_preview_viewport.get_child(0).add_child(_environment_loader)

	var backend_bridge := AeroVideoPlayerGodotBackendBridge.new()
	for slot_name in ["warmup", "cooldown"]:
		var manager = backend_bridge.create_manager()
		manager.name = "VideoPreview_%s" % slot_name.capitalize()
		add_child(manager)
		manager.attach_surface(_coaching_video_controls[slot_name]["surface"], slot_name)
		manager.slot_media_loaded.connect(_on_video_media_loaded)
		manager.slot_error_raised.connect(_on_video_preview_error)
		manager.slot_position_changed.connect(_on_video_position_changed)
		_video_managers[slot_name] = manager

	_audio_loader = AeroAudioLoader.new()
	_audio_loader.name = "CoachingAudioPreview"
	add_child(_audio_loader)
	_audio_loader.listen_for_audio_state(Callable(self, "_on_audio_state_changed"), true)
	_audio_loader.listen_for_audio_position(Callable(self, "_on_audio_position_changed"), true)
	_audio_loader.listen_for_audio_media(Callable(self, "_on_audio_media_loaded"), true)
	_audio_loader.listen_for_audio_errors(Callable(self, "_on_audio_error"))

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
	_set_order_list.item_selected.connect(_on_set_selected)

func _apply_state(state: Dictionary) -> void:
	_is_syncing_ui = true
	var song_package: Dictionary = Dictionary(state.get("songPackage", {}))
	var coach_config: Dictionary = Dictionary(state.get("coachConfig", {}))
	var warmup_video: Dictionary = Dictionary(coach_config.get("warmupVideo", {}))
	var cooldown_video: Dictionary = Dictionary(coach_config.get("cooldownVideo", {}))

	_workout_id_edit.text = String(song_package.get("songPackageId", ""))
	_workout_name_edit.text = String(song_package.get("songPackageName", ""))
	_package_version_edit.text = String(state.get("packageVersion", song_package.get("packageVersion", "1.0.0")))
	_coach_config_id_edit.text = String(coach_config.get("coachConfigId", ""))
	_description_edit.text = String(song_package.get("description", ""))
	_coach_enabled_check.button_pressed = bool(coach_config.get("enabled", false))
	_coach_config_name_edit.text = String(coach_config.get("coachConfigName", ""))
	_warmup_video_path_edit.text = String(warmup_video.get("path", warmup_video.get("resourcePath", "")))
	_cooldown_video_path_edit.text = String(cooldown_video.get("path", cooldown_video.get("resourcePath", "")))
	_loaded_package_label.text = _loaded_package_text(state)
	_validation_label.text = _validation_summary_for_state(state)
	_refresh_sets_summary(state)
	_refresh_coaching_video_ui("warmup", warmup_video)
	_refresh_coaching_video_ui("cooldown", cooldown_video)
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
	var song_package: Dictionary = Dictionary(state.get("songPackage", {}))
	var set_order: Array = Array(song_package.get("setIds", []))
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
		_set_order_list.set_item_metadata(_set_order_list.item_count - 1, set_id)
	if _selected_set_id.is_empty() and not set_order.is_empty():
		_selected_set_id = String(set_order[0])
	if not _selected_set_id.is_empty():
		for index in range(_set_order_list.item_count):
			if String(_set_order_list.get_item_metadata(index)) == _selected_set_id:
				_set_order_list.select(index)
				break
	_sets_summary_label.text = "Author %d set(s). Each set now wires beatmap, environment, and coaching preview seams." % Array(state.get("sets", [])).size()
	_refresh_selected_set_editor(state)

func _refresh_selected_set_editor(state: Dictionary) -> void:
	var set_record := _selected_set_record(state)
	var selected_label: Label = _set_editor_controls["selected_label"]
	var name_edit: LineEdit = _set_editor_controls["name_edit"]
	var beatmap_path: LineEdit = _set_editor_controls["beatmap_path"]
	var beatmap_meta: Label = _set_editor_controls["beatmap_meta"]
	var primary_path: LineEdit = _set_editor_controls["primary_environment_path"]
	var fallback_path: LineEdit = _set_editor_controls["fallback_environment_path"]
	var environment_meta: Label = _set_editor_controls["environment_meta"]
	var audio_path: LineEdit = _set_editor_controls["coaching_audio_path"]
	var audio_meta: Label = _set_editor_controls["coaching_audio_meta"]
	var panel: VBoxContainer = _set_editor_controls["panel"]
	var delete_button: Button = _set_editor_controls["delete_button"]
	if set_record.is_empty():
		panel.visible = false
		selected_label.text = "No set selected."
		return
	panel.visible = true
	selected_label.text = "Editing %s" % String(set_record.get("setId", ""))
	name_edit.text = String(set_record.get("setName", ""))
	delete_button.disabled = Array(state.get("sets", [])).size() <= 1

	var chart_record := _runtime.get_record_by_id("charts", "chartId", String(set_record.get("chartId", "")))
	var beatmap_source := String(chart_record.get("sourcePath", "")).strip_edges()
	beatmap_path.text = beatmap_source
	beatmap_meta.text = _format_beatmap_metadata(chart_record)

	var preferred_environment := _runtime.get_set_environment_record(_selected_set_id, "preferred")
	var fallback_environment := _runtime.get_set_environment_record(_selected_set_id, "fallback")
	primary_path.text = String(preferred_environment.get("sourcePath", preferred_environment.get("resourcePath", "")))
	fallback_path.text = String(fallback_environment.get("sourcePath", fallback_environment.get("resourcePath", "")))
	environment_meta.text = _format_environment_metadata(preferred_environment, fallback_environment)

	var coaching_overlay := _runtime.get_set_coaching_overlay_record(_selected_set_id)
	audio_path.text = String(coaching_overlay.get("sourcePath", coaching_overlay.get("path", "")))
	audio_meta.text = _format_audio_metadata(coaching_overlay)
	_refresh_environment_preview()
	_refresh_coaching_audio_preview(coaching_overlay)

func _refresh_coaching_video_ui(slot_name: String, video_record: Dictionary) -> void:
	var ui: Dictionary = Dictionary(_coaching_video_controls.get(slot_name, {}))
	(ui["metadata"] as Label).text = _format_media_metadata(video_record)
	if String(video_record.get("path", video_record.get("sourcePath", ""))).strip_edges().is_empty():
		(ui["status"] as Label).text = "No %s video selected." % slot_name.capitalize()
		return
	var resolved_path := _runtime.resolve_preview_path(String(video_record.get("path", video_record.get("sourcePath", ""))))
	if resolved_path.is_empty():
		(ui["status"] as Label).text = "Preview source missing on disk."
		return
	var manager = _video_managers.get(slot_name)
	if manager == null:
		return
	manager.load({
		"path": resolved_path,
		"kind": "file",
		"slot": slot_name,
		"loop": true,
		"autoplay": true,
		"fit_mode": "contain",
	}, slot_name)
	manager.play(slot_name)
	(ui["status"] as Label).text = "Previewing %s video." % slot_name.capitalize()

func _refresh_environment_preview() -> void:
	if _selected_set_id.is_empty():
		if _environment_loader != null:
			_environment_loader.clear_environment()
		return
	var request_result := _runtime.resolve_environment_preview_request(_selected_set_id, "preferred")
	if not bool(request_result.get("ok", false)):
		_environment_status_label.text = "Environment preview: choose a primary environment for the selected set."
		if _environment_loader != null:
			_environment_loader.clear_environment()
		return
	_environment_status_label.text = "Environment preview: loading primary environment for %s." % _selected_set_id
	_environment_loader.load_environment(Dictionary(request_result.get("request", {})))

func _refresh_coaching_audio_preview(overlay_record: Dictionary) -> void:
	var status_label: Label = _set_editor_controls["coaching_audio_status"]
	var slider: HSlider = _set_editor_controls["coaching_audio_seek"]
	if overlay_record.is_empty():
		status_label.text = "No coaching audio selected."
		slider.value = 0.0
		return
	var resolved_path := _runtime.resolve_preview_path(String(overlay_record.get("path", overlay_record.get("sourcePath", ""))))
	if resolved_path.is_empty():
		status_label.text = "Coaching audio source missing on disk."
		return
	_audio_loader.load({
		"path": resolved_path,
		"kind": "file",
		"loop": false,
	}, _selected_set_id)
	status_label.text = "Coaching audio loaded."

func _commit_metadata_state() -> void:
	if _is_syncing_ui:
		return
	var state: Dictionary = _runtime.get_current_package_state()
	var song_package: Dictionary = Dictionary(state.get("songPackage", {})).duplicate(true)
	song_package["songPackageId"] = _workout_id_edit.text.strip_edges()
	song_package["songPackageName"] = _workout_name_edit.text.strip_edges()
	song_package["description"] = _description_edit.text.strip_edges()
	song_package["packageVersion"] = _package_version_edit.text.strip_edges()
	state["packageVersion"] = _package_version_edit.text.strip_edges()
	state["songPackage"] = song_package

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
			coach_config["featuredCoaches"] = [{"coachId": "ab-coach-default", "coachName": "Coach Default"}]
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

func _on_metadata_field_changed(_value: String) -> void:
	_commit_metadata_state()

func _on_description_changed() -> void:
	_commit_metadata_state()

func _on_coach_config_changed(_enabled: bool) -> void:
	_commit_metadata_state()

func _on_coach_config_text_changed(_value: String) -> void:
	_commit_metadata_state()

func _on_save_pressed() -> void:
	_set_status("Choose a destination folder for the authored song package export.")
	_save_dialog.popup_centered_ratio(0.75)

func _on_load_pressed() -> void:
	_set_status("Choose an unzipped song package folder to load.")
	_load_dialog.popup_centered_ratio(0.75)

func _on_save_dir_selected(destination_dir: String) -> void:
	_set_status("Saving song package…")
	var result: Dictionary = _runtime.save_current_package(destination_dir)
	if bool(result.get("ok", false)):
		var output_dir: String = String(result.get("outputDir", destination_dir))
		var zip_path: String = String(result.get("zipPath", ""))
		_set_status("Saved song package folder to %s and sibling zip to %s." % [output_dir, zip_path])
		_apply_validation_report(_runtime.validate_current_package())
	else:
		_set_status("Save failed: %s" % String(result.get("errorCode", "unknown_error")))

func _on_load_dir_selected(package_dir: String) -> void:
	_set_status("Loading song package…")
	var result: Dictionary = _runtime.load_song_package_folder(package_dir)
	if bool(result.get("ok", false)):
		_apply_state(_runtime.get_current_package_state())
		_apply_validation_report(_runtime.validate_current_package())
		_set_status("Loaded song package from %s." % package_dir)
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

func _build_background_preview_layer() -> void:
	var preview_layer := SubViewportContainer.new()
	preview_layer.name = "EnvironmentPreviewLayer"
	preview_layer.anchors_preset = Control.PRESET_FULL_RECT
	preview_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	preview_layer.stretch = true
	preview_layer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	preview_layer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_child(preview_layer)
	move_child(preview_layer, 0)

	_preview_viewport = SubViewport.new()
	_preview_viewport.name = "EnvironmentPreviewViewport"
	_preview_viewport.transparent_bg = false
	_preview_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	_preview_viewport.size = size if size != Vector2.ZERO else Vector2(1280, 720)
	preview_layer.add_child(_preview_viewport)

	var preview_root := Node.new()
	preview_root.name = "PreviewRoot"
	_preview_viewport.add_child(preview_root)

	_preview_world_root = Node3D.new()
	_preview_world_root.name = "WorldRoot"
	preview_root.add_child(_preview_world_root)

	var camera := Camera3D.new()
	camera.name = "PreviewCamera"
	camera.position = Vector3(0.0, 0.0, 6.0)
	_preview_world_root.add_child(camera)

	var light := DirectionalLight3D.new()
	light.name = "PreviewLight"
	light.rotation_degrees = Vector3(-45.0, -15.0, 0.0)
	_preview_world_root.add_child(light)

	var canvas_layer := CanvasLayer.new()
	canvas_layer.name = "CanvasLayer"
	preview_root.add_child(canvas_layer)

	_preview_canvas_root = Control.new()
	_preview_canvas_root.name = "CanvasRoot"
	_preview_canvas_root.anchors_preset = Control.PRESET_FULL_RECT
	_preview_canvas_root.size = _preview_viewport.size
	canvas_layer.add_child(_preview_canvas_root)

	var overlay := ColorRect.new()
	overlay.name = "EnvironmentDimmer"
	overlay.anchors_preset = Control.PRESET_FULL_RECT
	overlay.color = Color(0.03, 0.03, 0.04, 0.65)
	preview_layer.add_child(overlay)
	move_child(_margin_container, get_child_count() - 1)

	_environment_status_label = Label.new()
	_environment_status_label.name = "EnvironmentPreviewStatusLabel"
	_environment_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_environment_status_label.text = "Environment preview: waiting for a set environment selection."
	_sets_tab.add_child(_environment_status_label)
	_sets_tab.move_child(_environment_status_label, _sets_tab.get_child_count() - 1)
	resized.connect(_on_root_resized)

func _build_picker_dialogs() -> void:
	_dialogs["beatmap"] = _create_picker_dialog("BeatmapFileDialog", ["*.json ; JSON beatmaps", "*.yaml ; YAML beatmaps", "*.yml ; YML beatmaps"]) 
	_dialogs["environment"] = _create_picker_dialog("EnvironmentFileDialog", ["*.png ; Images", "*.jpg ; Images", "*.jpeg ; Images", "*.webp ; Images", "*.mp4 ; Videos", "*.webm ; Videos", "*.ogv ; Videos", "*.glb ; GLB", "*.ply ; PLY", "*.compressed.ply ; Compressed PLY", "*.splat ; Splat", "*.sog ; SOG"]) 
	_dialogs["coaching_audio"] = _create_picker_dialog("CoachingAudioFileDialog", ["*.ogg ; Ogg Audio", "*.wav ; Wav Audio", "*.mp3 ; MP3 Audio", "*.flac ; FLAC Audio", "*.m4a ; M4A Audio", "*.aac ; AAC Audio"]) 
	_dialogs["coach_video"] = _create_picker_dialog("CoachVideoFileDialog", ["*.ogv ; OGV Video"]) 

func _create_picker_dialog(node_name: String, filters: Array) -> FileDialog:
	var dialog := FileDialog.new()
	dialog.name = node_name
	dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	dialog.access = FileDialog.ACCESS_FILESYSTEM
	dialog.use_native_dialog = true
	dialog.size = Vector2i(920, 540)
	dialog.filters = PackedStringArray(filters)
	dialog.file_selected.connect(_on_picker_file_selected)
	add_child(dialog)
	return dialog

func _build_sets_editor_ui() -> void:
	var add_delete_row := HBoxContainer.new()
	add_delete_row.name = "SetActionsRow"
	var add_button := Button.new()
	add_button.name = "CreateSetButton"
	add_button.text = "Create Set"
	add_button.pressed.connect(_on_create_set_pressed)
	add_delete_row.add_child(add_button)
	var delete_button := Button.new()
	delete_button.name = "DeleteSetButton"
	delete_button.text = "Delete Selected Set"
	delete_button.pressed.connect(_on_delete_selected_set_pressed)
	add_delete_row.add_child(delete_button)
	_sets_tab.add_child(add_delete_row)
	_sets_tab.move_child(add_delete_row, 1)

	var panel := VBoxContainer.new()
	panel.name = "SetEditorPanel"
	panel.add_theme_constant_override("separation", 10)
	_sets_tab.add_child(panel)

	var selected_label := Label.new()
	selected_label.name = "SelectedSetLabel"
	selected_label.text = "No set selected."
	panel.add_child(selected_label)

	var name_row := HBoxContainer.new()
	panel.add_child(name_row)
	var name_label := Label.new()
	name_label.text = "Set Name"
	name_row.add_child(name_label)
	var name_edit := LineEdit.new()
	name_edit.name = "SetNameEdit"
	name_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_edit.text_changed.connect(_on_set_name_changed)
	name_row.add_child(name_edit)

	panel.add_child(_build_picker_row("Beatmap", "BeatmapPathEdit", "PickBeatmapButton", Callable(self, "_open_picker").bind({"kind": "beatmap"}), Callable(self, "_clear_selected_beatmap")))
	var beatmap_meta := Label.new()
	beatmap_meta.name = "BeatmapMetadataLabel"
	beatmap_meta.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	panel.add_child(beatmap_meta)

	panel.add_child(_build_picker_row("Primary Environment", "PrimaryEnvironmentPathEdit", "PickPrimaryEnvironmentButton", Callable(self, "_open_picker").bind({"kind": "environment", "role": "preferred"}), Callable(self, "_clear_selected_environment").bind("preferred")))
	panel.add_child(_build_picker_row("Fallback Environment", "FallbackEnvironmentPathEdit", "PickFallbackEnvironmentButton", Callable(self, "_open_picker").bind({"kind": "environment", "role": "fallback"}), Callable(self, "_clear_selected_environment").bind("fallback")))
	var environment_meta := Label.new()
	environment_meta.name = "EnvironmentMetadataLabel"
	environment_meta.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	panel.add_child(environment_meta)

	panel.add_child(_build_picker_row("Coaching Audio", "CoachingAudioPathEdit", "PickCoachingAudioButton", Callable(self, "_open_picker").bind({"kind": "coaching_audio"}), Callable(self, "_clear_selected_coaching_audio")))
	var coaching_audio_meta := Label.new()
	coaching_audio_meta.name = "CoachingAudioMetadataLabel"
	coaching_audio_meta.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	panel.add_child(coaching_audio_meta)

	var audio_controls := VBoxContainer.new()
	audio_controls.name = "CoachingAudioControls"
	panel.add_child(audio_controls)
	var audio_status := Label.new()
	audio_status.name = "CoachingAudioStatusLabel"
	audio_status.text = "No coaching audio selected."
	audio_controls.add_child(audio_status)
	var audio_buttons := HBoxContainer.new()
	audio_controls.add_child(audio_buttons)
	var play_button := Button.new()
	play_button.name = "PlayCoachingAudioButton"
	play_button.text = "Play"
	play_button.pressed.connect(_on_play_coaching_audio_pressed)
	audio_buttons.add_child(play_button)
	var pause_button := Button.new()
	pause_button.name = "PauseCoachingAudioButton"
	pause_button.text = "Pause"
	pause_button.pressed.connect(_on_pause_coaching_audio_pressed)
	audio_buttons.add_child(pause_button)
	var stop_button := Button.new()
	stop_button.name = "StopCoachingAudioButton"
	stop_button.text = "Stop"
	stop_button.pressed.connect(_on_stop_coaching_audio_pressed)
	audio_buttons.add_child(stop_button)
	var seek_slider := HSlider.new()
	seek_slider.name = "CoachingAudioSeekSlider"
	seek_slider.min_value = 0.0
	seek_slider.max_value = 1.0
	seek_slider.step = 0.001
	seek_slider.value_changed.connect(_on_coaching_audio_seek_changed)
	audio_controls.add_child(seek_slider)
	var volume_row := HBoxContainer.new()
	audio_controls.add_child(volume_row)
	var volume_label := Label.new()
	volume_label.text = "Volume"
	volume_row.add_child(volume_label)
	var volume_slider := HSlider.new()
	volume_slider.name = "CoachingAudioVolumeSlider"
	volume_slider.min_value = -40.0
	volume_slider.max_value = 6.0
	volume_slider.step = 1.0
	volume_slider.value = 0.0
	volume_slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	volume_slider.value_changed.connect(_on_coaching_audio_volume_changed)
	volume_row.add_child(volume_slider)

	_set_editor_controls = {
		"panel": panel,
		"selected_label": selected_label,
		"name_edit": name_edit,
		"delete_button": delete_button,
		"beatmap_path": panel.find_child("BeatmapPathEdit", true, false),
		"beatmap_meta": beatmap_meta,
		"primary_environment_path": panel.find_child("PrimaryEnvironmentPathEdit", true, false),
		"fallback_environment_path": panel.find_child("FallbackEnvironmentPathEdit", true, false),
		"environment_meta": environment_meta,
		"coaching_audio_path": panel.find_child("CoachingAudioPathEdit", true, false),
		"coaching_audio_meta": coaching_audio_meta,
		"coaching_audio_status": audio_status,
		"coaching_audio_seek": seek_slider,
		"coaching_audio_volume": volume_slider,
	}

func _build_picker_row(label_text: String, line_edit_name: String, button_name: String, pick_callback: Callable, clear_callback: Callable) -> HBoxContainer:
	var row := HBoxContainer.new()
	var label := Label.new()
	label.text = label_text
	label.custom_minimum_size = Vector2(150.0, 0.0)
	row.add_child(label)
	var line_edit := LineEdit.new()
	line_edit.name = line_edit_name
	line_edit.editable = false
	line_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(line_edit)
	var pick_button := Button.new()
	pick_button.name = button_name
	pick_button.text = "Pick…"
	pick_button.pressed.connect(pick_callback)
	row.add_child(pick_button)
	var clear_button := Button.new()
	clear_button.text = "Clear"
	clear_button.pressed.connect(clear_callback)
	row.add_child(clear_button)
	return row

func _build_coaching_preview_ui(tab: VBoxContainer, slot_name: String) -> void:
	var picker_row := HBoxContainer.new()
	picker_row.name = "%sPickerRow" % slot_name.capitalize()
	var pick_button := Button.new()
	pick_button.name = "%sPickVideoButton" % slot_name.capitalize()
	pick_button.text = "Pick %s .ogv" % slot_name.capitalize()
	pick_button.pressed.connect(_open_picker.bind({"kind": "coach_video", "slot": slot_name}))
	picker_row.add_child(pick_button)
	var clear_button := Button.new()
	clear_button.text = "Clear"
	clear_button.pressed.connect(_clear_coach_video.bind(slot_name))
	picker_row.add_child(clear_button)
	tab.add_child(picker_row)

	var metadata := Label.new()
	metadata.name = "%sVideoMetadataLabel" % slot_name.capitalize()
	metadata.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tab.add_child(metadata)

	var surface_frame := PanelContainer.new()
	surface_frame.name = "%sVideoSurfaceFrame" % slot_name.capitalize()
	surface_frame.custom_minimum_size = Vector2(0.0, 220.0)
	tab.add_child(surface_frame)
	var surface := Control.new()
	surface.name = "%sVideoSurface" % slot_name.capitalize()
	surface.custom_minimum_size = Vector2(0.0, 220.0)
	surface.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	surface.size_flags_vertical = Control.SIZE_EXPAND_FILL
	surface_frame.add_child(surface)

	var status := Label.new()
	status.name = "%sVideoStatusLabel" % slot_name.capitalize()
	status.text = "No %s video selected." % slot_name.capitalize()
	tab.add_child(status)

	var controls_row := HBoxContainer.new()
	tab.add_child(controls_row)
	var play_button := Button.new()
	play_button.text = "Play"
	play_button.pressed.connect(_on_video_play_pressed.bind(slot_name))
	controls_row.add_child(play_button)
	var pause_button := Button.new()
	pause_button.text = "Pause"
	pause_button.pressed.connect(_on_video_pause_pressed.bind(slot_name))
	controls_row.add_child(pause_button)
	var stop_button := Button.new()
	stop_button.text = "Stop"
	stop_button.pressed.connect(_on_video_stop_pressed.bind(slot_name))
	controls_row.add_child(stop_button)

	var seek_slider := HSlider.new()
	seek_slider.min_value = 0.0
	seek_slider.max_value = 1.0
	seek_slider.step = 0.001
	seek_slider.value_changed.connect(_on_video_seek_changed.bind(slot_name))
	tab.add_child(seek_slider)

	_coaching_video_controls[slot_name] = {
		"metadata": metadata,
		"surface": surface,
		"status": status,
		"seek": seek_slider,
	}

func _open_picker(context: Dictionary) -> void:
	_pending_picker = context.duplicate(true)
	var dialog_key := String(context.get("kind", "")).strip_edges()
	if dialog_key == "coach_video":
		dialog_key = "coach_video"
	var dialog: FileDialog = _dialogs.get(dialog_key)
	if dialog != null:
		dialog.popup_centered_ratio(0.8)

func _on_picker_file_selected(path: String) -> void:
	var kind := String(_pending_picker.get("kind", "")).strip_edges()
	match kind:
		"beatmap":
			var beatmap_result := _runtime.import_beatmap_for_set(_selected_set_id, path)
			if bool(beatmap_result.get("ok", false)):
				_set_status("Imported beatmap for %s." % _selected_set_id)
		"environment":
			var environment_result := _runtime.assign_environment_to_set(_selected_set_id, String(_pending_picker.get("role", "preferred")), path)
			if bool(environment_result.get("ok", false)):
				_set_status("Linked %s environment for %s." % [String(_pending_picker.get("role", "preferred")), _selected_set_id])
		"coaching_audio":
			var audio_result := _runtime.assign_coaching_audio_to_set(_selected_set_id, path)
			if bool(audio_result.get("ok", false)):
				_set_status("Linked coaching audio for %s." % _selected_set_id)
		"coach_video":
			var slot_name := String(_pending_picker.get("slot", "warmup"))
			var video_result := _runtime.set_coach_video_source(slot_name, path)
			if bool(video_result.get("ok", false)):
				_set_status("Linked %s video preview." % slot_name)
	_pending_picker = {}

func _on_create_set_pressed() -> void:
	var result := _runtime.create_set()
	if bool(result.get("ok", false)):
		_selected_set_id = String(Dictionary(result.get("set", {})).get("setId", ""))
		_set_status("Created %s." % _selected_set_id)

func _on_delete_selected_set_pressed() -> void:
	if _selected_set_id.is_empty():
		return
	var state_before := _runtime.get_current_package_state()
	var order_before: Array = Array(Dictionary(state_before.get("songPackage", {})).get("setIds", []))
	var deleted_id := _selected_set_id
	var result := _runtime.delete_set(deleted_id)
	if bool(result.get("ok", false)):
		var state_after := Dictionary(result.get("state", {}))
		var order_after: Array = Array(Dictionary(state_after.get("songPackage", {})).get("setIds", []))
		_selected_set_id = String(order_after[0]) if not order_after.is_empty() else ""
		_set_status("Deleted %s." % deleted_id)

func _on_set_selected(index: int) -> void:
	_selected_set_id = String(_set_order_list.get_item_metadata(index))
	_refresh_selected_set_editor(_runtime.get_current_package_state())

func _on_set_name_changed(value: String) -> void:
	if _is_syncing_ui or _selected_set_id.is_empty():
		return
	_runtime.rename_set(_selected_set_id, value)

func _clear_selected_beatmap() -> void:
	if _selected_set_id.is_empty():
		return
	_runtime.update_set_record(_selected_set_id, {"chartId": ""})
	_set_status("Cleared beatmap link for %s." % _selected_set_id)

func _clear_selected_environment(role: String) -> void:
	if _selected_set_id.is_empty():
		return
	var field_name := "preferredEnvironmentId" if role == "preferred" else "fallbackEnvironmentId"
	_runtime.update_set_record(_selected_set_id, {field_name: ""})
	_set_status("Cleared %s environment link for %s." % [role, _selected_set_id])

func _clear_selected_coaching_audio() -> void:
	if _selected_set_id.is_empty():
		return
	_runtime.update_set_record(_selected_set_id, {"coachingOverlayId": ""})
	_set_status("Cleared coaching audio link for %s." % _selected_set_id)

func _clear_coach_video(slot_name: String) -> void:
	_runtime.clear_coach_video_source(slot_name)
	_set_status("Cleared %s video." % slot_name)

func _on_play_coaching_audio_pressed() -> void:
	if _selected_set_id.is_empty():
		return
	_audio_loader.play(_selected_set_id)

func _on_pause_coaching_audio_pressed() -> void:
	if _selected_set_id.is_empty():
		return
	_audio_loader.pause(_selected_set_id)

func _on_stop_coaching_audio_pressed() -> void:
	if _selected_set_id.is_empty():
		return
	_audio_loader.stop(_selected_set_id)

func _on_coaching_audio_seek_changed(value: float) -> void:
	if _is_syncing_ui or _selected_set_id.is_empty():
		return
	var duration := _audio_loader.get_duration(_selected_set_id)
	if duration > 0.0:
		_audio_loader.seek(duration * value, _selected_set_id)

func _on_coaching_audio_volume_changed(value: float) -> void:
	if _selected_set_id.is_empty():
		return
	_audio_loader.set_volume_db(value, _selected_set_id)

func _on_audio_state_changed(audio_id: String, state_name: String, state: Dictionary) -> void:
	if audio_id != _selected_set_id:
		return
	(_set_editor_controls["coaching_audio_status"] as Label).text = "Audio preview: %s" % state_name

func _on_audio_position_changed(audio_id: String, _seconds: float, normalized: float) -> void:
	if audio_id != _selected_set_id:
		return
	var slider: HSlider = _set_editor_controls["coaching_audio_seek"]
	_is_syncing_ui = true
	slider.value = normalized
	_is_syncing_ui = false

func _on_audio_media_loaded(audio_id: String, info: Dictionary) -> void:
	if audio_id != _selected_set_id:
		return
	(_set_editor_controls["coaching_audio_status"] as Label).text = "Audio preview loaded (%s)." % String(info.get("path", info.get("resolved_path", "media")))

func _on_audio_error(audio_id: String, error_info: Dictionary) -> void:
	if audio_id != _selected_set_id:
		return
	(_set_editor_controls["coaching_audio_status"] as Label).text = "Audio preview error: %s" % String(error_info.get("message", "unknown_error"))

func _on_video_play_pressed(slot_name: String) -> void:
	var manager = _video_managers.get(slot_name)
	if manager != null:
		manager.play(slot_name)

func _on_video_pause_pressed(slot_name: String) -> void:
	var manager = _video_managers.get(slot_name)
	if manager != null:
		manager.pause(slot_name)

func _on_video_stop_pressed(slot_name: String) -> void:
	var manager = _video_managers.get(slot_name)
	if manager != null:
		manager.stop(slot_name)

func _on_video_seek_changed(value: float, slot_name: String) -> void:
	if _is_syncing_ui:
		return
	var manager = _video_managers.get(slot_name)
	if manager == null:
		return
	var state: Dictionary = manager.get_state(slot_name)
	var duration := float(Dictionary(state.get("media_info", {})).get("duration", 0.0))
	if duration > 0.0:
		manager.seek(duration * value, slot_name)

func _on_video_media_loaded(slot_name: String, info: Dictionary) -> void:
	if not _coaching_video_controls.has(slot_name):
		return
	(_coaching_video_controls[slot_name]["status"] as Label).text = "Video preview loaded (%s)." % String(info.get("resolved_path", info.get("path", "video")))

func _on_video_position_changed(slot_name: String, _seconds: float, normalized: float) -> void:
	if not _coaching_video_controls.has(slot_name):
		return
	var slider: HSlider = _coaching_video_controls[slot_name]["seek"]
	_is_syncing_ui = true
	slider.value = normalized
	_is_syncing_ui = false

func _on_video_preview_error(slot_name: String, error_info: Dictionary) -> void:
	if not _coaching_video_controls.has(slot_name):
		return
	(_coaching_video_controls[slot_name]["status"] as Label).text = "Video preview error: %s" % String(error_info.get("message", "unknown_error"))

func _on_environment_preview_loaded(result: Dictionary) -> void:
	_environment_status_label.text = "Environment preview active: %s" % String(result.get("asset_path", "environment"))

func _on_environment_preview_failed(error: Dictionary) -> void:
	_environment_status_label.text = "Environment preview error: %s" % String(error.get("message", error.get("error_code", "loader_failed")))

func _on_environment_preview_cleared() -> void:
	_environment_status_label.text = "Environment preview: no environment loaded."

func _on_root_resized() -> void:
	if _preview_viewport != null:
		_preview_viewport.size = size
	if _preview_canvas_root != null:
		_preview_canvas_root.size = size

func _selected_set_record(state: Dictionary) -> Dictionary:
	for set_variant in Array(state.get("sets", [])):
		var set_record := Dictionary(set_variant)
		if String(set_record.get("setId", "")) == _selected_set_id:
			return set_record.duplicate(true)
	return {}

func _format_beatmap_metadata(chart_record: Dictionary) -> String:
	if chart_record.is_empty():
		return "Beatmap: no linked file yet."
	var bits: Array[String] = []
	bits.append("Beatmap: %s" % String(chart_record.get("chartName", chart_record.get("chartId", "(unnamed)"))))
	bits.append("mode=%s" % String(chart_record.get("mode", "boxing")))
	bits.append("difficulty=%s" % String(chart_record.get("difficulty", "Normal")))
	bits.append("events=%d" % Array(chart_record.get("beats", [])).size())
	if chart_record.has("songId") and not String(chart_record.get("songId", "")).is_empty():
		bits.append("songId=%s" % String(chart_record.get("songId", "")))
	return " • ".join(bits)

func _format_environment_metadata(preferred_environment: Dictionary, fallback_environment: Dictionary) -> String:
	if preferred_environment.is_empty() and fallback_environment.is_empty():
		return "Environment: choose primary and fallback environment assets. Fallback is required; it may match the primary."
	var parts: Array[String] = []
	if not preferred_environment.is_empty():
		parts.append("primary=%s (%s)" % [String(preferred_environment.get("environmentId", "")), String(preferred_environment.get("type", ""))])
	if not fallback_environment.is_empty():
		parts.append("fallback=%s (%s)" % [String(fallback_environment.get("environmentId", "")), String(fallback_environment.get("type", ""))])
	return "Environment: %s" % " • ".join(parts)

func _format_audio_metadata(overlay_record: Dictionary) -> String:
	if overlay_record.is_empty():
		return "Coaching audio: pick a per-set overlay clip to enable preview."
	return _format_media_metadata(overlay_record)

func _format_media_metadata(record: Dictionary) -> String:
	if record.is_empty():
		return "No media selected."
	var source_path := String(record.get("sourcePath", record.get("path", ""))).strip_edges()
	var metadata := _runtime.get_file_metadata(_runtime.resolve_preview_path(source_path if source_path.contains("/") else String(record.get("path", ""))))
	var parts: Array[String] = []
	if record.has("mediaId"):
		parts.append("mediaId=%s" % String(record.get("mediaId", "")))
	if record.has("overlayId"):
		parts.append("overlayId=%s" % String(record.get("overlayId", "")))
	if not metadata.is_empty():
		parts.append("file=%s" % String(metadata.get("fileName", "")))
		parts.append("ext=%s" % String(metadata.get("extension", "")))
		parts.append("bytes=%d" % int(metadata.get("fileSizeBytes", 0)))
	else:
		parts.append("path=%s" % String(record.get("path", "")))
	return " • ".join(parts)
