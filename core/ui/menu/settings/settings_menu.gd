extends Control

var settings_state := preload("res://assets/state/states/settings.tres") as State

@onready var setting_buttons_container: VBoxContainer = %SettingButtonsContainer


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	settings_state.state_entered.connect(_on_state_entered)
	

func _on_state_entered(_from: State) -> void:
	for child in setting_buttons_container.get_children():
		if not child is Button:
			continue
		child.grab_focus.call_deferred()
		break
