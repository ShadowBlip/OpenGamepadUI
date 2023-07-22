@icon("res://assets/ui/icons/gamepad-bold.svg")
extends ManagedGamepad
class_name HandheldGamepad

const AudioManager := preload("res://core/global/audio_manager.tres")
var platform := load("res://core/global/platform.tres") as Platform

## List of virtual events that are currently held.
var active_events: Array[EvdevEvent]
## List of keys and their values that are currently pressed.
var active_keys: Array[EvdevEvent]
## evdev character file path for the keybaord/mouse device
var kb_event_path: String
## The physical keyboard/mouse device we are mapping input from.
var keypads: Array[Keypad]
## List of vitural events that will be emitted upon release of the held key.
var queued_events: Array[HandheldEvent]
#var queued_ogui_events: PackedStringArray
### List of ogui events that are currently held.
#var sent_ogui_events: PackedStringArray


func _init() -> void:
	logger = Log.get_logger("HandheldGamepad", Log.LEVEL.INFO)


## Setup the given keyboard devices for the handheld gamepad
func setup(keyboards: Array[InputDevice]) -> void:
	for keyboard in keyboards:
		var keypad := Keypad.new()
		keypad.device = keyboard
		keypad.event_path = keyboard.get_path()
		
		# Grab exclusive access over the physical device
		if not "--disable-grab-gamepad" in OS.get_cmdline_args():
			var result := keyboard.grab(true)
			if result != OK:
				logger.error("Unable to grab " + keyboard.get_name())
				continue
			logger.debug("Grabbed " + keyboard.get_name())
		
		keypads.append(keypad)


## Main process thread for input translation from one device to another.
func process_input() -> void:
	# Call the gamepad's process input
	super()
	
	# Process the input for all handheld keypads
	for keypad in keypads:
		# Only process input if we have a valid handle
		if not keypad.device or not keypad.device.is_open():
			return
		
		# Process all physical input events
		var events := keypad.device.get_events()
		
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
			var evdev_event := EvdevEvent.from_input_device_event(event)
			if not _process_event(evdev_event):
				stop_after_process = true
			
			# If no keys are active we can stop here.
			if stop_after_process:
				logger.debug("We were told to stop after process")
				continue
			if active_keys.size() == 0:
				logger.debug("No active keys")
				continue
			
			_check_mapped_events()


## Called to handle an individual event. Sets the active keys.
func _process_event(event: EvdevEvent) -> bool:
	# Always skip anything thats not a button
	if event.get_type() not in [event.EV_KEY]:
		return true
	
	# Ignore this code, its linux kernel reserved and causes issues.
	if event.get_code() == 0:
		return true
	
	# release event, remove active keys
	logger.debug("event: type " + str(event.type) + " event: code " + str(event.code) + " value " + str(event.value))
	if event.value == 0:
		return _on_key_up(event)
		
	# Block adding the same active event twice
	if _find_active_key(event) >= 0:
		logger.debug("Already Active! Keys:")
		for key in active_keys:
			logger.debug(str(key.get_type()) + " : " +str(key.get_code()) + " : " +str(key.get_value()))
		return false
		
	return _on_key_down(event)


## Called for key down events.
func _on_key_down(event: EvdevEvent) -> bool:
	logger.debug("______ Key __DOWN__ event ______")
	active_keys.insert(active_keys.bsearch_custom(event, _sort_events), event)
	logger.debug("Active keys:")
	for key in active_keys:
		logger.debug(str(key.get_type()) + " : " +str(key.get_code()) + " : " +str(key.get_value()))
		
	return true


## Called for key up events.
func _on_key_up(event: EvdevEvent) -> bool:
	# Ignore if the active keys list is empty.
	if active_keys.size() == 0:
		return false
	logger.debug("------ Key --UP-- event ------")
	
	# Some keys might be active with two values, clear them all.
	active_keys.clear()
	logger.debug("Active keys:")
	for key in active_keys:
		logger.debug(str(key.get_type()) + " : " +str(key.get_code()) + " : " +str(key.get_value()))
		
	return false


## Translates the given event to an AudioManager event.
func _do_audio_event(event_type: int, event_code: int, event_value: int) -> void:
	# Ignore key up events.
	if event_value == 0:
		logger.debug("Got key_up event for audio_event")
		return
	logger.debug("Got audio event: " + str(event_code) + str(event_value))
	var return_code: int
	match event_code:
		InputDeviceEvent.KEY_MUTE:
			AudioManager.call_deferred("toggle_mute")
		InputDeviceEvent.KEY_VOLUMEDOWN:
			AudioManager.call_deferred("set_volume", -0.06, AudioManager.VOLUME.RELATIVE)
		InputDeviceEvent.KEY_VOLUMEUP:
			AudioManager.call_deferred("set_volume", 0.06, AudioManager.VOLUME.RELATIVE)
		_:
			logger.warn("Event with type" + str(event_type) + " and code: " + str(event_code) + " is not supported.")


## Called after processing all events in the event loop. Checks if our current
## active_keys matches any of our mapped events.
func _check_mapped_events() -> void:
	if not platform or not platform.platform is HandheldPlatform:
		logger.debug("No handheld platform was defined!")
		return
	var handheld_platform := platform.platform as HandheldPlatform

	logger.debug("Checking events for matches")
	for mapped_event in handheld_platform.key_map:
		if not mapped_event.trigger_events_match(active_keys):
			continue
		
		logger.debug("Found a matching event")
		inject_event(mapped_event.emits)


# Sends an ogui_event input action to the event queue
#func _send_input(input_action: InputEventAction, action: String, pressed: bool, strength: float = 1.0) -> void:
#	input_action.action = action
#	input_action.pressed = pressed
#	input_action.strength = strength
#	Input.parse_input_event(input_action)


## Returns the index of an active key.
func _find_active_key(event: EvdevEvent) -> int:
	for i in active_keys.size():
		if active_keys[i].type == event.type and \
		active_keys[i].code == event.code and \
		active_keys[i].value == event.value:
			return i
	return -1


## Custom sort method that returns true if the first InputDeviceEvent  is less 
## than the second InputDeviceEvent.  Checks type, then code, then value.
func _sort_events(event1: InputDeviceEvent, event2: InputDeviceEvent) -> bool:
	if event1.get_type() != event2.get_type():
		return event1.get_type() < event2.get_type()
	if event1.get_code() != event2.get_code():
		return event1.get_code() < event2.get_code()
	return event1.get_value() < event2.get_value()


## Structure representing a handheld keypad device
class Keypad:
	var device: InputDevice
	var event_path: String
