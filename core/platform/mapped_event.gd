extends Resource
class_name MappedEvent
## List of events that will trigger this MappedEvent.
@export var activation_keys: Array[InputDeviceEvent]
## List of events that are tiggered by this MappedEvent.
@export var event_list: Array[InputDeviceEvent]
## String correlating to an ogui_event. If set, takes precendence over
## event_list and ignores on_release.
@export var ogui_event: String
## Set true if event should be queued during "press" event and fired during
## "release" event. Only applies to the event_list.
@export var on_release: bool = false

## Will show logger statements in the event log with the prefix [MappedEvent].
var logger := Log.get_logger("MappedEvent", Log.LEVEL.DEBUG)


## Checks if the given Array of InputDeviceEvent's matches the event_list array.
func output_events_match(active_event: Array[InputDeviceEvent]) -> bool:
#	logger.debug("Checking active events against event list.")
	if active_event.size() != event_list.size() or active_event.size() == 0:
#		logger.debug("Event list too short")
		return false
	for i in active_event.size():
		if not _is_same_event(active_event[i], event_list[i]):
#			logger.debug("Event list doesn't match active event")
			return false
	return true


## Checks if the given Array of InputDeviceEvent's matches the activation_keys array.
func trigger_events_match(active_keys: Array[InputDeviceEvent]) -> bool:
#	logger.debug("Checking active keys against key actvation keys.")
	if active_keys.size() != activation_keys.size() or active_keys.size() == 0:
#		logger.debug("Event list too short")
		return false
	for i in active_keys.size():
		if not _is_same_event(activation_keys[i], active_keys[i]):
#			logger.debug("Activation list doesn't match active keys.")
			return false
	return true


## Checks if event1 matches event2
func _is_same_event(event1: InputDeviceEvent, event2: InputDeviceEvent) -> bool:
	if event1.type == event2.type:
		if event1.code == event2.code:
			if event1.value == event2.value:
				return true
	return false
