extends Resource
class_name InputPlumberAxisEvent

@export var name: String
@export var direction: String
@export var deadzone: float


static func from_dict(dict: Dictionary) -> InputPlumberAxisEvent:
	var event := InputPlumberAxisEvent.new()
	if "name" in dict:
		event.name = dict["name"]
	if "direction" in dict:
		event.direction = dict["direction"]
	if "deadzone" in dict:
		event.deadzone = dict["deadzone"]
	
	return event


func to_dict() -> Dictionary:
	var dict := {}
	dict["name"] = self.name
	if self.direction:
		dict["direction"] = self.direction
	if self.deadzone:
		dict["deadzone"] = self.deadzone

	return dict
