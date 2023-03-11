extends Resource
class_name HandheldGamepad

## List of keys and their values that are currently pressed.
var active_keys: Array[InputDeviceEvent]
## List of virtual events that are currently held.
var active_events: Array[InputDeviceEvent]
## List of vitural events that will be emitted upon release of the held key.
var queued_events: Array[InputDeviceEvent]
## List of ogui events that are currently held.
var sent_ogui_events: PackedStringArray
## The physical keyboard/mouse device we are mapping input from.
var kb_device: InputDevice
## The physical controller we want to associate input with
var gamepad_device: ManagedGamepad
## evdev character file path for the keybaord/mouse device
var kb_event_path: String

# Override below in device specific implementation
## List of MappedEvent's that are activated by a specific Array[InputDeviceEvent].
## that activates either an ogui_event or another Array[InputDeviceEvent]
@export var mapped_events: Array[MappedEvent]
## Path of the device in sysfs ATTR{phys}
@export var kb_phys_path: String
## Name of the device in sysfs ATTR{name}
@export var kb_phys_name: String
## Path of the device in sysfs ATTR{phys}
@export var gamepad_phys_path: String
## Name of the device in sysfs ATTR{name}
@export var gamepad_phys_name: String

## Will show logger events with the prefix HandheldGamepad
var logger := Log.get_logger("HandheldGamepad", Log.LEVEL.DEBUG)


## Main process thread for input translation from one device to another.
func process_input() -> void:
	# Only process input if we have a valid handle
	if not kb_device or not kb_device.is_open():
		return
	# Process all physical input events
	var events = kb_device.get_events()
	for event in events:
		if not event or not event is InputDeviceEvent:
			continue
		_process_event(event)
	if active_keys.size() == 0 and active_events.size() == 0 and queued_events.size() == 0:
		return
	_check_mapped_events()


## Called to handle an individual event. Sets the active keys.
func _process_event(event: InputDeviceEvent) -> void:
	# Always skip anything thats not a button
	if event.get_type() not in [event.EV_KEY, event.EV_MSC]:
		return
	# AYANEO 2 and Geek use these codes for different buttons.
	if event.get_type() == event.EV_MSC and \
		event.get_code() not in [102, 103, 140]:
			return
	# release event, remove active keys
	logger.debug("event: code " + str(event.code) + " value " + str(event.value))
	if event.value == 0:
		logger.debug("Key up event")
		var index := _find_active_key(event)
		if index >= 0:
			active_keys.remove_at(index)
		_on_release_event()
		logger.debug("Active keys: " + str(active_keys))
		return
	# Block adding the same active event twice
	if _find_active_key(event) >= 0:
		return
	logger.debug("Key down event")
	active_keys.append(event)
	logger.debug("Active keys: " + str(active_keys))


## Returns the index of an active key.
func _find_active_key(event: InputDeviceEvent) -> int:
	var i := 0
	for active_key in active_keys:
		if active_key.code == event.code:
			return i
		i += 1
	return -1


## Runs on any event with value 0, handles key up/release events.
func _on_release_event() -> void:
	if active_events.size() == 0:
		if not sent_ogui_events.size() == 0:
			sent_ogui_events.clear()
		return
	_emit_events(active_events, true)
	active_events.clear()
	# Any events that were queued as "on release" should now be activated.
	# Clear events will hit on next loop
	
	_emit_events(queued_events, true)
	active_events = queued_events.duplicate()
	queued_events.clear()


## Called after processing all events in the event loop. Checks if our current
## active_keys matches any of our mapped events.
func _check_mapped_events() -> void:
	logger.debug("Mapped events: " + str(mapped_events))
	for mapped_event in mapped_events:
		if not mapped_event.trigger_events_match(active_keys):
			continue
		_handle_mapped_event(mapped_event)
		return


## Checks if a given mapped event needs to be ignored, queued, or emited.
func _handle_mapped_event(mapped_event: MappedEvent) -> void:
	# Check if the event has already been handled
	if mapped_event.output_events_match(active_events):
		logger.debug("Matching event already activated")
		return
	if mapped_event.output_events_match(queued_events):
		logger.debug("Matching event already queued.")
		return
	if mapped_event.ogui_event in sent_ogui_events:
		logger.debug("Matching ogui event already sent.")
		return
	logger.debug("Event has not been handled")
	# Queue events that should activate only on release of the button
	if mapped_event.on_release == true:
		logger.debug("queue events!")
		queued_events = mapped_event.event_list.duplicate()
		logger.debug("Queued events: " + str(queued_events))
		return
	# Check if there is an ogui_event mapped to this MappedEvent. This superceeds
	# the event_list.
	if mapped_event.ogui_event != "":
		var input_action := InputEventAction.new()
		input_action.action = mapped_event.ogui_event
		if not input_action.is_action(mapped_event.ogui_event):
			logger.warn("Listed ogui_event \"" + mapped_event.ogui_event +
			"\" does not correlate to a known event. Verify configuration of gamepad.")
			return
		logger.debug("emit ogui_event!")
		_send_input(input_action, mapped_event.ogui_event, true)
		sent_ogui_events.append(mapped_event.ogui_event)
		return
	# Don't crash if the event_list is incomplete. Warn user.
	if mapped_event.event_list.size() == 0:
		logger.warn("No events list or ogui_event mapping for active keys. Verify configuration of gamepad.")
		return
	# Finally, send events to virtual device.
	_emit_events(mapped_event.event_list)
	active_events = mapped_event.event_list.duplicate()
	logger.debug("Active events: " + str(active_events))
	# Clear and queued events because we overrode it with an on_press event
	queued_events.clear()

## Loops through the given events list and emits the events. If do-release = true,
## all events will be release/key up events.
func _emit_events(event_list: Array[InputDeviceEvent], do_release = false) -> void:
	for event in event_list:
		var value = event.get_value()
		if do_release:
			value = 0
		logger.debug("Emit event:" + str(event.type) + " code: "  + str(event.code) + " value: "  + str(value))
		_emit_event(event.get_type(), event.get_code(), value)
		if event_list.size() > 1:
			OS.delay_msec(60)
		_emit_event(InputDeviceEvent.EV_SYN, InputDeviceEvent.SYN_REPORT, 0)

## Emits a virtual device event.
func _emit_event(type: int, code: int, value: int) -> void:
	if not gamepad_device.phys_device.has_event_code(type, code):
		logger.debug("Virtual gamepad does not have event " + str(type) + ":" + str(code) +
		". Sending xinput event instead.")
		logger.warn("Function Not Implemented.")
		return
	gamepad_device.virt_device.write_event(type, code, value)


## Opens the given physical device with exclusive access. Requres a UDEV rule
## that provides uaccess for input devices that detect as keyboard/mouse.
func open() -> int:
	kb_device = InputDevice.new()
	var result: int = kb_device.open(kb_event_path)
	if result != OK:
		logger.warn("Unable to open event device: " + kb_event_path)
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
	logger.debug("Checking input device: " + device.get_name())
	if device.get_phys() == kb_phys_path and device.get_name() == kb_phys_name:
		logger.info("Found handheld input device: " + device.get_name())
		return true
	return false


## Saves the keyboard/mouse device event character file path
func set_kb_event_path(path: String) -> void:
	kb_event_path = path


## Sets the associated ManagedGamepad so it can recieve virtual device events
## that are mapped via the mapped_events Array.
func set_gamepad_device(gamepad: ManagedGamepad) -> void:
	gamepad_device = gamepad
	if open() != OK:
		logger.warn("Unable to open extra handheld buttons device")
		return
	logger.debug("Configured extra handheld buttons device")
