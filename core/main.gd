extends Node

var args := OS.get_cmdline_args()


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Display a custom help if 'help' in args
	if "help" in args:
		_show_help()
		get_tree().quit()
		return
	
	# Launch old ui
	if "--vapor-ui" in args:
		# in only-qam mode
		if "--qam-only" in args or "--only-qam" in args:
			get_tree().change_scene_to_file("res://core/ui/vapor_ui_only_qam/only_qam_main.tscn")
			return
		get_tree().change_scene_to_file("res://core/ui/vapor_ui/vapor_ui.tscn")
		return

	# Launch CardUI in only-qam mode
	if "--qam-only" in args or "--only-qam" in args:
		get_tree().change_scene_to_file("res://core/ui/card_ui_only_qam/only_qam_main.tscn")
		return
	# Launch the main interface
	get_tree().change_scene_to_file("res://core/ui/card_ui/card_ui.tscn")


# Show command-line help options
func _show_help() -> void:
	print("OpenGamepadUI open source game launcher")
	print("")
	print("Usage:")
	print("  ", OS.get_executable_path(), " [flags] [command]")
	print("")
	print("Available Commands:")
	print("  help             Display this help message")
	print("")
	print("Flags:")
	print("  --vapor-ui       Load Vapor UI")
	print("  --only-qam       Load the only-qam UI")
	print("")
	print("Environment Variables:")
	print("  LOG_LEVEL        Set the global log level (debug,info,warn,error)")
	print("  LOG_LEVEL_<NAME> Set the log level for one logger (debug,info,warn,error)")
	print("")
