extends Object
class_name Log

# Possible log levels
enum LEVEL {
	NONE,
	ERROR,
	WARN,
	INFO,
	DEBUG,
}

class Logger:
	var _name: String
	var _level: int
	
	func _init(name: String, level: LEVEL = LEVEL.INFO):
		self._name = name
		self._level = level
	
	func _get_caller() -> Dictionary:
		var stack := get_stack()
		return stack[2]
		
	func _format_prefix(level: String, caller: Dictionary) -> String:
		var file: String = caller["source"].split("/")[-1]
		var line: int = caller["line"]
		var prefix := "[{0}] [{1}] {2}:{3}: ".format([level, self._name, file, line])
		return prefix
		
	func debug(message: Variant):
		if self._level < LEVEL.DEBUG:
			return
		var prefix := _format_prefix("DEBUG", _get_caller())
		print_rich("[color=cyan]", prefix, "[/color]", message)
		
	func info(message: Variant):
		if self._level < LEVEL.INFO:
			return
		var prefix := _format_prefix("INFO", _get_caller())
		print_rich("[color=white]", prefix, "[/color]", message)
	
	func warn(message: Variant):
		if self._level < LEVEL.WARN:
			return
		var prefix := _format_prefix("WARN", _get_caller())
		push_warning(prefix, message)
		print_rich("[color=orange]", prefix, "[/color]", message)
	
	func error(message: Variant):
		if self._level < LEVEL.ERROR:
			return
		var prefix := _format_prefix("ERROR", _get_caller())
		push_error(prefix, message)
		print_rich("[color=red]", prefix, "[/color]", message)

	
# Returns a named logger for logging
static func get_logger(name: String, level: LEVEL = LEVEL.INFO) -> Logger:
	return Logger.new(name, level)
