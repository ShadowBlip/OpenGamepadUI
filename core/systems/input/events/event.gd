extends Resource
class_name InputPlumberEvent

@export var keyboard: String
@export var mouse: InputPlumberMouseEvent
@export var dbus: String
@export var gamepad: InputPlumberGamepadEvent


## Create a new InputPlumberEvent from the given capability string
static func from_capability(capability: String) -> InputPlumberEvent:
	var event := InputPlumberEvent.new()
	if event.set_capability(capability) != OK:
		return null
	return event


## Create a new InputPlumberEvent from the given JSON dictionary
static func from_dict(dict: Dictionary) -> InputPlumberEvent:
	var event := InputPlumberEvent.new()
	if "keyboard" in dict:
		event.keyboard = dict["keyboard"]
	if "mouse" in dict:
		event.mouse = InputPlumberMouseEvent.from_dict(dict["mouse"] as Dictionary)
	if "dbus" in dict:
		event.dbus = dict["dbus"]
	if "gamepad" in dict:
		event.gamepad = InputPlumberGamepadEvent.from_dict(dict["gamepad"] as Dictionary)

	return event


## Convert the event into a JSON-serializable dictionary
func to_dict() -> Dictionary:
	var dict := {}
	if self.keyboard:
		dict["keyboard"] = self.keyboard
	if self.mouse:
		dict["mouse"] = self.mouse.to_dict()
	if self.dbus:
		dict["dbus"] = self.dbus
	if self.gamepad:
		dict["gamepad"] = self.gamepad.to_dict()

	return dict


## Returns the controller icon path from the given event
func to_joypad_path() -> String:
	var capability := self.to_capability()
	return InputPlumberEvent.get_joypad_path(capability)


## Returns the capability string of the event. E.g. "Gamepad:Button:South"
func to_capability() -> String:
	var capability := ""
	if keyboard:
		return "Keyboard:" + keyboard
	if dbus:
		return "DBus:" + dbus
	if gamepad:
		capability += "Gamepad:"
		if gamepad.button:
			capability += "Button:"
			return capability + gamepad.button
		if gamepad.axis:
			capability += "Axis:"
			return capability + gamepad.axis.name
		if gamepad.trigger:
			capability += "Trigger:"
			return capability + gamepad.trigger.name
		if gamepad.gyro:
			return capability + "Gyro"
		return ""
	if mouse:
		capability += "Mouse:"
		if mouse.button:
			capability += "Button:"
			return capability + mouse.button
		if mouse.motion:
			capability += "Motion"
			return capability
		return ""

	return capability


## Set the event based on the given capability string (e.g. "Gamepad:Button:South")
## TODO: FINISH THIS!
func set_capability(capability: String) -> int:
	if capability.begins_with("Gamepad:Button"):
		gamepad = InputPlumberGamepadEvent.new()
		gamepad.button = capability.trim_prefix("Gamepad:Button:")
		return OK
	#if capability.begins_with("Gamepad:Axis"):
		#gamepad = InputPlumberGamepadEvent.new()
		#gamepad.axis = capability.trim_prefix("Gamepad:Axis:")
		#return OK
	#if capability.begins_with("Gamepad:Trigger"):
		#gamepad = InputPlumberGamepadEvent.new()
		#gamepad.trigger = capability.trim_prefix("Gamepad:Trigger:")
		#return OK
	#if capability.begins_with("Gamepad:Gyro"):
		#gamepad = InputPlumberGamepadEvent.new()
		#gamepad.gyro = capability.trim_prefix("Gamepad:Gyro:")
		#return OK
	
	return ERR_DOES_NOT_EXIST


## Returns true if the given event matches this event capability
func matches(event: InputPlumberEvent) -> bool:
	var cap_a := self.to_capability()
	var cap_b := event.to_capability()
	
	return cap_a == cap_b


## Returns the controller icon path from the given event
static func get_joypad_path(cap: String) -> String:
	var mapping := {
		# Buttons
		"Gamepad:Button:South": "joypad/a",
		"Gamepad:Button:North": "joypad/x",
		"Gamepad:Button:East": "joypad/b",
		"Gamepad:Button:West": "joypad/y",
		"Gamepad:Button:Start": "joypad/start",
		"Gamepad:Button:Select": "joypad/select",
		"Gamepad:Button:Guide": "joypad/home",
		"Gamepad:Button:QuickAccess": "joypad/quickaccess",
		"Gamepad:Button:QuickAccess2": "joypad/quickaccess2",
		"Gamepad:Button:Screenshot": "joypad/screenshot",
		"Gamepad:Button:Keyboard": "joypad/keyboard",
		# DPad
		"Gamepad:Button:DPadLeft": "joypad/dpad/left",
		"Gamepad:Button:DPadRight": "joypad/dpad/right",
		"Gamepad:Button:DPadUp": "joypad/dpad/up",
		"Gamepad:Button:DPadDown": "joypad/dpad/down",
		# Shoulders
		"Gamepad:Button:LeftBumper": "joypad/lb",
		"Gamepad:Button:LeftTop": "joypad/left_top",
		"Gamepad:Button:RightBumper": "joypad/rb",
		"Gamepad:Button:RightTop": "joypad/right_top",
		# Triggers
		"Gamepad:Trigger:LeftTrigger": "joypad/lt",
		"Gamepad:Trigger:RightTrigger": "joypad/rt",
		# Paddles
		"Gamepad:Button:LeftPaddle1": "joypad/left_paddle_1",
		"Gamepad:Button:LeftPaddle2": "joypad/left_paddle_2",
		"Gamepad:Button:LeftPaddle3": "joypad/left_paddle_3",
		"Gamepad:Button:RightPaddle1": "joypad/right_paddle_1",
		"Gamepad:Button:RightPaddle2": "joypad/right_paddle_2",
		"Gamepad:Button:RightPaddle3": "joypad/right_paddle_3",
		# Axes
		"Gamepad:Axis:LeftStick": "joypad/l_stick",
		"Gamepad:Axis:RightStick": "joypad/r_stick",
		"Gamepad:Button:LeftStick": "joypad/l_stick_click",
		"Gamepad:Button:RightStick": "joypad/r_stick_click",
		"Gamepad:Button:LeftStickTouch": "joypad/l_stick_touch",
		"Gamepad:Button:RightStickTouch": "joypad/r_stick_touch",
		# Touchpads
		"Touchpad:LeftPad:Motion": "joypad/left_pad",
		"Touchpad:LeftPad:Button:Touch": "joypad/left_pad",
		"Touchpad:LeftPad:Button:Press": "joypad/left_pad",
		"Touchpad:CenterPad:Motion": "joypad/center_pad",
		"Touchpad:CenterPad:Button:Touch": "joypad/center_pad",
		"Touchpad:CenterPad:Button:Press": "joypad/center_pad",
		"Touchpad:RightPad:Motion": "joypad/right_pad",
		"Touchpad:RightPad:Button:Touch": "joypad/right_pad",
		"Touchpad:RightPad:Button:Press": "joypad/right_pad",
		# Mouse
		"Mouse:Motion": "mouse/motion",
		"Mouse:Button:Left": "mouse/left",
		"Mouse:Button:Middle": "mouse/middle",
		"Mouse:Button:Right": "mouse/right",
		"Mouse:Button:Extra1": "mouse/extra1",
		"Mouse:Button:Extra2": "mouse/extra2",
		"Mouse:Button:WheelUp": "mouse/wheel_up",
		"Mouse:Button:WheelDown": "mouse/wheel_down",
	}

	if cap in mapping:
		return mapping[cap] as String
	
	return ""


## Sorts the given string capabilities and returns them sorted
static func sort_capabilities(caps: PackedStringArray) -> PackedStringArray:
	# Weights for capabilities. Higher values will sort to the beginning.
	var weights := {
		"Gamepad:Button:South": 150,
		"Gamepad:Button:East": 149,
		"Gamepad:Button:North": 148,
		"Gamepad:Button:West": 147,
		"Gamepad:Button:Start": 146,
		"Gamepad:Button:Select": 145,
		"Gamepad:Button:Guide": 144,
		"Gamepad:Button:QuickAccess": 143,
		"Gamepad:Button:QuickAccess2": 142,
		"Gamepad:Button:Screenshot": 141,
		"Gamepad:Button:Keyboard": 140,
		"Gamepad:Button:DPadLeft": 130,
		"Gamepad:Button:DPadRight": 129,
		"Gamepad:Button:DPadUp": 128,
		"Gamepad:Button:DPadDown": 127,
		"Gamepad:Button:LeftBumper": 120,
		"Gamepad:Button:LeftTop": 119,
		"Gamepad:Button:RightBumper": 118,
		"Gamepad:Button:RightTop": 117,
		"Gamepad:Button:LeftStick": 80,
		"Gamepad:Button:LeftStickTouch": 79,
		"Gamepad:Button:RightStick": 78,
		"Gamepad:Button:RightStickTouch": 77,
		"Gamepad:Button:LeftPaddle1": 50,
		"Gamepad:Button:LeftPaddle2": 49,
		"Gamepad:Button:LeftPaddle3": 48,
		"Gamepad:Button:RightPaddle1": 47,
		"Gamepad:Button:RightPaddle2": 46,
		"Gamepad:Button:RightPaddle3": 45,
	}

	# Custom sort for sorter higher weighted values towards the beggining
	var weighted_sort := func(a: String, b: String) -> bool:
		var a_weight := -1
		if a in weights:
			a_weight = weights[a] as int
		var b_weight := -1
		if b in weights:
			b_weight = weights[b] as int
		return a_weight > b_weight
	
	var sorted: Array = Array(caps.duplicate())
	sorted.sort()
	sorted.sort_custom(weighted_sort)
	
	return PackedStringArray(sorted)
