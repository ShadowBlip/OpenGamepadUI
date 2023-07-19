extends TextureRect

var logger := Log.get_logger("GamepadDiagram")

var diagram_map := {
	ControllerSettings.Devices.XBOXSERIES: "res://addons/controller_icons/assets/xboxseries/diagram_simple.png",
	ControllerSettings.Devices.XBOXONE: "res://addons/controller_icons/assets/xboxone/diagram_simple.png",
	ControllerSettings.Devices.XBOX360: "res://assets/images/gamepad/xbox360/XboxOne_Diagram.png",
	ControllerSettings.Devices.OXP: "res://assets/images/gamepad/oxp-mini/diagram.png",
	ControllerSettings.Devices.STEAM_DECK: "res://assets/images/gamepad/steamdeck/diagram.png",
	ControllerSettings.Devices.PS5: "res://addons/controller_icons/assets/ps5/diagram_simple.png",
}


func _ready() -> void:
	_update_diagram()
	Input.joy_connection_changed.connect(_on_joy_connection_changed)
	


func _on_joy_connection_changed(_device, _connected):
	_update_diagram()


# Updates the center controller diagram with the appropriate texture
func _update_diagram() -> void:
	var mapper := ControllerMapper.new()
	var fallback := ControllerSettings.Devices.XBOX360
	logger.debug("Found gamepad type: " + Input.get_joy_name(0))
	var gamepad_type := mapper._get_joypad_type(fallback) as ControllerSettings.Devices
	if gamepad_type in diagram_map:
		texture = load(diagram_map[gamepad_type])
		return

	# Fallback if we have no diagram
	texture = load("res://assets/images/gamepad/xbox360/XboxOne_Diagram.png")
