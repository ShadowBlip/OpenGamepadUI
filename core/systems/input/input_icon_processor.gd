@tool
@icon("res://assets/editor-icons/tabler-icons.svg")
extends Node
class_name InputIconProcessor


const DEADZONE := 0.4

var input_plumber := load("res://core/systems/input/input_plumber.tres") as InputPlumberInstance
var icon_manager := load("res://core/systems/input/input_icon_manager.tres") as InputIconManager


## Listen for any input events and update the input type based on the last
## detected input.
func _input(event: InputEvent) -> void:
	var input_type := icon_manager.last_input_type
	var device_name := icon_manager.last_input_device
	match event.get_class():
		"InputEventKey":
			input_type = InputIconManager.InputType.KEYBOARD_MOUSE
		"InputEventJoypadButton", "InputEventAction":
			input_type = InputIconManager.InputType.GAMEPAD
			# If this is an InputPlumber event, use the name from the device
			if event.has_meta("dbus_path") and not event.get_meta("dbus_path", "").is_empty():
				var dbus_path := event.get_meta("dbus_path") as String
				var device := input_plumber.get_composite_device(dbus_path)
				if device:
					device_name = device.name
			# Otherwise, use the detected device name
			else:
				device_name = Input.get_joy_name(event.device)
		"InputEventJoypadMotion":
			if abs(event.axis_value) > DEADZONE:
				input_type = InputIconManager.InputType.GAMEPAD
	var refresh := false
	if input_type != icon_manager.last_input_type:
		icon_manager.set_last_input_type(input_type)
		refresh = true
	if device_name != icon_manager.last_input_device:
		icon_manager.last_input_device = device_name
		refresh = true
	if refresh:
		icon_manager.refresh()
