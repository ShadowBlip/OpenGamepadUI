extends MarginContainer

signal finished

const SettingsManager := preload("res://core/global/settings_manager.tres")

@onready var next_button := $%NextButton as CardButton


# When the user presses finish, update the settings so first-boot doesn't run
# again.
func _ready() -> void:
	var on_finished := func():
		SettingsManager.set_value("general", "first_boot", false)
		finished.emit()
	next_button.button_up.connect(on_finished)
