extends Control

var gamescope := load("res://core/global/gamescope.tres") as Gamescope
var logger := Log.get_logger("PerformanceMenu", Log.LEVEL.INFO)

@onready var mangoapp_slider := $%MangoAppSlider
@onready var fps_slider := $%FramerateLimitSlider
@onready var fps_timer := $%FramerateChangeTimer as Timer


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	mangoapp_slider.value_changed.connect(_on_mangoapp_changed)
	fps_slider.value_changed.connect(_on_fps_limit_changed)
	fps_timer.timeout.connect(_on_fps_limit_timer_timeout)


# Set the mangoapp config on slider change
func _on_mangoapp_changed(value: float) -> void:
	if value == 0:
		MangoApp.set_config(MangoApp.CONFIG_NONE)
		return
	if value == 1:
		MangoApp.set_config(MangoApp.CONFIG_FPS)
		return
	if value == 2:
		MangoApp.set_config(MangoApp.CONFIG_MIN)
		return
	if value == 3:
		MangoApp.set_config(MangoApp.CONFIG_DEFAULT)
		return
	if value >= 4:
		MangoApp.set_config(MangoApp.CONFIG_INSANE)
		return


# Whenever the FPS slider is changed, start a small timer to limit the number
# of changes
func _on_fps_limit_changed(_value: float) -> void:
	fps_timer.start()


# Update the gamescope FPS limit
func _on_fps_limit_timer_timeout() -> void:
	gamescope.set_fps_limit(fps_slider.value)
