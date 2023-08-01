extends Resource
class_name GamepadMouse

var mouse_path: String
var device: VirtualInputDevice

var mouse_speed_pps := 800
var mouse_remainder := Vector2()
var mouse_position := Vector2.ZERO
var should_process := false

var logger := Log.get_logger("GamepadMouse")


## Creates and opens the gamepad mouse device
func open() -> int:
	# Create a virtual mouse associated with this gamepad
	logger.debug("Opening virtual mouse device")
	device = InputDevice.create_mouse()
	if not device:
		logger.debug("Got null virtual device: " + str(device))
		return ERR_CANT_CREATE

	# Set the path to the virtual mouse
	mouse_path = device.get_devnode()

	return OK


## Processes the given mouse motion or button input event.
func process_mouse_event(event: InputEvent) -> void:
	# Handle mouse button event translations
	if event is InputEventMouseButton:
		# Set the value to send
		var value := 1 if event.is_pressed() else 0
		
		# Set the button to send
		var button := -1
		match event.button_index:
			MOUSE_BUTTON_LEFT:
				button = InputDeviceEvent.BTN_LEFT
			MOUSE_BUTTON_RIGHT:
				button = InputDeviceEvent.BTN_RIGHT
			MOUSE_BUTTON_MIDDLE:
				button = InputDeviceEvent.BTN_MIDDLE
		if button > 0:
			device.write_event(InputDeviceEvent.EV_KEY, button, value)
			device.write_event(InputDeviceEvent.EV_SYN, InputDeviceEvent.SYN_REPORT, 0)

		# Handle mousewheel events
		if event.button_index in [MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN]:
			if not event.is_pressed():
				return
			if event.button_index == MOUSE_BUTTON_WHEEL_UP:
				device.write_event(InputDeviceEvent.EV_REL, InputDeviceEvent.REL_WHEEL, 1)
				device.write_event(InputDeviceEvent.EV_SYN, InputDeviceEvent.SYN_REPORT, 0)
			if event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
				device.write_event(InputDeviceEvent.EV_REL, InputDeviceEvent.REL_WHEEL, -1)
				device.write_event(InputDeviceEvent.EV_SYN, InputDeviceEvent.SYN_REPORT, 0)
			return

		return

	# Handle mouse motion event translation targets
	if event is InputEventMouseMotion:
		# Update the virtual mouse position. The "relative" property is used as a mask
		# to determine what axis the event should update.
		# TODO: How do we handle multiple events updating the mouse position?
		if event.relative.x == 1:
			mouse_position.x = event.position.x
		if event.relative.y == 1:
			mouse_position.y = event.position.y
		return


## Should be called every input frame to move the mouse
func process(delta: float) -> void:
	_move_mouse(delta)


## Move the mouse based on the given input event translation
func _move_mouse(delta: float) -> void:
	var pixels_to_move := Vector2()

	pixels_to_move.x = _calculate_mouse_move(delta, mouse_position.x)
	pixels_to_move.y = _calculate_mouse_move(delta, mouse_position.y)
	
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
		device.write_event(EV_REL, REL_X, x)
		device.write_event(EV_SYN, SYN_REPORT, 0)
	if y != 0:
		device.write_event(EV_REL, REL_Y, y)
		device.write_event(EV_SYN, SYN_REPORT, 0)


# Calculate how much the mouse should move based on the current axis value
func _calculate_mouse_move(delta: float, value: float) -> float:
	var threshold := 0.20
	if abs(value) < threshold:
		return 0
	var pixels_to_move := mouse_speed_pps * value * delta

	return pixels_to_move
