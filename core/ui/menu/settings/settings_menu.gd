extends Control

enum STATES {
	NONE,
	GENERAL,
	MANAGE_PLUGINS,
	PLUGIN_STORE,
	POWER,
}

var state_machine := preload("res://assets/state/state_machines/global_state_machine.tres") as StateMachine
var settings_state := preload("res://assets/state/states/settings.tres") as State
var in_game_state := preload("res://assets/state/states/in_game.tres") as State

@onready var local_state_manager := $StateManager
@onready var general_button := $MainContainer/MenuMarginContainer/VBoxContainer/GeneralButton
@onready var button_container := $MainContainer/MenuMarginContainer/VBoxContainer

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	settings_state.state_entered.connect(_on_settings_state_entered)
	settings_state.state_exited.connect(_on_settings_state_exited)
	

func _on_settings_state_entered(_from: State) -> void:
	visible = true
	general_button.grab_focus.call_deferred()


func _on_settings_state_exited(to: State) -> void:
	visible = state_machine.has_state(settings_state)
	if to == in_game_state:
		state_machine.remove_state(settings_state)
		

func _on_local_state_change(from: int, to: int, data: Dictionary) -> void:
	pass
