extends Resource
class_name InputPlumberGamepadEvent

@export var axis: InputPlumberAxisEvent
@export var gyro: InputPlumberGyroEvent
@export var trigger: InputPlumberTriggerEvent
@export var button: String


static func from_dict(dict: Dictionary) -> InputPlumberGamepadEvent:
	var event := InputPlumberGamepadEvent.new()
	if "axis" in dict:
		event.axis = InputPlumberAxisEvent.from_dict(dict["axis"] as Dictionary)
	if "gyro" in dict:
		event.gyro = InputPlumberGyroEvent.from_dict(dict["gyro"] as Dictionary)
	if "trigger" in dict:
		event.trigger = InputPlumberTriggerEvent.from_dict(dict["trigger"] as Dictionary)
	if "button" in dict:
		event.button = dict["button"]

	return event


func to_dict() -> Dictionary:
	var dict := {}
	if self.axis:
		dict["axis"] = self.axis.to_dict()
	if self.gyro:
		dict["gyro"] = self.gyro.to_dict()
	if self.trigger:
		dict["trigger"] = self.trigger.to_dict()
	if self.button:
		dict["button"] = self.button

	return dict
