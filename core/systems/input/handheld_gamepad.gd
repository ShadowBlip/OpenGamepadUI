@icon("res://assets/ui/icons/gamepad-bold.svg")
extends ManagedGamepad
class_name HandheldGamepad

var platform := load("res://core/global/platform.tres") as Platform
var device_hider := load("res://core/systems/input/device_hider.tres") as DeviceHider

## List of keys and their values that are currently pressed.
var active_keys: Array[EvdevEvent]
## The physical keyboard/mouse device we are mapping input from.
var keypads: Array[Keypad]


func _init() -> void:
	logger = Log.get_logger("HandheldGamepad", Log.LEVEL.DEBUG)
	

## Setup the given keyboard devices for the handheld gamepad
func setup(keyboards: Array[InputDevice]) -> void:
	for keyboard in keyboards:
		var keypad := Keypad.new()
		keypad.device = keyboard
		keypad.event_path = keyboard.get_path()
		
		# Try to hide the keyboard device
		var hidden_path := await device_hider.hide_event_device(keypad.event_path)
		if hidden_path == "":
			logger.warn("Unable to hide handheld keypad: " + keypad.event_path)
			logger.warn("Opening the raw handheld keypad instead")
			# Try to open the non-hidden device instead
			hidden_path = keypad.event_path

		# Grab exclusive access over the physical device
		if not "--disable-grab-gamepad" in OS.get_cmdline_args():
			var result := keyboard.grab(true)
			if result != OK:
				logger.error("Unable to grab " + keyboard.get_name())
				continue
			logger.debug("Grabbed " + keyboard.get_name())
		
		keypads.append(keypad)


## Returns the capabilities of the gamepad
func get_capabilities() -> Array[MappableEvent]:
	# Get the gamepad capabilities to start with. This is implemented by
	# [ManagedGamepad].
	var capabilities := super()
	var handheld_platform := platform.platform as HandheldPlatform
	
	for mapped_event in handheld_platform.key_map:
		capabilities.append(mapped_event.emits)

	return capabilities


## Main process thread for input translation from one device to another.
func process_input() -> void:
	# Call the gamepad's process input
	super()

	# Calculate the amount of time that has passed since last invocation
	var current_time := Time.get_ticks_usec()
	var delta_us := current_time - _last_time
	_last_time = current_time
	var delta := delta_us / 1000000.0  # Convert to seconds

	# Process the input for all handheld keypads
	for keypad in keypads:
		# Only process input if we have a valid handle
		if not keypad.device or not keypad.device.is_open():
			logger.warn("Problem with keypad!")
			continue

		# Process all physical input events
		var events := keypad.device.get_events()

		# Prevents multi-button combos from firing/queuing an event if the first
		# released leaves an active_keys array that matches a trigger event.
		# Any time a key is pressed there is always an EV_KEY with code 0 and value 0.
		if events.size() <= 1:
			continue

		logger.debug(keypad.device.get_name() + " : " + keypad.device.get_phys())
		# Loop through events and check if we need to do anything, then do it.
		for event in events:
			if not event or not event is InputDeviceEvent:
				continue
			var evdev_event := EvdevEvent.from_input_device_event(event)
			_process_event(evdev_event, delta)


## Called to handle an individual event. Sets the active keys.
func _process_event(event: EvdevEvent, delta: float) -> void:
	# Always skip anything thats not a button
	if event.get_event_type() != InputDeviceEvent.EV_KEY:
		return
	# Ignore this code, its linux kernel reserved and causes issues.
	if event.get_event_code() == 0:
		return

	# Ignore this event if we want to filter it
	if _filter_event(event):
		return

	# release event, remove active keys
	logger.debug("event: type " + str(event.get_event_type()) + " event: code " + str(event.get_event_code()) + " value " + str(event.get_event_value()))
	if event.get_event_value() == 0:
		_on_key_up(event, delta)
		return

	_on_key_down(event)
	_check_mapped_events(event.get_event_value(), delta)


## Called for key down events.
func _on_key_down(event: EvdevEvent) -> void:
	# Block adding the same active event twice
	if _find_active_key(event) >= 0:
		logger.debug("Already Active! Keys:")
		for key in active_keys:
			logger.debug(str(key.get_event_type()) + " : " +str(key.get_event_code()) + " : " +str(key.get_event_value()))
		return
	
	# Update existing keys if the value changed
	var idx := _find_updatable_key(event)
	if idx >= 0:
		logger.debug("Found updatable key!")
		active_keys[idx].set_value(event.get_value())
		return
		
	logger.debug("______ Key __DOWN__ event ______")
	active_keys.insert(active_keys.bsearch_custom(event, _sort_events), event)
	logger.debug("Active keys:")
	for key in active_keys:
		logger.debug(str(key.get_event_type()) + " : " +str(key.get_event_code()) + " : " +str(key.get_event_value()))


## Called for key up events.
func _on_key_up(event: EvdevEvent, delta: float) -> bool:
	# Ignore if the active keys list is empty.
	if active_keys.size() == 0:
		return false
	logger.debug("------ Key --UP-- event ------")
	var to_remove: Array[EvdevEvent]
	# Some keys might be active with two values, clear them all.
	for active_key in active_keys:
		if not event.matches(active_key):
			continue
		_check_mapped_events(event.get_event_value(), delta)
		to_remove.append(active_key)
		
	for key in to_remove:
		active_keys.erase(key)

	logger.debug("Active keys:")
	for key in active_keys:
		logger.debug(str(key.get_event_type()) + " : " +str(key.get_event_code()) + " : " +str(key.get_event_value()))

	return false


## Called after processing all events in the event loop. Checks if our current
## active_keys matches any of our mapped events.
func _check_mapped_events(value: float, delta: float) -> void:
	if not platform or not platform.platform is HandheldPlatform:
		logger.debug("No handheld platform was defined!")
		return
	var handheld_platform := platform.platform as HandheldPlatform

	logger.debug("Checking events for matches")
	
	for mapped_event in handheld_platform.key_map:
		if not mapped_event.trigger_events_match(active_keys):
			continue

		logger.debug("Found a matching event. Emitting event: " + str(mapped_event.emits))
		var event := mapped_event.emits.duplicate(true)
		event.set_value(value)
		inject_event(event, delta)


# Checks if the given event is part of the handheld_platform's filter_events array.
func _filter_event(event: EvdevEvent) -> bool:
	if not platform or not platform.platform is HandheldPlatform:
		logger.debug("No handheld platform was defined!")
		return false

	var handheld_platform := platform.platform as HandheldPlatform
	if handheld_platform.filtered_events.size() == 0:
		return false

	logger.debug("Checking if event should be filtered.")
	for filtered_event in handheld_platform.filtered_events:
		if filtered_event.matches(event):
			logger.debug("Event will be filtered: " + str(event))
			return true

	return false


## Returns the index of an active key.
func _find_active_key(event: EvdevEvent) -> int:
	for i in active_keys.size():
		if active_keys[i].get_event_type() == event.get_event_type() and \
		active_keys[i].get_event_code() == event.get_event_code() and \
		active_keys[i].get_event_value() == event.get_event_value():
			return i
	return -1


## Returns the index of an active key who's value does not match.
func _find_updatable_key(event: EvdevEvent) -> int:
	for i in active_keys.size():
		if active_keys[i].get_event_type() == event.get_event_type() and \
		active_keys[i].get_event_code() == event.get_event_code() and \
		active_keys[i].get_event_value() != event.get_event_value():
			return i
	return -1


## Custom sort method that returns true if the first EvdevEvent is less 
## than the second EvdevEvent.  Checks type, then code, then value.
func _sort_events(event1: EvdevEvent, event2: EvdevEvent) -> bool:
	if event1.get_event_type() != event2.get_event_type():
		return event1.get_event_type() < event2.get_event_type()
	if event1.get_event_code() != event2.get_event_code():
		return event1.get_event_code() < event2.get_event_code()
	return event1.get_event_value() < event2.get_event_value()


## Structure representing a handheld keypad device
class Keypad:
	var device: InputDevice
	var event_path: String
