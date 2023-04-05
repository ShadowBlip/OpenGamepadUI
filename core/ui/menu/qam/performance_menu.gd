extends Control

var command_timer: Timer

var logger := Log.get_logger("PerformanceMenu", Log.LEVEL.INFO)

@onready var mangoapp_slider := $%MangoAppSlider


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	command_timer = Timer.new()
	command_timer.set_autostart(false)
	command_timer.set_one_shot(true)
	add_child(command_timer)

	mangoapp_slider.value_changed.connect(_on_mangoapp_changed)


# Set the mangoapp config on slider change
func _on_mangoapp_changed(value: float) -> void:
	_setup_callback_func(_do_mangoapp_change)


func _do_mangoapp_change() -> void:
	var value = mangoapp_slider.value
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
