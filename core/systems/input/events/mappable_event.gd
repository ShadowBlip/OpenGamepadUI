extends Resource
class_name MappableEvent

## Base class for events that can be translated from one type to another
##
## This class is not meant to be used directly.


## Returns true if the given event matches. This should be overriden in each
## child implementation.
func matches(event: MappableEvent) -> bool:
	return false


## Set the given value on the event. This should be overriden in each child
## implementation
func set_value(value: float) -> void:
	pass


## Return the underlying value of the event. This should be overidden in each
## child class
func get_value() -> float:
	return 0


## Returns a signature of the event to aid with faster matching. This signature
## should return a unique string based on the kind of event but not the value.
func get_signature() -> String:
	return ""


## Returns whether or not the given event only uses binary values (e.g. pressed
## or not pressed). Defaults to true.
func is_binary_event() -> bool:
	return true
