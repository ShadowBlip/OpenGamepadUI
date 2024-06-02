extends OSPlatform
class_name PlatformChimeraOS

const DEFAULT_THEME := "res://assets/themes/card_ui-darksoul.tres"
const DEFAULT_OVERLAY_THEME := "res://assets/themes/card_ui-water-vapor.tres"
const SESSION_SELECT_PATH := "/usr/lib/os-session-select"

var settings_manager := load("res://core/global/settings_manager.tres") as SettingsManager


func _init() -> void:
	logger.set_name("PlatformChimeraOS")
	logger.set_level(Log.LEVEL.INFO)


func ready(root: Window) -> void:
	if not _has_session_switcher():
		logger.info("No session switcher script detected")
		return
	_add_session_switcher(root)
	_set_default_theme(root)


## Add a button to the power menu to allow session switching
func _add_session_switcher(root: Window) -> void:
	# Get the power menu
	var power_menu := root.get_tree().get_first_node_in_group("power_menu")
	if not power_menu:
		logger.warn("No power menu was found. Unable to add session switcher.")
		return

	# Create a button that will perform the session switching
	var button_scene := load("res://core/ui/components/card_button.tscn") as PackedScene
	var switch_to_desktop := button_scene.instantiate() as CardButton
	switch_to_desktop.click_focuses = false
	switch_to_desktop.text = "Switch to Desktop"
	switch_to_desktop.pressed.connect(_switch_session.bind("desktop"))

	# Add the buttons just above the exit button
	var exit_button := power_menu.exit_button as Control
	var container := exit_button.get_parent()
	container.add_child(switch_to_desktop)
	container.move_child(switch_to_desktop, exit_button.get_index())

	# Coerce the focus group to recalculate the focus neighbors
	var focus_group := power_menu.focus_group as FocusGroup
	focus_group.recalculate_focus()


## Returns true if we detect the session switching script
func _has_session_switcher() -> bool:
	return FileAccess.file_exists(SESSION_SELECT_PATH)


## Switch to the given session
func _switch_session(name: String) -> void:
	var out: Array = []
	var code := OS.execute(SESSION_SELECT_PATH, [name], out)
	if code != OK:
		logger.error("Unable to switch sessions: " + out[0])


## Sets the default theme.
func _set_default_theme(root: Window) -> void:
	var user_theme := settings_manager.get_value("general", "theme", "") as String
	if not user_theme.is_empty():
		logger.debug("Found existing theme: " + user_theme)
		return
	logger.debug("No theme set. Using OS specific default theme: " + DEFAULT_THEME)

	# Find the main node
	var main: Control
	var nodes := root.get_tree().get_nodes_in_group("main")
	for node in nodes:
		if not node is Control:
			continue
		main = node
		break

	if not main:
		logger.warn("Unable to find main node!")
		return

	# Set the default theme depending on if this is overlay mode or full session
	var theme_path := DEFAULT_THEME
	if main.name == "CardUI":
		logger.debug("Detected full session")
		theme_path = DEFAULT_THEME
	elif main.name.contains("Control"):
		logger.debug("Detected overlay session")
		theme_path = DEFAULT_OVERLAY_THEME
	else:
		logger.warn("Unable to determine session type to set theme")
	logger.debug("Using theme: " + theme_path)

	# Set the theme when the main node is ready
	var on_main_ready := func():
		var current_theme = main.theme
		if theme_path != "" && current_theme.resource_path != theme_path:
			logger.debug("Setting theme to: " + theme_path)
			var loaded_theme = load(theme_path)
			if loaded_theme != null:
				# TODO: This is a workaround, themes aren't properly set the first time.
				main.call_deferred("set_theme", loaded_theme)
				main.call_deferred("set_theme", current_theme)
				main.call_deferred("set_theme", loaded_theme)
			else:
				logger.debug("Unable to load theme")
	main.ready.connect(on_main_ready)
