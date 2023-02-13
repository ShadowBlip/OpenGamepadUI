@icon("res://assets/icons/navigation.svg")
extends Node

const InputManager := preload("res://core/global/input_manager.tres")


func _ready() -> void:
	InputManager.init()


func _input(event: InputEvent) -> void:
	if not InputManager.input(event):
		return
	get_viewport().set_input_as_handled()


func _exit_tree() -> void:
	InputManager.exit()
