@icon("res://assets/icons/eye.svg")
extends Node
class_name VisibilityManager

# State machine to use
@export var state_machine: StateMachine = preload(
	"res://assets/state/state_machines/global_state_machine.tres"
)
@export var state: State
@export var visible_during: Array[Resource] = []

var logger := Log.get_logger("VisibilityManager")
@onready var _parent := get_parent() as CanvasItem


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	state_machine.state_changed.connect(_on_state_changed)
	visible_during.push_front(state)


func _on_state_changed(_from: State, to: State) -> void:
	if state_machine.has_state(state) and to in visible_during:
		_transition(true)
		return
	_transition(false)


func _transition(visibility: bool) -> void:
	# Set our z-index based on where we are in the state stack
	_parent.z_index = state_machine.stack().find(state)

	# If the parent doesn't have any transitions, flip visibility
	if not _parent.has_node("TransitionContainer"):
		_parent.visible = visibility
		return

	# Use transitions if they exist
	var transition := _parent.get_node("TransitionContainer") as TransitionContainer
	if visibility:
		transition.enter()
		return
	transition.exit()
