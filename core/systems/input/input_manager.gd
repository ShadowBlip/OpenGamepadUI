extends Node
class_name InputManager

@export_node_path(LaunchManager) var launch_manager = NodePath("../LaunchManager")
@export_node_path(StateManager) var state_manager = NodePath("../StateManager")
@onready var launch_mgr: LaunchManager = get_node(launch_manager)
@onready var state_mgr: StateManager = get_node(state_manager)

func _ready() -> void:
	state_mgr.state_changed.connect(_on_state_changed)

# Set focus will use Gamescope to focus OpenGamepadUI
func set_focus(focused: bool) -> void:
	# Sets ourselves to the input focus
	var window_id = launch_mgr.overlay_window_id
	if focused:
		print_debug("Focusing overlay")
		Gamescope.set_xprop(window_id, "STEAM_INPUT_FOCUS", "32c", "1")
		return
	print_debug("Un-focusing overlay")
	Gamescope.set_xprop(window_id, "STEAM_INPUT_FOCUS", "32c", "0")


func set_overlay(enable: bool) -> void:
	var window_id = launch_mgr.overlay_window_id
	var overlay_enabled = "0"
	if enable:
		overlay_enabled = "1"
	Gamescope.set_xprop(window_id, "STEAM_OVERLAY", "32c", overlay_enabled)


func _on_state_changed(from: int, to: int):
	var from_str = StateManager.StateMap[from]
	var to_str = StateManager.StateMap[from]
	print_debug("Switched from state {0} to {1}".format([from_str, to_str]))
	if to == StateManager.State.IN_GAME:
		set_focus(false)
	else:
		set_focus(true)

	# Setting overlay should only happen when we are overlaying UI over a running
	# game.
	if state_mgr.has_state(StateManager.State.IN_GAME):
		set_overlay(true)
		#if to in [StateManager.State.IN_GAME_MENU, StateManager.State.MAIN_MENU]:
		#	set_overlay(true)
		#else:
		#	set_overlay(false)
	else:
		set_overlay(false)


func _input(event: InputEvent) -> void:
	var state = state_mgr.current_state()
	
	# Handle "guide" button presses
	if event.is_action_pressed("ogui_guide"):
		# Handle cases where a game is running
		if state_mgr.has_state(StateManager.State.IN_GAME):
			# If we're in game, pull up the in-game menu
			if state == StateManager.State.IN_GAME:
				state_mgr.push_state(StateManager.State.IN_GAME_MENU)
			# If we're not in game, go back
			else:
				state_mgr.replace_state(StateManager.State.IN_GAME)
				
		# Handle opening the main menu outside of a running game
		elif state == StateManager.State.MAIN_MENU:
			print("Removing mm state")
			state_mgr.remove_state(StateManager.State.MAIN_MENU)
		elif state != StateManager.State.MAIN_MENU:
			print("Adding mm state")
			state_mgr.push_state(StateManager.State.MAIN_MENU)
	
	#if state != StateManager.State.IN_GAME:
	#	if event.is_action_pressed("ui_cancel"):
	#		get_tree().quit()
