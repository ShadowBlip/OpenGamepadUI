@icon("res://addons/core/assets/icons/inputplumber.svg")
extends Node
class_name InputPlumber

## Manages routing input to and from InputPlumber.
##
## The InputPlumberManager class is responsible for handling dbus messages to and
## from the InputPlumber input manager daemon.

const DEFAULT_PROFILE := "res://assets/gamepad/profiles/default.json"
const DEFAULT_GLOBAL_PROFILE := "user://data/gamepad/profiles/global_default.json"
const PROFILES_DIR := "user://data/gamepad/profiles"

@export var instance: InputPlumberInstance = load("res://core/systems/input/input_plumber.tres")

# Keep a reference to dbus devices so they are not cleaned up automatically
var _dbus_devices := {}


func _ready() -> void:
	# Add listeners for any new devices
	var on_device_added := func(device: CompositeDevice):
		var dbus_devices := device.dbus_devices
		if dbus_devices.is_empty():
			return
		var dbus_device := dbus_devices[0]
		var dbus_path := device.dbus_path
		_dbus_devices[dbus_path] = dbus_device
	instance.composite_device_added.connect(on_device_added)
	
	# Add listeners when devices are removed
	var on_device_removed := func(dbus_path: String):
		if not _dbus_devices.has(dbus_path):
			return
		_dbus_devices.erase(dbus_path)
	instance.composite_device_removed.connect(on_device_removed)

	# Find all composite devices
	var devices := instance.get_composite_devices()
	for device in devices:
		on_device_added.call(device)


func _process(_delta: float) -> void:
	if not instance:
		return
	instance.process()


 ## Load the given profile on the composite device, optionally specifying a profile
## modifier, which is a target device string (e.g. "deck", "ds5-edge", etc.) to
## adapt the profile for. This will update the profile with target-specific
## defaults, like mapping left/right pads to the DualSense center pad if no
## other mappings are defined.
static func load_target_modified_profile(device: CompositeDevice, path: String, profile_modifier: String = "") -> void:
	var logger := Log.get_logger("InputPlumber", Log.LEVEL.DEBUG)
	logger.debug("Loading Profile:", path)
	if path == "" or not path.ends_with(".json") or not FileAccess.file_exists(path):
		logger.error("Profile path:", path," is not a valid profile path.")
		return
	if profile_modifier.is_empty():
		device.load_profile_path(path)
		return

	var profile := InputPlumberProfile.load(path)

	var c_pad_cap = "Touchpad:CenterPad:Motion"
	var l_pad_cap = "Touchpad:LeftPad:Motion"
	var r_pad_cap = "Touchpad:RightPad:Motion"
	var mouse_cap = "Mouse:Motion"

	if !profile_modifier.is_empty():
		var mapped_capabilities := profile.to_json()
		logger.debug("Mapped Capabilities (before):", mapped_capabilities)
		match profile_modifier:
				"deck":
					logger.debug("Steam Deck Profile")
					if c_pad_cap not in mapped_capabilities:
						logger.debug("Map", c_pad_cap)
						var c_pad_map := InputPlumberMapping.from_source_capability(c_pad_cap)
						var r_pad_event := InputPlumberEvent.from_capability(r_pad_cap)
						c_pad_map.target_events = [r_pad_event]
						profile.mapping.append(c_pad_map)

				"ds5", "ds5-edge":
					logger.debug("Dualsense Profile")
					if l_pad_cap not in mapped_capabilities:
						logger.debug("Map", l_pad_cap)
						var l_pad_map := InputPlumberMapping.from_source_capability(l_pad_cap)
						var c_pad_event := InputPlumberEvent.from_capability(c_pad_cap)
						l_pad_map.target_events = [c_pad_event]
						profile.mapping.append(l_pad_map)
					if r_pad_cap not in mapped_capabilities:
						logger.debug("Map", r_pad_cap)
						var r_pad_map := InputPlumberMapping.from_source_capability(r_pad_cap)
						var c_pad_event := InputPlumberEvent.from_capability(c_pad_cap)
						r_pad_map.target_events = [c_pad_event]
						profile.mapping.append(r_pad_map)

				_:
					logger.debug("Target device needs no modifications:", profile_modifier)

		mapped_capabilities = profile.to_json()
		logger.debug("Mapped Capabilities (after):", mapped_capabilities)

	path = path.rstrip(".json") + profile_modifier + ".json"
	if profile.save(path) != OK:
		logger.error("Failed to save", profile.name, "to", path)
		return
	device.load_profile_path(path)
