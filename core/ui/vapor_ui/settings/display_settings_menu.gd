extends Control

var SettingsManager := load("res://core/global/settings_manager.tres") as SettingsManager
@onready var scale_slider := $%ScaleSlider


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var display_scale := SettingsManager.get_value("display", "scale", 1.0) as float
	scale_slider.value = display_scale
	get_window().content_scale_factor = display_scale
	scale_slider.value_changed.connect(_on_scale_changed)


func _on_scale_changed(value: float) -> void:
	get_window().content_scale_factor = value
	SettingsManager.set_value("display", "scale", value)
