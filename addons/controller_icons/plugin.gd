@tool
extends EditorPlugin

func _enter_tree():
	add_autoload_singleton("ControllerIcons", "res://addons/controller_icons/ControllerIcons.gd")
	
func _exit_tree():
	remove_autoload_singleton("ControllerIcons")
