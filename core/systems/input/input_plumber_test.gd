extends Node2D

var input_plumber := load("res://core/systems/input/input_plumber.tres") as InputPlumber


# Called when the node enters the scene tree for the first time.
func _ready():
	for compo in input_plumber.composite_devices:
		print(compo.dbus_targets)
		for dt in compo.dbus_targets:
			dt.input_event.connect(_on_input_event)

	input_plumber.composite_device_added.connect(_on_dev_add)
	input_plumber.composite_device_removed.connect(_on_dev_rm)
	input_plumber.set_intercept_mode(InputPlumber.INTERCEPT_MODE.ALL)
	get_tree().root.mode = Window.MODE_MINIMIZED


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _on_input_event(event: String, value: float) -> void:
	print("Got input event " + event + " with value " + str(value))
	if event == "ui_guide":
		var pressed = value == 1.0
		for device in input_plumber.composite_devices:
			device.intercept_mode = 0
			device.send_event("Gamepad:Button:Guide", pressed)
			device.intercept_mode = InputPlumber.INTERCEPT_MODE.ALL as int

	if event == "ui_accept":
		for device in input_plumber.composite_devices:
			var intercept_mode = device.intercept_mode
			device.intercept_mode = 0
			device.send_button_chord(["Gamepad:Button:Guide", "Gamepad:Button:South"])
			device.intercept_mode = InputPlumber.INTERCEPT_MODE.ALL  as int


func _on_dev_add() -> void:
	print("Newbie doobie")

func _on_dev_rm() -> void:
	print("bubye")
