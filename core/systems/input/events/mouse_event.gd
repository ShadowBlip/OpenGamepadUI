extends Resource
class_name InputPlumberMouseEvent

@export var button: String
@export var motion: InputPlumberMouseMotionEvent


static func from_dict(dict: Dictionary) -> InputPlumberMouseEvent:
	var event := InputPlumberMouseEvent.new()
	if "button" in dict:
		event.button = dict["button"]
	if "motion" in dict:
		event.motion = InputPlumberMouseMotionEvent.from_dict(dict["motion"] as Dictionary)
	
	return event


func to_dict() -> Dictionary:
	var dict := {}
	if self.button:
		dict["button"] = self.button
	if self.motion:
		dict["motion"] = self.motion.to_dict()

	return dict
