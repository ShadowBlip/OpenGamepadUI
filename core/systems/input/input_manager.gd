@icon("res://assets/icons/navigation.svg")
extends Node
class_name InputManager

var state_machine := preload("res://assets/state/state_machines/global_state_machine.tres") as StateMachine
var in_game_state := preload("res://assets/state/states/in_game.tres") as State
var qam_state := preload("res://assets/state/states/quick_access_menu.tres") as State
var main_menu_state := preload("res://assets/state/states/main_menu.tres") as State
var in_game_menu_state := preload("res://assets/state/states/in_game_menu.tres") as State
var display = OS.get_environment("DISPLAY")
var logger := Log.get_logger("InputManager")
var guide_action := false

@onready var main: Main = get_node("..")
@onready var launch_manager: LaunchManager = get_node("../LaunchManager")

func _ready() -> void:
	in_game_state.state_entered.connect(_on_game_state_entered)
	in_game_state.state_exited.connect(_on_game_state_exited)

func _on_game_state_entered(_from: State) -> void:
	set_focus(false)


func _on_game_state_exited(_to: State) -> void:
	set_focus(true)


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


func _input(event: InputEvent) -> void:
	var state := state_machine.current_state()
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
			# TODO: Just send the "ogui_qam" event
			if state == qam_state:
				state_machine.pop_state()
			elif state in [main_menu_state, in_game_menu_state]: #, osk_state:
				state_machine.replace_state(qam_state)
			else:
				state_machine.push_state(qam_state)

	if Input.is_action_just_released("ogui_qam"):
		if state == qam_state:
			state_machine.pop_state()
		elif state in [main_menu_state, in_game_menu_state]: #, osk_state:
			state_machine.replace_state(qam_state)
		else:
			state_machine.push_state(qam_state)

	# Handle "guide" button presses
	if event.is_action_released("ogui_guide"):
		if not guide_action:
			return
		
		guide_action = false
		
		var menu_state := main_menu_state
		# Handle cases where a game is running
		if state_machine.has_state(in_game_state):
			menu_state = in_game_menu_state

		if state == menu_state:
			state_machine.pop_state()
		elif state in [qam_state]: #osk_state:
			state_machine.replace_state(menu_state)
		else:
			state_machine.push_state(menu_state)

	# Handle back button presses
	if event.is_action_pressed("ogui_east") and state_machine.stack_length() > 1:
		if not guide_action:
			state_machine.pop_state()
