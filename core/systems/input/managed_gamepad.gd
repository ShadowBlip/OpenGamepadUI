extends Resource
class_name ManagedGamepad

## A ManagedGamepad is a physical/virtual gamepad pair for processing input
##
## ManagedGamepad will convert physical gamepad input into virtual gamepad input.

## Intercept mode defines how we intercept gamepad events
enum INTERCEPT_MODE {
	NONE,  ## Don't intercept ANY input
	PASS,  ## Pass all inputs to the virtual device
	ALL,  ## Intercept all inputs and send nothing to the virtual device
}

var profile: GamepadProfile
var xwayland: Xlib
var event_map := {}
var mode := INTERCEPT_MODE.NONE
var phys_path: String
var virt_path: String
var phys_device: InputDevice
var virt_device: VirtualInputDevice
var abs_y_max: int
var abs_y_min: int
var abs_x_max: int
var abs_x_min: int
var abs_z_max: int
var abs_z_min: int
var abs_ry_max: int
var abs_ry_min: int
var abs_rx_max: int
var abs_rx_min: int
var abs_rz_max: int
var abs_rz_min: int
var cur_x: float
var cur_y: float
var cur_rx: float
var cur_ry: float
var mouse_remainder := Vector2()
var should_process_mouse := false
var _ff_effects := {}  # Current force feedback effect ids
var _last_time := 0
var logger := Log.get_logger("ManagedGamepad", Log.LEVEL.DEBUG)


## Opens the given physical gamepad with exclusive access and creates a virtual
## gamepad.
func open(path: String) -> int:
	# Create a physical device
	phys_path = path
	phys_device = InputDevice.new()
	if phys_device.open(phys_path) != OK:
		logger.warn("Unable to open gamepad: " + phys_path)
		return ERR_CANT_OPEN

	# Query information about the device
	abs_y_max = phys_device.get_abs_max(InputDeviceEvent.ABS_Y)
	abs_y_min = phys_device.get_abs_min(InputDeviceEvent.ABS_Y)
	abs_x_max = phys_device.get_abs_max(InputDeviceEvent.ABS_X)
	abs_x_min = phys_device.get_abs_min(InputDeviceEvent.ABS_X)
	abs_z_max = phys_device.get_abs_max(InputDeviceEvent.ABS_Z)
	abs_z_min = phys_device.get_abs_min(InputDeviceEvent.ABS_Z)
	abs_ry_max = phys_device.get_abs_max(InputDeviceEvent.ABS_RY)
	abs_ry_min = phys_device.get_abs_min(InputDeviceEvent.ABS_RY)
	abs_rx_max = phys_device.get_abs_max(InputDeviceEvent.ABS_RX)
	abs_rx_min = phys_device.get_abs_min(InputDeviceEvent.ABS_RX)
	abs_rz_max = phys_device.get_abs_max(InputDeviceEvent.ABS_RZ)
	abs_rz_min = phys_device.get_abs_min(InputDeviceEvent.ABS_RZ)

	# Create a virtual gamepad from this physical one
	virt_device = phys_device.duplicate()
	if not virt_device:
		logger.warn("Unable to create virtual gamepad for: " + phys_path)
		return ERR_CANT_CREATE

	# Set the path to the virtual gamepad
	virt_path = virt_device.get_devnode()

	# Grab exclusive access over the physical device
	phys_device.grab(true)

	return OK


## Set the managed gamepad to use the given gamepad profile for translating
## input events into other input events
func set_profile(gamepad_profile: GamepadProfile) -> void:
	profile = gamepad_profile
	event_map = {}
	should_process_mouse = false
	if not profile:
		return

	logger.info("Setting gamepad profile: " + profile.name)
	# Map the profile mappings with the events to translate
	for m in profile.mapping:
		var mapping := m as GamepadMapping
		if not mapping.source_event in event_map:
			event_map[mapping.source_event] = []
		event_map[mapping.source_event].append(mapping)

		# If there is a mapping that does mouse motion, enable
		# processing of mouse motion in process_input()
		if mapping.target is InputEventMouseMotion:
			should_process_mouse = true


## Processes all physical and virtual inputs for this controller. This should be
## called in a tight loop to process input events.
func process_input() -> void:
	# Calculate the amount of time that has passed since last invocation
	var current_time := Time.get_ticks_usec()
	var delta_us := current_time - _last_time
	_last_time = current_time
	var delta := delta_us / 1000000.0  # Convert to seconds

	# Only process input if we have a valid handle
	if not phys_device or not phys_device.is_open():
		return

	# Process all physical input events
	var events = phys_device.get_events()
	for event in events:
		if not event or not event is InputDeviceEvent:
			continue
		_process_phys_event(event, delta)

	# Process all virtual input events
	events = virt_device.get_events()
	for event in events:
		if not event or not event is InputDeviceEvent:
			continue
		_process_virt_event(event)

	# If we need to process mouse movement, do it
	if mode == INTERCEPT_MODE.PASS and should_process_mouse:
		_move_mouse(delta)


## Processes a single physical gamepad event. Depending on the intercept mode,
## this usually means forwarding events from the physical gamepad to the
## virtual gamepad. In other cases we want to translate physical input into
## Godot events that only OGUI will respond to.
func _process_phys_event(event: InputDeviceEvent, delta: float) -> void:
	# Always skip passing FF events to the virtual gamepad
	if event.get_type() == event.EV_FF:
		return

	# Intercept mode NONE will pass all input to the virtual gamepad
	if mode == INTERCEPT_MODE.NONE:
		virt_device.write_event(event.get_type(), event.get_code(), event.get_value())
		return

	# Intercept mode PASS will pass all input to the virtual gamepad except
	# for guide button presses.
	if mode == INTERCEPT_MODE.PASS:
		# Intercept guide button presses so the game doesn't see them
		if event.get_code() == event.BTN_MODE:
			if event.value == 1:
				mode = INTERCEPT_MODE.ALL
			else:
				mode = INTERCEPT_MODE.PASS
			_send_input("ogui_guide", event.value == 1, 1)
			return

		# If a profile is set, and this event needs translation, do that
		# instead.
		if profile and event.get_code() in event_map:
			_translate_event(event, delta)
			return

		virt_device.write_event(event.get_type(), event.get_code(), event.get_value())
		return

	# Intercept mode ALL will not send *any* input to the virtual gamepad
	match event.get_code():
		event.BTN_SOUTH:
			_send_input("ogui_south", event.value == 1, 1)
			_send_input("ui_accept", event.value == 1, 1)
		event.BTN_NORTH:
			_send_input("ogui_north", event.value == 1, 1)
		event.BTN_WEST:
			_send_input("ogui_west", event.value == 1, 1)
			_send_input("ui_select", event.value == 1, 1)
		event.BTN_EAST:
			_send_input("ogui_east", event.value == 1, 1)
		event.BTN_MODE:
			_send_input("ogui_guide", event.value == 1, 1)
		event.BTN_TRIGGER_HAPPY1:
			_send_input("ui_left", event.value == 1, 1)
		event.BTN_TRIGGER_HAPPY2:
			_send_input("ui_right", event.value == 1, 1)
		event.BTN_TRIGGER_HAPPY3:
			_send_input("ui_up", event.value == 1, 1)
		event.BTN_TRIGGER_HAPPY4:
			_send_input("ui_down", event.value == 1, 1)
		event.ABS_Y:
			var value := _normalize_axis(event)
			if value == 0:
				return
			_send_joy_input(JOY_AXIS_LEFT_Y, value)
		event.ABS_X:
			var value := _normalize_axis(event)
			if value == 0:
				return
			_send_joy_input(JOY_AXIS_LEFT_X, value)


## Sometimes games will send gamepad events to the controller, such as when to
## rumble the controller. This method handles those by capturing those events
## and forwarding them to the physical controller.
func _process_virt_event(event: InputDeviceEvent) -> void:
	if event.get_type() == event.EV_FF:
		# Write any force feedback events to the physical gamepad
		phys_device.write_event(event.get_type(), event.get_code(), event.get_value())
		return

	if event.get_type() != event.EV_UINPUT:
		return

	if event.get_code() == event.UI_FF_UPLOAD:
		# NOTE: Don't use a type hint here:
		# https://github.com/godotengine/godot-cpp/issues/1020
		var upload = virt_device.begin_upload(event.value)
		if not upload:
			logger.error("Unable to handle FF_UPLOAD event!")
			return

		# Upload the effect to the physical gamepad
		var effect = upload.get_effect()
		if not effect.effect_id in _ff_effects:
			effect.effect_id = -1  # set to -1 for kernel to allocate a new id
		phys_device.upload_effect(effect)
		upload.retval = 0

		_ff_effects[effect.effect_id] = true

		virt_device.end_upload(upload)
		return

	if event.get_code() == event.UI_FF_ERASE:
		# NOTE: Don't use a type hint here:
		# https://github.com/godotengine/godot-cpp/issues/1020
		var erase = virt_device.begin_erase(event.value)
		if not erase:
			logger.error("Unable to handle FF_ERASE event!")
			return

		# Erase the effect from the physical controller
		var effect_id := erase.get_effect_id()
		erase.retval = phys_device.erase_effect(effect_id)

		virt_device.end_erase(erase)
		return


## Translates the given event based on the gamepad profile.
func _translate_event(event: InputDeviceEvent, delta: float) -> void:
	var mappings := event_map[event.get_code()] as Array

	# Loop through the translation mappings for this event
	for m in mappings:
		var mapping := m as GamepadMapping

		# Handle keyboard event translation targets
		if mapping.target is InputEventKey:
			var target_event := mapping.target as InputEventKey
			var pressed := false

			# Check to see if the event source is an ABS axis event
			if mapping.SOURCE_EVENTS[mapping.source].begins_with("ABS"):
				var is_positive := mapping.axis == mapping.AXIS.POSITIVE
				pressed = _is_axis_pressed(event, is_positive)

			# Translate gamepad button events
			else:
				if event.get_value() == 1:
					pressed = true

			#logger.debug("Sending key: " + OS.get_keycode_string(target_event.keycode))
			xwayland.send_key(target_event.keycode, pressed)
			continue

		# Handle mouse button event translations
		if mapping.target is InputEventMouseButton:
			var target_event := mapping.target as InputEventMouseButton
			var pressed := false

			# Check to see if the event source is an ABS axis event
			if mapping.SOURCE_EVENTS[mapping.source].begins_with("ABS"):
				var is_positive := mapping.axis == mapping.AXIS.POSITIVE
				pressed = _is_axis_pressed(event, is_positive)

			# Translate gamepad button events
			else:
				if event.get_value() == 1:
					pressed = true

			# Set the button pressed value
			var value := 0
			if pressed:
				value = 1

			# Set the button to send
			var button := -1
			match target_event.button_index:
				MOUSE_BUTTON_LEFT:
					button = event.BTN_LEFT
				MOUSE_BUTTON_RIGHT:
					button = event.BTN_RIGHT
				MOUSE_BUTTON_MIDDLE:
					button = event.BTN_MIDDLE
			if button > 0:
				virt_device.write_event(event.EV_KEY, button, value)
				virt_device.write_event(event.EV_SYN, event.SYN_REPORT, 0)

			# Handle mousewheel events
			if target_event.button_index in [MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN]:
				print("Got mousewheel!")
				if not pressed:
					print("Not pressed!")
					continue
				if target_event.button_index == MOUSE_BUTTON_WHEEL_UP:
					print("Sending up wheel!")
					virt_device.write_event(event.EV_REL, event.REL_WHEEL, 1)
					virt_device.write_event(event.EV_SYN, event.SYN_REPORT, 0)
				if target_event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
					print("Sending down wheel!")
					virt_device.write_event(event.EV_REL, event.REL_WHEEL, -1)
					virt_device.write_event(event.EV_SYN, event.SYN_REPORT, 0)
				continue

			continue

		# Handle mouse motion event translation targets
		if mapping.target is InputEventMouseMotion:
			# TODO: Get mouse speed from mapping target
			var target_event := mapping.target as InputEventMouseMotion
			_set_current_axis_value(event)
			continue


# Tries to determine if an axis is "pressed" enough to send a key press event
func _is_axis_pressed(event: InputDeviceEvent, is_positive: bool) -> bool:
	var threshold := 0.35
	var value := _normalize_axis(event)

	if is_positive:
		if value > threshold:
			return true
	else:
		if value < -threshold:
			return true

	return false


# Updates the current axis values
func _set_current_axis_value(event: InputDeviceEvent) -> void:
	var value := _normalize_axis(event)
	match event.get_code():
		event.ABS_X:
			cur_x = value
		event.ABS_Y:
			cur_y = value
		event.ABS_RX:
			cur_rx = value
		event.ABS_RY:
			cur_ry = value


# Move the mouse based on the given input event translation
# TODO: Don't assume the source is a joystick
func _move_mouse(delta: float) -> void:
	var pixels_to_move := Vector2()

	var lx := _calculate_mouse_move(delta, cur_x)
	var ly := _calculate_mouse_move(delta, cur_y)
	var rx := _calculate_mouse_move(delta, cur_rx)
	var ry := _calculate_mouse_move(delta, cur_ry)

	# Add the left and right joystick inputs
	pixels_to_move.x = lx + rx
	pixels_to_move.y = ly + ry

	# Get the fractional value of the position so we can accumulate them
	# in between invocations
	var x: int = pixels_to_move.x  # E.g. 3.14 -> 3
	var y: int = pixels_to_move.y
	var remainder_x: float = pixels_to_move.x - float(x)
	var remainder_y: float = pixels_to_move.y - float(y)

	# Keep track of relative mouse movements to keep around fractional values
	mouse_remainder.x += remainder_x
	if mouse_remainder.x >= 1:
		x += 1
		mouse_remainder.x -= 1
	if mouse_remainder.x <= -1:
		x -= 1
		mouse_remainder.x += 1
	mouse_remainder.y += remainder_y
	if mouse_remainder.y >= 1:
		y += 1
		mouse_remainder.y -= 1
	if mouse_remainder.y <= -1:
		y -= 1
		mouse_remainder.y += 1

	# Write the mouse motion event to the virtual device
	var EV_REL := InputDeviceEvent.EV_REL
	var EV_SYN := InputDeviceEvent.EV_SYN
	var REL_X := InputDeviceEvent.REL_X
	var REL_Y := InputDeviceEvent.REL_Y
	var SYN_REPORT := InputDeviceEvent.SYN_REPORT
	if x != 0:
		virt_device.write_event(EV_REL, REL_X, x)
		virt_device.write_event(EV_SYN, SYN_REPORT, 0)
	if y != 0:
		virt_device.write_event(EV_REL, REL_Y, y)
		virt_device.write_event(EV_SYN, SYN_REPORT, 0)


# Calculate how much the mouse should move based on the current axis value
func _calculate_mouse_move(delta: float, value: float) -> float:
	var threshold := 0.20
	if abs(value) < threshold:
		return 0
	var mouse_speed_pps := 800
	var pixels_to_move := mouse_speed_pps * value * delta

	return pixels_to_move


# Uses the axis minimum and maximum values to return a value from -1.0 - 1.0
# reflecting how far the axis has been pushed from the center
func _normalize_axis(event: InputDeviceEvent) -> float:
	match event.get_code():
		event.ABS_Y:
			if event.value > 0:
				var maximum := abs_y_max
				var value := event.value / float(maximum)
				return value
			if event.value <= 0:
				var minimum := abs_y_min
				var value := event.value / float(minimum)
				return -value
		event.ABS_X:
			if event.value > 0:
				var maximum := abs_x_max
				var value := event.value / float(maximum)
				return value
			if event.value <= 0:
				var minimum := abs_x_min
				var value := event.value / float(minimum)
				return -value
		event.ABS_Z:
			if event.value > 0:
				var maximum := abs_z_max
				var value := event.value / float(maximum)
				return value
			if event.value <= 0:
				var minimum := abs_z_min
				var value := event.value / float(minimum)
				return -value
		event.ABS_RY:
			if event.value > 0:
				var maximum := abs_ry_max
				var value := event.value / float(maximum)
				return value
			if event.value <= 0:
				var minimum := abs_ry_min
				var value := event.value / float(minimum)
				return -value
		event.ABS_RX:
			if event.value > 0:
				var maximum := abs_rx_max
				var value := event.value / float(maximum)
				return value
			if event.value <= 0:
				var minimum := abs_rx_min
				var value := event.value / float(minimum)
				return -value
		event.ABS_RZ:
			if event.value > 0:
				var maximum := abs_rz_max
				var value := event.value / float(maximum)
				return value
			if event.value <= 0:
				var minimum := abs_rz_min
				var value := event.value / float(minimum)
				return -value

	return 0


# Sends an input action to the event queue
func _send_input(action: String, pressed: bool, strength: float = 1.0) -> void:
	var input_action := InputEventAction.new()
	input_action.action = action
	input_action.pressed = pressed
	input_action.strength = strength
	Input.parse_input_event(input_action)


# Sends joy motion input to the event queue
func _send_joy_input(axis: int, value: float) -> void:
	var joy_action := InputEventJoypadMotion.new()
	joy_action.axis = axis
	joy_action.axis_value = value
	Input.parse_input_event(joy_action)
