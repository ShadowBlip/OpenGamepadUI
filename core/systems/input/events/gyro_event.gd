extends Resource
class_name InputPlumberGyroEvent

@export var name: String
@export var direction: String
@export var deadzone: float
@export var axis: String


static func from_dict(dict: Dictionary) -> InputPlumberGyroEvent:
	var event := InputPlumberGyroEvent.new()
	if "name" in dict:
		event.name = dict["name"]
	if "direction" in dict:
		event.direction = dict["direction"]
	if "deadzone" in dict:
		event.deadzone = dict["deadzone"]
	if "axis" in dict:
		event.axis = dict["axis"]
	
	return event


func to_dict() -> Dictionary:
	var dict := {}
	dict["name"] = self.name
	if self.direction:
		dict["direction"] = self.direction
	if self.deadzone:
		dict["deadzone"] = self.deadzone
	if self.axis:
		dict["axis"] = self.axis

	return dict
