@icon("res://assets/icons/eye.svg")
extends Node
class_name VisibilityManager

# State machine to use
@export var state_machine: Resource = preload("res://assets/state/state_machines/global_state_machine.tres")
@export var state: Resource
@export var visible_during: Array[Resource] = []

var logger := Log.get_logger("VisibilityManager")
@onready var _parent := get_parent()

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
	if not _parent.has_node("TransitionContainer"):
		_parent.visible = visibility
		return
	
	# Use transitions if they exist
	var transition := _parent.get_node("TransitionContainer") as TransitionContainer
	if visibility:
		transition.enter()
		return
	transition.exit()
