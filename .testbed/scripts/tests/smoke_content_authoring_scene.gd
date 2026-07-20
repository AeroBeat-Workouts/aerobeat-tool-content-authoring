extends SceneTree

const TestSupport = preload("res://scripts/tests/test_support.gd")

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var scene_resource: PackedScene = load("res://scenes/ContentAuthoring.tscn")
	var scene := scene_resource.instantiate()
	root.add_child(scene)
	await process_frame

	var workflow_tabs: TabContainer = scene.get_node("MarginContainer/RootVBox/WorkflowTabs")
	var save_button: Button = scene.get_node("MarginContainer/RootVBox/TopBar/ActionButtons/SaveWorkoutButton")
	var load_button: Button = scene.get_node("MarginContainer/RootVBox/TopBar/ActionButtons/LoadWorkoutButton")
	var metadata_scroll: ScrollContainer = scene.get_node("MarginContainer/RootVBox/WorkflowTabs/MetadataTab/MetadataScroll")
	var runtime = scene.get_node("AuthoringRuntime")
	var tab_titles: Array[String] = []
	for index in range(workflow_tabs.get_tab_count()):
		tab_titles.append(workflow_tabs.get_tab_title(index))

	var workout_id_edit: LineEdit = scene.get_node("MarginContainer/RootVBox/WorkflowTabs/MetadataTab/MetadataScroll/MetadataMargin/MetadataStack/MetadataForm/WorkoutIdEdit")
	var workout_name_edit: LineEdit = scene.get_node("MarginContainer/RootVBox/WorkflowTabs/MetadataTab/MetadataScroll/MetadataMargin/MetadataStack/MetadataForm/WorkoutNameEdit")
	var package_version_edit: LineEdit = scene.get_node("MarginContainer/RootVBox/WorkflowTabs/MetadataTab/MetadataScroll/MetadataMargin/MetadataStack/MetadataForm/PackageVersionEdit")
	workout_id_edit.text = "ab-song-package-scene-smoke"
	workout_name_edit.text = "Scene Smoke Draft"
	package_version_edit.text = "9.9.9"
	scene._commit_metadata_state()
	var committed_state: Dictionary = runtime.get_current_package_state()

	var fixture_dir: String = TestSupport.demo_package_dir()
	var load_result: Dictionary = runtime.load_song_package_folder(fixture_dir)
	await process_frame
	var loaded_state: Dictionary = runtime.get_current_package_state()
	var sets_list: ItemList = scene.get_node("MarginContainer/RootVBox/WorkflowTabs/SetsTab/SetOrderList")
	var loaded_package_label: Label = scene.get_node("MarginContainer/RootVBox/InfoPanel/InfoMargin/InfoVBox/LoadedPackageLabel")
	var create_set_button: Button = scene.get_node("MarginContainer/RootVBox/WorkflowTabs/SetsTab/SetActionsRow/CreateSetButton")
	var set_editor_panel: VBoxContainer = scene.get_node("MarginContainer/RootVBox/WorkflowTabs/SetsTab/SetEditorPanel")
	var warmup_surface: Control = scene.get_node("MarginContainer/RootVBox/WorkflowTabs/WarmUpCoachingTab/WarmupVideoSurfaceFrame/WarmupVideoSurface")
	var preview_layer: SubViewportContainer = scene.get_node("EnvironmentPreviewLayer")

	var checks := {
		"scene_name": scene.name == "ContentAuthoring",
		"default_tab_metadata": workflow_tabs.current_tab == 0 and workflow_tabs.get_tab_title(0) == "Metadata",
		"tab_titles": tab_titles == ["Metadata", "Warm-Up Coaching", "Sets", "Cool-Down Coaching"],
		"buttons_present": save_button != null and load_button != null,
		"metadata_scroll_present": metadata_scroll != null,
		"metadata_binding": String(Dictionary(committed_state.get("songPackage", {})).get("songPackageId", "")) == "ab-song-package-scene-smoke" and String(committed_state.get("songPackage", {}).get("packageVersion", "")) == "9.9.9",
		"fixture_loaded": bool(load_result.get("ok", false)) and String(Dictionary(loaded_state.get("songPackage", {})).get("songPackageId", "")) == "ab-songpkg-splat-demo",
		"default_one_set_exists": Array(runtime.get_current_package_state().get("sets", [])).size() >= 1,
		"sets_reflected": sets_list.item_count > 0,
		"set_editor_present": create_set_button != null and set_editor_panel != null,
		"warmup_preview_present": warmup_surface != null,
		"background_preview_present": preview_layer != null,
		"loaded_label_updated": loaded_package_label.text.contains("demo-neon-boxing-bootcamp"),
	}

	var passed := true
	for value in checks.values():
		if not bool(value):
			passed = false
			break

	print(JSON.stringify({
		"passed": passed,
		"checks": checks,
		"loadResult": load_result,
	}, "  "))
	quit(0 if passed else 1)
