extends Control

var Gamescope := preload("res://core/global/gamescope.tres") as Gamescope
var AudioManager := preload("res://core/global/audio_manager.tres") as AudioManager
var DisplayManager := preload("res://core/global/display_manager.tres") as DisplayManager

var backlights := DisplayManager.get_backlight_paths()

@onready var output_volume := $%VolumeSlider
@onready var brightness_slider := $%BrightnessSlider
@onready var saturation_slider := $%SaturationSlider


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var current_volume := AudioManager.get_current_volume()
	output_volume.value = current_volume * 100
	output_volume.value_changed.connect(_on_output_volume_slider_changed)
	AudioManager.volume_changed.connect(_on_output_volume_changed)

	saturation_slider.value = 100
	saturation_slider.value_changed.connect(_on_saturation_changed)

	# Setup the brightness slider
	if not DisplayManager.supports_brightness():
		brightness_slider.visible = false
		return
	brightness_slider.value = DisplayManager.get_brightness(backlights[0]) * 100
	brightness_slider.value_changed.connect(_on_brightness_slider_changed)


func _on_output_volume_changed(value: float) -> void:
	output_volume.value = value * 100


func _on_output_volume_slider_changed(value: float) -> void:
	var percent := value * 0.01
	AudioManager.set_volume(percent)


func _on_brightness_slider_changed(value: float) -> void:
	var percent := value * 0.01
	DisplayManager.set_brightness(percent)


func _on_saturation_changed(value: float) -> void:
	Gamescope.set_saturation(value / 100.0)
