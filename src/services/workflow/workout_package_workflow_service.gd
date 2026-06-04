class_name WorkoutPackageWorkflowService
extends RefCounted

const WorkoutPackageYamlCodec = preload("workout_package_yaml_codec.gd")

var _codec: WorkoutPackageYamlCodec = WorkoutPackageYamlCodec.new()

func create_new_package_state(seed: Dictionary = {}) -> Dictionary:
	return {
		"ok": true,
		"state": _codec.create_blank_package_state(seed),
	}

func load_package_folder(package_dir: String) -> Dictionary:
	return _codec.load_package_state(package_dir)

func write_package_state(state: Dictionary, package_dir: String) -> Dictionary:
	return _codec.write_package_state(state, package_dir)

func reset_package_state() -> Dictionary:
	return {
		"ok": true,
		"state": _codec.create_blank_package_state(),
	}
