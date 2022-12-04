extends Node
class_name InputManager
@icon("res://assets/icons/navigation.svg")

@onready var main: Main = get_node("..")
@onready var launch_manager: LaunchManager = get_node("../LaunchManager")
@onready var state_manager: StateManager = get_node("../StateManager")

var logger := Log.get_logger("InputManager")
var guide_action := false

func _ready() -> void:
	state_manager.state_changed.connect(_on_state_changed)


# Set focus will use Gamescope to focus OpenGamepadUI
func set_focus(focused: bool) -> void:
	# Sets ourselves to the input focus
	var display = OS.get_environment("DISPLAY")
	var window_id = main.overlay_window_id
	if focused:
		logger.debug("Focusing overlay")
		Gamescope.set_xprop(display, window_id, "STEAM_INPUT_FOCUS", 1)
		return
	logger.debug("Un-focusing overlay")
	Gamescope.set_xprop(display, window_id, "STEAM_INPUT_FOCUS", 0)


# Set ourselves to focused in any state other than IN_GAME
func _on_state_changed(from: int, to: int, _data: Dictionary):
	if to == StateManager.State.IN_GAME:
		set_focus(false)
		return
	set_focus(true)


func _input(event: InputEvent) -> void:
	var state = state_manager.current_state()
	
	if event.is_action_pressed("ogui_guide"):
		if not guide_action:
			guide_action = true

	# Handle "QAM" button combo
	if Input.is_action_pressed("ogui_north"):
		if guide_action:
			guide_action = false
			if state == StateManager.State.QUICK_ACCESS_MENU:
				state_manager.pop_state()
			else:
				if not state in [StateManager.State.HOME, StateManager.State.IN_GAME]:
					state_manager.replace_state(StateManager.State.QUICK_ACCESS_MENU)
				else:
					state_manager.push_state(StateManager.State.QUICK_ACCESS_MENU)

	# Handle "guide" button presses
	if event.is_action_released("ogui_guide"):
		if guide_action:
			guide_action = false

			# Handle cases where a game is running
			if state_manager.has_state(StateManager.State.IN_GAME):
				# If we're in game, pull up the in-game menu
				if state == StateManager.State.IN_GAME:
					state_manager.push_state(StateManager.State.IN_GAME_MENU)
				# If we're not in game, go back
				else:
					state_manager.replace_state(StateManager.State.IN_GAME)

			# Handle opening the main menu outside of a running game
			elif state == StateManager.State.MAIN_MENU:
				logger.debug("Removing mm state")
				state_manager.pop_state()
			elif state != StateManager.State.MAIN_MENU:
				logger.debug("Adding mm state")
				if state == StateManager.State.HOME:
					state_manager.push_state(StateManager.State.MAIN_MENU)
				else:
					state_manager.replace_state(StateManager.State.MAIN_MENU)

	# Handle back button presses
	if event.is_action_pressed("ogui_east") and state_manager.stack_length() > 1:
		if not guide_action:
			state_manager.pop_state()
