@icon("res://assets/ui/icons/gamepad-bold.svg")
extends Resource
class_name GamepadProfile

## A gamepad profile is a managed gamepad profile that can remap inputs.
##
## A gamepad profile describes a controller mapping. With it, you can map
## controller inputs to keyboard and mouse actions, or other gamepad actions.

signal updated

## Name of the gamepad profile
@export var name: String
@export var mapping: Array[GamepadMapping]

@export_category("Mouse")
@export var mouse_speed_pps := 800

# Map of an event signature to a gamepad mapping. This is used to try and do
# fast lookups of events.
var _mapping_dict: Dictionary = {}
var _mutex := Mutex.new()
var logger := Log.get_logger("GamepadProfile")


## Add the given [GamepadMapping] to the [GamepadProfile].
func add(m: GamepadMapping) -> void:
	if not m:
		return
	if has_mapping_for(m.source_event):
		erase_mapping_for(m.source_event)
	_mutex.lock()
	mapping.append(m)
	_mutex.unlock()
	load_mappings()
	updated.emit()


## Erase the given gamepad mapping from the [GamepadProfile].
func erase(m: GamepadMapping) -> void:
	if not m or not m.source_event:
		return
	var signature := m.source_event.get_signature()
	_mutex.lock()
	_mapping_dict.erase(signature)
	mapping.erase(m)
	_mutex.unlock()
	updated.emit()


## Erase the [GamepadMapping] that matches the given source event from the 
## [GamepadProfile].
func erase_mapping_for(source_event: MappableEvent) -> void:
	var m := get_mapping_for(source_event)
	if not m:
		return
	erase(m)


## Sorts the event mappings for faster lookup. This is done by getting the
## "event signature" from all the source events. The event signature identifies
## the kind of event it is (e.g. an EvdevEvent with EV_KEY and BTN_SOUTH)
func load_mappings() -> void:
	for item in mapping:
		if not item.source_event:
			logger.warn("No source event specified for mapping!")
			continue
		var signature := item.source_event.get_signature()
		_mutex.lock()
		if signature in _mapping_dict:
			logger.debug("Signature already exists in mapping cache")
			_mutex.unlock()
			continue
		_mapping_dict[signature] = item
		_mutex.unlock()


## Returns true if the [GamepadProfile] as a [GamepadMapping] for the given event
func has_mapping_for(event: MappableEvent) -> bool:
	return get_mapping_for(event) != null


## Get the profile's gamepad mapping for the given event. This will return null
## if no mapping was found.
func get_mapping_for(event: MappableEvent) -> GamepadMapping:
	var signature := event.get_signature()
	
	# Lookup the mapping for the event
	_mutex.lock()
	if signature in _mapping_dict:
		var map := _mapping_dict[signature] as GamepadMapping
		_mutex.unlock()
		return map
	_mutex.unlock()
	return null


## Returns a [GamepadAxesMapping] of the given axis pair
func get_axes_mapping_for(x: MappableEvent, y: MappableEvent) -> GamepadAxesMapping:
	var axes_mapping := GamepadAxesMapping.new()
	axes_mapping.x = get_mapping_for(x)
	axes_mapping.y = get_mapping_for(y)

	return axes_mapping


## Get the profile's gamepad mapping for the given event. This will return null
## if no mapping was found. (SLOW)
func find_mapping_for(event: MappableEvent) -> GamepadMapping:
	_mutex.lock()
	for m in mapping:
		if not m.source_event:
			continue
		if not m.source_event.matches(event):
			continue

		_mutex.unlock()
		return m
	_mutex.unlock()

	return null
