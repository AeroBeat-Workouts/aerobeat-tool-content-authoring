extends GutTest

const AeroToolManager = preload("../src/AeroToolManager.gd")

func test_manager_initializes_shared_services():
	var manager := AeroToolManager.new()
	add_child_autofree(manager)
	manager._ready()
	assert_true(manager.get_validate_package_service() != null)
	assert_true(manager.get_build_content_package_service() != null)
