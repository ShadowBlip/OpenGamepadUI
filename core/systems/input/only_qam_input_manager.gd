@icon("res://assets/icons/navigation.svg")
extends Node

const InputManager := preload("res://core/global/input_manager.tres")

@onready var state_machine: StateMachine = preload("res://assets/state/state_machines/global_state_machine.tres")

var process_input_during: Array[State] = []

var handle_back: bool = false

## Will show logger events with the prefix OnlyQAMInputManager
var logger := Log.get_logger("OnlyQAMInputManager", Log.LEVEL.INFO)

func _ready() -> void:
	InputManager.init()
	state_machine.state_changed.connect(_on_state_changed)
	process_input_during = [load("res://assets/state/states/quick_access_menu.tres") as State]


# Only process input when the given states are active
func _on_state_changed(_from: State, to: State) -> void:
	if to in process_input_during:
		logger.debug("Handle Back")
		handle_back = true
		return
	logger.debug("Don't handle back.")
	handle_back = false


func _input(event: InputEvent) -> void:
	var valid_events: Array = [event.is_action_pressed("ogui_qam"), event.is_action_pressed("ogui_east")]
	if not true in valid_events:
		return

	if event.is_action_pressed("ogui_qam"):
		InputManager._qam_input(event)
		get_viewport().set_input_as_handled()
		return

	if not handle_back:
		return
	logger.debug("Pop state")
	# Pop the state machine stack to go back
	state_machine.pop_state()
	get_viewport().set_input_as_handled()


func _exit_tree() -> void:
	InputManager.exit()
