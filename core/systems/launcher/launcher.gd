@icon("res://assets/editor-icons/ph-rocket-launch-fill.svg")
extends Node
class_name Launcher

@export var launch_manager := preload("res://core/global/launch_manager.tres") as LaunchManager

@onready var overlay_display = OS.get_environment("DISPLAY")
@onready var input_manager := get_tree().get_first_node_in_group("input_manager") as InputManager

func _init() -> void:
	launch_manager._load_persist_data()


func _ready() -> void:
	var timer := Timer.new()
	timer.autostart = true
	timer.one_shot = false
	timer.wait_time = 1
	timer.timeout.connect(launch_manager.check_running)
	add_child(timer)

	# Give the launch manager access to the input manager
	launch_manager.setup(input_manager)
