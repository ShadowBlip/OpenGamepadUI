extends Node
class_name ControllerMapper

func _convert_joypad_path(path: String, fallback) -> String:
	match _get_joypad_type(fallback):
		ControllerSettings.Devices.LUNA:
			return _convert_joypad_to_luna(path)
		ControllerSettings.Devices.PS3:
			return _convert_joypad_to_ps3(path)
		ControllerSettings.Devices.PS4:
			return _convert_joypad_to_ps4(path)
		ControllerSettings.Devices.PS5:
			return _convert_joypad_to_ps5(path)
		ControllerSettings.Devices.STADIA:
			return _convert_joypad_to_stadia(path)
		ControllerSettings.Devices.STEAM:
			return _convert_joypad_to_steam(path)
		ControllerSettings.Devices.SWITCH:
			return _convert_joypad_to_switch(path)
		ControllerSettings.Devices.JOYCON:
			return _convert_joypad_to_joycon(path)
		ControllerSettings.Devices.XBOX360:
			return _convert_joypad_to_xbox360(path)
		ControllerSettings.Devices.XBOXONE:
			return _convert_joypad_to_xboxone(path)
		ControllerSettings.Devices.XBOXSERIES:
			return _convert_joypad_to_xboxseries(path)
		ControllerSettings.Devices.STEAM_DECK:
			return _convert_joypad_to_steamdeck(path)
		_:
			return ""

func _get_joypad_type(fallback):
	var controller_name = Input.get_joy_name(0)
	if "Luna Controller" in controller_name:
		return ControllerSettings.Devices.LUNA
	elif "PS3 Controller" in controller_name:
		return ControllerSettings.Devices.PS3
	elif "PS4 Controller" in controller_name:
		return ControllerSettings.Devices.PS4
	elif "PS5 Controller" in controller_name:
		return ControllerSettings.Devices.PS5
	elif "Stadia Controller" in controller_name:
		return ControllerSettings.Devices.STADIA
	elif "Steam Controller" in controller_name:
		return ControllerSettings.Devices.STEAM
	elif "Switch Controller" in controller_name or \
		"Switch Pro Controller" in controller_name:
		return ControllerSettings.Devices.SWITCH
	elif "Joy-Con" in controller_name:
		return ControllerSettings.Devices.JOYCON
	elif "Xbox 360 Controller" in controller_name:
		return ControllerSettings.Devices.XBOX360
	elif "Xbox One" in controller_name or \
		"X-Box One" in controller_name or \
		"Xbox Wireless Controller" in controller_name:
		return ControllerSettings.Devices.XBOXONE
	elif "Xbox Series" in controller_name:
		return ControllerSettings.Devices.XBOXSERIES
	elif "Steam Deck" in controller_name or \
		"Steam Virtual Gamepad" in controller_name:
		return ControllerSettings.Devices.STEAM_DECK
	else:
		return fallback

func _convert_joypad_to_luna(path: String):
	path = path.replace("joypad", "luna")
	match path.substr(path.find("/") + 1):
		"select":
			return path.replace("/select", "/circle")
		"start":
			return path.replace("/start", "/menu")
		"share":
			return path.replace("/share", "/microphone")
		_:
			return path

func _convert_joypad_to_ps3(path: String):
	path = path.replace("joypad", "ps3")
	match path.substr(path.find("/") + 1):
		"a":
			return path.replace("/a", "/cross")
		"b":
			return path.replace("/b", "/circle")
		"x":
			return path.replace("/x", "/square")
		"y":
			return path.replace("/y", "/triangle")
		"lb":
			return path.replace("/lb", "/l1")
		"rb":
			return path.replace("/rb", "/r1")
		"lt":
			return path.replace("/lt", "/l2")
		"rt":
			return path.replace("/rt", "/r2")
		_:
			return path

func _convert_joypad_to_ps4(path: String):
	path = path.replace("joypad", "ps4")
	match path.substr(path.find("/") + 1):
		"a":
			return path.replace("/a", "/cross")
		"b":
			return path.replace("/b", "/circle")
		"x":
			return path.replace("/x", "/square")
		"y":
			return path.replace("/y", "/triangle")
		"lb":
			return path.replace("/lb", "/l1")
		"rb":
			return path.replace("/rb", "/r1")
		"lt":
			return path.replace("/lt", "/l2")
		"rt":
			return path.replace("/rt", "/r2")
		"select":
			return path.replace("/select", "/share")
		"start":
			return path.replace("/start", "/options")
		"share":
			return path.replace("/share", "/")
		_:
			return path

func _convert_joypad_to_ps5(path: String):
	path = path.replace("joypad", "ps5")
	match path.substr(path.find("/") + 1):
		"a":
			return path.replace("/a", "/cross")
		"b":
			return path.replace("/b", "/circle")
		"x":
			return path.replace("/x", "/square")
		"y":
			return path.replace("/y", "/triangle")
		"lb":
			return path.replace("/lb", "/l1")
		"rb":
			return path.replace("/rb", "/r1")
		"lt":
			return path.replace("/lt", "/l2")
		"rt":
			return path.replace("/rt", "/r2")
		"select":
			return path.replace("/select", "/share")
		"start":
			return path.replace("/start", "/options")
		"home":
			return path.replace("/home", "/assistant")
		"share":
			return path.replace("/share", "/microphone")
		_:
			return path

func _convert_joypad_to_stadia(path: String):
	path = path.replace("joypad", "stadia")
	match path.substr(path.find("/") + 1):
		"lb":
			return path.replace("/lb", "/l1")
		"rb":
			return path.replace("/rb", "/r1")
		"lt":
			return path.replace("/lt", "/l2")
		"rt":
			return path.replace("/rt", "/r2")
		"select":
			return path.replace("/select", "/dots")
		"start":
			return path.replace("/start", "/menu")
		"share":
			return path.replace("/share", "/select")
		_:
			return path

func _convert_joypad_to_steam(path: String):
	path = path.replace("joypad", "steam")
	match path.substr(path.find("/") + 1):
		"r_stick_click":
			return path.replace("/r_stick_click", "/right_track_center")
		"select":
			return path.replace("/select", "/back")
		"home":
			return path.replace("/home", "/system")
		"dpad":
			return path.replace("/dpad", "/left_track")
		"dpad_up":
			return path.replace("/dpad_up", "/left_track_up")
		"dpad_down":
			return path.replace("/dpad_down", "/left_track_down")
		"dpad_left":
			return path.replace("/dpad_left", "/left_track_left")
		"dpad_right":
			return path.replace("/dpad_right", "/left_track_right")
		"l_stick":
			return path.replace("/l_stick", "/stick")
		"r_stick":
			return path.replace("/r_stick", "/right_track")
		_:
			return path

func _convert_joypad_to_switch(path: String):
	path = path.replace("joypad", "switch")
	match path.substr(path.find("/") + 1):
		"a":
			return path.replace("/a", "/b")
		"b":
			return path.replace("/b", "/a")
		"x":
			return path.replace("/x", "/y")
		"y":
			return path.replace("/y", "/x")
		"select":
			return path.replace("/select", "/minus")
		"start":
			return path.replace("/start", "/plus")
		"share":
			return path.replace("/share", "/square")
		_:
			return path

func _convert_joypad_to_joycon(path: String):
	path = path.replace("joypad", "switch")
	match path.substr(path.find("/") + 1):
		"a":
			return path.replace("/a", "/b")
		"b":
			return path.replace("/b", "/a")
		"x":
			return path.replace("/x", "/y")
		"y":
			return path.replace("/y", "/x")
		"dpad_up":
			return path.replace("/dpad_up", "/up")
		"dpad_down":
			return path.replace("/dpad_down", "/down")
		"dpad_left":
			return path.replace("/dpad_left", "/left")
		"dpad_right":
			return path.replace("/dpad_right", "/right")
		"select":
			return path.replace("/select", "/minus")
		"start":
			return path.replace("/start", "/plus")
		"share":
			return path.replace("/share", "/square")
		_:
			return path

func _convert_joypad_to_xbox360(path: String):
	path = path.replace("joypad", "xbox360")
	match path.substr(path.find("/") + 1):
		"select":
			return path.replace("/select", "/back")
		_:
			return path

func _convert_joypad_to_xboxone(path: String):
	path = path.replace("joypad", "xboxone")
	match path.substr(path.find("/") + 1):
		"select":
			return path.replace("/select", "/view")
		"start":
			return path.replace("/start", "/menu")
		_:
			return path

func _convert_joypad_to_xboxseries(path: String):
	path = path.replace("joypad", "xboxseries")
	match path.substr(path.find("/") + 1):
		"select":
			return path.replace("/select", "/view")
		"start":
			return path.replace("/start", "/menu")
		_:
			return path

func _convert_joypad_to_steamdeck(path: String):
	path = path.replace("joypad", "steamdeck")
	match path.substr(path.find("/") + 1):
		"lb":
			return path.replace("/lb", "/l1")
		"rb":
			return path.replace("/rb", "/r1")
		"lt":
			return path.replace("/lt", "/l2")
		"rt":
			return path.replace("/rt", "/r2")
		"select":
			return path.replace("/select", "/square")
		"start":
			return path.replace("/start", "/menu")
		"home":
			return path.replace("/home", "/steam")
		"share":
			return path.replace("/share", "/dots")
		_:
			return path
