extends Control

var settings_manager := load("res://core/global/settings_manager.tres") as SettingsManager
var first_boot_state_machine := load("res://assets/state/state_machines/first_boot_state_machine.tres") as StateMachine
var first_boot_state := load("res://assets/state/states/first_boot_menu.tres") as State

@onready var finished_menu := $%FinishMenu


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if not settings_manager.get_value("general", "first_boot", true):
		finish()
		return
	finished_menu.finished.connect(finish)
	var on_refresh := func():
		first_boot_state_machine.refresh()
	first_boot_state.refreshed.connect(on_refresh)


## Removes the menu from the scene when all first-boot menus are done or user
## has already ran first boot steps.
func finish() -> void:
	queue_free()
