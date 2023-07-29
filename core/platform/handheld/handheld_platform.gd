@icon("res://assets/editor-icons/game-console.svg")
extends PlatformProvider
class_name HandheldPlatform


@export_category("Gamepad Profile")

@export var key_map: Array[HandheldEventMapping]
@export var filtered_events: Array[EvdevEvent]
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
	if device.get_phys() == gamepad.phys_path and device.get_name() == gamepad.name:
		logger.info("Found handheld gamepad device: " + device.get_path() + ": " + device.get_name())
		return true
	return false


func is_handheld_keyboard(device: InputDevice) -> bool:
	for keypad in keypads:
		if device.get_phys() == keypad.phys_path and device.get_name() == keypad.name:
			logger.info("Found handheld input device: " + device.get_path() + ": " + device.get_name())
			return true
	return false
