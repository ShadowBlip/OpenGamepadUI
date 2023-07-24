extends Resource
class_name MappableEvent

## Base class for events that can be translated from one type to another
##
## This class is not meant to be used directly.


## Returns true if the given event matches. This should be overriden in each
## child implementation.
func matches(event: MappableEvent) -> bool:
	return false


func set_value(value: float) -> void:
	pass


func get_value() -> float:
	return 0
