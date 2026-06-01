extends Control

@onready var _status_label: Label = %StatusLabel

func _ready() -> void:
	_status_label.text = "AeroBeat Content Authoring testbed skeleton ready."
