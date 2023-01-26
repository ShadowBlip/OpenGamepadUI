extends Node

const main := preload("res://main.tscn")


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	get_tree().get_root().transparent_bg = true
	
	var args := OS.get_cmdline_args()
	if "--qam-only" in args or "--only-qam" in args:
		get_tree().change_scene_to_file("res://core/ui/menu/qam/quick_access_menu.tscn")
