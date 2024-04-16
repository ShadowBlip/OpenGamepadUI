@icon("res://assets/editor-icons/game-console.svg")
extends PlatformProvider
class_name HandheldPlatform

## PC Handheld platform provider
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
