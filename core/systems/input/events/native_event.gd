@icon("res://assets/editor-icons/godotengine.svg")
extends MappableEvent
class_name NativeEvent

@export var event: InputEvent


func matches(event: MappableEvent) -> bool:
	if not event is NativeEvent:
		return false
	
	return false


func set_value(value: float) -> void:
	if not event:
		return
	if event is InputEventAction:
		event.pressed = value == 1


func get_value() -> float:
	if not event:
		return 0
	if event is InputEventAction:
		return event.pressed
	return 0


## Returns a signature of the event to aid with faster matching. This signature
## should return a unique string based on the kind of event but not the value.
func get_signature() -> String:
	var kind := str(event)
	if event is InputEventAction:
		kind = "Action:" + event.action
	elif event is InputEventKey:
		kind = "Key:" + str(event.keycode)
	# TODO: Do we need to make a signature for other native events?
	return "Native:" + kind


func is_binary_event() -> bool:
	if event is InputEventJoypadMotion:
		return false
	if event is InputEventMouseMotion:
		return false
	return true


func _to_string() -> String:
	return "<NativeEvent: " + str(event) + ">"
