extends Resource
class_name CPUCore

## Instance of a single CPU core

var path: String
var num: int

func _init(n: int) -> void:
	num = n
	path = "/".join([CPU.CPUS_PATH, "cpu" + str(n)])


## Returns whether or not the core is online
func get_online() -> bool:
	if num == 0:
		return true
	var online_str := _get_property("online").strip_escapes()
	return online_str == "1"


func _get_property(prop: String) -> String:
	var prop_path := "/".join([path, prop])
	if not FileAccess.file_exists(prop_path):
		return ""
	var file := FileAccess.open(prop_path, FileAccess.READ)
	var length := file.get_length()
	var bytes := file.get_buffer(length)

	return bytes.get_string_from_utf8()


func _to_string() -> String:
	return "<Core" + str(num) + ">"
