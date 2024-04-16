extends Node

var args := OS.get_cmdline_args()


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Display a custom help if 'help' in args
	if "help" in args:
		_show_help()
		get_tree().quit()
		return

	# Launch CardUI in overlay mode
	if "--qam-only" in args or "--only-qam" in args:
		print("[WARN] Deprecation Warning: --only-qam and --qam-only launch arguments are deprecated\
		and will be removed in a future update. Use --overlay-mode instead.")
		_change_to_scene("res://core/ui/card_ui_overlay_mode/card_ui_overlay_mode.tscn")
		return
	elif "--overlay-mode" in args:
		_change_to_scene("res://core/ui/card_ui_overlay_mode/card_ui_overlay_mode.tscn")
		return

	# Launch the main interface
	_change_to_scene("res://core/ui/card_ui/card_ui.tscn")


# Change to the given scene
func _change_to_scene(scene_path: String) -> void:
	var scene := load(scene_path) as PackedScene
	var root := get_window()
	root.add_child(scene.instantiate())
	queue_free()


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
	print("  --only-qam       Launch in overlay mode (Deprecated)")
	print("  --overlay-mode   Launch in overlay mode")
	print("")
	print("Environment Variables:")
	print("  LOG_LEVEL        Set the global log level (debug,info,warn,error)")
	print("  LOG_LEVEL_<NAME> Set the log level for one logger (debug,info,warn,error)")
	print("")
