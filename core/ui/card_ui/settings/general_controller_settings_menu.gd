extends Control

var input_plumber := load("res://core/systems/input/input_plumber.tres") as InputPlumberInstance
var state_machine := load("res://assets/state/state_machines/menu_state_machine.tres") as StateMachine
var state := load("res://assets/state/states/gamepad_settings.tres") as State

@onready var gamepad_button := $%GamepadSettingsButton as CardButton

# Called when the node enters the scene tree for the first time.
func _ready():
	gamepad_button.gui_input.connect(_on_button_input)


# If the user presses the gamepad settings button with a non-gamepad input method,
# open the settings for the first detected controller.
# TODO: Add a controller select pop-up to select a gamepad to configure
func _on_button_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if (event as InputEventMouseButton).button_index != MOUSE_BUTTON_LEFT:
			return
		if (event as InputEventMouseButton).pressed:
			return
		_open_menu_default_gamepad()
		return

	if event is InputEventKey:
		if !event.is_action("ui_accept"):
			return
		if event.pressed:
			return
		_open_menu_default_gamepad()


# Push the gamepad config menu for the first detected controller.
func _open_menu_default_gamepad() -> void:
	state.set_meta("dbus_path", "")
	var devices := input_plumber.get_composite_devices()
	if !devices.is_empty():
		var device := devices[0]
		state.set_meta("dbus_path", device.dbus_path)

	state_machine.push_state(state)
