@icon("res://assets/editor-icons/godotengine.svg")
extends MappableEvent
class_name NativeEvent

@export var event: InputEvent


func matches(event: MappableEvent) -> bool:
	if not event is NativeEvent:
		return false
	
	return false


## Set the given value on the event. How this gets set depends on the underlying
## Godot event.
func set_value(value: float) -> void:
	if not event:
		return
	if event is InputEventAction:
		event.pressed = value == 1
	elif event is InputEventKey:
		event.pressed = value == 1
	elif event is InputEventJoypadButton:
		event.pressed = value == 1
	elif event is InputEventMouseButton:
		event.pressed = value == 1
	elif event is InputEventMouseMotion:
		# The "relative" property acts as a mask to determine which values should
		# be set.
		var position := Vector2.ZERO
		if event.relative.x == 1:
			position.x = value
		if event.relative.y == 1:
			position.y = value
		event.position = position


func get_value() -> float:
	if not event:
		return 0
	if event is InputEventAction:
		return 1 if event.pressed else 0
	elif event is InputEventKey:
		return 1 if event.pressed else 0
	elif event is InputEventJoypadButton:
		return 1 if event.pressed else 0
	elif event is InputEventMouseButton:
		return 1 if event.pressed else 0
	elif event is InputEventMouseMotion:
		# The "relative" property acts as a mask to determine which values should
		# be returned.
		if event.relative.x == 1:
			return event.position.x
		elif event.relative.y == 1:
			return event.position.y
		return 0
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
