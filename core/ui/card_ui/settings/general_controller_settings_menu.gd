extends Control

var settings_manager := preload("res://core/global/settings_manager.tres") as SettingsManager

@onready var sdl_hidapi_toggle := $%SDLHIDAPIToggle as Toggle

# Called when the node enters the scene tree for the first time.
func _ready():
	sdl_hidapi_toggle.button_pressed = settings_manager.get_value("general.controller", "sdl_hidapi_enabled", false)
	sdl_hidapi_toggle.toggled.connect(_on_sdl_hidapi_toggled)


## Called when the SDLHIDAPIToggle is toggled.
func _on_sdl_hidapi_toggled(pressed: bool) -> void:
	settings_manager.set_value("general.controller", "sdl_hidapi_enabled", pressed)
	pass
