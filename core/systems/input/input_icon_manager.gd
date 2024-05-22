@icon("res://assets/editor-icons/tabler-icons.svg")
extends Resource
class_name InputIconManager

## [InputIconManager] is responsible for managing what input glyphs to show in the UI
##
## The InputIconManager will keep track of the last used input device and signal
## when the input device has changed to allow the UI to display the appropriate
## glyphs. In order for [InputIconManager] to work correctly, a [InputIconProcessor]
## must be added to the scene.

signal input_type_changed(input_type: InputType)

const MAPPINGS_DIR := "res://assets/gamepad/icon_mappings"
const DEFAULT_MAPPING := "res://assets/gamepad/icon_mappings/xbox360.tres"

enum InputType {
	KEYBOARD_MOUSE,
	GAMEPAD,
}

var in_game_state := load("res://assets/state/states/in_game.tres") as State
var input_plumber := load("res://core/systems/input/input_plumber.tres") as InputPlumber
var logger := Log.get_logger("InputIconManager", Log.LEVEL.INFO)

## Disable/Enable signaling on input type changes
var disabled := false
## The last detected input type
var last_input_type := InputType.GAMEPAD
## The device name of the last detected input
var last_input_device: String
## Mapping of device names to match to path to input icon mapping. There can be
## multiple device names that match a single icon mapping resource.
## E.g. {"Xbox 360 Controller": "res://assets/gamepad/icon_mappings/xb360.tres"}
var _device_mappings := discover_device_mappings(MAPPINGS_DIR)
## Mapping of icon mapping names to the path to the mapping
## E.g. {"XBox 360": "res://assets/gamepad/icon_mappings/xb360.tres"}
var _mappings := {}
## Mapping of device names to a mapping name. There can be multiple device names
## that match a single icon mapping name.
## E.g. {"Xbox 360 Wireless Controller": "XBox 360"}
var _device_name_to_mapping_name := {}
var _custom_input_actions := {}
## Special actions is a mapping of actions that can have fallback mappings
## if a particular icon map doesn't have certain inputs. 
## TODO: Can we do this better?
var _special_actions := {
	"ui_accept": {
		InputType.GAMEPAD: {
			"paths": ["joypad/a"],
		},
		InputType.KEYBOARD_MOUSE: {
			"paths": ["key/enter"],
		},
	},
	"ogui_qb": {
		InputType.GAMEPAD: {
			"paths": ["joypad/quickaccess"],
			"fallback": ["joypad/guide", "joypad/a"],
		},
		InputType.KEYBOARD_MOUSE: {
			"paths": ["key/ctrl", "key/f2"],
		},
	},
	"ogui_guide": {
		InputType.GAMEPAD: {
			"paths": ["joypad/guide"],
		},
		InputType.KEYBOARD_MOUSE: {
			"paths": ["key/ctrl", "key/f1"],
		},
	},
	"ogui_menu": {
		InputType.GAMEPAD: {
			"paths": ["joypad/guide"],
		},
		InputType.KEYBOARD_MOUSE: {
			"paths": ["key/ctrl", "key/f1"],
		},
	},
	"ogui_osk": {
		InputType.GAMEPAD: {
			"paths": ["joypad/keyboard"],
			"fallback": ["joypad/guide", "joypad/b"],
		},
		InputType.KEYBOARD_MOUSE: {
			"paths": ["key/alt", "key/4"],
		},
	},
	"ogui_back": {
		InputType.GAMEPAD: {
			"paths": ["joypad/b"],
		},
		InputType.KEYBOARD_MOUSE: {
			"paths": ["key/esc"],
		},
	},
	"ogui_east": {
		InputType.GAMEPAD: {
			"paths": ["joypad/b"],
		},
		InputType.KEYBOARD_MOUSE: {
			"paths": ["key/esc"],
		},
	},
	"ogui_tab_left": {
		InputType.GAMEPAD: {
			"paths": ["joypad/lb"],
		},
		InputType.KEYBOARD_MOUSE: {
			"paths": ["key/ctrl", "key/page_up"],
		},
	},
	"ogui_tab_right": {
		InputType.GAMEPAD: {
			"paths": ["joypad/rb"],
		},
		InputType.KEYBOARD_MOUSE: {
			"paths": ["key/ctrl", "key/page_down"],
		},
	},
	"ogui_search": {
		InputType.GAMEPAD: {
			"paths": ["joypad/x"],
		},
		InputType.KEYBOARD_MOUSE: {
			"paths": ["key/f5"],
		},
	},
}


func _init():
	if Engine.is_editor_hint():
		_parse_input_actions()

	self._mappings = discover_mappings(MAPPINGS_DIR)
	self._device_mappings = discover_device_mappings(MAPPINGS_DIR)
	
	# Populate mapping of device names to mapping names
	for mapping_name in self._mappings.keys():
		var mapping_path := self._mappings[mapping_name] as String
		for device_name in self._device_mappings.keys():
			if mapping_path != self._device_mappings[device_name]:
				continue
			self._device_name_to_mapping_name[device_name] = mapping_name

	# Disable when in game
	var on_in_game_entered := func(_from: State):
		self.disabled = true
	in_game_state.state_entered.connect(on_in_game_entered)
	var on_in_game_exited := func(_to: State):
		self.disabled = false
	in_game_state.state_exited.connect(on_in_game_exited)

	# Listen for InputPlumber device change events
	var on_comp_device_added := func(_device: InputPlumber.CompositeDevice):
		_on_joy_connection_changed(true)
	input_plumber.composite_device_added.connect(on_comp_device_added)
	var on_comp_device_removed := func(_path: String):
		_on_joy_connection_changed(false)
	input_plumber.composite_device_removed.connect(on_comp_device_removed)
	
	# Listen for Godot joypad change events
	var on_godot_joy_changed := func(_device: int, connected: bool):
		_on_joy_connection_changed(connected)
	Input.joy_connection_changed.connect(on_godot_joy_changed)

	# Set input type to what's likely being used currently
	set_last_input_type(InputType.GAMEPAD)


## Discover all input icon mappings from the specified path
static func discover_mappings(mappings_dir: String) -> Dictionary:
	var mappings := DirAccess.get_files_at(mappings_dir)
	var name_mappings := {}

	# Load all the mappings and organize them based on matching device names
	for filename: String in mappings:
		# After being exported, resources are listed with a ".remap" extension
		if filename.ends_with(".remap"):
			filename = filename.trim_suffix(".remap")
		var path := "/".join([MAPPINGS_DIR, filename])
		var mapping := load(path) as InputIconMapping
		if not mapping:
			push_error("InputIconManager: Failed to load input icon mapping: ", path)
			continue
		name_mappings[mapping.name] = path

	return name_mappings


## Discover all input icon mapping devices from the specified path
static func discover_device_mappings(mappings_dir: String) -> Dictionary:
	var mappings := DirAccess.get_files_at(mappings_dir)
	var device_mappings := {}

	# Load all the mappings and organize them based on matching device names
	for filename: String in mappings:
		# After being exported, resources are listed with a ".remap" extension
		if filename.ends_with(".remap"):
			filename = filename.trim_suffix(".remap")
		var path := "/".join([MAPPINGS_DIR, filename])
		var mapping := load(path) as InputIconMapping
		if not mapping:
			push_error("InputIconManager: Failed to load input icon mapping: ", path)
			continue
		for dev_name: String in mapping.device_names:
			device_mappings[dev_name] = path
	
	return device_mappings


## Refresh all icons
func refresh():
	# All it takes is to signal icons to refresh paths
	if not self.disabled:
		input_type_changed.emit(last_input_type)


## Parse the given input path and return the texture(s) associated with that type of
## input. The input path can either be in the form of "joypad/south" for specific inputs,
## or the name of an event action defined in the project's input map (i.e. "ui_accept").
## Optionally, a mapping name can be passed to get a specific icon from a specific mapping.
func parse_path(path: String, mapping_name: String = "", input_type: InputType = last_input_type) -> Array[Texture]:
	logger.debug("Getting texture(s) for path: " + path)
	var paths := PackedStringArray([path])
	var textures: Array[Texture] = []
	
	# If a mapping was explicitly set, look up the icon for that mapping
	if mapping_name != "":
		logger.debug("Mapping name specified: " + mapping_name)
		var mapping_path := DEFAULT_MAPPING
		if mapping_name in self._mappings:
			mapping_path = self._mappings[mapping_name] as String
		var mapping := load(mapping_path) as InputIconMapping
		if not mapping:
			logger.warn("Failed to load input icon mapping: " + mapping_path)
			mapping = load(DEFAULT_MAPPING) as InputIconMapping
		var texture := mapping.get_texture(path)
		if texture == null:
			logger.warn("No texture for '" + path + "' found in mapping: " + mapping.name)
			return textures
		textures.push_back(texture)
		return textures

	# Determine the type of input icon texture should be returned
	var device_name := self.last_input_device
	var mapping
	match input_type:
		InputType.GAMEPAD:
			mapping = self.load_matching_mapping(device_name)
		InputType.KEYBOARD_MOUSE:
			mapping = load("res://assets/keyboard/icon_mappings/keyboard.tres")
	if not mapping:
		logger.warn("No mapping found for device: " + device_name)
		return textures
	
	# Check to see if this path is a special action with possible fallbacks
	if path in self._special_actions:
		logger.debug("Path is a special action: " + path)
		var data := self._special_actions[path] as Dictionary
		var settings := data[input_type] as Dictionary
		var special_paths := settings["paths"] as Array
		
		# Check that the mapping has texture(s) for this action
		var mapping_has_textures := !special_paths.is_empty()
		for special_path in special_paths:
			if not mapping.get_texture(special_path):
				mapping_has_textures = false
				break
		
		# If the mapping doesn't have the texture, use the fallback paths
		if not mapping_has_textures and "fallback" in settings:
			logger.debug("Unable to find texture for special action '" + path + "' in mapping: " + mapping.name + ". Using fallback.")
			var fallback_paths := settings["fallback"] as Array
			paths.clear()
			paths.append_array(fallback_paths)
		else:
			paths.clear()
			paths.append_array(special_paths)
		logger.debug("Converted special action to: " + str(paths))
	
	# If the provided path is a custom input action, parse the input actions
	# and convert the string into an input path. (e.g. "ogui_accept" -> "joypad/a")
	if not path in self._special_actions and _is_path_action(path):
		logger.debug("Path '" + path + "' is an input action")
		var events := _get_matching_event(path, input_type)
		logger.debug("Found " + str(events.size()) + " event(s) for action '" + path + "': " + str(events))
		if events.is_empty():
			logger.warn("Unable to find events in input map for action: " + path)
			return textures
		
		paths.clear()
		for event: InputEvent in events:
			var converted_path := _convert_event_to_path(event)
			if converted_path.is_empty():
				logger.warn("Unable to convert event " + str(event) + " into path for action: " + path)
				continue
			logger.debug("Converted input event '" + str(event) + "' to path: " + converted_path)
			paths.append(converted_path)
	
	# Loop through all of the input paths (i.e. ["key/ctrl", "key/f1"]) and
	# get the corresponding texture based on the last detected device.
	for input_path in paths:
		var texture := mapping.get_texture(input_path) as Texture
		if not texture:
			logger.warn("No texture for '" + input_path + "' found in mapping: " + mapping.name)
			continue
		textures.push_back(texture)

	return textures


## Load and return the mapping that matches the given device.
func load_matching_mapping(device_name: String) -> InputIconMapping:
	# First try to do an exact match
	#logger.debug("Devices with mappings: " + str(self._device_mappings))
	if device_name in self._device_mappings:
		var mapping_path := self._device_mappings[device_name] as String
		var mapping := load(mapping_path) as InputIconMapping
		return mapping
	
	# Next, try to do a substring match
	for pattern: String in self._device_mappings.keys():
		if not pattern in device_name:
			continue
		var mapping_path := self._device_mappings[pattern] as String
		var mapping := load(mapping_path) as InputIconMapping
		return mapping
	
	# Last resort, fallback to default icon mapping
	logger.warn("No input icon mapping found for device: " + device_name)
	var mapping_path := DEFAULT_MAPPING
	var mapping := load(mapping_path) as InputIconMapping
	return mapping


## Returns the mapping name for the given device name. The mapping name is the
## "name" property of an [InputIconMapping].
func get_mapping_name_from_device(device_name: String) -> String:
	# First try to do an exact match
	#logger.debug("Devices with mappings: " + str(self._device_mappings))
	if device_name in self._device_name_to_mapping_name:
		return self._device_name_to_mapping_name[device_name] as String
	
	# Next, try to do a substring match
	for pattern: String in self._device_name_to_mapping_name.keys():
		if not pattern in device_name:
			continue
		return self._device_name_to_mapping_name[pattern] as String
	
	return ""


## Returns the Godot event(s) defined in the input map with the given name and
## match the given input type
func _get_matching_event(path: String, input_type: InputType) -> Array[InputEvent]:
	var events: Array[InputEvent] = []
	var matching_events: Array[InputEvent] = []
	if _custom_input_actions.has(path):
		events = _custom_input_actions[path]
	else:
		events = InputMap.action_get_events(path)
		# Check if any of the events have key modifiers
		var mod_events: Array[InputEvent] = []
		for event: InputEvent in events:
			if not event is InputEventKey:
				continue
			var key := event as InputEventKey
			if key.alt_pressed:
				var mod := InputEventKey.new()
				mod.keycode = KEY_ALT
				mod_events.append(mod)
			if key.meta_pressed:
				var mod := InputEventKey.new()
				mod.keycode = KEY_META
				mod_events.append(mod)
			if key.shift_pressed:
				var mod := InputEventKey.new()
				mod.keycode = KEY_SHIFT
				mod_events.append(mod)
			if key.ctrl_pressed:
				var mod := InputEventKey.new()
				mod.keycode = KEY_CTRL
				mod_events.append(mod)
		mod_events.append_array(events)
		events = mod_events

	for event: InputEvent in events:
		match event.get_class():
			"InputEventKey", "InputEventMouse", "InputEventMouseMotion", "InputEventMouseButton":
				if input_type == InputType.KEYBOARD_MOUSE:
					matching_events.append(event)
			"InputEventJoypadButton", "InputEventJoypadMotion":
				if input_type == InputType.GAMEPAD:
					matching_events.append(event)

	return matching_events


## Set the last input type to the given value and emit a signal
func set_last_input_type(_last_input_type: InputType):
	last_input_type = _last_input_type
	if not self.disabled:
		input_type_changed.emit(_last_input_type)


## Signal whenever a gamepad is connected/disconnected
func _on_joy_connection_changed(connected: bool) -> void:
	if connected:
		set_last_input_type(InputType.GAMEPAD)
	else:
		set_last_input_type(InputType.KEYBOARD_MOUSE)


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


func _is_path_action(path: String) -> bool:
	return _custom_input_actions.has(path) or InputMap.has_action(path)


func _add_custom_input_action(input_action: String, data: Dictionary):
	_custom_input_actions[input_action] = data["events"]


## Convert the given Godot input event into an input icon path 
## (e.g. "joypad/south", "key/a", etc.)
func _convert_event_to_path(event: InputEvent) -> String:
	if event is InputEventKey:
		# If this is a physical key, convert to localized scancode
		if event.keycode == 0:
			return _convert_key_to_path(
				DisplayServer.keyboard_get_keycode_from_physical(event.physical_keycode)
			)
		return _convert_key_to_path(event.keycode)
	elif event is InputEventMouseButton:
		return _convert_mouse_button_to_path(event.button_index)
	elif event is InputEventJoypadButton:
		return _convert_joypad_button_to_path(event.button_index)
	elif event is InputEventJoypadMotion:
		return _convert_joypad_motion_to_path(event.axis)
	return ""


func _convert_key_to_path(scancode: int) -> String:
	match scancode:
		KEY_ESCAPE:
			return "key/esc"
		KEY_TAB:
			return "key/tab"
		KEY_BACKSPACE:
			return "key/backspace_alt"
		KEY_ENTER:
			return "key/enter_alt"
		KEY_KP_ENTER:
			return "key/enter_tall"
		KEY_INSERT:
			return "key/insert"
		KEY_DELETE:
			return "key/del"
		KEY_PRINT:
			return "key/print_screen"
		KEY_HOME:
			return "key/home"
		KEY_END:
			return "key/end"
		KEY_LEFT:
			return "key/arrow_left"
		KEY_UP:
			return "key/arrow_up"
		KEY_RIGHT:
			return "key/arrow_right"
		KEY_DOWN:
			return "key/arrow_down"
		KEY_PAGEUP:
			return "key/page_up"
		KEY_PAGEDOWN:
			return "key/page_down"
		KEY_SHIFT:
			return "key/shift_alt"
		KEY_CTRL:
			return "key/ctrl"
		KEY_META:
			match OS.get_name():
				"OSX":
					return "key/command"
				_:
					return "key/meta"
		KEY_ALT:
			return "key/alt"
		KEY_CAPSLOCK:
			return "key/caps_lock"
		KEY_NUMLOCK:
			return "key/num_lock"
		KEY_F1:
			return "key/f1"
		KEY_F2:
			return "key/f2"
		KEY_F3:
			return "key/f3"
		KEY_F4:
			return "key/f4"
		KEY_F5:
			return "key/f5"
		KEY_F6:
			return "key/f6"
		KEY_F7:
			return "key/f7"
		KEY_F8:
			return "key/f8"
		KEY_F9:
			return "key/f9"
		KEY_F10:
			return "key/f10"
		KEY_F11:
			return "key/f11"
		KEY_F12:
			return "key/f12"
		KEY_KP_MULTIPLY, KEY_ASTERISK:
			return "key/asterisk"
		KEY_KP_SUBTRACT, KEY_MINUS:
			return "key/minus"
		KEY_KP_ADD:
			return "key/plus_tall"
		KEY_KP_0:
			return "key/0"
		KEY_KP_1:
			return "key/1"
		KEY_KP_2:
			return "key/2"
		KEY_KP_3:
			return "key/3"
		KEY_KP_4:
			return "key/4"
		KEY_KP_5:
			return "key/5"
		KEY_KP_6:
			return "key/6"
		KEY_KP_7:
			return "key/7"
		KEY_KP_8:
			return "key/8"
		KEY_KP_9:
			return "key/9"
		KEY_UNKNOWN:
			return ""
		KEY_SPACE:
			return "key/space"
		KEY_QUOTEDBL:
			return "key/quote"
		KEY_PLUS:
			return "key/plus"
		KEY_0:
			return "key/0"
		KEY_1:
			return "key/1"
		KEY_2:
			return "key/2"
		KEY_3:
			return "key/3"
		KEY_4:
			return "key/4"
		KEY_5:
			return "key/5"
		KEY_6:
			return "key/6"
		KEY_7:
			return "key/7"
		KEY_8:
			return "key/8"
		KEY_9:
			return "key/9"
		KEY_SEMICOLON:
			return "key/semicolon"
		KEY_LESS:
			return "key/mark_left"
		KEY_GREATER:
			return "key/mark_right"
		KEY_QUESTION:
			return "key/question"
		KEY_A:
			return "key/a"
		KEY_B:
			return "key/b"
		KEY_C:
			return "key/c"
		KEY_D:
			return "key/d"
		KEY_E:
			return "key/e"
		KEY_F:
			return "key/f"
		KEY_G:
			return "key/g"
		KEY_H:
			return "key/h"
		KEY_I:
			return "key/i"
		KEY_J:
			return "key/j"
		KEY_K:
			return "key/k"
		KEY_L:
			return "key/l"
		KEY_M:
			return "key/m"
		KEY_N:
			return "key/n"
		KEY_O:
			return "key/o"
		KEY_P:
			return "key/p"
		KEY_Q:
			return "key/q"
		KEY_R:
			return "key/r"
		KEY_S:
			return "key/s"
		KEY_T:
			return "key/t"
		KEY_U:
			return "key/u"
		KEY_V:
			return "key/v"
		KEY_W:
			return "key/w"
		KEY_X:
			return "key/x"
		KEY_Y:
			return "key/y"
		KEY_Z:
			return "key/z"
		KEY_BRACKETLEFT:
			return "key/bracket_left"
		KEY_BACKSLASH:
			return "key/slash"
		KEY_BRACKETRIGHT:
			return "key/bracket_right"
		KEY_ASCIITILDE:
			return "key/tilda"
		_:
			return ""


func _convert_mouse_button_to_path(button_index: int) -> String:
	match button_index:
		MOUSE_BUTTON_LEFT:
			return "mouse/left"
		MOUSE_BUTTON_RIGHT:
			return "mouse/right"
		MOUSE_BUTTON_MIDDLE:
			return "mouse/middle"
		_:
			return "mouse/sample"


func _convert_joypad_button_to_path(button_index: int) -> String:
	var path: String
	match button_index:
		JOY_BUTTON_A:
			path = "joypad/a"
		JOY_BUTTON_B:
			path = "joypad/b"
		JOY_BUTTON_X:
			path = "joypad/x"
		JOY_BUTTON_Y:
			path = "joypad/y"
		JOY_BUTTON_LEFT_SHOULDER:
			path = "joypad/lb"
		JOY_BUTTON_RIGHT_SHOULDER:
			path = "joypad/rb"
		JOY_AXIS_TRIGGER_LEFT:
			path = "joypad/lt"
		JOY_AXIS_TRIGGER_RIGHT:
			path = "joypad/rt"
		JOY_BUTTON_LEFT_STICK:
			path = "joypad/l_stick_click"
		JOY_BUTTON_RIGHT_STICK:
			path = "joypad/r_stick_click"
		JOY_BUTTON_BACK:
			path = "joypad/select"
		JOY_BUTTON_START:
			path = "joypad/start"
		JOY_BUTTON_DPAD_UP:
			path = "joypad/dpad_up"
		JOY_BUTTON_DPAD_DOWN:
			path = "joypad/dpad_down"
		JOY_BUTTON_DPAD_LEFT:
			path = "joypad/dpad_left"
		JOY_BUTTON_DPAD_RIGHT:
			path = "joypad/dpad_right"
		JOY_BUTTON_GUIDE:
			path = "joypad/home"
		JOY_BUTTON_MISC1:
			path = "joypad/share"
		_:
			return ""

	return path


func _convert_joypad_motion_to_path(axis: int) -> String:
	var path: String
	match axis:
		JOY_AXIS_LEFT_X, JOY_AXIS_LEFT_Y:
			path = "joypad/l_stick"
		JOY_AXIS_RIGHT_X, JOY_AXIS_RIGHT_Y:
			path = "joypad/r_stick"
		JOY_AXIS_TRIGGER_LEFT:
			path = "joypad/lt"
		JOY_AXIS_TRIGGER_RIGHT:
			path = "joypad/rt"
		_:
			return ""

	return path
