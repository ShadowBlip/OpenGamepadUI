extends Control

const SettingsManager := preload("res://core/global/settings_manager.tres")

@onready var finished_menu := $%FinishMenu


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if not SettingsManager.get_value("general", "first_boot", true):
		finish()
		return
	finished_menu.finished.connect(finish)


## Removes the menu from the scene when all first-boot menus are done or user
## has already ran first boot steps.
func finish() -> void:
	queue_free()
