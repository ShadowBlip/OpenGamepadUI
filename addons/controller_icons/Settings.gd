@tool
extends Resource
class_name ControllerSettings

enum Devices {
	LUNA,
	OUYA,
	PS3,
	PS4,
	PS5,
	STADIA,
	STEAM,
	SWITCH,
	JOYCON,
	VITA,
	WII,
	WIIU,
	XBOX360,
	XBOXONE,
	XBOXSERIES,
	STEAM_DECK
}

## Controller type to fallback to if automatic
## controller detection fails
@export var joypad_fallback : Devices = Devices.XBOX360

# Controller deadzone for triggering an icon remap when input
# is analogic (movement sticks or triggers)
@export_range(0.0, 1.0) var joypad_deadzone : float = 0.5

# Allow mouse movement to trigger an icon remap
@export var allow_mouse_remap : bool = true

# Minimum mouse "instantaneous" movement for
# triggering an icon remap
@export_range(0, 10000) var mouse_min_movement : int = 200

# Custom asset lookup folder for custom icons
@export_dir var custom_asset_dir : String = ""

# Custom generic joystick mapper script
@export var custom_mapper : Script
