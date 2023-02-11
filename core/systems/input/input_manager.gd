@icon("res://assets/icons/navigation.svg")
extends Node

var InputManager := load("res://core/global/input_manager.tres") as InputManager


func _input(event: InputEvent) -> void:
	if not InputManager.input(event):
		return
	get_viewport().set_input_as_handled()


func _exit_tree() -> void:
	InputManager.exit()
