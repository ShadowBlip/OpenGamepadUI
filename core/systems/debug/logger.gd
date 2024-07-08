extends Resource
class_name Logger

## Named logger that can log text with a prefix and a name

var _level: int

func _init(name: String = "", level: Log.LEVEL = Log.LEVEL.INFO) -> void:
	self.resource_name = name
	self._level = level


func _get_caller() -> Dictionary:
	var stack := get_stack()
	if len(stack) == 0:
		return {"source": "", "line": 0}
	return stack[2]


func _format_prefix(level: String, caller: Dictionary) -> String:
	var file: String = caller["source"].split("/")[-1]
	var line: int = caller["line"]
	var time := Time.get_ticks_msec()
	var prefix := "{0} [{1}] [{2}] {3}:{4}: ".format([time, level, self.resource_name, file, line])
	return prefix


func _stringify(arg1: Variant, arg2: Variant = null, arg3: Variant = null, arg4: Variant = null, arg5: Variant = null, arg6: Variant = null) -> String:
	var array := PackedStringArray()
	for argument in [arg1, arg2, arg3, arg4, arg5, arg6]:
		if argument == null:
			continue
		if argument is String:
			array.push_back(argument as String)
			continue
		array.push_back(str(argument) as String)
	
	return " ".join(array)


func set_level(level: Log.LEVEL) -> void:
	_level = level


func trace(message: Variant, xtra2: Variant = null, xtra3: Variant = null, xtra4: Variant = null, xtra5: Variant = null, xtra6: Variant = null):
	if self._level < Log.LEVEL.TRACE:
		return
	var prefix := _format_prefix("TRACE", _get_caller())
	var msg := _stringify(message, xtra2, xtra3, xtra4, xtra5, xtra6)
	print_rich("[color=magenta]", prefix, "[/color]", msg)


func debug(message: Variant, xtra2: Variant = null, xtra3: Variant = null, xtra4: Variant = null, xtra5: Variant = null, xtra6: Variant = null):
	if self._level < Log.LEVEL.DEBUG:
		return
	var prefix := _format_prefix("DEBUG", _get_caller())
	var msg := _stringify(message, xtra2, xtra3, xtra4, xtra5, xtra6)
	print_rich("[color=cyan]", prefix, "[/color]", msg)


func info(message: Variant, xtra2: Variant = null, xtra3: Variant = null, xtra4: Variant = null, xtra5: Variant = null, xtra6: Variant = null):
	if self._level < Log.LEVEL.INFO:
		return
	var prefix := _format_prefix("INFO", _get_caller())
	var msg := _stringify(message, xtra2, xtra3, xtra4, xtra5, xtra6)
	print_rich("[color=white]", prefix, "[/color]", msg)


func warn(message: Variant, xtra2: Variant = null, xtra3: Variant = null, xtra4: Variant = null, xtra5: Variant = null, xtra6: Variant = null):
	if self._level < Log.LEVEL.WARN:
		return
	var prefix := _format_prefix("WARN", _get_caller())
	var msg := _stringify(message, xtra2, xtra3, xtra4, xtra5, xtra6)
	push_warning(prefix, msg)
	print_rich("[color=orange]", prefix, "[/color]", msg)


func error(message: Variant, xtra2: Variant = null, xtra3: Variant = null, xtra4: Variant = null, xtra5: Variant = null, xtra6: Variant = null):
	if self._level < Log.LEVEL.ERROR:
		return
	var prefix := _format_prefix("ERROR", _get_caller())
	var msg := _stringify(message, xtra2, xtra3, xtra4, xtra5, xtra6)
	push_error(prefix, msg)
	print_rich("[color=red]", prefix, "[/color]", msg)


func deprecated(message: Variant) -> void:
	var prefix := _format_prefix("DEPRECATED", _get_caller())
	var msg := str(message)
	print_rich("[color=pink]", prefix, "[/color]", msg)
