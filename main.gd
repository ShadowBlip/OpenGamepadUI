extends Control
class_name Main

var DISPLAY: String = OS.get_environment("DISPLAY")
var PID: int = OS.get_process_id()
var overlay_display = DISPLAY
var overlay_window_id = Gamescope.get_window_id(DISPLAY, PID)
var logger = Log.get_logger("Main", Log.LEVEL.DEBUG)

func _init() -> void:
	# Tell gamescope that we're an overlay
	if overlay_window_id < 0:
		logger.error("Unable to detect Window ID. Overlay is not going to work!")
	logger.debug("Found primary X display: " + DISPLAY)
	logger.debug("Found primary window id: {0}".format([overlay_window_id]))
	_setup(overlay_window_id)


# Called when the node enters the scene tree for the first time.
# gamescope --xwayland-count 2 -- build/opengamepad-ui.x86_64
func _ready() -> void:
	# Set bg to transparent
	get_tree().get_root().transparent_bg = true
	
	logger.debug("ID: {0}".format([Gamescope.get_window_id(DISPLAY, PID)]))
	# Subscribe to state changes
	var state_manager: StateManager = $StateManager
	state_manager.state_changed.connect(_on_state_changed)


# Handle state changes
func _on_state_changed(from: int, to: int, _data: Dictionary):
	# Hide all menus when in-game
	if to == StateManager.State.IN_GAME:
		for child in $UIContainer.get_children():
			child.visible = false
		return
	
	# Display all menus?
	for child in $UIContainer.get_children():
		child.visible = true
	return


# Lets us run as an overlay in gamescope
func _setup(window_id: int) -> void:
	# Pretend to be Steam
	# Gamescope is hard-coded to look for appId 769
	if Gamescope.set_main_app(DISPLAY, window_id) != OK:
		logger.error("Unable to set STEAM_GAME atom!")
	# Sets ourselves to the input focus
	if Gamescope.set_input_focus(DISPLAY, window_id, 1) != OK:
		logger.error("Unable to set STEAM_INPUT_FOCUS atom!")
