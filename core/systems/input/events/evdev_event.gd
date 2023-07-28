@icon("res://assets/editor-icons/integrated-circuit.svg")
extends MappableEvent
class_name EvdevEvent

var input_device_event: InputDeviceEvent


func _init() -> void:
	input_device_event = InputDeviceEvent.new()


func matches(event: MappableEvent) -> bool:
	if not event is EvdevEvent:
		return false
	return event.input_device_event.code == input_device_event.code and \
		event.input_device_event.type == input_device_event.type


func equals(event: MappableEvent) -> bool:
	if not event is EvdevEvent:
		return false
	return event.input_device_event.code == input_device_event.code and \
		event.input_device_event.type == input_device_event.type and \
		event.input_device_event.value == input_device_event.value


func set_value(value: float) -> void:
	input_device_event.value = value


func get_value() -> float:
	return input_device_event.value


func get_event_type() -> int:
	return input_device_event.type


func get_event_code() -> int:
	return input_device_event.code


func get_event_value() -> int:
	return input_device_event.value


func to_input_device_event() -> InputDeviceEvent:
	return input_device_event

func _to_string() -> String:
	return "<EvdevEvent-Type: " + str(get_event_type()) + ", Code: " + str(get_event_code()) + ", Value: " + str(get_event_value()) + ">"


## Create a new [EvdevEvent] from the given [InputDeviceEvent]
static func from_input_device_event(event: InputDeviceEvent) -> EvdevEvent:
	var evdev_event := EvdevEvent.new()
	evdev_event.input_device_event = event
	return evdev_event
