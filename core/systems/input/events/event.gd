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
		"Gamepad:Button:South": "joypad/a",
		"Gamepad:Button:North": "joypad/x",
		"Gamepad:Button:East": "joypad/b",
		"Gamepad:Button:West": "joypad/y",
		"Gamepad:Button:LeftBumper": "joypad/lb",
		"Gamepad:Button:RightBumper": "joypad/rb",
		"Gamepad:Button:LeftBumper2": "joypad/lt",
		"Gamepad:Button:RightBumper2": "joypad/rt",
		"Gamepad:Button:Start": "joypad/start",
		"Gamepad:Button:Select": "joypad/select",
		"Gamepad:Button:LeftStick": "joypad/l_stick_click",
		"Gamepad:Button:RightStick": "joypad/r_stick_click",
		"Gamepad:Button:Guide": "joypad/home",
		"Gamepad:Button:QuickAccess": "joypad/quickaccess",
		"Gamepad:Button:Screenshot": "joypad/screenshot",
		"Gamepad:Axis:LeftStick": "joypad/l_stick",
		"Gamepad:Axis:RightStick": "joypad/r_stick",
		"Gamepad:Trigger:LeftTrigger": "joypad/lt",
		"Gamepad:Trigger:RightTrigger": "joypad/rt",
		"Gamepad:Button:DPadLeft": "joypad/dpad",
		"Gamepad:Button:DPadRight": "joypad/dpad",
		"Gamepad:Button:DPadUp": "joypad/dpad",
		"Gamepad:Button:DPadDown": "joypad/dpad",
		# TODO: Finish this
		#InputDeviceEvent.BTN_TRIGGER_HAPPY1: "joypad/dpad_left",
		#InputDeviceEvent.BTN_TRIGGER_HAPPY2: "joypad/dpad_right",
		#InputDeviceEvent.BTN_TRIGGER_HAPPY3: "joypad/dpad_up",
		#InputDeviceEvent.BTN_TRIGGER_HAPPY4: "joypad/dpad_down",
	}

	if cap in mapping:
		return mapping[cap] as String
	
	return ""
