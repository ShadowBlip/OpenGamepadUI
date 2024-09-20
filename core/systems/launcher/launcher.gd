@icon("res://assets/editor-icons/ph-rocket-launch-fill.svg")
extends Node
class_name Launcher

@export var launch_manager := preload("res://core/global/launch_manager.tres") as LaunchManager

@onready var overlay_display = OS.get_environment("DISPLAY")


func _init() -> void:
	launch_manager._load_persist_data()


# TODO: Replace this with dbus signaling. This is super shitty.
func _process(delta) -> void:
	launch_manager.check_running()
