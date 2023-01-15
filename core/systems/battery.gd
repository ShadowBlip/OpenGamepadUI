extends Object
class_name Battery
@icon("res://assets/icons/battery-charging.svg")

const power_supply_dir = "/sys/class/power_supply"

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
