@icon("res://assets/editor-icons/ph-rocket-launch-fill.svg")
extends Node

@export var launch_manager := preload("res://core/global/launch_manager.tres") as LaunchManager

@onready var overlay_display = OS.get_environment("DISPLAY")


func _init() -> void:
	launch_manager._load_persist_data()


func _ready() -> void:
	# Set a timer that will update our state based on if anything is running.
	var running_timer = Timer.new()
	running_timer.timeout.connect(launch_manager._check_running)
	running_timer.wait_time = 1
	add_child(running_timer)
	running_timer.start()
