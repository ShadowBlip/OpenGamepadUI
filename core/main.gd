extends Node

var args := OS.get_cmdline_args()


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Launch only-qam mode
	if "--qam-only" in args or "--only-qam" in args:
		get_tree().change_scene_to_file("res://core/ui/only_qam_ui/only_qam_main.tscn")
		return

	# Launch old ui
	if "--vapor-ui" in args:
		get_tree().change_scene_to_file("res://core/ui/vapor_ui/vapor_ui.tscn")
		return

	# Launch the main interface
	get_tree().change_scene_to_file("res://core/ui/card_ui/card_ui.tscn")
