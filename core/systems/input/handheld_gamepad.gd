extends Resource
class_name HandheldGamepad

## List of virtual events that are currently held.
var active_events: Array[InputDeviceEvent]
## List of keys and their values that are currently pressed.
var active_keys: Array[InputDeviceEvent]
## The physical controller we want to associate input with
var gamepad_device: ManagedGamepad
## evdev character file path for the keybaord/mouse device
var kb_event_path: String
## The physical keyboard/mouse device we are mapping input from.
var kb_device: InputDevice
## List of vitural events that will be emitted upon release of the held key.
var queued_events: Array[InputDeviceEvent]
## List of ogui events that are currently held.
var sent_ogui_events: PackedStringArray
var _last_time := 0
var _last_volume := 0

# Override below in device specific implementation
## List of MappedEvent's that are activated by a specific Array[InputDeviceEvent].
## that activates either an ogui_event or another Array[InputDeviceEvent]
@export var mapped_events: Array[MappedEvent]
## Path of the device in sysfs ATTR{phys}
@export var kb_phys_path: String
## Name of the device in sysfs ATTR{name}z
@export var kb_phys_name: String
## Path of the device in sysfs ATTR{phys}
@export var gamepad_phys_path: String
## Name of the device in sysfs ATTR{name}
@export var gamepad_phys_name: String

## Will show logger events with the prefix HandheldGamepad
var logger := Log.get_logger("HandheldGamepad", Log.LEVEL.INFO)


## Main process thread for input translation from one device to another.
func process_input() -> void:
	# Calculate the amount of time that has passed since last invocation
	var current_time := Time.get_ticks_usec()
	var delta_us := current_time - _last_time
	_last_time = current_time
	var delta := delta_us / 1000000.0  # Convert to seconds

	# Only process input if we have a valid handle
	if not kb_device or not kb_device.is_open():
		return
	# Process all physical input events
	var events = kb_device.get_events()
	# Prevents multi-button combos from firing/queuing an event if the first
	# released leaves an active_keys array that matches a trigger event.
	# Any time a key is pressed there is always an EV_KEY with code 0 and value 0.
	if events.size() <= 1:
		return
	var stop_after_process := false
	# Loop through events and check if we need to do anything, then do it.
	for event in events:
		if not event or not event is InputDeviceEvent:
			continue
		if not _process_event(event, delta):
			stop_after_process = true
	# If no keys are active we can stop here.
	if stop_after_process:
		return
	if active_keys.size() == 0:
		return
	_check_mapped_events(delta)


## Called to handle an individual event. Sets the active keys.
func _process_event(event: InputDeviceEvent, delta: float) -> bool:
	# Always skip anything thats not a button
	if event.get_type() not in [event.EV_KEY, event.EV_MSC]:
		return true
	# AYANEO 2 and Geek use these codes for different buttons.
	if event.get_type() == event.EV_MSC and event.get_code() == 4:
		if event.get_value() not in [102, 103, 104] or active_keys == []:
			return true
	# Ignore this code, its linux kernel reserved and causes issues.
	if event.get_code() == 0:
		return true
	# release event, remove active keys
	logger.debug("event: type " + str(event.type) + " event: code " + str(event.code) + " value " + str(event.value))
	if event.value == 0:
		# Ignore if the active keys list is empty.
		if active_keys.size() == 0:
			return false
		logger.debug("------ Key --UP-- event ------")
		# Some keys might be active with two values, clear them all.
		active_keys.clear()
		_on_release_event(delta)
		logger.debug("Active keys:")
		for key in active_keys:
			logger.debug(str(key.get_type()) + " : " +str(key.get_code()) + " : " +str(key.get_value()))
		return false
	# Block adding the same active event twice
	if _find_active_key(event) >= 0:
		logger.debug("Already Active! Keys:")
		for key in active_keys:
			logger.debug(str(key.get_type()) + " : " +str(key.get_code()) + " : " +str(key.get_value()))
		return false
	logger.debug("______ Key __DOWN__ event ______")
	active_keys.insert(active_keys.bsearch_custom(event, _sort_events), event)
	logger.debug("Active keys:")
	for key in active_keys:
		logger.debug(str(key.get_type()) + " : " +str(key.get_code()) + " : " +str(key.get_value()))
	return true


## Returns the index of an active key.
func _find_active_key(event: InputDeviceEvent) -> int:
	for i in active_keys.size():
		if active_keys[i].type == event.type and \
		active_keys[i].code == event.code and \
		active_keys[i].value == event.value:
			return i
	return -1


## Runs on any event with value 0, handles key up/release events.
func _on_release_event(delta: float) -> void:
	# Clear any ogui events
	if active_events.size() == 0 and not sent_ogui_events.size() == 0:
		sent_ogui_events.clear()
		return
	#Any events that were activated by on press or by queue should now be deactivated.
	if not active_events.size() == 0:
		logger.debug("Clearing active events with key_up")
		_emit_events(active_events, delta, true)
		active_events.clear()
	# Any events that were queued as "on release" should now be activated.
	# Events will be "key_up" on next loop ext loop
	if not queued_events.size() == 0:
		logger.debug("Clearing queued events with key_down")
		_emit_events(queued_events, delta)
		active_events = queued_events.duplicate()
		queued_events.clear()


## Called after processing all events in the event loop. Checks if our current
## active_keys matches any of our mapped events.
func _check_mapped_events(delta: float) -> void:
	logger.debug("Checking events for matches")
	for mapped_event in mapped_events:
		if not mapped_event.trigger_events_match(active_keys):
			continue
		logger.debug("Found a matching event")
		_handle_mapped_event(mapped_event, delta)
		return


## Checks if a given mapped event needs to be ignored, queued, or emited.
func _handle_mapped_event(mapped_event: MappedEvent, delta: float) -> void:
	# Check if the event has already been handled
	if mapped_event.ogui_event in sent_ogui_events:
		return
	if mapped_event.on_release == false and \
	mapped_event.output_events_match(active_events):
		return
	if mapped_event.on_release == true and \
	mapped_event.output_events_match(queued_events):
		return
	# Check if there is an ogui_event mapped to this MappedEvent. This superceeds
	# the event_list.
	if mapped_event.ogui_event != "":
		var input_action := InputEventAction.new()
		input_action.action = mapped_event.ogui_event
		if not input_action.is_action(mapped_event.ogui_event):
			logger.warn("Listed ogui_event \"" + mapped_event.ogui_event +
			"\" does not correlate to a known event. Verify configuration of gamepad.")
			# Clear any queued events because we overrode it with an on_press event
			queued_events.clear()
			return
		logger.debug("Emit " + mapped_event.ogui_event)
		_send_input(input_action, mapped_event.ogui_event, true)
		sent_ogui_events.append(mapped_event.ogui_event)
		# Clear any queued events because we overrode it with an on_press event
		queued_events.clear()
		return
	# Queue events that should activate only on release of the button
	if mapped_event.on_release == true:
		logger.debug("Queue events.")
		queued_events = mapped_event.event_list.duplicate()
		return
	# Don't crash if the event_list is incomplete. Warn user.
	if mapped_event.event_list.size() == 0:
		logger.warn("No events list or ogui_event mapping for active keys. Verify configuration of gamepad.")
		return
	# Finally, send events to virtual device.
	logger.debug("Emit mapped events!")
	_emit_events(mapped_event.event_list, delta)
	active_events = mapped_event.event_list.duplicate()
	# Clear and queued events because we overrode it with an on_press event
	queued_events.clear()


## Loops through the given events list and emits the events. If do-release = true,
## all events will be release/key up events.
func _emit_events(event_list: Array[InputDeviceEvent], delta: float, do_release = false) -> void:
	for event in event_list:
		var value = event.get_value()
		if do_release:
			value = 0
#		logger.debug("Emit event:" + str(event.type) + " code: "  + str(event.code) + " value: "  + str(value))
		if _emit_event(event.get_type(), event.get_code(), value) == ERR_PARAMETER_RANGE_ERROR:
			_do_audio_event(event, delta)
		if event_list.size() > 1:
			OS.delay_msec(80)
		_emit_event(InputDeviceEvent.EV_SYN, InputDeviceEvent.SYN_REPORT, 0)


## Translates the given event to an AudioManager event.
func _do_audio_event(event: InputDeviceEvent, delta: float) -> void:
	var current_volume := AudioManager.get_current_volume()
	logger.debug("Current volume: " +str(current_volume))
	match event.get_code():
		113:
			logger.debug("Got event:" + str(event.get_type()) + " : " + str(event.get_code) + ". Muting.")
			if current_volume == 0:
				AudioManager.set_volume(_last_volume)
				return
			_last_volume = current_volume
			AudioManager.set_volume(0)
		114:
			logger.debug("Got event:" + str(event.get_type()) + " : " + str(event.get_code) + ". Decreasing volume.")
			if current_volume == 0:
				return
			AudioManager.set_volume(current_volume - .01)
		115:
			logger.debug("Got event:" + str(event.get_type()) + " : " + str(event.get_code) + ". Increasing volume.")
			if current_volume == 1:
				return
			AudioManager.set_volume(current_volume + .01)
		_:
			logger.warn("Event with type" + str(event.get_type()) + " and code: " + str(event.get_code) + " is not supported.")


## Emits a virtual device event.
func _emit_event(type: int, code: int, value: int) -> int:
	if type == null or code == null or value == null:
		logger.warn("Got malformed event. Verify controller configuration.")
		return ERR_UNCONFIGURED
	if not gamepad_device.phys_device.has_event_code(type, code):
		logger.debug("Virtual gamepad does not have event type: " + str(type) + " code: " + str(code) +
		". Sending xinput event instead.")
		return ERR_PARAMETER_RANGE_ERROR
	gamepad_device.virt_device.write_event(type, code, value)
	return OK


## Opens the given physical device with exclusive access. Requres a UDEV rule
## that provides uaccess for input devices that detect as keyboard/mouse.
func open() -> int:
	# Don't reconfigure if called by another gamepad reconnecting.
	if kb_device and kb_device.is_open():
		return OK
	kb_device = InputDevice.new()
	var result: int = kb_device.open(kb_event_path)
	if result != OK:
		logger.warn("Unable to open event device: " + kb_event_path)
		kb_device = null
		return result
	# Grab exclusive access over the physical device
	if not "--disable-grab-gamepad" in OS.get_cmdline_args():
		kb_device.grab(true)
	return result


# Sends an input action to the event queue
func _send_input(input_action: InputEventAction, action: String, pressed: bool, strength: float = 1.0) -> void:
	input_action.action = action
	input_action.pressed = pressed
	input_action.strength = strength
	Input.parse_input_event(input_action)


## Check if the given ManagedGamepad matches the parameters of the defined
## ManagedGamepad as specified in the device implementation.
func is_found_gamepad(gamepad: ManagedGamepad) -> bool:
	if gamepad.phys_device.get_phys() == gamepad_phys_path and gamepad.phys_device.get_name() == gamepad_phys_name:
		logger.info("Found handheld gamepad device: " + gamepad.phys_device.get_name())
		return true
	return false


## Check if the given InputDevice matches the parameters of the defined
## keyboard/mouse device as specified in the device implementation.
func is_found_kb(device: InputDevice) -> bool:
	if device.get_phys() == kb_phys_path and device.get_name() == kb_phys_name:
		logger.info("Found handheld input device: " + device.get_name())
		return true
	return false


## Saves the keyboard/mouse device event character file path
func set_kb_event_path(path: String) -> void:
	kb_event_path = path


## Sets the associated ManagedGamepad so it can recieve virtual device events
## that are mapped via the mapped_events Array.
func set_gamepad_device(gamepad: ManagedGamepad) -> bool:
	gamepad_device = gamepad
	if open() != OK:
		logger.warn("Unable to configure handheld gamepad device")
		return false
	gamepad_device.xwayland
	logger.info("Configured handeheld gamepad device")
	return true


## Custom sort method that returns true if the first InputDeviceEvent  is less 
## than the second InputDeviceEvent.  Checks type, then code, then value.
func _sort_events(event1: InputDeviceEvent, event2: InputDeviceEvent) -> bool:
	if event1.get_type() != event2.get_type():
		return event1.get_type() < event2.get_type()
	if event1.get_code() != event2.get_code():
		return event1.get_code() < event2.get_code()
	return event1.get_value() < event2.get_value()
