extends MappableEvent
class_name HandheldEventMapping

## Name of the event to emit
@export var name: String
## List of events that will trigger this MappedEvent.
@export var activation_keys: Array[EvdevEvent]
## Emits this event when the activation keys are triggered
@export var emits: HandheldEvent


## Will show logger statements in the event log with the prefix [HandheldEventMapping].
var logger := Log.get_logger("HandheldEventMapping", Log.LEVEL.INFO)


## Checks if the given Array of InputDeviceEvent's matches the event_list array.
func output_events_match(active_event: Array[EvdevEvent]) -> bool:
#	logger.debug("Checking active events against event list.")
	if active_event.size() != activation_keys.size() or active_event.size() == 0:
#		logger.debug("Event list too short")
		return false
	for i in active_event.size():
		if not _is_same_event(active_event[i], activation_keys[i]):
#			logger.debug("Event list doesn't match active event")
			return false
	return true


## Checks if the given Array of InputDeviceEvent's matches the activation_keys array.
func trigger_events_match(active_keys: Array[EvdevEvent]) -> bool:
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
func _is_same_event(event1: EvdevEvent, event2: EvdevEvent) -> bool:
	if event1.type == event2.type:
		if event1.code == event2.code:
			if event1.value == event2.value:
				return true
	return false
