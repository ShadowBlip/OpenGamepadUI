extends Resource
class_name MappedEvent

@export var activation_keys: Array[InputDeviceEvent]
@export var event_list: Array[InputDeviceEvent]
@export var ogui_event: String
@export var on_release: bool = false


func get_mapped_events() -> Array[InputDeviceEvent]:
	return event_list


func matches(active_keys: Array[InputDeviceEvent]) -> bool:
	var i := 0
	for key in active_keys:
		if not _is_same_event(active_keys[i], activation_keys[i]):
			return false
		i +=1
	return true


func _is_same_event(event1: InputDeviceEvent, event2: InputDeviceEvent) -> bool:
	if event1.type == event2.type:
		if event1.code == event2.code:
			if event1.value == event2.value:
				return true
	return false
