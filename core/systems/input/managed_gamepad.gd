extends Resource
class_name ManagedGamepad

# Intercept mode defines how we intercept gamepad events
enum INTERCEPT_MODE {
	NONE,
	PASS,  # Pass all inputs to the virtual device except guide
	PASS_QAM, # Pass all inputs to the virtual device except guide + south
	ALL,  # Intercept all inputs and send nothing to the virtual device
}

var mode := INTERCEPT_MODE.NONE
var phys_path: String
var virt_path: String
var phys_device: InputDevice
var virt_device: VirtualInputDevice
var abs_y_max: int
var abs_y_min: int
var abs_x_max: int
var abs_x_min: int
var _ff_effects := {}  # Current force feedback effect ids
var logger := Log.get_logger("ManagedGamepad")
var mode_event: InputDeviceEvent

# List of events to consume the BTN_MODE event in PASS_QAM mode. This enables the
# use of default button combo's in Steam.
var use_mode_list: Array = [InputDeviceEvent.BTN_WEST, InputDeviceEvent.BTN_NORTH,
	InputDeviceEvent.BTN_SOUTH, InputDeviceEvent.BTN_TRIGGER_HAPPY1,
	InputDeviceEvent.BTN_TRIGGER_HAPPY2, InputDeviceEvent.BTN_TRIGGER_HAPPY3,
	InputDeviceEvent.BTN_TRIGGER_HAPPY4, InputDeviceEvent.ABS_HAT0X,
	InputDeviceEvent.ABS_HAT0Y, InputDeviceEvent.BTN_TL, InputDeviceEvent.BTN_TR,
	InputDeviceEvent.BTN_SELECT, InputDeviceEvent.BTN_START]

# Opens the given physical gamepad with exclusive access and creates a virtual
# gamepad.
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


# Processes all physical and virtual inputs for this controller. This should be
# called in a tight loop to process input events.
func process_input() -> void:
	# Only process input if we have a valid handle
	if not phys_device or not phys_device.is_open():
		return

	# Process all physical input events
	var events = phys_device.get_events()
	for event in events:
		if not event or not event is InputDeviceEvent:
			continue
		_process_phys_event(event)

	# Process all virtual input events
	events = virt_device.get_events()
	for event in events:
		if not event or not event is InputDeviceEvent:
			continue
		_process_virt_event(event)


# Processes a single physical gamepad event. Depending on the intercept mode,
# this usually means forwarding events from the physical gamepad to the
# virtual gamepad. In other cases we want to translate physical input into
# Godot events that only OGUI will respond to.
func _process_phys_event(event: InputDeviceEvent) -> void:
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
		if event.get_code() == event.BTN_MODE:
			if event.value == 1:
				mode = INTERCEPT_MODE.ALL
			else:
				mode = INTERCEPT_MODE.PASS
			_send_input("ogui_guide", event.value == 1, 1)
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
					OS.delay_msec(80) # Give steam time to accept the input
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
				OS.delay_msec(80) # Give steam time to accept the input
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
		event.BTN_TRIGGER_HAPPY1:
			_send_input("ui_left", event.value == 1, 1)
		event.BTN_TRIGGER_HAPPY2:
			_send_input("ui_right", event.value == 1, 1)
		event.BTN_TRIGGER_HAPPY3:
			_send_input("ui_up", event.value == 1, 1)
		event.BTN_TRIGGER_HAPPY4:
			_send_input("ui_down", event.value == 1, 1)
		event.ABS_Y:
			if event.value > 0:
				var maximum := abs_y_max
				var value := event.value / float(maximum)
				if value == 0:
					return
				_send_joy_input(JOY_AXIS_LEFT_Y, value)
			if event.value <= 0:
				var minimum := abs_y_min
				var value := event.value / float(minimum)
				if value == 0:
					return
				_send_joy_input(JOY_AXIS_LEFT_Y, -value)
		event.ABS_X:
			if event.value > 0:
				var maximum := abs_x_max
				var value := event.value / float(maximum)
				if value == 0:
					return
				_send_joy_input(JOY_AXIS_LEFT_X, value)
			if event.value <= 0:
				var minimum := abs_x_min
				var value := event.value / float(minimum)
				if value == 0:
					return
				_send_joy_input(JOY_AXIS_LEFT_X, -value)


# Sometimes games will send gamepad events to the controller, such as when to
# rumble the controller. This method handles those by capturing those events
# and forwarding them to the physical controller.
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
