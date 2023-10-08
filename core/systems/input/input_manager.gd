@icon("res://assets/icons/navigation.svg")
extends Node
class_name InputManager

## Manages global input
##
## The InputManager class is responsible for handling global input that should
## happen everywhere in the application, regardless of the current menu. Examples
## include opening up the main or quick bar menus.[br][br]
##
## To include this functionality, add this as a node to the root node in the
## scene tree.

## Reference to the on-screen keyboard instance to open when the OSK action is
## pressed.
const osk := preload("res://core/global/keyboard_instance.tres")

## The audio manager to use to adjust the audio when audio input events happen.
var audio_manager := load("res://core/global/audio_manager.tres") as AudioManager
## State machine to use to switch menu states in response to input events.
var state_machine := (
	preload("res://assets/state/state_machines/global_state_machine.tres") as StateMachine
)
var in_game_menu_state := preload("res://assets/state/states/in_game_menu.tres") as State
var main_menu_state := preload("res://assets/state/states/main_menu.tres") as State
var quick_bar_state := preload("res://assets/state/states/quick_bar_menu.tres") as State
var osk_state := preload("res://assets/state/states/osk.tres") as State
var logger := Log.get_logger("InputManager", Log.LEVEL.INFO)


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	add_to_group("InputManager")


## Queue a release event for the given action
func action_release(action: String, strength: float = 1.0) -> void:
	_send_input(action, false, strength)


## Queue a pressed event for the given action
func action_press(action: String, strength: float = 1.0) -> void:
	_send_input(action, true, strength)


## Sends an input action to the event queue
func _send_input(action: String, pressed: bool, strength: float = 1.0) -> void:
	var input_action := InputEventAction.new()
	input_action.action = action
	input_action.pressed = pressed
	input_action.strength = strength
	logger.debug("Send input: " + str(input_action))
	Input.parse_input_event(input_action)


## Process all unhandled input, possibly preventing the input from propagating further.
## https://docs.godotengine.org/en/latest/tutorials/inputs/inputevent.html#how-does-it-work
func _input(event: InputEvent) -> void:
	# Handle guide button inputs
	if event.is_action("ogui_guide"):
		_guide_input(event)
		get_viewport().set_input_as_handled()
		return

	# Quick Bar Open Events
	if event.is_action("ogui_qb"):
		_on_quick_bar_open(event)
		get_viewport().set_input_as_handled()
		return

	# OSK Events
	if event.is_action("ogui_osk"):
		_osk_input(event)
		get_viewport().set_input_as_handled()
		return

	# Main menu events
	if event.is_action("ogui_menu"):
		_main_menu_input(event)
		get_viewport().set_input_as_handled()
		return

	# Audio events
	if event.is_action("ogui_volume_down") or event.is_action("ogui_volume_up") or event.is_action("ogui_volume_mute"):
		_audio_input(event)
		get_viewport().set_input_as_handled()
		return

	# Handle guide action release events
	if event.is_action_released("ogui_guide_action"):
		if event.is_action_released("ogui_north"):
			action_release("ogui_osk")
			get_viewport().set_input_as_handled()
			return
		if event.is_action_released("ogui_south"):
			action_release("ogui_qb")
			get_viewport().set_input_as_handled()
			return

	# Handle inputs when the guide button is being held
	if Input.is_action_pressed("ogui_guide"):
		# OSK
		if event.is_action_pressed("ogui_north"):
			action_press("ogui_osk")
			action_press("ogui_guide_action")
		# Quick Bar
		if event.is_action_pressed("ogui_south"):
			action_press("ogui_qb")
			action_press("ogui_guide_action")

		# Prevent ALL input from propagating if guide is held!
		get_viewport().set_input_as_handled()
		return


## Handle guide button events and determine whether this is a guide action
## (e.g. guide + A to open the Quick Bar), or if it's just a normal guide button press.
func _guide_input(event: InputEvent) -> void:
	# Only act on release events
	if event.is_pressed():
		return

	# If a guide action combo was pressed and we released the guide button,
	# end the guide action and do nothing else.
	if Input.is_action_pressed("ogui_guide_action"):
		action_release("ogui_guide_action")
		return

	# Emit the main menu action if this was not a guide action
	action_press("ogui_menu")
	action_release("ogui_menu")


## Handle main menu events to open the main menu
func _main_menu_input(event: InputEvent) -> void:
	# Only act on release events
	if event.is_pressed():
		return

	# Open the main menu
	var state := state_machine.current_state()
	var menu_state := main_menu_state

	if state == menu_state:
		state_machine.pop_state()
	elif state in [quick_bar_state, osk_state]:
		state_machine.replace_state(menu_state)
	else:
		state_machine.push_state(menu_state)


## Handle quick bar menu events to open the quick bar menu
func _on_quick_bar_open(event: InputEvent) -> void:
	# Only act on press events
	if not event.is_pressed():
		return

	var state := state_machine.current_state()
	if state == quick_bar_state:
		state_machine.pop_state()
	elif state in [main_menu_state, in_game_menu_state, osk_state]:
		state_machine.replace_state(quick_bar_state)
	else:
		state_machine.push_state(quick_bar_state)


## Handle OSK events for bringing up the on-screen keyboard
func _osk_input(event: InputEvent) -> void:
	# Only act on press events
	if not event.is_pressed():
		return

	var context := KeyboardContext.new()
	context.type = KeyboardContext.TYPE.X11
	osk.open(context)

	var state := state_machine.current_state()
	if state == osk_state:
		state_machine.pop_state()
	elif state in [main_menu_state, in_game_menu_state, quick_bar_state]:
		state_machine.replace_state(osk_state)
	else:
		state_machine.push_state(osk_state)


## Handle audio input events such as mute, volume up, and volume down
func _audio_input(event: InputEvent) -> void:
	# Only act on press events
	if not event.is_pressed():
		return
	
	if event.is_action("ogui_volume_mute"):
		logger.debug("Mute!")
		audio_manager.call_deferred("toggle_mute")
		return
	if event.is_action("ogui_volume_down"):
		logger.debug("Volume Down!")
		audio_manager.call_deferred("set_volume", -0.06, audio_manager.VOLUME.RELATIVE)
		return
	if event.is_action("ogui_volume_up"):
		logger.debug("Volume Up!")
		audio_manager.call_deferred("set_volume", 0.06, audio_manager.VOLUME.RELATIVE)
		return

