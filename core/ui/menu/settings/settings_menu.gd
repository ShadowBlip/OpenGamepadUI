extends Control

enum STATES {
	NONE,
	GENERAL,
	MANAGE_PLUGINS,
	PLUGIN_STORE,
	POWER,
}

var settings_state := preload("res://assets/state/states/settings.tres") as State
var in_game_state := preload("res://assets/state/states/in_game.tres") as State

@onready var local_state_manager := $StateManager
@onready var general_button := $MainContainer/MenuMarginContainer/VBoxContainer/GeneralButton
@onready var button_container := $MainContainer/MenuMarginContainer/VBoxContainer

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	settings_state.state_entered.connect(_on_state_entered)
	

func _on_state_entered(_from: State) -> void:
	general_button.grab_focus.call_deferred()


func _on_local_state_change(from: int, to: int, data: Dictionary) -> void:
	pass
