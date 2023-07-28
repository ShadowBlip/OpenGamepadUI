@icon("res://assets/editor-icons/game-console.svg")
extends PlatformProvider
class_name HandheldPlatform


@export_category("Gamepad Profile")
#@export var gamepad: HandheldGamepad ## The handheld gamepad profile associated with this handheld
# Override below in device specific implementation
## List of MappedEvent's that are activated by a specific Array[InputDeviceEvent].
## that activates either an ogui_event or another Array[InputDeviceEvent]
@export var key_map: Array[HandheldEventMapping]
@export var keypads: Array[SysfsDevice]
@export var gamepad: SysfsDevice

@export_category("Images")
@export var image: Texture2D ## Image to show in the general settings menu
@export var logo: Texture2D ## Logo image of the platform

@export_category("Controller Icons")
@export var diagram: Texture2D = load("res://addons/controller_icons/assets/xboxone/diagram_simple.png")
@export var icon_mappings: Array[HandheldIconMapping] ## Array of icon mappings

@export_category("System Paths")
@export var thermal_policy_path: String


func is_handheld_gamepad(device: InputDevice) -> bool:
	logger.info("Test input device: " + device.get_path() + ": " + device.get_name())
	logger.info("Looking for: " + gamepad.phys_path + ": " + gamepad.name)
	if device.get_phys() == gamepad.phys_path and device.get_name() == gamepad.name:
		logger.info("Found handheld gamepad device: " + device.get_path() + ": " + device.get_name())
		return true
	logger.info("Rejected input device: " + device.get_path() + ": " + device.get_name())
	return false


func is_handheld_keyboard(device: InputDevice) -> bool:
	logger.info("Test input device: " + device.get_path() + ": " + device.get_name())
	for keypad in keypads:
		logger.info("Looking for: " + keypad.phys_path + ": " + keypad.name)
		if device.get_phys() == keypad.phys_path and device.get_name() == keypad.name:
			logger.info("Found handheld input device: " + device.get_path() + ": " + device.get_name())
			return true
	logger.info("Rejected input device: " + device.get_path() + ": " + device.get_name())
	return false
