extends Node

const main := preload("res://main.tscn")


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var args := OS.get_cmdline_args()
	if "--qam-only" in args or "--only-qam" in args:
		get_tree().get_root().transparent_bg = true
		get_tree().change_scene_to_file("res://core/ui/menu/qam/quick_access_menu.tscn")
		var display := OS.get_environment("DISPLAY")
		var pid := OS.get_process_id()
		var window_id := Gamescope.get_window_id(display, pid)
		Gamescope.set_external_overlay(display, window_id, 1)
