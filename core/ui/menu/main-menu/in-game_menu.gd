extends Control

var state_machine := preload("res://assets/state/state_machines/global_state_machine.tres") as StateMachine
var in_game_menu_state := preload("res://assets/state/states/in_game_menu.tres") as State
var in_game_state := preload("res://assets/state/states/in_game.tres") as State

@onready var resume_button := $MarginContainer/VBoxContainer/ResumeButton


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	visible = false
	in_game_menu_state.state_entered.connect(_on_game_menu_entered)
	in_game_state.state_entered.connect(_on_game_state_entered)
	in_game_state.state_removed.connect(_on_game_state_removed)


func _on_game_menu_entered(_from: State) -> void:
	resume_button.grab_focus.call_deferred()


func _on_game_state_entered(_from: State) -> void:
	visible = true
	
	
func _on_game_state_removed() -> void:
	visible = false


func _on_resume_button_button_up() -> void:
	state_machine.replace_state(in_game_state)


func _on_exit_button_button_up() -> void:
	# TODO: Handle this better
	LaunchManager.stop(LaunchManager.running[-1])
