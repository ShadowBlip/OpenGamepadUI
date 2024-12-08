extends Resource
class_name CPU

## Read and manage the system CPU

## Emitted when CPU boost is updated
signal boost_updated(enabled: bool)
## Emitted when SMT is updated
signal smt_updated(enabled: bool)

const CPUS_PATH := "/sys/bus/cpu/devices"

var core_count := get_total_core_count()
var vendor: String
var model: String
var logger := Log.get_logger("CPU")


func _init() -> void:
	var cpu_raw := _get_lscpu_info()
	for param in cpu_raw:
		var parts := param.split(" ", false) as Array
		if parts.is_empty():
			continue
		if parts[0] == "Vendor" and parts[1] == "ID:":
			# Delete parts of the string we don't want
			parts.remove_at(1)
			parts.remove_at(0)
			vendor = str(" ".join(parts))
		if parts[0] == "Model" and parts[1] == "name:":
			# Delete parts of the string we don't want
			parts.remove_at(1)
			parts.remove_at(0)
			model = str(" ".join(parts))
		# TODO: We can get min/max CPU freq here.


## Returns the count of number of enabled CPU cores
func get_enabled_core_count() -> int:
	return OS.get_processor_count()


## Returns an instance of the given CPU core
func get_core(num: int) -> CPUCore:
	# Try to load the core info if it already exists
	var res_path := "hardware://cpu/" + str(num)
	if ResourceLoader.exists(res_path):
		var core := load(res_path) as CPUCore
		core.update()
		return core

	# Create a new core instance and take over the caching path
	var core := CPUCore.new(num)
	core.take_over_path(res_path)
	core.update()

	return core


## Returns an array of all CPU cores
func get_cores() -> Array[CPUCore]:
	var cores: Array[CPUCore] = []
	for core_num in range(0, core_count):
		var core := get_core(core_num)
		if core:
			cores.append(core)
	
	return cores


## Returns the total number of detected CPU cores
func get_total_core_count() -> int:
	var core_dirs := DirAccess.get_directories_at(CPUS_PATH)
	if core_dirs.size() == 0:
		logger.warn("Unable to determine total CPU count")
		return 1
	return core_dirs.size()


## Returns the total number of CPU cores that are online
func get_online_core_count() -> int:
	var count := 0
	for core in get_cores():
		if not core.online:
			continue
		count += 1
	return count


func _get_property(prop_path: String) -> String:
	if not FileAccess.file_exists(prop_path):
		return ""
	var file := FileAccess.open(prop_path, FileAccess.READ)
	var length := file.get_length()
	var bytes := file.get_buffer(length)

	return bytes.get_string_from_utf8()


## Provides info on the GPU vendor, model, and capabilities.
func _get_lscpu_info() -> PackedStringArray:
	var cmd := Command.create("lscpu", [])
	if cmd.execute_blocking() != OK:
		return []
	return cmd.stdout.split("\n")


func _to_string() -> String:
	return "<CPU:" \
		+ " Vendor: (" + str(vendor) \
		+ ") Model: (" + str(model) \
		+ ") Core count: (" + str(core_count) \
		+ ")>"
