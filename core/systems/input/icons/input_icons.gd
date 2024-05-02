@tool
extends Node
class_name InputIcons

signal input_type_changed(input_type: InputType)

const DEADZONE := 0.4

enum InputType {
	KEYBOARD_MOUSE,
	GAMEPAD,
}

var last_input_type: InputType = InputType.GAMEPAD
var _custom_input_actions := {}


func _enter_tree():
	if Engine.is_editor_hint():
		_parse_input_actions()


func _ready():
	Input.joy_connection_changed.connect(_on_joy_connection_changed)
	# Wait a frame to give a chance for the app to initialize
	await get_tree().process_frame
	# Set input type to what's likely being used currently
	_set_last_input_type(InputType.GAMEPAD)


## Refresh all icons
func refresh():
	# All it takes is to signal icons to refresh paths
	input_type_changed.emit(last_input_type)


func _set_last_input_type(_last_input_type: InputType):
	last_input_type = _last_input_type
	input_type_changed.emit(_last_input_type)


func _on_joy_connection_changed(device, connected):
	if device == 0:
		if connected:
			# An await is required, otherwise a deadlock happens
			await get_tree().process_frame
			_set_last_input_type(InputType.GAMEPAD)
		else:
			# An await is required, otherwise a deadlock happens
			await get_tree().process_frame
			_set_last_input_type(InputType.KEYBOARD_MOUSE)


func _input(event: InputEvent):
	var input_type := last_input_type
	match event.get_class():
		"InputEventKey":
			input_type = InputType.KEYBOARD_MOUSE
		"InputEventJoypadButton", "InputEventAction":
			input_type = InputType.GAMEPAD
		"InputEventJoypadMotion":
			if abs(event.axis_value) > DEADZONE:
				input_type = InputType.GAMEPAD
	if input_type != last_input_type:
		_set_last_input_type(input_type)


func _parse_input_actions():
	# A script running at editor ("tool") level only has
	# the default mappings. The way to get around this is
	# manually parsing the project file and adding the
	# new input actions to lookup.
	var proj_file := ConfigFile.new()
	if proj_file.load("res://project.godot"):
		printerr(
			'Failed to open "project.godot"! Custom input actions will not work on editor view!'
		)
		return
	if proj_file.has_section("input"):
		for input_action in proj_file.get_section_keys("input"):
			var data: Dictionary = proj_file.get_value("input", input_action)
			_add_custom_input_action(input_action, data)


func _add_custom_input_action(input_action: String, data: Dictionary):
	_custom_input_actions[input_action] = data["events"]
