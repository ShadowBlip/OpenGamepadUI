@icon("res://assets/editor-icons/game-console.svg")
extends PlatformProvider
class_name HandheldPlatform


@export_category("Gamepad Profile")
@export var gamepad: HandheldGamepad ## The handheld gamepad profile associated with this handheld

@export_category("Images")
@export var image: Texture2D ## Image to show in the general settings menu
@export var logo: Texture2D ## Logo image of the platform

@export_category("Controller Icons")
@export var diagram: Texture2D = load("res://addons/controller_icons/assets/xboxone/diagram_simple.png")
@export var icon_mappings: Array[HandheldIconMapping] ## Array of icon mappings

@export_category("System Paths")
@export var thermal_policy_path: String


func get_handheld_gamepad() -> HandheldGamepad:
	logger.info("Using " + name + " platform configuration.")
	return gamepad
