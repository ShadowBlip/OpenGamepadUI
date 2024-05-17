@icon("res://assets/editor-icons/tabler-icons.svg")
extends Resource
class_name InputIconMapping

## Icon mapping for input devices

## Name of the icon mapping
@export var name: String

## Input device names to match
@export var device_names: PackedStringArray

@export_category("Diagram")
@export var diagram: Texture

@export_category("Button Mappings")
@export var north: Texture
@export var south: Texture
@export var east: Texture
@export var west: Texture
@export var guide: Texture
@export var start: Texture
@export var select: Texture
@export var share: Texture
@export var screenshot: Texture
@export var quickaccess: Texture
@export var quickaccess_2: Texture

@export_category("D-Pad Mappings")
@export var dpad: Texture
@export var dpad_left: Texture
@export var dpad_right: Texture
@export var dpad_up: Texture
@export var dpad_down: Texture

@export_category("Trigger Mappings")
@export var left_shoulder: Texture
@export var left_trigger: Texture
@export var left_top: Texture
@export var right_shoulder: Texture
@export var right_trigger: Texture
@export var right_top: Texture

@export_category("Back Paddle Mappings")
@export var left_paddle_1: Texture
@export var left_paddle_2: Texture
@export var left_paddle_3: Texture
@export var right_paddle_1: Texture
@export var right_paddle_2: Texture
@export var right_paddle_3: Texture

@export_category("Axis Mappings")
@export var left_stick: Texture
@export var left_stick_left: Texture
@export var left_stick_right: Texture
@export var left_stick_up: Texture
@export var left_stick_down: Texture
@export var left_stick_click: Texture
@export var right_stick: Texture
@export var right_stick_left: Texture
@export var right_stick_right: Texture
@export var right_stick_up: Texture
@export var right_stick_down: Texture
@export var right_stick_click: Texture

@export_category("Touchpad Mappings")
@export var left_pad: Texture
@export var center_pad: Texture
@export var right_pad: Texture

@export_category("Gyro")
@export var gyro: Texture


## Return the texture in the mapping from the given path
func get_texture(path: String) -> Texture:
	match path:
		"joypad/diagram":
			return self.diagram
		"joypad/north", "joypad/y":
			return self.north
		"joypad/south", "joypad/a":
			return self.south
		"joypad/west", "joypad/x":
			return self.west
		"joypad/east", "joypad/b":
			return self.east
		"joypad/left_shoulder", "joypad/lb":
			return self.left_shoulder
		"joypad/right_shoulder", "joypad/rb":
			return self.right_shoulder
		"joypad/left_trigger", "joypad/lt":
			return self.left_trigger
		"joypad/right_trigger", "joypad/rt":
			return self.right_trigger
		"joypad/start":
			return self.start
		"joypad/select":
			return self.select
		"joypad/l_stick_click":
			return self.left_stick_click
		"joypad/r_stick_click":
			return self.right_stick_click
		"joypad/guide", "joypad/home":
			return self.guide
		"joypad/quick", "joypad/quickaccess":
			return self.quickaccess
		"joypad/quick2", "joypad/quickaccess2":
			return self.quickaccess_2
		"joypad/share":
			return self.share
		"joypad/left_stick", "joypad/l_stick":
			return self.left_stick
		"joypad/right_stick", "joypad/r_stick":
			return self.right_stick
		"joypad/left_trigger", "joypad/lt":
			return self.left_trigger
		"joypad/right_trigger", "joypad/rt":
			return self.right_trigger
		"joypad/dpad":
			return self.dpad

	return null
