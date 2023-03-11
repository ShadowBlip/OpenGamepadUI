extends Resource
class_name MappedEvent
## List of events that will trigger this MappedEvent
@export var activation_keys: Array[InputDeviceEvent]
## List of events that are tiggered by this MappedEvent
@export var event_list: Array[InputDeviceEvent]
## String correlating to an ogui_event. If set takes precendence over event_list
@export var ogui_event: String
## Set true if event should be queued during "press" event and fired during "release" event.
@export var on_release: bool = false

## Will show logger events with the prefix MappedEvent
var logger := Log.get_logger("MappedEvent", Log.LEVEL.DEBUG)


## Checks if the given Array of InputDeviceEvent's matches the event_list array.
func effect_matches (active_event: Array[InputDeviceEvent]) -> bool:
	logger.debug("Checking active keys against key activators")
	var i := 0
	if active_event.size() != event_list.size() or active_event.size() == 0:
		logger.debug("Event list too short")
		return false
	for key in active_event:
		if not _is_same_event(active_event[i], event_list[i]):
			return false
		i +=1
	return true


## Checks if the given Array of InputDeviceEvent's matches the activation_keys array.
func activate_matches(active_keys: Array[InputDeviceEvent]) -> bool:
	logger.debug("Checking active keys against key activators")
	var i := 0
	if active_keys.size() != activation_keys.size() or active_keys.size() == 0:
		logger.debug("Event list too short")
		return false
	for key in active_keys:
		if not _is_same_event(active_keys[i], activation_keys[i]):
			return false
		i +=1
	return true


## Checks if event1 matches event2
func _is_same_event(event1: InputDeviceEvent, event2: InputDeviceEvent) -> bool:
	logger.debug("checking type:" + str(event1.type) + " code: "  + str(event1.code) + " value: "  + str(event1.value))
	logger.debug("against type:" + str(event2.type) + " code: "  + str(event2.code) + " value: "  + str(event2.value))
	if event1.type == event2.type:
		logger.debug("event1.type is the same as event2.type")
		if event1.code == event2.code:
			logger.debug("event1.code is the same as event2.code")
			if event1.value == event2.value:
				logger.debug("event1.value is the same as event2.value")
				return true
	logger.debug("But that was all that matched")
	return false
