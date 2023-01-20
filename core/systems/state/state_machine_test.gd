extends Node


func _ready() -> void:
	var state_machine := load("res://assets/state/state_machines/global_state_machine.tres") as StateMachine
	state_machine.state_changed.connect(_on_state_changed)
	

func _on_state_changed(from: StateMachineState, to: StateMachineState) -> void:
	print("State changed!")
	pass
