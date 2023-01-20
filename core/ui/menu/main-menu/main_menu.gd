extends Control

var state_machine := preload("res://assets/state/state_machines/global_state_machine.tres") as StateMachine
var main_menu_state := preload("res://assets/state/states/main_menu.tres") as State
var in_game_menu_state := preload("res://assets/state/states/in_game_menu.tres") as State


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	main_menu_state.state_entered.connect(_on_state_entered)
	main_menu_state.state_exited.connect(_on_state_exited)
	in_game_menu_state.state_entered.connect(_on_state_entered)
	in_game_menu_state.state_exited.connect(_on_state_exited)
	
	
func _on_state_entered(_from: State) -> void:
	if state_machine.current_state() == main_menu_state:
		var button: Button = $MarginContainer/VBoxContainer/HomeButton
		button.grab_focus.call_deferred()


func _on_state_exited(_to: State) -> void:
	pass


func _on_power_button_pressed() -> void:
	get_tree().quit()

