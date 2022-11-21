extends Node
class_name Launcher

@export var cmd: String
@export var args: PackedStringArray
@export var signal_name: String = "button_up"
@onready var parent: Node = get_parent()

func _ready() -> void:
	parent.connect(signal_name, _on_launch)

func _on_launch():
	var launch_manager: LaunchManager = get_node("/root/Main/LaunchManager")
	launch_manager.launch(cmd, args)

	# TODO: Make this better
	#parent.get_parent().get_parent().visible = false
