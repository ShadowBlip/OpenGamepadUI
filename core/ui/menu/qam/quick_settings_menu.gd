extends Control

var Gamescope := preload("res://core/global/gamescope.tres") as Gamescope
var AudioManager := preload("res://core/global/audio_manager.tres") as AudioManager
var DisplayManager := preload("res://core/global/display_manager.tres") as DisplayManager

var backlights := DisplayManager.get_backlight_paths()

var logger := Log.get_logger("QuickSettings", Log.LEVEL.INFO)

@onready var output_volume := $%VolumeSlider
@onready var brightness_slider := $%BrightnessSlider
@onready var saturation_slider := $%SaturationSlider
@onready var focus_group := $%FocusGroup


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Set the volume sliders
	var current_volume := AudioManager.get_current_volume()
	output_volume.value = current_volume * 100
	output_volume.value_changed.connect(_on_output_volume_slider_changed)
	AudioManager.volume_changed.connect(_on_output_volume_changed)

	# Setup the saturation slider
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
	var percent: float = value * 0.01
	AudioManager.set_volume(percent)


func _on_brightness_slider_changed(value: float) -> void:
	var percent: float = value * 0.01
	DisplayManager.set_brightness(percent)


func _on_saturation_changed(value: float) -> void:
	var code := Gamescope.set_saturation(value / 100.0)
	if code != OK:
		logger.warn("Unable to set saturation. Code: " + str(code))
