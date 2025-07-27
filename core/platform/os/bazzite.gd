extends OSPlatform
class_name PlatformBazzite

const SESSION_SELECT_PATH := "/usr/bin/steamos-session-select"


func _init() -> void:
	logger.set_name("PlatformBazzite")
	logger.set_level(Log.LEVEL.INFO)


func ready(root: Window) -> void:
	if not _has_session_switcher():
		logger.info("No session switcher script detected")
		return
	_add_session_switcher(root)


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
