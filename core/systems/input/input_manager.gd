extends Node
class_name InputManager
@icon("res://assets/icons/navigation.svg")

@onready var main: Main = get_node("..")
@onready var launch_manager: LaunchManager = get_node("../LaunchManager")
@onready var state_manager: StateManager = get_node("../StateManager")

var display = OS.get_environment("DISPLAY")
var logger := Log.get_logger("InputManager")
var guide_action := false

func _ready() -> void:
	state_manager.state_changed.connect(_on_state_changed)


# Set focus will use Gamescope to focus OpenGamepadUI
func set_focus(focused: bool) -> void:
	# Sets ourselves to the input focus
	var window_id = main.overlay_window_id
	if focused:
		logger.debug("Focusing overlay")
		Gamescope.set_input_focus(display, window_id, 1)
		return
	logger.debug("Un-focusing overlay")
	Gamescope.set_input_focus(display, window_id, 0)


# Set ourselves to focused in any state other than IN_GAME
func _on_state_changed(from: int, to: int, _data: Dictionary):
	if to == StateManager.State.IN_GAME:
		Gamescope.set_blur_mode(display, Gamescope.BLUR_MODE.OFF)
		set_focus(false)
		return
	set_focus(true)
	if state_manager.has_state(StateManager.State.IN_GAME):
		Gamescope.set_blur_mode(display, Gamescope.BLUR_MODE.ALWAYS)
	else:
		Gamescope.set_blur_mode(display, Gamescope.BLUR_MODE.OFF)


func _input(event: InputEvent) -> void:
	var state = state_manager.current_state()
	if event.is_action_pressed("ogui_guide"):
		if not guide_action:
			guide_action = true
	# Handle OSK Button combo
	if Input.is_action_pressed("ogui_north"):
		if guide_action:
			guide_action = false
			return
#			if state == StateManager.State.OSK_STATE:
#				state_manager.pop_state()
#			elif state in [StateManager.State.MAIN_MENU, StateManager.State.IN_GAME_MENU, SateManager.State.QUICK_ACCESS_MENU]:
#				state_manager.replace_state(StateManager.State.OSK_STATE)
#			else:
#				state_manager.push_state(StateManager.State.OSK_STATE)

	# Handle "QAM" button combo
	if Input.is_action_pressed("ogui_south"):
		if guide_action:
			guide_action = false
			if state == StateManager.State.QUICK_ACCESS_MENU:
				state_manager.pop_state()
			elif state in [StateManager.State.MAIN_MENU, StateManager.State.IN_GAME_MENU]: #, StateManager.State.OSK_STATE]:
				state_manager.replace_state(StateManager.State.QUICK_ACCESS_MENU)
			else:
				state_manager.push_state(StateManager.State.QUICK_ACCESS_MENU)

	# Handle "guide" button presses
	if event.is_action_released("ogui_guide"):
		if not guide_action:
			return
		
		guide_action = false
		
		var menu_state:= StateManager.State.MAIN_MENU
		# Handle cases where a game is running
		if state_manager.has_state(StateManager.State.IN_GAME):
			menu_state = StateManager.State.IN_GAME_MENU

		if state == menu_state:
			state_manager.pop_state()
		elif state in [StateManager.State.QUICK_ACCESS_MENU]: #StateManager.State.OSK_STATE]:
			state_manager.replace_state(menu_state)
		else:
			state_manager.push_state(menu_state)

	# Handle back button presses
	if event.is_action_pressed("ogui_east") and state_manager.stack_length() > 1:
		if not guide_action:
			state_manager.pop_state()
