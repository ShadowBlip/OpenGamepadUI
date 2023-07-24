@icon("res://assets/editor-icons/godotengine.svg")
extends MappableEvent
class_name NativeEvent

@export var event: InputEvent


func matches(event: MappableEvent) -> bool:
	if not event is NativeEvent:
		return false
	
	return false
