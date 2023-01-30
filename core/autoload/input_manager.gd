@icon("res://assets/icons/navigation.svg")
extends Node

var state_machine := (
	preload("res://assets/state/state_machines/global_state_machine.tres") as StateMachine
)
var in_game_state := preload("res://assets/state/states/in_game.tres") as State
var qam_state := preload("res://assets/state/states/quick_access_menu.tres") as State
var main_menu_state := preload("res://assets/state/states/main_menu.tres") as State
var in_game_menu_state := preload("res://assets/state/states/in_game_menu.tres") as State
var PID: int = OS.get_process_id()
var display = OS.get_environment("DISPLAY")
var overlay_window_id = Gamescope.get_window_id(display, PID)
var logger := Log.get_logger("InputManager")
var guide_action := false

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
	var window_id = overlay_window_id
	if focused:
		logger.debug("Focusing overlay")
		Gamescope.set_input_focus(display, window_id, 1)
		return
	logger.debug("Un-focusing overlay")
	Gamescope.set_input_focus(display, window_id, 0)


# https://docs.godotengine.org/en/latest/tutorials/inputs/inputevent.html#how-does-it-work
func _input(event: InputEvent) -> void:
	# Handle guide button inputs
	if event.is_action("ogui_guide"):
		_guide_input(event)
		get_viewport().set_input_as_handled()
		return

	# QAM Events
	if event.is_action("ogui_qam"):
		_qam_input(event)
		get_viewport().set_input_as_handled()
		return

	# OSK Events
	if event.is_action("ogui_osk"):
		_osk_input(event)
		get_viewport().set_input_as_handled()
		return

	# Handle guide action release events
	if event.is_action_released("ogui_guide_action"):
		if event.is_action_released("ogui_north"):
			_action_release("ogui_osk")
			get_viewport().set_input_as_handled()
			return
		if event.is_action_released("ogui_south"):
			_action_release("ogui_qam")
			get_viewport().set_input_as_handled()
			return

	# Handle inputs when the guide button is being held
	if Input.is_action_pressed("ogui_guide"):
		# OSK
		if event.is_action_pressed("ogui_north"):
			_action_press("ogui_osk")
			_action_press("ogui_guide_action")
		# QAM
		if event.is_action_pressed("ogui_south"):
			_action_press("ogui_qam")
			_action_press("ogui_guide_action")

		# Prevent ALL input from propagating if guide is held!
		get_viewport().set_input_as_handled()


func _guide_input(event: InputEvent) -> void:
	# Only act on release events
	if event.is_pressed():
		return

	# If a guide action combo was pressed and we released the guide button,
	# end the guide action and do nothing else.
	if Input.is_action_pressed("ogui_guide_action"):
		_action_release("ogui_guide_action")
		return

	# Open the main menu
	var state := state_machine.current_state()
	var menu_state := main_menu_state

	# Handle cases where a game is running
	if state_machine.has_state(in_game_state):
		menu_state = in_game_menu_state

	if state_machine.stack_length() > 2:
		state_machine.pop_state()
		state = state_machine.current_state()

	if state == menu_state:
		state_machine.pop_state()
	elif state in [qam_state]:  #osk_state:
		state_machine.replace_state(menu_state)
	else:
		state_machine.push_state(menu_state)


func _qam_input(event: InputEvent) -> void:
	# Only act on press events
	if not event.is_pressed():
		return

	var state := state_machine.current_state()
	if state == qam_state:
		state_machine.pop_state()
	elif state in [main_menu_state, in_game_menu_state]:  #, osk_state:
		state_machine.replace_state(qam_state)
	else:
		state_machine.push_state(qam_state)


func _osk_input(_event: InputEvent) -> void:
	pass


func _action_release(action: String, strength: float = 1.0) -> void:
	_send_input(action, false, strength)


func _action_press(action: String, strength: float = 1.0) -> void:
	_send_input(action, true, strength)


# Sends an input action to the event queue
func _send_input(action: String, pressed: bool, strength: float = 1.0) -> void:
	var input_action := InputEventAction.new()
	input_action.action = action
	input_action.pressed = pressed
	input_action.strength = strength
	Input.parse_input_event(input_action)
