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
