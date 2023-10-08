extends Resource
class_name ManagedGamepad

## A ManagedGamepad is a physical/virtual gamepad pair for processing input
##
## ManagedGamepad will convert physical gamepad input into virtual gamepad input.

signal profile_updated

## Intercept mode defines how we intercept gamepad events
enum INTERCEPT_MODE {
	NONE,
	PASS,  # Pass all inputs to the virtual device except guide
	PASS_QB,  # Pass all inputs to the virtual device except guide + south
	ALL,  # Intercept all inputs and send nothing to the virtual device
}

enum AXIS_PRESSED {
	NONE = 0,
	UP = 1,
	DOWN = 2,
	LEFT = 4,
	RIGHT = 8,
}

var input_thread := load("res://core/systems/threading/input_thread.tres") as SharedThread
var gamescope := load("res://core/global/gamescope.tres") as Gamescope
var mode := INTERCEPT_MODE.ALL
var profile := load("res://assets/gamepad/profiles/default.tres") as GamepadProfile
var xwayland := gamescope.get_xwayland(Gamescope.XWAYLAND.GAME)
var mutex := Mutex.new()

var phys: String
var phys_path: String
var virt_path: String
var phys_device: InputDevice
var virt_device: VirtualInputDevice
var virt_mouse := GamepadMouse.new()
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
## Bitwise flags indicating what left-stick axis directions are currently being pressed.
var axis_pressed: AXIS_PRESSED
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
var logger: Log.Logger

# List of events to consume the BTN_MODE event in PASS_QB mode. This enables the
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


func _init() -> void:
	logger = Log.get_logger("ManagedGamepad", Log.LEVEL.INFO)


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
	if virt_mouse.open() != OK:
		logger.warn("Unable to create virtual mouse for: " + phys_path)
		return ERR_CANT_CREATE

	# Grab exclusive access over the physical device
	grab()
	
	# If a default profile exists, load its mappings
	if profile:
		profile.load_mappings()

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


## Set the intercept mode on the gamepad
func set_mode(intercept_mode: INTERCEPT_MODE) -> void:
	logger.debug("Setting intercept mode to: " + str(intercept_mode))
	mutex.lock()
	mode = intercept_mode
	mutex.unlock()


## Set the managed gamepad to use the given gamepad profile for translating
## input events into other input events
func set_profile(gamepad_profile: GamepadProfile) -> void:
	var profile_name := "null"
	if gamepad_profile:
		profile_name = gamepad_profile.name
		
	logger.debug("Setting gamepad profile to: " + profile_name)
	mutex.lock()
	should_process_mouse = false
	profile = gamepad_profile
	if profile:
		virt_mouse.mouse_speed_pps = profile.mouse_speed_pps

		# Map the profile mappings with the events to translate
		for mapping in profile.mapping:
			# If there is a mapping that does mouse motion, enable
			# processing of mouse motion in process_input()
			for output_event in mapping.output_events:
				if not output_event is NativeEvent:
					continue
				if output_event.event is InputEventMouseMotion:
					logger.debug("Profile contains a mouse mapping")
					should_process_mouse = true
	
	# Load the profile mappings
	profile.load_mappings()
	mutex.unlock()
	
	profile_updated.emit()


## Grab exclusive access over the physical device
func grab() -> void:
	if not "--disable-grab-gamepad" in OS.get_cmdline_args():
		phys_device.grab(true)


## Processes all physical and virtual inputs for this controller. This should be
## called in a tight loop to process input events.
func process_input() -> void:
	# Only process input if we have a valid handle
	if not phys_device or not phys_device.is_open():
		return

	# Calculate the amount of time that has passed since last invocation
	var current_time := Time.get_ticks_usec()
	var delta_us := current_time - _last_time
	_last_time = current_time
	var delta := delta_us / 1000000.0  # Convert to seconds

	# Process all physical input events
	var events = phys_device.get_events()
	for event in events:
		if not event or not event is InputDeviceEvent:
			continue
		
		# TODO: Find a better way
		# Hack to get the QB button working on Steam Deck OpenSD devices
		if event.type == event.EV_KEY and event.code == event.KEY_F20:
			var quick_bar_event := InputDeviceEvent.new()
			quick_bar_event.type = event.EV_KEY
			quick_bar_event.code = event.BTN_BASE
			quick_bar_event.value = event.value
			event = quick_bar_event
		
		# Possibly translate the physical event and process it
		var mappable_event := EvdevEvent.from_input_device_event(event)
		var translated_events := _translate_event(mappable_event, delta)
		for translated in translated_events:
			_process_mappable_event(translated, delta)

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
		virt_mouse.process(delta)


## Inject the given event into the event processing queue.
func inject_event(event: MappableEvent, delta: float) -> void:
	var translated_events := _translate_event(event, delta)
	
	# Determine the order in which translated events should be emitted.
	if event.get_value() == 0 and translated_events.size() > 1:
		translated_events = translated_events.duplicate()
		translated_events.reverse()
	
	# Emit any translated events
	for translated in translated_events:
		if translated is EvdevEvent:
			logger.debug("Emitting EvdevEvent: " + str(translated))
		if translated is NativeEvent:
			# Duplicate to avoid attempting to transmit the same object in the same frame multiple times
			var t_event := translated.event.duplicate() as InputEvent
			translated = translated.duplicate()
			translated.event = t_event
			logger.debug("Emitting NativeEvent: " + str(translated))
		
		# Just process the event immediately if only one event is injected
		if translated_events.size() == 1:
			_process_mappable_event(translated, delta)
			virt_device.write_event(InputDeviceEvent.EV_SYN, InputDeviceEvent.SYN_REPORT, 0)
			continue

		# Defer processing this event
		_process_mappable_event(translated, delta)

		# Important to delay before writing syn report when multiple key's are being sent. Otherwise
		# we get issues with button passthrough.
		OS.delay_msec(80)
		virt_device.write_event(InputDeviceEvent.EV_SYN, InputDeviceEvent.SYN_REPORT, 0)


## Returns the capabilities of the gamepad
func get_capabilities() -> Array[MappableEvent]:
	var capabilities: Array[MappableEvent] = []
	var types := [InputDeviceEvent.EV_KEY, InputDeviceEvent.EV_REL, InputDeviceEvent.EV_ABS]
	var maxes := [InputDeviceEvent.KEY_MAX, InputDeviceEvent.REL_MAX, InputDeviceEvent.ABS_MAX]

	# Loop through all types we care about
	var idx := 0
	for type in types:
		# Get the total number of codes for this event type
		var max = maxes[idx]

		# Check every code to see if this gamepad has the event type
		for code in range(max):
			if not phys_device.has_event_code(type, code):
				continue
			
			# If the gamepad has the code, add it to our list of capabilities
			var event := InputDeviceEvent.new()
			event.type = type
			event.code = code
			var evdev_event := EvdevEvent.from_input_device_event(event)
			capabilities.append(evdev_event)
		
		idx += 1

	return capabilities


## Processes a single mappable event.
func _process_mappable_event(event: MappableEvent, delta: float) -> void:
	if event is EvdevEvent:
		_process_phys_event(event.to_input_device_event(), delta)
		return
	if event is NativeEvent:
		_process_native_event(event.event, delta)


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

		virt_device.write_event(event.get_type(), event.get_code(), event.get_value())
		return

	# Intercept mode PASS_QB will pass all input to the virtual gamepad except
	# for guide + south button combo presses.
	if mode == INTERCEPT_MODE.PASS_QB:
		if event.get_code() == event.BTN_MODE:
			logger.debug("Mode Pressed!")
			if event.value == 1:
				logger.debug("Mode DOWN (Catch)!")
				mode_event = event
				return
			else:
				if mode_event:
					virt_device.write_event(mode_event.get_type(), mode_event.get_code(), 1)
					OS.delay_msec(80)
					virt_device.write_event(event.EV_SYN, event.SYN_REPORT, 0)
					virt_device.write_event(mode_event.get_type(), mode_event.get_code(), 0)
					OS.delay_msec(80)
					virt_device.write_event(event.EV_SYN, event.SYN_REPORT, 0)
					mode_event = null

		if event.get_code() == event.BTN_EAST and mode_event:
			logger.debug("Open the Quick Bar Menu")
			_send_input("ogui_qb", event.value == 1, 1)
			mode_event = null
			return

		# Process button combos that use BTN_MODE and another button
		if event.get_code() in use_mode_list and mode_event:
			if event.value == 1:
				logger.debug("Mode DOWN! (Out)")
				virt_device.write_event(mode_event.get_type(), mode_event.get_code(), 1)
				OS.delay_msec(80)
				virt_device.write_event(event.EV_SYN, event.SYN_REPORT, 0)
				mode_event = null
		if event.get_type() == event.EV_KEY:
			logger.debug("Event out: " + event.get_code_name() + " " + str(event.get_value()))
		virt_device.write_event(event.get_type(), event.get_code(), event.get_value())
		return

	# Intercept mode ALL will not send *any* input to the virtual gamepad
	#logger.debug("Processing event in intercept ALL")
	match event.get_code_name():
		"BTN_SOUTH":
			_send_input("ogui_south", event.value == 1, 1)
			_send_input("ui_accept", event.value == 1, 1)
		"BTN_NORTH":
			_send_input("ogui_north", event.value == 1, 1)
			_send_input("ogui_search", event.value == 1, 1)
		"BTN_WEST":
			_send_input("ogui_west", event.value == 1, 1)
			_send_input("ui_select", event.value == 1, 1)
		"BTN_EAST":
			_send_input("ogui_east", event.value == 1, 1)
		"BTN_MODE":
			_send_input("ogui_guide", event.value == 1, 1)
		"BTN_TR":
			_send_input("ogui_tab_right", event.value == 1, 1)
		"BTN_TL":
			_send_input("ogui_tab_left", event.value == 1, 1)
		"BTN_TRIGGER_HAPPY1":
			var pressed := event.value == 1
			_send_input("ui_left", pressed, 1)
			axis_pressed = Bitwise.set_flag_to(axis_pressed, AXIS_PRESSED.LEFT, pressed)
			return
		"BTN_TRIGGER_HAPPY2":
			var pressed := event.value == 1
			_send_input("ui_right", pressed, 1)
			axis_pressed = Bitwise.set_flag_to(axis_pressed, AXIS_PRESSED.RIGHT, pressed)
			return
		"BTN_TRIGGER_HAPPY3":
			var pressed := event.value == 1
			_send_input("ui_up", pressed, 1)
			axis_pressed = Bitwise.set_flag_to(axis_pressed, AXIS_PRESSED.UP, pressed)
			return
		"BTN_TRIGGER_HAPPY4":
			var pressed := event.value == 1
			_send_input("ui_down", pressed, 1)
			axis_pressed = Bitwise.set_flag_to(axis_pressed, AXIS_PRESSED.DOWN, pressed)
			return
		"ABS_HAT0Y":
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
		"ABS_HAT0X":
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
		"ABS_Y":
			var value := event.value
			var pressed := _is_axis_pressed(event, value > 0)

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
		"ABS_X":
			var value := event.value
			var pressed := _is_axis_pressed(event, value > 0)

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
		"ABS_RY":
			var value := _normalize_axis(event)
			_send_joy_input(JOY_AXIS_RIGHT_Y, value)
			return
		"ABS_RX":
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


## Process native Godot input events
func _process_native_event(event: InputEvent, delta: float) -> void:
	# Handle OpenGamepadUI action events (e.g. "ogui_qb")
	if event is InputEventAction:
		_send_input_event(event)
		return

	# Handle keyboard event translations
	if event is InputEventKey:
		logger.debug("Sending key: " + OS.get_keycode_string(event.keycode))
		var value := 1 if event.is_pressed() else 0
		xwayland.send_key(event.keycode, value)
		return

	# Handle mouse button event translations
	if event is InputEventMouseButton or event is InputEventMouseMotion:
		logger.debug("Sending mouse input")
		virt_mouse.process_mouse_event(event)
		return


## Translates the given event based on the gamepad profile.
func _translate_event(event: MappableEvent, delta: float) -> Array[MappableEvent]:
	# If no gamepad profile is set, do no translation
	if not profile:
		return [event]
	
	# Get the event mapping from the gamepad profile
	var mapping := profile.get_mapping_for(event)
	
	# If no mapping exists, do no translation
	if not mapping:
		return [event]
	if not mapping.source_event:
		return [event]
	if not mapping.source_event.matches(event):
		return [event]
	
	# Get the value from the source event
	var value := event.get_value()
	
	# If this is an EvdevAbsEvent, we need to normalize the value by
	# using the axis minimum and maximum values to return a value from -1.0 - 1.0
	# reflecting how far the axis has been pushed from the center
	if event is EvdevAbsEvent:
		value = _normalize_axis(event.input_device_event)
		logger.debug("Normalized EV_ABS value " + str(event.get_event_value()) + " to: " + str(value))

	# Handle axis output behavior. This type of translation is usually to map analog
	# source events to multiple outputs. E.g. ABS_Y to 'W' and 'S' keys
	if mapping.output_behavior == mapping.OUTPUT_BEHAVIOR.AXIS:
		# If there is only one output event, treat this accordingly
		if mapping.output_events.size() == 1:
			var out_event := mapping.output_events[0]
			var translated_event := _translate_output_event(out_event, value)
			return [translated_event]
		
		# If there are two events defined, choose one based on the source value
		if mapping.output_events.size() == 2:
			var pos_axis_event: MappableEvent
			var neg_axis_event: MappableEvent
			
			# If the value is positive, we only care about the positive axis
			if value >= 0:
				pos_axis_event = _translate_output_event(mapping.output_events[1], value)
				neg_axis_event = _translate_output_event(mapping.output_events[0], 0)
			# If the value is negative, we only care about the negative axis
			else:
				pos_axis_event = _translate_output_event(mapping.output_events[1], 0)
				neg_axis_event = _translate_output_event(mapping.output_events[0], value)
			
			logger.debug("Translated event " + str(event) + " into " + str(pos_axis_event))
			logger.debug("Translated event " + str(event) + " into " + str(neg_axis_event))
			return [pos_axis_event, neg_axis_event]
		
		logger.warn("No axis output defined. Not translating event")
		return [event]

	# Default behavior is to return a sequence of events
	# Loop through each event in the mapping and translate the source event
	# to the target event.
	var translated: Array[MappableEvent] = []
	for out_event in mapping.output_events:
		var translated_event := _translate_output_event(out_event, value)
		translated.append(translated_event)
		logger.debug("Translated event " + str(event) + " into " + str(translated_event))
	
	return translated


## Creates a new translated event from the given gamepad profile event mapping
## and value.
func _translate_output_event(out_event: MappableEvent, value: float) -> MappableEvent:
	var translated_event := out_event.duplicate() as MappableEvent
	var translated_value := value
	
	# If this is an evdev event, duplicate the object
	if out_event is EvdevKeyEvent:
		var input_device_event := out_event.input_device_event.duplicate() as InputDeviceEvent
		translated_event.input_device_event = input_device_event
	
	# If we are translating to a native event, duplicate the event object
	# so it is not processed twice.
	elif out_event is NativeEvent:
		var input_event := out_event.event.duplicate() as InputEvent
		translated_event.event = input_event
	
	# If we're translating to an axis event, we need to denormalize the
	# value. Converting a percentage into the real value. E.g. translate 1.0 -> 35433
	if translated_event is EvdevAbsEvent:
		translated_value = _denormalize_axis(translated_event.get_event_code(), value)
	
	# TODO: Maybe this?
#	if translated_event is EvdevRelEvent:
#		translated_value = 0.0
	
	# If we're translating from a non-binary value (e.g. 0.75) to a binary event
	# (e.g. 1 or 0), we need to convert the value based on some threshold.
	var is_binary_value := translated_value == 0 or translated_value == 1
	if translated_event.is_binary_event() and not is_binary_value:
		var threshold := 0.45
		if translated_value > threshold or translated_value < -threshold:
			translated_value = 1
		else:
			translated_value = 0
	
	# Set the value of the event from the source event
	translated_event.set_value(translated_value)
	
	return translated_event


# Tries to determine if an axis is "pressed" enough to send a key press event
func _is_axis_pressed(event: InputDeviceEvent, is_positive: bool) -> bool:
	var threshold := 0.35
	var value := _normalize_axis(event)
	logger.debug("_is_axis_pressed: " + event.get_code_name() + " code: " + str(event.get_code()) + " value: " + str(value))
	if is_positive:
		if value > threshold:
			logger.debug("_is_axis_pressed: true")
			return true
	else:
		if value < -threshold:
			logger.debug("_is_axis_pressed: true")
			return true
	logger.debug("_is_axis_pressed: false")
	return false


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


# Uses the given normalized value and returns the real value between the minimum
# and maximum values for the given axis. This does the opposite of _normalize_axis().
# E.g. _denormalize_axis(event.get_code(), 0.75)
func _denormalize_axis(axis_code: int, normalized_value: float) -> float:
	match axis_code:
		InputDeviceEvent.ABS_Y:
			if normalized_value > 0:
				var maximum := abs_y_max
				var value := normalized_value * float(maximum)
				return value
			if normalized_value <= 0:
				var minimum := abs_y_min
				var value := normalized_value * float(minimum)
				return -value
		InputDeviceEvent.ABS_X:
			if normalized_value > 0:
				var maximum := abs_x_max
				var value := normalized_value * float(maximum)
				return value
			if normalized_value <= 0:
				var minimum := abs_x_min
				var value := normalized_value * float(minimum)
				return -value
		InputDeviceEvent.ABS_Z:
			if normalized_value > 0:
				var maximum := abs_z_max
				var value := normalized_value * float(maximum)
				return value
			if normalized_value <= 0:
				var minimum := abs_z_min
				var value := normalized_value * float(minimum)
				return -value
		InputDeviceEvent.ABS_RY:
			if normalized_value > 0:
				var maximum := abs_ry_max
				var value := normalized_value * float(maximum)
				return value
			if normalized_value <= 0:
				var minimum := abs_ry_min
				var value := normalized_value * float(minimum)
				return -value
		InputDeviceEvent.ABS_RX:
			if normalized_value > 0:
				var maximum := abs_rx_max
				var value := normalized_value * float(maximum)
				return value
			if normalized_value <= 0:
				var minimum := abs_rx_min
				var value := normalized_value * float(minimum)
				return -value
		InputDeviceEvent.ABS_RZ:
			if normalized_value > 0:
				var maximum := abs_rz_max
				var value := normalized_value * float(maximum)
				return value
			if normalized_value <= 0:
				var minimum := abs_rz_min
				var value := normalized_value * float(minimum)
				return -value

	return 0


# Sends an input action to the event queue
func _send_input(action: String, pressed: bool, strength: float = 1.0) -> void:
	var input_action := InputEventAction.new()
	input_action.action = action
	input_action.pressed = pressed
	input_action.strength = strength
	input_action.set_meta("managed_gamepad", phys_path)
	logger.debug("send_input: " + str(input_action))
	Input.parse_input_event(input_action)


# Sends an input action to the event queue
func _send_input_event(event: InputEvent) -> void:
	event.set_meta("managed_gamepad", phys_path)
	logger.debug("send_input_event: " + str(event))
	Input.parse_input_event(event)


# Sends joy motion input to the event queue
func _send_joy_input(axis: int, value: float) -> void:
	var joy_action := InputEventJoypadMotion.new()
	joy_action.axis = axis
	joy_action.axis_value = value
	joy_action.set_meta("managed_gamepad", phys_path)
	logger.debug("_send_joy_input: " + str(joy_action))
	Input.parse_input_event(joy_action)
