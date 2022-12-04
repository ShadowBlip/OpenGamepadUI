extends Control
class_name Main

var DISPLAY: String = OS.get_environment("DISPLAY")
var PID: int = OS.get_process_id()
var overlay_display = DISPLAY
var overlay_window_id = Gamescope.get_window_id(DISPLAY, PID)

func _init() -> void:
	# Tell gamescope that we're an overlay
	_setup(overlay_window_id)


# Called when the node enters the scene tree for the first time.
# gamescope --xwayland-count 2 -- build/opengamepad-ui.x86_64
func _ready() -> void:
	# Set bg to transparent
	get_tree().get_root().transparent_bg = true
	
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
	Gamescope.set_xprop(DISPLAY, window_id, "STEAM_GAME", 769)
	# Sets ourselves to the input focus
	Gamescope.set_xprop(DISPLAY, window_id, "STEAM_INPUT_FOCUS", 1)
