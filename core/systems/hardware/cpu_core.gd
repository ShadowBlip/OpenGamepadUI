extends Resource
class_name CPUCore

## Instance of a single CPU core

var path: String
var num: int
var online: bool:
	get:
		var prop := online
		return prop
	set(v):
		if online == v:
			return
		online = v
		changed.emit()

func _init(n: int) -> void:
	num = n
	path = "/".join([CPU.CPUS_PATH, "cpu" + str(n)])


## Update the state of the CPU core
func update() -> void:
	online = get_online()


## Returns whether or not the core is online
func get_online() -> bool:
	if num == 0:
		return true
	var online_str := _get_property("online").strip_escapes()
	return online_str == "1"


## Sets the online state of the CPU core
func set_online(enabled: bool) -> int:
	var logger := Log.get_logger("CPUInfo")
	if num == 0:
		logger.warn("Unable to disable CPU 0")
		return -1
	var enabled_str := "1" if enabled else "0"
	var cmd := CommandSync.new(CPU.POWERTOOLS_PATH, ["cpuToggle", str(num), enabled_str])
	if cmd.execute() != OK:
		logger.warn("Failed to update CPU core: " + cmd.stdout)
	update()
	logger.info("Set core " + str(num) + " enabled: " + str(enabled))

	return cmd.code


func _get_property(prop: String) -> String:
	var prop_path := "/".join([path, prop])
	if not FileAccess.file_exists(prop_path):
		return ""
	var file := FileAccess.open(prop_path, FileAccess.READ)
	var length := file.get_length()
	var bytes := file.get_buffer(length)

	return bytes.get_string_from_utf8()


func _to_string() -> String:
	return "<Core" + str(num) + " Online: " + str(online) + ">"
