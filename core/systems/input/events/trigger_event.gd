extends Resource
class_name InputPlumberTriggerEvent

@export var name: String
@export var deadzone: float


static func from_dict(dict: Dictionary) -> InputPlumberTriggerEvent:
	var event := InputPlumberTriggerEvent.new()
	if "name" in dict:
		event.name = dict["name"]
	if "deadzone" in dict:
		event.deadzone = dict["deadzone"]
	
	return event


func to_dict() -> Dictionary:
	var dict := {"name": self.name}
	if self.deadzone:
		dict["deadzone"] = self.deadzone
	
	return dict
