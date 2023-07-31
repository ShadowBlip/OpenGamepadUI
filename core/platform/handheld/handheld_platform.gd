@icon("res://assets/editor-icons/game-console.svg")
extends PlatformProvider
class_name HandheldPlatform

## PC Handheld platform provider


@export_category("Gamepad Profile")
## List of MappedEvent's that are activated by a specific Array[InputDeviceEvent].
## that activates either an ogui_event or another Array[InputDeviceEvent]
@export var key_map: Array[HandheldEventMapping]
## List of events to filter from the handheld keypads
@export var filtered_events: Array[EvdevEvent]
## One or more keyboard devices that the handheld device uses for extra buttons.
## The events from these devices will be watched and translated according to the
## key map.
@export var keypads: Array[SysfsDevice]
## Path and name of the gamepad device that is built-in to the handheld.
@export var gamepad: SysfsDevice

@export_category("Images")
## Image of the device to show in the general settings menu
@export var image: Texture2D
## Logo image of the platform
@export var logo: Texture2D

@export_category("Controller Icons")
## Image of the device as a diagram to show in the gamepad configuration menus.
@export var diagram: Texture2D = load("res://addons/controller_icons/assets/xboxone/diagram_simple.png")
## Custom icon images to use when displaying buttons/joysticks in the interface
@export var icon_mappings: Array[HandheldIconMapping]

@export_category("System Paths")
## Optional path to the thermal policy file
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
