extends Resource
class_name CPU

## Read and manage the system CPU

## Emitted when CPU boost is updated
signal boost_updated(enabled: bool)
## Emitted when SMT is updated
signal smt_updated(enabled: bool)

const POWERTOOLS_PATH := "/usr/share/opengamepadui/scripts/powertools"
const BOOST_PATH := "/sys/devices/system/cpu/cpufreq/boost"
const SMT_PATH := "/sys/devices/system/cpu/smt/control"
const CPUS_PATH := "/sys/bus/cpu/devices"

var mutex := Mutex.new()
var core_count := get_total_core_count()
var boost_capable: bool = false
var boost_enabled := false:
	get:
		mutex.lock()
		var prop := boost_enabled
		mutex.unlock()
		return prop
	set(v):
		if boost_enabled == v:
			return
		mutex.lock()
		boost_enabled = v
		mutex.unlock()
		emit_signal.call_deferred("changed")
		emit_signal.call_deferred("boost_updated", v)
var vendor: String
var model: String
var smt_capable: bool = false
var smt_enabled := false:
	get:
		mutex.lock()
		var prop := smt_enabled
		mutex.unlock()
		return prop
	set(v):
		if smt_enabled == v:
			return
		mutex.lock()
		smt_enabled = v
		mutex.unlock()
		emit_signal.call_deferred("changed")
		emit_signal.call_deferred("smt_updated", v)
var logger := Log.get_logger("CPU")


func _init() -> void:
	var cpu_raw := _get_lscpu_info()
	for param in cpu_raw:
		var parts := param.split(" ", false) as Array
		if parts.is_empty():
			continue
		if parts[0] == "Flags:":
			if "ht" in parts:
				smt_capable = true
			if "cpb" in parts and FileAccess.file_exists(BOOST_PATH):
				boost_capable = true
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
	update()


## Returns the count of number of enabled CPU cores
func get_enabled_core_count() -> int:
	return OS.get_processor_count()


## Returns true if boost is currently enabled
func get_boost_enabled() -> bool:
	if not boost_capable:
		return false
	var value := _get_property(BOOST_PATH).to_lower().strip_edges()

	return value == "on" or value == "1"


## Set CPU boost to the given value
func set_boost_enabled(enabled: bool) -> int:
	if not boost_capable:
		return -1
	var enabled_str := "1" if enabled else "0"
	var args := ["cpuBoost", enabled_str]
	var cmd := CommandSync.new(POWERTOOLS_PATH, args)
	if cmd.execute() != OK:
		logger.warn("Failed to set CPU boost")
		return cmd.code
	update()
	
	return cmd.code


## Returns true if SMT is currently enabled
func get_smt_enabled() -> bool:
	if not smt_capable:
		return false
	var value := _get_property(SMT_PATH).to_lower().strip_edges()

	return value == "on" or value == "1"


## Set CPU smt to the given value
func set_smt_enabled(enabled: bool) -> int:
	if not smt_capable:
		return -1
	var enabled_str := "1" if enabled else "0"
	var args := ["smtToggle", enabled_str]
	var cmd := CommandSync.new(POWERTOOLS_PATH, args)
	if cmd.execute() != OK:
		logger.warn("Failed to set CPU smt")
		return cmd.code
	update()
	
	return cmd.code


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


## Called to set the number of enabled CPU's
func set_cpu_core_count(value: int) -> void:
	# Update the state of the CPU
	update()
	var cores := get_cores()
	logger.debug("Enable cpu cores: " + str(value) + "/" + str(cores.size()))

	for core in cores:
		if core.num == 0:
			continue
		var online := true
		if smt_enabled and core.num >= value:
			online = false
		elif not smt_enabled:
			if core.num % 2 != 0 or core.num >= (value * 2) - 1:
				online = false
		logger.debug("Set CPU No: " + str(core.num) + " online: " + str(online))
		core.set_online(online)


## Fetches the current CPU info
func update() -> void:
	boost_enabled = get_boost_enabled()
	smt_enabled = get_smt_enabled()


func _get_property(prop_path: String) -> String:
	if not FileAccess.file_exists(prop_path):
		return ""
	var file := FileAccess.open(prop_path, FileAccess.READ)
	var length := file.get_length()
	var bytes := file.get_buffer(length)

	return bytes.get_string_from_utf8()


## Provides info on the GPU vendor, model, and capabilities.
func _get_lscpu_info() -> PackedStringArray:
	var cmd := CommandSync.new("lscpu")
	if cmd.execute() != OK:
		return []
	return cmd.stdout.split("\n")


func _to_string() -> String:
	return "<CPU:" \
		+ " Vendor: (" + str(vendor) \
		+ ") Model: (" + str(model) \
		+ ") Core count: (" + str(core_count) \
		+ ") Boost Capable: (" + str(boost_capable) \
		+ ") SMT Capable: (" + str(smt_capable) \
		+ ")>"

