@icon("res://assets/icons/battery-charging.svg")
extends Object
class_name Battery

const power_supply_dir = "/sys/class/power_supply"
const icon_charging = preload("res://assets/ui/icons/battery-charging.svg")
const icon_full = preload("res://assets/ui/icons/battery-full.svg")
const icon_high = preload("res://assets/ui/icons/battery-75.svg")
const icon_half = preload("res://assets/ui/icons/battery-half.svg")
const icon_low = preload("res://assets/ui/icons/battery-low.svg")
const icon_empty = preload("res://assets/ui/icons/battery-empty.svg")

enum STATUS {
	NONE,
	DISCHARGING,
	NOT_CHARGING,
	CHARGING,
	FULL,
}

var logger := Log.get_logger("Battery")

# Finds the battery path. If none is found, returns null.
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


# Returns the current battery capacity as a percentage
static func get_capacity(battery: String) -> int:
	if battery == "":
		return -1
	var capacity_file: String = "/".join([battery, "capacity"])
	var file: FileAccess = FileAccess.open(capacity_file, FileAccess.READ)
	var bytes: PackedByteArray = file.get_buffer(100)
	var str: String = bytes.get_string_from_ascii().strip_edges()
	if not str.is_valid_int():
		return -1
	return str.to_int()


## Returns the status of the given battery
static func get_status(battery: String) -> STATUS:
	if battery == "":
		return STATUS.NONE
	var status_file: String = "/".join([battery, "status"])
	
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
static func get_capacity_texture(capacity: int, status: STATUS = STATUS.NONE) -> Texture2D:
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
