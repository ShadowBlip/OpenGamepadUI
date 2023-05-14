@icon("res://assets/editor-icons/arrow-back.svg")
extends Node
class_name BackInputHandler

## The state machine to use to update when back input is pressed
@export var state_machine: StateMachine = preload(
	"res://assets/state/state_machines/global_state_machine.tres"
)
## Pop the state machine when back input is pressed during any of these
## states
@export var process_input_during: Array[State] = []
## Minimum number of states in the state machine stack. [BackInputHandler]
## will not pop the state machine stack beyond this number.
@export var minimum_states := 1

## Will show logger events with the prefix BackInputHandler
var logger := Log.get_logger("BackInputHandler", Log.LEVEL.INFO)

func _ready() -> void:
	set_process_input(false)
	state_machine.state_changed.connect(_on_state_changed)


# Only process input when the given states are active
func _on_state_changed(_from: State, to: State) -> void:
	if to in process_input_during:
		set_process_input(true)
		return
	set_process_input(false)


# _gui_input events don't propagate to parents :(
# https://github.com/godotengine/godot/issues/19402
# https://docs.godotengine.org/en/latest/tutorials/inputs/inputevent.html#how-does-it-work
func _input(event: InputEvent) -> void:
	# Only handle back button pressed and when the guide button is not held
	if not event.is_action_pressed("ogui_east") or Input.is_action_pressed("ogui_guide"):
		return
	logger.debug(str(event))

	# Stop the event from propagating
	get_viewport().set_input_as_handled()

	# Pop the state machine stack to go back
	if state_machine.stack_length() > minimum_states:
		state_machine.pop_state()
		return
