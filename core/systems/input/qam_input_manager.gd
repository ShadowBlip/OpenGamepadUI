@icon("res://assets/icons/navigation.svg")
extends Node

const InputManager := preload("res://core/global/input_manager.tres")

@onready var state_machine: StateMachine = preload("res://assets/state/state_machines/global_state_machine.tres")

var process_input_during: Array[State] = []

var handle_back: bool = false

func _ready() -> void:
	InputManager.init()
	state_machine.state_changed.connect(_on_state_changed)
	process_input_during = [load("res://assets/state/states/quick_access_menu.tres") as State]
	print("process: ", process_input_during)


# Only process input when the given states are active
func _on_state_changed(_from: State, to: State) -> void:
	print("We just changed to ", to.name)
	if to in process_input_during:
		print("we got the B")
		handle_back = true
		return
	handle_back = false

func _input(event: InputEvent) -> void:
	print(event)
	var valid_events: Array = [event.is_action_pressed("ogui_qam"), event.is_action_pressed("ogui_east")]
	if not true in valid_events:
		print("No event to process")
		return
	
	if event.is_action_pressed("ogui_qam"):
		InputManager._qam_input(event)
		get_viewport().set_input_as_handled()
		return
	
	if not handle_back:
		print("we got a B, but we can't handle the truth")
		return
	
	print("Heading back")
	# Pop the state machine stack to go back
	state_machine.pop_state()
	get_viewport().set_input_as_handled()
	
func _exit_tree() -> void:
	InputManager.exit()
