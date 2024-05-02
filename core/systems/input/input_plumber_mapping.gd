extends Resource
class_name InputPlumberMapping

## Resource for a single mapping in an InputPlumber input profile
##
## This resource is used to represent a single mapping of a source event to
## a target event.

@export var name: String
@export var source_event: InputPlumberEvent
@export var target_events: Array[InputPlumberEvent]


static func from_dict(dict: Dictionary) -> InputPlumberMapping:
	var obj := InputPlumberMapping.new()
	if "name" in dict:
		obj.name = dict["name"]
	if "source_event" in dict:
		obj.source_event = InputPlumberEvent.from_dict(dict["source_event"] as Dictionary)
	if "target_events" in dict:
		var events: Array[InputPlumberEvent] = []
		var target_events_dicts := dict["target_events"] as Array
		for target_event_dict: Dictionary in target_events_dicts:
			var target_event := InputPlumberEvent.from_dict(target_event_dict)
			events.append(target_event)
		obj.target_events = events

	return obj


func to_dict() -> Dictionary:
	var dict := {
		"name": self.name,
	}
	if self.source_event:
		dict["source_event"] = self.source_event.to_dict()
	if self.target_events:
		var events := []
		for target_event: InputPlumberEvent in self.target_events:
			events.append(target_event.to_dict())
		dict["target_events"] = events

	return dict


func _to_string() -> String:
	return "<Mapping: " + name + ">"
