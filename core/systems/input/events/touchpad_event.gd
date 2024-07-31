extends Resource
class_name InputPlumberTouchpadEvent

@export var name: String
@export var touch: InputPlumberTouchEvent


static func from_dict(dict: Dictionary) -> InputPlumberTouchpadEvent:
	var event := InputPlumberTouchpadEvent.new()
	if "name" in dict:
		event.name = dict["name"]
	if "touch" in dict:
		var touch = InputPlumberTouchEvent.from_dict(dict["touch"])
		event.touch = touch

	return event


func to_dict() -> Dictionary:
	var dict := {}
	if self.name:
		dict["name"] = self.name
	if self.touch:
		dict["touch"] = self.touch.to_dict()

	return dict
