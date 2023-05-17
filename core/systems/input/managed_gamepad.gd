extends Resource
class_name ManagedGamepad

## A ManagedGamepad is a physical/virtual gamepad pair for processing input
##
## ManagedGamepad will convert physical gamepad input into virtual gamepad input.

## Intercept mode defines how we intercept gamepad events
enum INTERCEPT_MODE {
	NONE,
	PASS,  # Pass all inputs to the virtual device except guide
	PASS_QAM,  # Pass all inputs to the virtual device except guide + south
	ALL,  # Intercept all inputs and send nothing to the virtual device
}

enum AXIS_PRESSED {
	NONE = 0,
	UP = 1,
	DOWN = 2,
	LEFT = 4,
	RIGHT = 8,
}

var profile: GamepadProfile
var xwayland: Xlib
var event_map := {}
var mode := INTERCEPT_MODE.ALL
var phys: String
var phys_path: String
var virt_path: String
var mouse_path: String
var phys_device: InputDevice
var virt_device: VirtualInputDevice
var virt_mouse: VirtualInputDevice
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
## Bitwise flags indicating what left-stick axis directions are currently being pressed.
var axis_pressed: AXIS_PRESSED
var mouse_remainder := Vector2()
var should_process_mouse := false
var _ff_effects := {}  # Current force feedback effect ids

## Time in seconds to wait to start sending echo events when a direction is being
## held and intercept mode is ALL.
var echo_initial_delay_secs := 0.6
## Time in seconds between sending echo events when a direction is being held and
## intercept mode is ALL.
var echo_interval_secs := 0.15
## Map of directional echo events and how long it has been since the last echo
## event was sent. This is used in _process_echo_input to calculate when the
## next echo event should be sent.
var echo_last_event_time := {
	AXIS_PRESSED.UP: -echo_initial_delay_secs,
	AXIS_PRESSED.DOWN: -echo_initial_delay_secs,
	AXIS_PRESSED.LEFT: -echo_initial_delay_secs,
	AXIS_PRESSED.RIGHT: -echo_initial_delay_secs,
}

var mode_event: InputDeviceEvent
var _last_time := 0
var logger := Log.get_logger("ManagedGamepad", Log.LEVEL.INFO)

# List of events to consume the BTN_MODE event in PASS_QAM mode. This enables the
# use of default button combo's in Steam.
var use_mode_list: Array = [
	InputDeviceEvent.BTN_WEST,
	InputDeviceEvent.BTN_NORTH,
	InputDeviceEvent.BTN_SOUTH,
	InputDeviceEvent.BTN_TRIGGER_HAPPY1,
	InputDeviceEvent.BTN_TRIGGER_HAPPY2,
	InputDeviceEvent.BTN_TRIGGER_HAPPY3,
	InputDeviceEvent.BTN_TRIGGER_HAPPY4,
	InputDeviceEvent.ABS_HAT0X,
	InputDeviceEvent.ABS_HAT0Y,
	InputDeviceEvent.BTN_TL,
	InputDeviceEvent.BTN_TR,
	InputDeviceEvent.BTN_SELECT,
	InputDeviceEvent.BTN_START
]


## Opens the given physical gamepad with exclusive access and creates a virtual
## gamepad.
func open(path: String) -> int:
	# Open the physical device
	var err := open_physical(path)
	if err != OK:
		return err

	# Create a virtual gamepad from this physical one
	virt_device = phys_device.duplicate()
	if not virt_device:
		logger.warn("Unable to create virtual gamepad for: " + phys_path)
		return ERR_CANT_CREATE

	# Set the path to the virtual gamepad
	virt_path = virt_device.get_devnode()

	# Create a virtual mouse associated with this gamepad
	virt_mouse = InputDevice.create_mouse()
	if not virt_mouse:
		logger.warn("Unable to create virtual mouse for: " + phys_path)
		return ERR_CANT_CREATE

	# Set the path to the virtual mouse
	mouse_path = virt_mouse.get_devnode()

	# Grab exclusive access over the physical device
	grab()

	return OK


## Opens the given physical device and grabs exclusive access to it.
func open_physical(path: String) -> int:
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

	# Store value of get_phys() so this can be reidentified if disconnected.
	phys = phys_device.get_phys()

	return OK


## Re-opens the physical device, re-using the existing virtual device
func reopen(path: String) -> int:
	var err := open_physical(path)
	if err != OK:
		return err
	grab()
	return OK


## Grab exclusive access over the physical device
func grab() -> void:
	if not "--disable-grab-gamepad" in OS.get_cmdline_args():
		phys_device.grab(true)


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

	# Handle echo inputs for directions when intercepting input
	if mode == INTERCEPT_MODE.ALL:
		_process_echo_input(delta)

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
				logger.debug("Intercepted guide button press")
				logger.debug("Setting intercept mode to ALL")
				mode = INTERCEPT_MODE.ALL
			else:
				logger.debug("Setting intercept mode to PASS")
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

	# Intercept mode PASS_QAM will pass all input to the virtual gamepad except
	# for guide + south button combo presses.
	if mode == INTERCEPT_MODE.PASS_QAM:
		if event.get_code() == event.BTN_MODE:
			if event.value == 1:
				mode_event = event
				return
			else:
				if mode_event:
					virt_device.write_event(mode_event.get_type(), mode_event.get_code(), 1)
					virt_device.write_event(event.EV_SYN, event.SYN_REPORT, 0)
					OS.delay_msec(80)  # Give steam time to accept the input
					virt_device.write_event(mode_event.get_type(), mode_event.get_code(), 0)
					virt_device.write_event(event.EV_SYN, event.SYN_REPORT, 0)
					mode_event = null

		if event.get_code() == event.BTN_EAST and mode_event:
			if event.value == 1:
				mode = INTERCEPT_MODE.ALL
			_send_input("ogui_qam", event.value == 1, 1)
			mode_event = null
			return

		# Process button combos that use BTN_MODE and another button
		if event.get_code() in use_mode_list and mode_event:
			if event.value == 1:
				virt_device.write_event(mode_event.get_type(), mode_event.get_code(), 1)
				virt_device.write_event(event.EV_SYN, event.SYN_REPORT, 0)
				OS.delay_msec(80)  # Give steam time to accept the input
				mode_event = null

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
		event.BTN_TR:
			_send_input("ogui_tab_right", event.value == 1, 1)
		event.BTN_TL:
			_send_input("ogui_tab_left", event.value == 1, 1)
		event.BTN_TRIGGER_HAPPY1:
			var pressed := event.value == 1
			_send_input("ui_left", pressed, 1)
			axis_pressed = Bitwise.set_flag_to(axis_pressed, AXIS_PRESSED.LEFT, pressed)
			return
		event.BTN_TRIGGER_HAPPY2:
			var pressed := event.value == 1
			_send_input("ui_right", pressed, 1)
			axis_pressed = Bitwise.set_flag_to(axis_pressed, AXIS_PRESSED.RIGHT, pressed)
			return
		event.BTN_TRIGGER_HAPPY3:
			var pressed := event.value == 1
			_send_input("ui_up", pressed, 1)
			axis_pressed = Bitwise.set_flag_to(axis_pressed, AXIS_PRESSED.UP, pressed)
			return
		event.BTN_TRIGGER_HAPPY4:
			var pressed := event.value == 1
			_send_input("ui_down", pressed, 1)
			axis_pressed = Bitwise.set_flag_to(axis_pressed, AXIS_PRESSED.DOWN, pressed)
			return
		event.ABS_HAT0Y:
			if event.value < 0: # UP
				_send_input("ui_up", true)
				axis_pressed = Bitwise.set_flag(axis_pressed, AXIS_PRESSED.UP)
				return
			if event.value > 0: # DOWN
				_send_input("ui_down", true)
				axis_pressed = Bitwise.set_flag(axis_pressed, AXIS_PRESSED.DOWN)
				return
			if Input.is_action_pressed("ui_up"):
				_send_input("ui_up", false)
				axis_pressed = Bitwise.clear_flag(axis_pressed, AXIS_PRESSED.UP)
			else:
				_send_input("ui_down", false)
				axis_pressed = Bitwise.clear_flag(axis_pressed, AXIS_PRESSED.DOWN)
		event.ABS_HAT0X:
			if event.value < 0: # LEFT
				_send_input("ui_left", true)
				axis_pressed = Bitwise.set_flag(axis_pressed, AXIS_PRESSED.LEFT)
				return
			if event.value > 0: # RIGHT
				_send_input("ui_right", true)
				axis_pressed = Bitwise.set_flag(axis_pressed, AXIS_PRESSED.RIGHT)
				return
			if Input.is_action_pressed("ui_left"):
				_send_input("ui_left", false)
				axis_pressed = Bitwise.clear_flag(axis_pressed, AXIS_PRESSED.LEFT)
			else:
				_send_input("ui_right", false)
				axis_pressed = Bitwise.clear_flag(axis_pressed, AXIS_PRESSED.RIGHT)
		event.ABS_Y:
			var value := event.value
			var pressed := _is_axis_pressed(event, value > 0)
			if value == 0:
				return

			# Handle button up
			if not pressed:
				if Bitwise.has_flag(axis_pressed, AXIS_PRESSED.DOWN):
					_send_input("ui_down", false)
					axis_pressed = Bitwise.clear_flag(axis_pressed, AXIS_PRESSED.DOWN)
					return
				if Bitwise.has_flag(axis_pressed, AXIS_PRESSED.UP):
					_send_input("ui_up", false)
					axis_pressed = Bitwise.clear_flag(axis_pressed, AXIS_PRESSED.UP)
					return
				return

			# If a direction is already pressed, do nothing
			if axis_pressed > 0:
				return

			# Handle button down
			if value > 0:
				_send_input("ui_down", true)
				axis_pressed = Bitwise.set_flag(axis_pressed, AXIS_PRESSED.DOWN)
				return
			if value <= 0:
				_send_input("ui_up", true)
				axis_pressed = Bitwise.set_flag(axis_pressed, AXIS_PRESSED.UP)
				return
		event.ABS_X:
			var value := event.value
			var pressed := _is_axis_pressed(event, value > 0)
			if value == 0:
				return

			# Handle button up
			if not pressed:
				if Bitwise.has_flag(axis_pressed, AXIS_PRESSED.RIGHT):
					_send_input("ui_right", false)
					axis_pressed = Bitwise.clear_flag(axis_pressed, AXIS_PRESSED.RIGHT)
					return
				if Bitwise.has_flag(axis_pressed, AXIS_PRESSED.LEFT):
					_send_input("ui_left", false)
					axis_pressed = Bitwise.clear_flag(axis_pressed, AXIS_PRESSED.LEFT)
					return
				return

			# If a direction is already pressed, do nothing
			if axis_pressed > 0:
				return

			# Handle button down
			if value > 0:
				_send_input("ui_right", true)
				axis_pressed = Bitwise.set_flag(axis_pressed, AXIS_PRESSED.RIGHT)
				return
			if value <= 0:
				_send_input("ui_left", true)
				axis_pressed = Bitwise.set_flag(axis_pressed, AXIS_PRESSED.LEFT)
				return
		event.ABS_RY:
			var value := _normalize_axis(event)
			_send_joy_input(JOY_AXIS_RIGHT_Y, value)
			return
		event.ABS_RX:
			var value := _normalize_axis(event)
			_send_joy_input(JOY_AXIS_RIGHT_X, value)
			return


# Detect and emit "echo" inputs. Echo inputs are repeated input events when the user
# is holding down a direction.
func _process_echo_input(delta: float) -> void:
	# Go through each possible direction
	for direction in echo_last_event_time.keys():
		if Bitwise.has_flag(axis_pressed, direction):
			echo_last_event_time[direction] += delta
		else:
			echo_last_event_time[direction] = -echo_initial_delay_secs
			continue
		
		# If echo_interval amount of time has passed, send an event
		if not echo_last_event_time[direction] > echo_interval_secs:
			continue
		
		if direction == AXIS_PRESSED.UP:
			_send_input("ui_up", true)
		elif direction == AXIS_PRESSED.DOWN:
			_send_input("ui_down", true)
		elif direction == AXIS_PRESSED.LEFT:
			_send_input("ui_left", true)
		elif direction == AXIS_PRESSED.RIGHT:
			_send_input("ui_right", true)
		echo_last_event_time[direction] = 0.0


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
				virt_mouse.write_event(event.EV_KEY, button, value)
				virt_mouse.write_event(event.EV_SYN, event.SYN_REPORT, 0)

			# Handle mousewheel events
			if target_event.button_index in [MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN]:
				if not pressed:
					continue
				if target_event.button_index == MOUSE_BUTTON_WHEEL_UP:
					virt_mouse.write_event(event.EV_REL, event.REL_WHEEL, 1)
					virt_mouse.write_event(event.EV_SYN, event.SYN_REPORT, 0)
				if target_event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
					virt_mouse.write_event(event.EV_REL, event.REL_WHEEL, -1)
					virt_mouse.write_event(event.EV_SYN, event.SYN_REPORT, 0)
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
		virt_mouse.write_event(EV_REL, REL_X, x)
		virt_mouse.write_event(EV_SYN, SYN_REPORT, 0)
	if y != 0:
		virt_mouse.write_event(EV_REL, REL_Y, y)
		virt_mouse.write_event(EV_SYN, SYN_REPORT, 0)


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
	input_action.set_meta("managed_gamepad", phys_path)
	Input.parse_input_event(input_action)


# Sends joy motion input to the event queue
func _send_joy_input(axis: int, value: float) -> void:
	var joy_action := InputEventJoypadMotion.new()
	joy_action.axis = axis
	joy_action.axis_value = value
	joy_action.set_meta("managed_gamepad", phys_path)
	Input.parse_input_event(joy_action)
