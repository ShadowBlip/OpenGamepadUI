extends Node


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	get_tree().get_root().transparent_bg = true

	var args := OS.get_cmdline_args()
	# Launch only-qam mode
	if "--qam-only" in args or "--only-qam" in args:
		get_tree().change_scene_to_file("res://core/only_qam.tscn")
		return

	# Launch the main interface
	get_tree().change_scene_to_file("res://core/main.tscn")
