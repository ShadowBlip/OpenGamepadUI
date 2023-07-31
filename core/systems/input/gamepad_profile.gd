@icon("res://assets/ui/icons/gamepad-bold.svg")
extends Resource
class_name GamepadProfile

## A gamepad profile is a managed gamepad profile that can remap inputs.
##
## A gamepad profile describes a controller mapping. With it, you can map
## controller inputs to keyboard and mouse actions, or other gamepad actions.

## Name of the gamepad profile
@export var name: String
@export var mapping: Array[GamepadMapping]

# Map of an event signature to a gamepad mapping. This is used to try and do
# fast lookups of events.
var _mapping_dict: Dictionary = {}
var logger := Log.get_logger("GamepadProfile")


## Sorts the event mappings for faster lookup. This is done by getting the
## "event signature" from all the source events. The event signature identifies
## the kind of event it is (e.g. an EvdevEvent with EV_KEY and BTN_SOUTH)
func load_mappings() -> void:
	for item in mapping:
		var signature := item.source_event.get_signature()
		if signature in _mapping_dict:
			logger.debug("Signature already exists in mapping cache")
			continue
		_mapping_dict[signature] = item


## Get the profile's gamepad mapping for the given event. This will return null
## if no mapping was found.
func get_mapping_for(event: MappableEvent) -> GamepadMapping:
	var signature := event.get_signature()
	if signature in _mapping_dict:
		return _mapping_dict[signature]
	return null


## Get the profile's gamepad mapping for the given event. This will return null
## if no mapping was found. (SLOW)
func find_mapping_for(event: MappableEvent) -> GamepadMapping:
	for mapping in mapping:
		if not mapping.source_event:
			continue
		if not mapping.source_event.matches(event):
			continue

		return mapping
	
	return null
