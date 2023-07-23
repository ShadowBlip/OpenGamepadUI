@icon("res://assets/icons/navigation.svg")
extends Node

var input_manager := preload("res://core/global/input_manager.tres") as InputManager
var gamepad_manager := load("res://core/systems/input/gamepad_manager.tres") as GamepadManager


func _input(event: InputEvent) -> void:
	if not input_manager.input(event):
		return
	get_viewport().set_input_as_handled()


func _exit_tree() -> void:
	input_manager.exit()
