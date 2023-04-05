extends Control

var logger := Log.get_logger("PerformanceMenu", Log.LEVEL.INFO)

@onready var mangoapp_slider := $%MangoAppSlider


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	mangoapp_slider.value_changed.connect(_on_mangoapp_changed)


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
