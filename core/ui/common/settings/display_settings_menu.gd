extends Control

var settings_manager := load("res://core/global/settings_manager.tres") as SettingsManager
@onready var scale_slider := $%ScaleSlider as ValueSlider
@onready var blur_toggle := $%BlurToggle as Toggle


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var display_scale := settings_manager.get_value("display", "scale", 1.0) as float
	scale_slider.value = display_scale
	get_window().content_scale_factor = display_scale
	scale_slider.value_changed.connect(_on_scale_changed)
	
	var blur_enabled := settings_manager.get_value("display", "enable_overlay_blur", true) as bool
	blur_toggle.button_pressed = blur_enabled
	blur_toggle.toggled.connect(_on_blur_toggled)


func _on_scale_changed(value: float) -> void:
	get_window().content_scale_factor = value
	settings_manager.set_value("display", "scale", value)


func _on_blur_toggled(pressed: bool) -> void:
	settings_manager.set_value("display", "enable_overlay_blur", pressed)
