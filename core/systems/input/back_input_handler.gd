extends Node

var in_game_state := preload("res://assets/state/states/in_game.tres") as State
var main_menu_state := preload("res://assets/state/states/main_menu.tres") as State

@export var state_machine: StateMachine = preload(
	"res://assets/state/state_machines/global_state_machine.tres"
)
@export var process_input_during: Array[State] = []


func _ready() -> void:
	set_process_unhandled_input(false)
	state_machine.state_changed.connect(_on_state_changed)


# Only process input when the given states are active
func _on_state_changed(_from: State, to: State) -> void:
	if to in process_input_during:
		set_process_unhandled_input(true)
		return
	set_process_unhandled_input(false)


# _gui_input events don't propagate to parents :(
# https://github.com/godotengine/godot/issues/19402
# https://docs.godotengine.org/en/latest/tutorials/inputs/inputevent.html#how-does-it-work
func _unhandled_input(event: InputEvent) -> void:
	# Only handle back button pressed and when the guide button is not held
	if not event.is_action_pressed("ogui_east") or Input.is_action_pressed("ogui_guide"):
		return

	# Stop the event from propagating
	get_viewport().set_input_as_handled()

	# Pop the state machine stack to go back
	if state_machine.stack_length() > 1:
		state_machine.pop_state()
		return
