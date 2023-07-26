@icon("res://assets/editor-icons/mind-map.svg")
extends MappableEvent
class_name HandheldEventMapping

## Name of the event to emit
@export var name: String
## List of events that will trigger this MappedEvent.
@export var activation_keys: Array[EvdevEvent]
## Emits this event when the activation keys are triggered
@export var emits: MappableEvent

## Will show logger statements in the event log with the prefix [HandheldEventMapping].
var logger := Log.get_logger("HandheldEventMapping", Log.LEVEL.INFO)


## Checks if the given Array of EvdevEvents matches the activation_keys array.
func output_events_match(active_event: Array[EvdevEvent]) -> bool:
#	logger.debug("Checking active events against event list.")
	if active_event.size() != activation_keys.size() or active_event.size() == 0:
#		logger.debug("Event list too short")
		return false
	for i in active_event.size():
		if not active_event[i].matches(activation_keys[i]):
#			logger.debug("Event list doesn't match active event")
			return false
	return true


## Checks if the given Array of EvdevEvents matches the activation_keys array.
func trigger_events_match(active_keys: Array[EvdevEvent]) -> bool:
#	logger.debug("Checking active keys against key actvation keys.")
	if active_keys.size() != activation_keys.size() or active_keys.size() == 0:
#		logger.debug("Event list too short. Active_keys.size():" + str(active_keys.size()) + " Activation_keys.size(): " + str(activation_keys.size()))
		return false
	for i in active_keys.size():
#		logger.debug("Checking event " + str(active_keys[i].get_event_type()) + " " + str(active_keys[i].get_event_code()))
#		logger.debug("Against event " + str(activation_keys[i].get_event_type()) + " " + str(activation_keys[i].get_event_code()))
		if not activation_keys[i].matches(active_keys[i]):
#			logger.debug("Activation list doesn't match active keys.")
			return false
	return true
