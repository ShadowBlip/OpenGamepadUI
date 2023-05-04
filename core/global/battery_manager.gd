@icon("res://assets/ui/icons/battery-charging.svg")
extends Resource
class_name BatteryManager


const power_supply_dir = "/sys/class/power_supply"

@export var icon_charging: Texture = preload("res://assets/ui/icons/battery-charging.svg")
@export var icon_full: Texture = preload("res://assets/ui/icons/battery-full.svg")
@export var icon_high: Texture = preload("res://assets/ui/icons/battery-75.svg")
@export var icon_half: Texture = preload("res://assets/ui/icons/battery-half.svg")
@export var icon_low: Texture = preload("res://assets/ui/icons/battery-low.svg")
@export var icon_empty: Texture = preload("res://assets/ui/icons/battery-empty.svg")

enum STATUS {
	NONE,
	DISCHARGING,
	NOT_CHARGING,
	CHARGING,
	FULL,
}

var battery_path: String = find_battery_path()
var logger := Log.get_logger("BatteryManager")

## Finds the battery path. If none is found, returns an empty string.
static func find_battery_path() -> Variant:
	var power_dir: DirAccess = DirAccess.open(power_supply_dir)
	var devices: PackedStringArray = power_dir.get_directories()
	var battery_dir: String = ""
	for folder in devices:
		if folder.begins_with("BAT"):
			battery_dir = folder
			break
	if battery_dir == "":
		return ""
	
	return "/".join([power_supply_dir, battery_dir])


## Returns the current battery capacity as a percentage. Returns -1 if no battery
## was discovered.
func get_capacity() -> int:
	if battery_path == "":
		return -1
	var capacity_file: String = "/".join([battery_path, "capacity"])
	var file: FileAccess = FileAccess.open(capacity_file, FileAccess.READ)
	var bytes: PackedByteArray = file.get_buffer(100)
	var str: String = bytes.get_string_from_ascii().strip_edges()
	if not str.is_valid_int():
		return -1
	return str.to_int()


## Returns the status of the given battery
func get_status() -> STATUS:
	if battery_path == "":
		return STATUS.NONE
	var status_file: String = "/".join([battery_path, "status"])
	
	var output := []
	var code := OS.execute("cat", [status_file], output)
	if code != OK:
		return STATUS.NONE
	var status := (output[0] as String).strip_edges()
	
	match status:
		"Discharging":
			return STATUS.DISCHARGING
		"Not charging":
			return STATUS.NOT_CHARGING
		"Charging":
			return STATUS.CHARGING
		"Full":
			return STATUS.FULL
	return STATUS.NONE


## Returns the texture reflecting the given battery capacity
func get_capacity_texture(capacity: int, status: STATUS = STATUS.NONE) -> Texture2D:
	if status > STATUS.NOT_CHARGING:
		return icon_charging
	if capacity >= 90:
		return icon_full
	if capacity >= 65:
		return icon_high
	if capacity >= 40:
		return icon_half
	if capacity >= 20:
		return icon_low
	return icon_empty
