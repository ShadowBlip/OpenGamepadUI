extends Node

var args := OS.get_cmdline_args()
var feature_flags := load("res://core/systems/features/feature_flags.tres") as FeatureFlags


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Resolve feature flags from launch arguments and the environment
	feature_flags.load_from_os()

	# Display a custom help if 'help' in args
	if "help" in args:
		_show_help()
		get_tree().quit()
		return

	# Launch CardUI in overlay mode
	if feature_flags.is_enabled("overlay-mode"):
		_change_to_scene("res://core/ui/card_ui_overlay_mode/card_ui_overlay_mode.tscn")
		return

	# Launch the main interface selected by feature flags (CardUI is the default)
	if feature_flags.is_enabled("etoile-ui"):
		_change_to_scene("res://core/ui/etoile_ui/etoile_ui.tscn")
		return
	if not feature_flags.is_enabled("card-ui"):
		print("[WARN] No UI feature enabled, loading the default CardUI")
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
	print("Environment Variables:")
	print("  LOG_LEVEL        Set the global log level (debug,info,warn,error)")
	print("  LOG_LEVEL_<NAME> Set the log level for one logger (debug,info,warn,error)")
	print("  OGUI_FEATURES    Comma-separated list of features to enable")
	print("  OGUI_DISABLED_FEATURES Comma-separated list of features to disable")
	print("")
	print("Features (--feature-<id> / --feature-no-<id>, or alias flags):")
	for feature in feature_flags.get_features():
		var description := feature.description
		if description == "":
			description = "Feature flag"
		print("  ", feature.id, "  ", description)
		var alias_text := ""
		for alias in feature.aliases:
			alias_text += " --" + str(alias)
		if alias_text != "":
			print("    aliases:", alias_text)
	print("")
