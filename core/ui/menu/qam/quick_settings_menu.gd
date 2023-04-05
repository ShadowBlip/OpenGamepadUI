extends Control

var Gamescope := preload("res://core/global/gamescope.tres") as Gamescope
var AudioManager := preload("res://core/global/audio_manager.tres") as AudioManager
var DisplayManager := preload("res://core/global/display_manager.tres") as DisplayManager

var backlights := DisplayManager.get_backlight_paths()
var command_timer: Timer

var logger := Log.get_logger("QuickSettings", Log.LEVEL.INFO)

@onready var output_volume := $%VolumeSlider
@onready var brightness_slider := $%BrightnessSlider
@onready var saturation_slider := $%SaturationSlider


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	command_timer = Timer.new()
	command_timer.set_autostart(false)
	command_timer.set_one_shot(true)
	add_child(command_timer)

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
	_setup_callback_func(_do_output_volume_slider_change)


func _do_output_volume_slider_change() -> void:
	var percent: float = output_volume.value * 0.01
	AudioManager.set_volume(percent)


func _on_brightness_slider_changed(_value: float) -> void:
	_setup_callback_func(_do_brightness_slider_change)


func _do_brightness_slider_change() -> void:
	var percent: float = brightness_slider.value * 0.01
	DisplayManager.set_brightness(percent)


func _on_saturation_changed(_value: float) -> void:
	_setup_callback_func(_do_brightness_slider_change)


func _do_saturation_change() -> void:
	var code := Gamescope.set_saturation(saturation_slider.value / 100.0)
	if code != OK:
		logger.warn("Unable to set saturation. Code: " + str(code))


# Overrides or sets the command_timer.timeout signal connection function and
# (re)starts the timer.
func _setup_callback_func(callable: Callable) -> void:
	logger.debug("Setting callback func")
	_clear_callbacks()
	command_timer.timeout.connect(callable, CONNECT_ONE_SHOT)
	command_timer.start(.5)


# Removes any existing signal connections to command_timer.timeout.
func _clear_callbacks() -> void:
	for connection in command_timer.timeout.get_connections():
		var callable := connection["callable"] as Callable
		command_timer.timeout.disconnect(callable)
