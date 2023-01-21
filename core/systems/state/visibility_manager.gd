@icon("res://assets/icons/eye.svg")
extends Node
class_name VisibilityManager

# State machine to use
@export var state_machine: Resource = preload("res://assets/state/state_machines/global_state_machine.tres")
@export var state: Resource
@export var visible_during: Array[Resource] = []

@onready var _parent := get_parent()

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	state_machine.state_changed.connect(_on_state_changed)
	visible_during.push_front(state)


func _on_state_changed(_from: State, to: State) -> void:
	if state_machine.has_state(state) and to in visible_during:
		_parent.visible = true
		return
	_parent.visible = false
