extends Resource
class_name InputPlumberTouchMotionEvent

@export var region: String
@export var speed_pps: int


static func from_dict(dict: Dictionary) -> InputPlumberTouchMotionEvent:
	var event := InputPlumberTouchMotionEvent.new()
	if "region" in dict:
		event.region = dict["region"]
	if "speed_pps" in dict:
		event.speed_pps = dict["speed_pps"]

	return event


func to_dict() -> Dictionary:
	var dict := {}
	if self.region:
		dict["region"] = self.region
	if self.speed_pps:
		dict["speed_pps"] = self.speed_pps

	return dict
