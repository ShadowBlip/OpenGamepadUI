extends Resource
class_name InputPlumberEvent

@export var keyboard: String
@export var mouse: InputPlumberMouseEvent
@export var dbus: String
@export var gamepad: InputPlumberGamepadEvent
@export var touchpad: InputPlumberTouchpadEvent


## Create a new InputPlumberEvent from the given capability string
static func from_capability(capability: String) -> InputPlumberEvent:
	var event := InputPlumberEvent.new()
	if event.set_capability(capability) != OK:
		return null
	return event


## Create a new InputPlumberEvent from the given Godot event
static func from_event(godot_event: InputEvent) -> InputPlumberEvent:
	if godot_event is InputEventKey:
		var key_event := godot_event as InputEventKey
		var capability := capability_from_keycode(key_event.keycode)
		return from_capability(capability)
	# TODO: Finish implementing these
	elif godot_event is InputEventJoypadButton:
		return null
	elif godot_event is InputEventJoypadMotion:
		return null
	elif godot_event is InputEventMouseButton:
		return null
	elif godot_event is InputEventMouseMotion:
		return null
	elif godot_event is InputEventAction:
		return null
	
	return null


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
	if "touchpad" in dict:
		event.touchpad = InputPlumberTouchpadEvent.from_dict(dict["touchpad"] as Dictionary)

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
	if self.touchpad:
		dict["touchpad"] = self.touchpad.to_dict()

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
	if touchpad:
		capability += "Touchpad:"
		if touchpad.name:
			capability += touchpad.name + ":"
		else:
			return ""
		if touchpad.touch and touchpad.touch.button:
			capability += "Button:" + touchpad.touch.button
			return capability
		if touchpad.touch and touchpad.touch.motion:
			capability += "Motion"
	return capability


## Set the event based on the given capability string (e.g. "Gamepad:Button:South")
## TODO: FINISH THIS!
func set_capability(capability: String) -> int:
	if capability.begins_with("Keyboard"):
		keyboard = capability.trim_prefix("Keyboard:")
		return OK
	if capability.begins_with("Mouse:Motion"):
		mouse = InputPlumberMouseEvent.new()
		mouse.motion = InputPlumberMouseMotionEvent.new()
		return OK
	if capability.begins_with("Mouse:Button"):
		mouse = InputPlumberMouseEvent.new()
		mouse.button = capability.trim_prefix("Mouse:Button:")
		return OK
	if capability.begins_with("Gamepad:Button"):
		gamepad = InputPlumberGamepadEvent.new()
		gamepad.button = capability.trim_prefix("Gamepad:Button:")
		return OK
	if capability.begins_with("Gamepad:Axis"):
		gamepad = InputPlumberGamepadEvent.new()
		var axis := InputPlumberAxisEvent.new()
		axis.name = capability.trim_prefix("Gamepad:Axis:")
		gamepad.axis = axis
		return OK
	if capability.begins_with("Gamepad:Trigger"):
		gamepad = InputPlumberGamepadEvent.new()
		var trigger := InputPlumberTriggerEvent.new()
		trigger.name = capability.trim_prefix("Gamepad:Trigger:")
		gamepad.trigger = trigger
		return OK
	if capability.begins_with("Gamepad:Gyro"):
		gamepad = InputPlumberGamepadEvent.new()
		var gyro := InputPlumberGyroEvent.new()
		gyro.name = "Gyro"
		gamepad.gyro = gyro
		return OK
	if capability.begins_with("Touchpad"):
		touchpad = InputPlumberTouchpadEvent.new()
		var parts := capability.split(":")
		if not parts.size() in [3, 4]:
			return ERR_CANT_CREATE
		touchpad.name = parts[1]
		var touch := InputPlumberTouchEvent.new()
		if parts[2] == "Button":
			touch.button = parts[3]
		if parts[2] == "Motion":
			var motion := InputPlumberTouchMotionEvent.new()
			touch.motion = motion
		touchpad.touch = touch

		return OK
	

	return ERR_DOES_NOT_EXIST


## Returns true if the given event matches this event capability
func matches(event: InputPlumberEvent) -> bool:
	var cap_a := self.to_capability()
	var cap_b := event.to_capability()
	
	return cap_a == cap_b


## Certain events can have a "direction" specified, such as for joysticks and
## gyro. This will return the direction if one exists and is supported.
func get_direction() -> String:
	if self.gamepad:
		if self.gamepad.axis and self.gamepad.axis.direction:
			return self.gamepad.axis.direction
	return ""


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
		# Keyboard
		"Keyboard:KeyEsc": "key/esc",
		"Keyboard:Key1": "key/1",
		"Keyboard:Key2": "key/2",
		"Keyboard:Key3": "key/3",
		"Keyboard:Key4": "key/4",
		"Keyboard:Key5": "key/5",
		"Keyboard:Key6": "key/6",
		"Keyboard:Key7": "key/7",
		"Keyboard:Key8": "key/8",
		"Keyboard:Key9": "key/9",
		"Keyboard:Key0": "key/0",
		"Keyboard:KeyMinus": "key/minus",
		"Keyboard:KeyEqual": "key/equal",
		"Keyboard:KeyBackspace": "key/backspace",
		"Keyboard:KeyTab": "key/tab",
		"Keyboard:KeyQ": "key/q",
		"Keyboard:KeyW": "key/w",
		"Keyboard:KeyE": "key/e",
		"Keyboard:KeyR": "key/r",
		"Keyboard:KeyT": "key/t",
		"Keyboard:KeyY": "key/y",
		"Keyboard:KeyU": "key/u",
		"Keyboard:KeyI": "key/i",
		"Keyboard:KeyO": "key/o",
		"Keyboard:KeyP": "key/p",
		"Keyboard:KeyLeftBrace": "key/left_brace",
		"Keyboard:KeyRightBrace": "key/right_brace",
		"Keyboard:KeyEnter": "key/enter",
		"Keyboard:KeyLeftCtrl": "key/left_ctrl",
		"Keyboard:KeyA": "key/a",
		"Keyboard:KeyS": "key/s",
		"Keyboard:KeyD": "key/d",
		"Keyboard:KeyF": "key/f",
		"Keyboard:KeyG": "key/g",
		"Keyboard:KeyH": "key/h",
		"Keyboard:KeyJ": "key/j",
		"Keyboard:KeyK": "key/k",
		"Keyboard:KeyL": "key/l",
		"Keyboard:KeySemicolon": "key/semicolon",
		"Keyboard:KeyApostrophe": "key/apostrophe",
		"Keyboard:KeyGrave": "key/tilda",
		"Keyboard:KeyLeftShift": "key/left_shift",
		"Keyboard:KeyBackslash": "key/backslash",
		"Keyboard:KeyZ": "key/z",
		"Keyboard:KeyX": "key/x",
		"Keyboard:KeyC": "key/c",
		"Keyboard:KeyV": "key/v",
		"Keyboard:KeyB": "key/b",
		"Keyboard:KeyN": "key/n",
		"Keyboard:KeyM": "key/m",
		"Keyboard:KeyComma": "key/comma",
		"Keyboard:KeyDot": "key/period",
		"Keyboard:KeySlash": "key/slash",
		"Keyboard:KeyRightShift": "key/right_shift",
		"Keyboard:KeyKpAsterisk": "key/kp_asterisk",
		"Keyboard:KeyLeftAlt": "key/left_alt",
		"Keyboard:KeySpace": "key/space",
		"Keyboard:KeyCapslock": "key/caps_lock",
		"Keyboard:KeyF1": "key/f1",
		"Keyboard:KeyF2": "key/f2",
		"Keyboard:KeyF3": "key/f3",
		"Keyboard:KeyF4": "key/f4",
		"Keyboard:KeyF5": "key/f5",
		"Keyboard:KeyF6": "key/f6",
		"Keyboard:KeyF7": "key/f7",
		"Keyboard:KeyF8": "key/f8",
		"Keyboard:KeyF9": "key/f9",
		"Keyboard:KeyF10": "key/f10",
		"Keyboard:KeyNumlock": "key/num_lock",
		"Keyboard:KeyScrollLock": "key/scroll_lock",
		"Keyboard:KeyKp7": "key/kp7",
		"Keyboard:KeyKp8": "key/kp8",
		"Keyboard:KeyKp9": "key/kp9",
		"Keyboard:KeyKpMinus": "key/kp_minus",
		"Keyboard:KeyKp4": "key/kp4",
		"Keyboard:KeyKp5": "key/kp5",
		"Keyboard:KeyKp6": "key/kp6",
		"Keyboard:KeyKpPlus": "key/kp_plus",
		"Keyboard:KeyKp1": "key/kp1",
		"Keyboard:KeyKp2": "key/kp2",
		"Keyboard:KeyKp3": "key/kp3",
		"Keyboard:KeyKp0": "key/kp0",
		"Keyboard:KeyKpDot": "key/kp_dot",
		"Keyboard:KeyZenkakuhankaku": "key/zenkakuhankaku",
		"Keyboard:Key102nd": "key/102nd",
		"Keyboard:KeyF11": "key/f11",
		"Keyboard:KeyF12": "key/f12",
		"Keyboard:KeyRo": "key/ro",
		"Keyboard:KeyKatakana": "key/katakana",
		"Keyboard:KeyHiragana": "key/hiragana",
		"Keyboard:KeyHenkan": "key/henkan",
		"Keyboard:KeyKatakanaHiragana": "key/katakana_hiragana",
		"Keyboard:KeyMuhenkan": "key/muhenkan",
		"Keyboard:KeyKpJpComma": "key/kp_jp_comma",
		"Keyboard:KeyKpEnter": "key/kp_enter",
		"Keyboard:KeyRightCtrl": "key/right_ctrl",
		"Keyboard:KeyKpSlash": "key/kp_slash",
		"Keyboard:KeySysrq": "key/sysrq",
		"Keyboard:KeyRightAlt": "key/right_alt",
		"Keyboard:KeyHome": "key/home",
		"Keyboard:KeyUp": "key/up",
		"Keyboard:KeyPageUp": "key/page_up",
		"Keyboard:KeyLeft": "key/left",
		"Keyboard:KeyRight": "key/right",
		"Keyboard:KeyEnd": "key/end",
		"Keyboard:KeyDown": "key/down",
		"Keyboard:KeyPageDown": "key/page_down",
		"Keyboard:KeyInsert": "key/insert",
		"Keyboard:KeyDelete": "key/delete",
		"Keyboard:KeyMute": "key/mute",
		"Keyboard:KeyVolumeDown": "key/volume_down",
		"Keyboard:KeyVolumeUp": "key/volume_up",
		"Keyboard:KeyPower": "key/power",
		"Keyboard:KeyKpEqual": "key/kp_equal",
		"Keyboard:KeyPause": "key/pause",
		"Keyboard:KeyKpComma": "key/kp_comma",
		"Keyboard:KeyHanja": "key/hanja",
		"Keyboard:KeyYen": "key/yen",
		"Keyboard:KeyLeftMeta": "key/left_meta",
		"Keyboard:KeyRightMeta": "key/right_meta",
		"Keyboard:KeyCompose": "key/compose",
		"Keyboard:KeyStop": "key/stop",
		"Keyboard:KeyAgain": "key/again",
		"Keyboard:KeyProps": "key/props",
		"Keyboard:KeyUndo": "key/undo",
		"Keyboard:KeyFront": "key/front",
		"Keyboard:KeyCopy": "key/copy",
		"Keyboard:KeyOpen": "key/open",
		"Keyboard:KeyPaste": "key/paste",
		"Keyboard:KeyFind": "key/find",
		"Keyboard:KeyCut": "key/cut",
		"Keyboard:KeyHelp": "key/help",
		"Keyboard:KeyCalc": "key/calc",
		"Keyboard:KeySleep": "key/sleep",
		"Keyboard:KeyWww": "key/www",
		"Keyboard:KeyBack": "key/back",
		"Keyboard:KeyForward": "key/forward",
		"Keyboard:KeyEjectCD": "key/eject_cd",
		"Keyboard:KeyNextSong": "key/next_song",
		"Keyboard:KeyPlayPause": "key/play_pause",
		"Keyboard:KeyPreviousSong": "key/previous_song",
		"Keyboard:KeyStopCD": "key/stop_cd",
		"Keyboard:KeyRefresh": "key/refresh",
		"Keyboard:KeyEdit": "key/edit",
		"Keyboard:KeyScrollUp": "key/scroll_up",
		"Keyboard:KeyScrollDown": "key/scroll_down",
		"Keyboard:KeyKpLeftParen": "key/kp_left_paren",
		"Keyboard:KeyKpRightParen": "key/kp_right_paren",
		"Keyboard:KeyF13": "key/f13",
		"Keyboard:KeyF14": "key/f14",
		"Keyboard:KeyF15": "key/f15",
		"Keyboard:KeyF16": "key/f16",
		"Keyboard:KeyF17": "key/f17",
		"Keyboard:KeyF18": "key/f18",
		"Keyboard:KeyF19": "key/f19",
		"Keyboard:KeyF20": "key/f20",
		"Keyboard:KeyF21": "key/f21",
		"Keyboard:KeyF22": "key/f22",
		"Keyboard:KeyF23": "key/f23",
		"Keyboard:KeyF24": "key/f24",
		"Keyboard:KeyProg1": "key/prog1",
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


## Convert the given key scancode into a capability string
static func capability_from_keycode(scancode: int) -> String:
	match scancode:
		KEY_ESCAPE:
			return "Keyboard:KeyEsc"
		KEY_1:
			return "Keyboard:Key1"
		KEY_2:
			return "Keyboard:Key2"
		KEY_3:
			return "Keyboard:Key3"
		KEY_4:
			return "Keyboard:Key4"
		KEY_5:
			return "Keyboard:Key5"
		KEY_6:
			return "Keyboard:Key6"
		KEY_7:
			return "Keyboard:Key7"
		KEY_8:
			return "Keyboard:Key8"
		KEY_9:
			return "Keyboard:Key9"
		KEY_0:
			return "Keyboard:Key0"
		KEY_MINUS:
			return "Keyboard:KeyMinus"
		KEY_EQUAL:
			return "Keyboard:KeyEqual"
		KEY_BACKSPACE:
			return "Keyboard:KeyBackspace"
		KEY_TAB:
			return "Keyboard:KeyTab"
		KEY_Q:
			return "Keyboard:KeyQ"
		KEY_W:
			return "Keyboard:KeyW"
		KEY_E:
			return "Keyboard:KeyE"
		KEY_R:
			return "Keyboard:KeyR"
		KEY_T:
			return "Keyboard:KeyT"
		KEY_Y:
			return "Keyboard:KeyY"
		KEY_U:
			return "Keyboard:KeyU"
		KEY_I:
			return "Keyboard:KeyI"
		KEY_O:
			return "Keyboard:KeyO"
		KEY_P:
			return "Keyboard:KeyP"
		KEY_BRACELEFT:
			return "Keyboard:KeyLeftBrace"
		KEY_BRACERIGHT:
			return "Keyboard:KeyRightBrace"
		KEY_ENTER:
			return "Keyboard:KeyEnter"
		KEY_CTRL:
			return "Keyboard:KeyLeftCtrl"
		KEY_A:
			return "Keyboard:KeyA"
		KEY_S:
			return "Keyboard:KeyS"
		KEY_D:
			return "Keyboard:KeyD"
		KEY_F:
			return "Keyboard:KeyF"
		KEY_G:
			return "Keyboard:KeyG"
		KEY_H:
			return "Keyboard:KeyH"
		KEY_J:
			return "Keyboard:KeyJ"
		KEY_K:
			return "Keyboard:KeyK"
		KEY_L:
			return "Keyboard:KeyL"
		KEY_SEMICOLON:
			return "Keyboard:KeySemicolon"
		KEY_APOSTROPHE:
			return "Keyboard:KeyApostrophe"
		KEY_ASCIITILDE:
			return "Keyboard:KeyGrave"
		KEY_SHIFT:
			return "Keyboard:KeyLeftShift"
		KEY_BACKSLASH:
			return "Keyboard:KeyBackslash"
		KEY_Z:
			return "Keyboard:KeyZ"
		KEY_X:
			return "Keyboard:KeyX"
		KEY_C:
			return "Keyboard:KeyC"
		KEY_V:
			return "Keyboard:KeyV"
		KEY_B:
			return "Keyboard:KeyB"
		KEY_N:
			return "Keyboard:KeyN"
		KEY_M:
			return "Keyboard:KeyM"
		KEY_COMMA:
			return "Keyboard:KeyComma"
		KEY_PERIOD:
			return "Keyboard:KeyDot"
		KEY_SLASH:
			return "Keyboard:KeySlash"
		KEY_SHIFT:
			return "Keyboard:KeyRightShift"
		KEY_ASTERISK:
			return "Keyboard:KeyKpAsterisk"
		KEY_ALT:
			return "Keyboard:KeyLeftAlt"
		KEY_SPACE:
			return "Keyboard:KeySpace"
		KEY_CAPSLOCK:
			return "Keyboard:KeyCapslock"
		KEY_F1:
			return "Keyboard:KeyF1"
		KEY_F2:
			return "Keyboard:KeyF2"
		KEY_F3:
			return "Keyboard:KeyF3"
		KEY_F4:
			return "Keyboard:KeyF4"
		KEY_F5:
			return "Keyboard:KeyF5"
		KEY_F6:
			return "Keyboard:KeyF6"
		KEY_F7:
			return "Keyboard:KeyF7"
		KEY_F8:
			return "Keyboard:KeyF8"
		KEY_F9:
			return "Keyboard:KeyF9"
		KEY_F10:
			return "Keyboard:KeyF10"
		KEY_NUMLOCK:
			return "Keyboard:KeyNumlock"
		KEY_SCROLLLOCK:
			return "Keyboard:KeyScrollLock"
		KEY_KP_7:
			return "Keyboard:KeyKp7"
		KEY_KP_8:
			return "Keyboard:KeyKp8"
		KEY_KP_9:
			return "Keyboard:KeyKp9"
		KEY_KP_SUBTRACT:
			return "Keyboard:KeyKpMinus"
		KEY_KP_4:
			return "Keyboard:KeyKp4"
		KEY_KP_5:
			return "Keyboard:KeyKp5"
		KEY_KP_6:
			return "Keyboard:KeyKp6"
		KEY_KP_ADD:
			return "Keyboard:KeyKpPlus"
		KEY_KP_1:
			return "Keyboard:KeyKp1"
		KEY_KP_2:
			return "Keyboard:KeyKp2"
		KEY_KP_3:
			return "Keyboard:KeyKp3"
		KEY_KP_0:
			return "Keyboard:KeyKp0"
		KEY_KP_PERIOD:
			return "Keyboard:KeyKpDot"
		KEY_F11:
			return "Keyboard:KeyF11"
		KEY_F12:
			return "Keyboard:KeyF12"
		KEY_JIS_KANA:
			return "Keyboard:KeyKatakanaHiragana"
		KEY_KP_ENTER:
			return "Keyboard:KeyKpEnter"
		KEY_CTRL:
			return "Keyboard:KeyRightCtrl"
		KEY_KP_DIVIDE:
			return "Keyboard:KeyKpSlash"
		KEY_SYSREQ:
			return "Keyboard:KeySysrq"
		KEY_ALT:
			return "Keyboard:KeyRightAlt"
		KEY_HOME:
			return "Keyboard:KeyHome"
		KEY_UP:
			return "Keyboard:KeyUp"
		KEY_PAGEUP:
			return "Keyboard:KeyPageUp"
		KEY_LEFT:
			return "Keyboard:KeyLeft"
		KEY_RIGHT:
			return "Keyboard:KeyRight"
		KEY_END:
			return "Keyboard:KeyEnd"
		KEY_DOWN:
			return "Keyboard:KeyDown"
		KEY_PAGEDOWN:
			return "Keyboard:KeyPageDown"
		KEY_INSERT:
			return "Keyboard:KeyInsert"
		KEY_DELETE:
			return "Keyboard:KeyDelete"
		KEY_VOLUMEMUTE:
			return "Keyboard:KeyMute"
		KEY_VOLUMEDOWN:
			return "Keyboard:KeyVolumeDown"
		KEY_VOLUMEUP:
			return "Keyboard:KeyVolumeUp"
		KEY_PAUSE:
			return "Keyboard:KeyPause"
		KEY_YEN:
			return "Keyboard:KeyYen"
		KEY_META:
			return "Keyboard:KeyLeftMeta"
		KEY_META:
			return "Keyboard:KeyRightMeta"
		KEY_STOP:
			return "Keyboard:KeyStop"
		KEY_HELP:
			return "Keyboard:KeyHelp"
		KEY_BACK:
			return "Keyboard:KeyBack"
		KEY_FORWARD:
			return "Keyboard:KeyForward"
		KEY_MEDIANEXT:
			return "Keyboard:KeyNextSong"
		KEY_MEDIAPLAY:
			return "Keyboard:KeyPlayPause"
		KEY_MEDIAPREVIOUS:
			return "Keyboard:KeyPreviousSong"
		KEY_MEDIASTOP:
			return "Keyboard:KeyStopCD"
		KEY_REFRESH:
			return "Keyboard:KeyRefresh"
		KEY_F13:
			return "Keyboard:KeyF13"
		KEY_F14:
			return "Keyboard:KeyF14"
		KEY_F15:
			return "Keyboard:KeyF15"
		KEY_F16:
			return "Keyboard:KeyF16"
		KEY_F17:
			return "Keyboard:KeyF17"
		KEY_F18:
			return "Keyboard:KeyF18"
		KEY_F19:
			return "Keyboard:KeyF19"
		KEY_F20:
			return "Keyboard:KeyF20"
		KEY_F21:
			return "Keyboard:KeyF21"
		KEY_F22:
			return "Keyboard:KeyF22"
		KEY_F23:
			return "Keyboard:KeyF23"
		KEY_F24:
			return "Keyboard:KeyF24"
		_:
			return ""
