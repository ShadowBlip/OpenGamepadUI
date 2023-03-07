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
	active_keys.sort()
	_check_event_match()


# Called to handle an individual event. Sets the active keys.
func _process_event(event: InputDeviceEvent) -> void:
	# Always skip anytihng thats not a button
	if event.get_type() != event.EV_KEY:
		return
	# release event, remove active keys
	if event.value == 0:
		var index := _find_active(event)
		if index >= 0:
			active_keys.remove_at(index)
			_on_release_event()
		return

	if _find_active(event) >= 0:
		return

	active_keys.append(event)


func _find_active(event: InputDeviceEvent) -> int:
	var i := 0
	for active_event in active_events:
		if active_event.code == event.code and active_event.value == event.value:
			return i
		i += 1
	return -1


func _on_release_event() -> void:
	var events_to_clear: Array[InputDeviceEvent] = []
	for active_event in active_events:
		var input_action := InputEventAction.new()
		if active_event.ogui_event != "" and input_action.is_action(active_event.ogui_event):
			_send_input(input_action, active_event.ogui_event, false)
		active_event.value = 0
		_emit_event(active_event)
		events_to_clear.append(active_event)
	if events_to_clear != []:
		for clear_event in events_to_clear:
			if queued_events.has(clear_event):
				queued_events.erase(clear_event)
			active_events.erase(clear_event)
		return
	for queued_event in queued_events:
		_emit_event(queued_event)
		active_events.append(queued_event)


# Called after processing all events in the event loop. Checks if our current
# active_keys matches any of our mapped events. 
func _check_event_match() -> void:
	logger.debug("Active keys: " + str(active_keys))
	for mapped_event in mapped_events:
		if mapped_event.matches(active_keys):
			if mapped_event.on_release == true:
				queued_events.append(mapped_event.event_list)
				return
			var input_action := InputEventAction.new()
			if mapped_event.ogui_event != "" and input_action.is_action(mapped_event.ogui_event):
				_send_input(input_action, mapped_event.ogui_event, true)
				return
			for event in mapped_event.event_list:
				_emit_event(event)
			active_events.append(mapped_event.event_list)
			# Clear and queued events because we overrode it with an on_press event
			queued_events.clear()


# Emits a virtual device event.
func _emit_event(event: InputDeviceEvent) -> void:
	gamepad_device.virt_device.write_event(event.type, event.code, event.value)


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
	if gamepad.get_phys() == gamepad_phys_path and gamepad.get_name() == gamepad_phys_name:
		return true
	return false


func is_found_kb(device: InputDevice) -> bool:
	if device.get_phys() == kb_phys_path and device.get_name() == kb_phys_name:
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

