extends Control

var state_machine := (
	preload("res://assets/state/state_machines/global_state_machine.tres") as StateMachine
)
var settings_state := preload("res://assets/state/states/settings.tres") as State

@onready var setting_buttons_container: VBoxContainer = $%SettingButtonsContainer
@onready var focus_manager := $%FocusManager as FocusManager


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	settings_state.state_entered.connect(_on_state_entered)


func _on_state_entered(_from: State) -> void:
	focus_manager.current_focus.grab_focus.call_deferred()
