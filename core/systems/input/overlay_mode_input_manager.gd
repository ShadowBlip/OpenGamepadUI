@icon("res://assets/icons/navigation.svg")
extends Node

var gamepad_manager := load("res://core/systems/input/gamepad_manager.tres") as GamepadManager
var audio_manager := load("res://core/global/audio_manager.tres") as AudioManager

var state_machine: StateMachine = preload("res://assets/state/state_machines/global_state_machine.tres")
var in_game_menu_state := preload("res://assets/state/states/in_game_menu.tres") as State
var main_menu_state := preload("res://assets/state/states/main_menu.tres") as State
var quick_bar_menu_state := preload("res://assets/state/states/quick_bar_menu.tres") as State
var osk_state := preload("res://assets/state/states/osk.tres") as State

var process_input_during: Array[State] = []

var handle_back: bool = false

## Will show logger events with the prefix InputManager(Overlay Mode)
var logger := Log.get_logger("InputManager(Overlay Mode)", Log.LEVEL.INFO)

func _ready() -> void:
	state_machine.state_changed.connect(_on_state_changed)
	process_input_during = [load("res://assets/state/states/quick_bar_menu.tres") as State]
	logger.debug("Input manager ready.")


# Only process input when the given states are active
func _on_state_changed(_from: State, to: State) -> void:
	if to in process_input_during:
		logger.debug("Start handle Back")
		handle_back = true
		return
	logger.debug("Stop handle back.")
	handle_back = false


func _input(event: InputEvent) -> void:

	var valid_events: Array = [
		event.is_action("ogui_qb"),
		event.is_action("ogui_east"),
		event.is_action("ogui_volume_down"),
		event.is_action("ogui_volume_up"),
		event.is_action("ogui_volume_mute"),
		]
	if not true in valid_events:
		return

	logger.debug("Incoming event: " + str(event))
	if event.is_action("ogui_qb"):
		_on_quick_bar_open(event)
		get_viewport().set_input_as_handled()
		return

	# Audio events
	if event.is_action("ogui_volume_down") or event.is_action("ogui_volume_up") or event.is_action("ogui_volume_mute"):
		_audio_input(event)
		return

	if not handle_back:
		return

	if not event.is_pressed():
		return

	logger.debug("Pop state")
	# Pop the state machine stack to go back
	state_machine.pop_state()
	get_viewport().set_input_as_handled()


## Handle quick bar menu events to open the quick bar menu
func _on_quick_bar_open(event: InputEvent) -> void:
	# Only act on press events
	if not event.is_pressed():
		return

	var state := state_machine.current_state()
	if state == quick_bar_menu_state:
		state_machine.pop_state()
	elif state in [main_menu_state, in_game_menu_state, osk_state]:
		state_machine.replace_state(quick_bar_menu_state)
	else:
		state_machine.push_state(quick_bar_menu_state)


func _audio_input(event: InputEvent) -> void:
	# Only act on press events
	if not event.is_pressed():
		return
	
	if event.is_action("ogui_volume_mute"):
		logger.debug("Mute!")
		audio_manager.call_deferred("toggle_mute")
		get_viewport().set_input_as_handled()
		return
	if event.is_action("ogui_volume_down"):
		logger.debug("Volume Down!")
		audio_manager.call_deferred("set_volume", -0.06, audio_manager.VOLUME.RELATIVE)
		get_viewport().set_input_as_handled()
		return
	if event.is_action("ogui_volume_up"):
		logger.debug("Volume Up!")
		audio_manager.call_deferred("set_volume", 0.06, audio_manager.VOLUME.RELATIVE)
		get_viewport().set_input_as_handled()
		return
