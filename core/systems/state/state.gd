@icon("res://assets/editor-icons/circle-dot-filled.svg")
extends Resource
class_name State

signal state_entered(from: State)
signal state_exited(to: State)
signal state_removed

@export var name: String
@export var data: Dictionary
