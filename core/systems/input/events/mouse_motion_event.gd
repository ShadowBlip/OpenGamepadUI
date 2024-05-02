extends Resource
class_name InputPlumberMouseMotionEvent

@export var direction: String
@export var speed_pps: int


static func from_dict(dict: Dictionary) -> InputPlumberMouseMotionEvent:
	var event := InputPlumberMouseMotionEvent.new()
	if "direction" in dict:
		event.direction = dict["direction"]
	if "speed_pps" in dict:
		event.speed_pps = dict["speed_pps"]
	
	return event


func to_dict() -> Dictionary:
	var dict := {}
	if self.direction:
		dict["direction"] = self.direction
	if self.speed_pps:
		dict["speed_pps"] = self.speed_pps

	return dict
