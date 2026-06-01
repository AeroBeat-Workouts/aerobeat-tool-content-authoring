@tool
class_name ContentAuthoringPlugin
extends EditorPlugin

const AeroContentAuthoring = preload("../../src/AeroContentAuthoring.gd")

static func build_service_registry() -> Dictionary:
	return AeroContentAuthoring.build_service_registry()

func _enter_tree() -> void:
	pass

func _exit_tree() -> void:
	pass
