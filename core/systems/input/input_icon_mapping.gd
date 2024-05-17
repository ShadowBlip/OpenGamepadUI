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
@export var keyboard: Texture
@export var mute: Texture

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
@export var left_stick_touch: Texture
@export var right_stick: Texture
@export var right_stick_left: Texture
@export var right_stick_right: Texture
@export var right_stick_up: Texture
@export var right_stick_down: Texture
@export var right_stick_click: Texture
@export var right_stick_touch: Texture

@export_category("Touchpad Mappings")
@export var left_pad: Texture
@export var center_pad: Texture
@export var right_pad: Texture

@export_category("Gyro")
@export var gyro: Texture


## Return the texture in the mapping from the given path
func get_texture(path: String) -> Texture:
	match path:
		# Diagram
		"joypad/diagram":
			return self.diagram
		# Buttons
		"joypad/north", "joypad/y":
			return self.north
		"joypad/south", "joypad/a":
			return self.south
		"joypad/west", "joypad/x":
			return self.west
		"joypad/east", "joypad/b":
			return self.east
		"joypad/start":
			return self.start
		"joypad/select":
			return self.select
		"joypad/guide", "joypad/home":
			return self.guide
		"joypad/quick", "joypad/quickaccess":
			return self.quickaccess
		"joypad/quick2", "joypad/quickaccess2":
			return self.quickaccess_2
		"joypad/share":
			return self.share
		"joypad/keyboard":
			return self.keyboard
		"joypad/mute":
			return self.mute
		# DPad
		"joypad/dpad":
			return self.dpad
		"joypad/dpad_up", "joypad/dpad/up":
			return self.dpad_up
		"joypad/dpad_down", "joypad/dpad/down":
			return self.dpad_down
		"joypad/dpad_left", "joypad/dpad/left":
			return self.dpad_left
		"joypad/dpad_right", "joypad/dpad/right":
			return self.dpad_right
		# Shoulders
		"joypad/left_shoulder", "joypad/lb":
			return self.left_shoulder
		"joypad/right_shoulder", "joypad/rb":
			return self.right_shoulder
		"joypad/left_top":
			return self.left_top
		"joypad/right_top":
			return self.right_top
		# Triggers
		"joypad/left_trigger", "joypad/lt":
			return self.left_trigger
		"joypad/right_trigger", "joypad/rt":
			return self.right_trigger
		# Back Paddles
		"joypad/left_paddle_1":
			return self.left_paddle_1
		"joypad/left_paddle_2":
			return self.left_paddle_2
		"joypad/left_paddle_3":
			return self.left_paddle_3
		"joypad/right_paddle_1":
			return self.right_paddle_1
		"joypad/right_paddle_2":
			return self.right_paddle_2
		"joypad/right_paddle_3":
			return self.right_paddle_3
		# Axes
		"joypad/left_stick", "joypad/l_stick":
			return self.left_stick
		"joypad/left_stick_click", "joypad/l_stick_click":
			return self.left_stick_click
		"joypad/left_stick_touch", "joypad/l_stick_touch":
			return self.left_stick_touch
		"joypad/left_stick_left", "joypad/left_stick/left", "joypad/l_stick_left", "joypad/l_stick/left":
			return self.left_stick_left
		"joypad/left_stick_right", "joypad/left_stick/right", "joypad/l_stick_right", "joypad/l_stick/right":
			return self.left_stick_right
		"joypad/left_stick_up", "joypad/left_stick/up", "joypad/l_stick_up", "joypad/l_stick/up":
			return self.left_stick_up
		"joypad/left_stick_down", "joypad/left_stick/down", "joypad/l_stick_down", "joypad/l_stick/down":
			return self.left_stick_down
		"joypad/right_stick", "joypad/r_stick":
			return self.right_stick
		"joypad/right_stick_click", "joypad/r_stick_click":
			return self.right_stick_click
		"joypad/right_stick_touch", "joypad/r_stick_touch":
			return self.right_stick_touch
		"joypad/right_stick_left", "joypad/right_stick/left", "joypad/r_stick_left", "joypad/r_stick/left":
			return self.right_stick_left
		"joypad/right_stick_right", "joypad/right_stick/right", "joypad/r_stick_right", "joypad/r_stick/right":
			return self.right_stick_right
		"joypad/right_stick_up", "joypad/right_stick/up", "joypad/r_stick_up", "joypad/r_stick/up":
			return self.right_stick_up
		"joypad/right_stick_down", "joypad/right_stick/down", "joypad/r_stick_down", "joypad/r_stick/down":
			return self.right_stick_down
		# Touchpads
		"joypad/left_pad":
			return self.left_pad
		"joypad/center_pad":
			return self.center_pad
		"joypad/right_pad":
			return self.right_pad
		# Gyro
		"joypad/gyro":
			return self.gyro

	return null
