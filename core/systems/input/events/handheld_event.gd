@icon("res://assets/editor-icons/game-console.svg")
extends MappableEvent
class_name HandheldEvent

## Arbitrary event from a handheld controller

@export var name: String
var value: float


func matches(event: MappableEvent) -> bool:
	if not event is HandheldEvent:
		return false
	if event.name == name:
		return true
	return false


func set_value(v: float) -> void:
	value = v


func get_value() -> float:
	return value
