extends Resource
class_name GamepadAxesMapping

## Structure for holding the X/Y event mappings for multi-axis pair
##
## Helps to join a pair of [GamepadMapping]

## The 'X' axis mapping
@export var x: GamepadMapping

## The 'Y' axis mapping
@export var y: GamepadMapping


## Returns true if the given event matches any axis
func matches(event: MappableEvent) -> bool:
	if not event:
		return false
	var signature := event.get_signature()
	if x and x.source_event and x.source_event.get_signature() == signature:
		return true
	if y and y.source_event and y.source_event.get_signature() == signature:
		return true

	return false
