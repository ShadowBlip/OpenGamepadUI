@icon("res://assets/icons/navigation.svg")
extends Node

var input_manager := load("res://core/global/input_manager.tres") as InputManager
var gamepad_manager := load("res://core/systems/input/gamepad_manager.tres") as GamepadManager
var audio_manager := load("res://core/global/audio_manager.tres") as AudioManager

@onready var state_machine: StateMachine = preload("res://assets/state/state_machines/global_state_machine.tres")

var process_input_during: Array[State] = []

var handle_back: bool = false

## Will show logger events with the prefix OnlyQAMInputManager
var logger := Log.get_logger("OnlyQAMInputManager", Log.LEVEL.INFO)

func _ready() -> void:
	state_machine.state_changed.connect(_on_state_changed)
	process_input_during = [load("res://assets/state/states/quick_access_menu.tres") as State]
	logger.debug("Input manager ready.")


# Only process input when the given states are active
func _on_state_changed(_from: State, to: State) -> void:
	if to in process_input_during:
		logger.debug("Handle Back")
		handle_back = true
		return
	logger.debug("Don't handle back.")
	handle_back = false


func _input(event: InputEvent) -> void:
	var valid_events: Array = [
		event.is_action_pressed("ogui_qam"), 
		event.is_action_pressed("ogui_east"),
		event.is_action("ogui_volume_down"),
		event.is_action("ogui_volume_up"),
		event.is_action("ogui_volume_mute"),
		]
	if not true in valid_events:
		return
	logger.debug("Incoming event: " + str(event))
	if event.is_action_pressed("ogui_qam"):
		input_manager._qam_input(event)
		get_viewport().set_input_as_handled()
		return

	# Audio events
	if event.is_action("ogui_volume_down") or event.is_action("ogui_volume_up") or event.is_action("ogui_volume_mute"):
		_audio_input(event)
		return

	if not handle_back:
		return
	logger.debug("Pop state")
	# Pop the state machine stack to go back
	state_machine.pop_state()
	get_viewport().set_input_as_handled()


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
