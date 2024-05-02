extends Resource
class_name InputPlumberProfile

## Resource for loading and saving InputPlumber Input Profiles
##
## This resource is used to load and save InputPlumber input profiles that can
## be used to remap gamepad inputs.

## Supported target devices to emulate
enum TargetDevice {
	Gamepad,
	Mouse,
	Keyboard,
	DualSense,
	DualSenseEdge,
	SteamDeck,
	XBox360,
}

## Version of the config
@export var version: int = 1

## Type of configuration schema
@export var kind: String = "DeviceProfile"

## Name of the profile
@export var name: String

## Target input devices to emulate
@export var target_devices: Array[TargetDevice]

## Input mappings
@export var mapping: Array[InputPlumberMapping]


## Load the InputPlumberProfile in JSON format from the given path
static func load(path: String) -> InputPlumberProfile:
	if not FileAccess.file_exists(path):
		return null
	var file := FileAccess.open(path, FileAccess.READ)
	var json := file.get_as_text()

	return InputPlumberProfile.from_json(json)


## Create an InputPlumberProfile from the given dictionary
static func from_dict(dict: Dictionary) -> InputPlumberProfile:
	var obj := InputPlumberProfile.new()
	if "version" in dict:
		obj.version = dict["version"]

	if "kind" in dict:
		obj.kind = dict["kind"]

	if "name" in dict:
		obj.name = dict["name"]

	if "target_devices" in dict:
		var devices: Array[TargetDevice] = []
		var target_devices_strs := dict["target_devices"] as Array
		for target_device_str: String in target_devices_strs:
			var target_device: TargetDevice
			match target_device_str:
				"gamepad":
					target_device = TargetDevice.Gamepad
				"mouse":
					target_device = TargetDevice.Mouse
				"keyboard":
					target_device = TargetDevice.Keyboard
				"ds5":
					target_device = TargetDevice.DualSense
				"ds5-edge":
					target_device = TargetDevice.DualSenseEdge
				"deck":
					target_device = TargetDevice.SteamDeck
				"xb360":
					target_device = TargetDevice.XBox360
			devices.append(target_device)
		obj.target_devices = devices

	if "mapping" in dict:
		var mappings: Array[InputPlumberMapping] = []
		var mapping_dict := dict["mapping"] as Array
		for map_dict: Dictionary in mapping_dict:
			var map := InputPlumberMapping.from_dict(map_dict)
			mappings.append(map)
		obj.mapping = mappings

	return obj


## Create an InputPlumberProfile from the given JSON string
static func from_json(json: String) -> InputPlumberProfile:
	var dict = JSON.parse_string(json)
	if not dict:
		return null
	return InputPlumberProfile.from_dict(dict as Dictionary)


## Save the profile to the given path in JSON format
func save(path: String) -> Error:
	if path.begins_with("user://") or path.begins_with("res://"):
		path = ProjectSettings.globalize_path(path)
	var path_parts := Array(path.split("/", false))
	path_parts.pop_back()
	var base_path := "/".join(path_parts)
	
	if DirAccess.make_dir_recursive_absolute(base_path) != OK:
		print("Failed to mkdir")
		return ERR_FILE_CANT_WRITE
	
	var data := self.to_json()
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		print("Failed to open file")
		return ERR_FILE_CANT_WRITE
	file.store_string(data)
	
	return OK


## Convert the profile to an easily serializable dictionary
func to_dict() -> Dictionary:
	var dict := {
		"version": self.version,
		"name": self.name,
		"kind": self.kind,
	}

	if self.target_devices and self.target_devices.size() > 0:
		var devices := []
		for target_device: TargetDevice in self.target_devices:
			var target_device_str: String
			match target_device:
				TargetDevice.Gamepad:
					target_device_str = "gamepad"
				TargetDevice.Mouse:
					target_device_str = "mouse"
				TargetDevice.Keyboard:
					target_device_str = "keyboard"
				TargetDevice.DualSense:
					target_device_str = "ds5"
				TargetDevice.DualSenseEdge:
					target_device_str = "ds5-edge"
				TargetDevice.SteamDeck:
					target_device_str = "deck"
				TargetDevice.XBox360:
					target_device_str = "xb360"
			devices.append(target_device_str)
		dict["target_devices"] = devices

	var mappings: Array[Dictionary] = []
	if self.mapping:
		for map: InputPlumberMapping in self.mapping:
			mappings.append(map.to_dict())
	dict["mapping"] = mappings

	return dict


## Serialize the profile to JSON
func to_json() -> String:
	var dict := self.to_dict()
	return JSON.stringify(dict)

