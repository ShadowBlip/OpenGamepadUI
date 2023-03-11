extends Resource
class_name HandheldGamepad


var active_keys: Array[InputDeviceEvent]
var active_events: Array[InputDeviceEvent]
var queued_events: Array[InputDeviceEvent]
var kb_device: InputDevice
var gamepad_device: ManagedGamepad
var kb_event_path: String # path of /dev/input/eventX

## Override below in device specific implementation

## Mapping of active_keys entry to list of InputDeviceEvent. Bool on_release
## determines if this event should be queued to trigger when the activated button
## is pressed (false) or released (true)
## e.g. {[[125, 1]]: [[event.EV_KEY, event.BTN_MODE]]}
@export var mapped_events: Array[MappedEvent]
## Path of the device in sysfs ATTR{phys}
@export var kb_phys_path: String
## Name of the device in sysfs ATTR{name}
@export var kb_phys_name: String
## Path of the device in sysfs ATTR{phys}
@export var gamepad_phys_path: String
## Name of the device in sysfs ATTR{name}
@export var gamepad_phys_name: String

var logger := Log.get_logger("HandheldGamepad", Log.LEVEL.DEBUG)


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
	if active_keys.size() == 0:
		return
	active_keys.sort_custom(_sort_events)
	_check_event_match()


# Called to handle an individual event. Sets the active keys.
func _process_event(event: InputDeviceEvent) -> void:
	# Always skip anything thats not a button
	if event.get_type() != event.EV_KEY:
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

func _find_active_key(event: InputDeviceEvent) -> int:
	var i := 0
	for active_key in active_keys:
		if active_key.code == event.code:
			return i
		i += 1
	return -1


func _find_active_event(event: InputDeviceEvent) -> int:
	var i := 0
	for active_event in active_events:
		if active_event.code == event.code:
			return i
		i += 1
	return -1


func _on_release_event() -> void:
	if active_events.size() == 0:
		return
	for active_event in active_events:
		# Send release events for active events and queue thier removal
		active_event.value = 0
		_emit_event(active_event.get_type(), active_event.get_code(), active_event.get_value())
	active_events.clear()
		
	# Any events that were queued as "on release" should now be activated.
	# Clear events will hit on next loop
	for queued_event in queued_events:
		_emit_event(queued_event.get_type(), queued_event.get_code(), queued_event.get_value())
	active_events = queued_events.duplicate()
	queued_events.clear()


# Called after processing all events in the event loop. Checks if our current
# active_keys matches any of our mapped events. 
func _check_event_match() -> void:
	logger.debug("Mapped events: " + str(mapped_events))
	for mapped_event in mapped_events:
		if mapped_event.activate_matches(active_keys):
			if mapped_event.effect_matches(active_events):
				logger.debug("Matching event already activated")
				return
			if mapped_event.effect_matches(queued_events):
				logger.debug("Matching event already queued.")
				return
			logger.debug("Found a mapped event")
			if mapped_event.on_release == true:
				logger.debug("queue events!")
				queued_events = mapped_event.event_list.duplicate()
				logger.debug("Queued events: " + str(queued_events))
				return
			var input_action := InputEventAction.new()
			if mapped_event.ogui_event != "":
				input_action.action = mapped_event.ogui_event
				if not input_action.is_action(mapped_event.ogui_event):
					logger.warn("Listed ogui_event \"" + mapped_event.ogui_event + "\" does not correlate to a known event. Verify configuration of gamepad.")
					return
				logger.debug("emit ogui_event!")
				_send_input(input_action, mapped_event.ogui_event, true)
				return
			if mapped_event.event_list.size() == 0:
				logger.warn("No events list or ogui_event mapping for active keys. Verify configuration of gamepad.")
				return
			logger.debug("emit events!")
			for event in mapped_event.event_list:
				logger.debug("Emit event:" + str(event.type) + " code: "  + str(event.code) + " value: "  + str(event.value))
				_emit_event(event.get_type(), event.get_code(), event.get_value())
			active_events = mapped_event.event_list.duplicate()
			logger.debug("Active events: " + str(active_events))
			# Clear and queued events because we overrode it with an on_press event
			queued_events.clear()
			return


# Emits a virtual device event.
func _emit_event(type: int, code: int, value: int) -> void:
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


func is_found_gamepad(gamepad: ManagedGamepad) -> bool:
	if gamepad.phys_device.get_phys() == gamepad_phys_path and gamepad.phys_device.get_name() == gamepad_phys_name:
		logger.info("Found handheld gamepad device: " + gamepad.phys_device.get_name())
		return true
	return false


func is_found_kb(device: InputDevice) -> bool:
	logger.debug("Checking input device: " + device.get_name())
	if device.get_phys() == kb_phys_path and device.get_name() == kb_phys_name:
		logger.info("Found handheld input device: " + device.get_name())
		return true
	return false


func set_kb_event_path(path: String) -> void:
	kb_event_path = path


func set_gamepad_device(gamepad: ManagedGamepad) -> void:
	gamepad_device = gamepad
	if open() != OK:
		logger.warn("Unable to open extra handheld buttons device")
		return
	logger.debug("Configured extra handheld buttons device")


## Returns true if the first element code is less than the second element code.
## If both elements have the same code, returns true if the first elements value
## is less than the second elements value.
func _sort_events(event1: InputDeviceEvent, event2: InputDeviceEvent) -> bool:
	if event1.code != event2.code:
		return event1.code < event2.code
	return event1.value < event2.value
