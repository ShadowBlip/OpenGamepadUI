extends Resource
class_name InputPlumberTouchEvent

@export var button: String
@export var motion: InputPlumberTouchMotionEvent


static func from_dict(dict: Dictionary) -> InputPlumberTouchEvent:
	var event := InputPlumberTouchEvent.new()
	if "button" in dict:
		event.button = dict["button"]
	if "motion" in dict:
		event.motion = InputPlumberTouchMotionEvent.from_dict(dict["motion"])
	
	return event


func to_dict() -> Dictionary:
	var dict := {}
	if self.button:
		dict["button"] = self.button
	if self.motion:
		dict["motion"] = self.motion.to_dict()

	return dict
