extends Resource
class_name Log


## Interface to control logging across an array of loggers
##
## Log provides an interface to control the logging level of various
## components in OpenGamepadUI.

## Possible log levels
enum LEVEL {
	NONE,	## Log nothing
	ERROR,	## Only log errors
	WARN,	## Log warnings and errors
	INFO,	## Log info, warnings, and errors
	DEBUG,	## Log everything
}

signal logger_registered(logger: Logger)
signal logger_unregistered
signal loggers_changed

## Mapping of loggers by their name. This is in the form of {"<logger name>": [<logger>, ...]}
var loggers_by_name: Dictionary = {}
## Mutex to allow register/unregister through threads
var mutex := Mutex.new()


## Register the given logger with the LogManager
func register(logger: Logger) -> void:
	if logger.get_name() == "":
		return
	mutex.lock()
	if not logger.get_name() in loggers_by_name:
		loggers_by_name[logger.get_name()] = []
	(loggers_by_name[logger.get_name()] as Array).append(logger)
	mutex.unlock()

	# If the global log level variable was set on start, update the logger's log level.
	# E.g. LOG_LEVEL=debug opengamepadui
	set_log_level_from_env(logger, "LOG_LEVEL")

	# Check to see if there is a named logger log level variable set. If there is,
	# update the log level.
	# E.g. LOG_LEVEL_BOXARTMANAGER=debug opengamepadui
	var env_suffix := logger.get_name().to_upper().replace(" ", "")
	set_log_level_from_env(logger, "LOG_LEVEL_" + env_suffix)

	# NOTE: Decrement the reference count so the logger gets garbage collected
	# if we're the only one referencing it.
	#logger.unreference()

	logger_registered.emit(logger)
	loggers_changed.emit()


## Set the given log level on all loggers
func set_global_log_level(level: Log.LEVEL) -> void:
	mutex.lock()
	var logger_names := loggers_by_name.keys()
	mutex.unlock()
	for logger in logger_names:
		set_log_level(logger, level)


## Sets the log level on loggers with the given name to the given level.
func set_log_level(name: String, level: Log.LEVEL) -> void:
	mutex.lock()
	var all_loggers := loggers_by_name.duplicate()
	mutex.unlock()
	if not name in all_loggers:
		return
	
	var loggers := all_loggers[name] as Array
	for l in loggers:
		if not l:
			continue
		var logger := l as Logger
		logger.set_level(level)


## Looks up the given environment variable and sets the log level on the given
## logger if the variable exists.
func set_log_level_from_env(logger: Logger, env_var: String) -> void:
	var env_level := OS.get_environment(env_var)
	if env_level == "":
		return
	match env_level.to_lower():
		"debug", "trace":
			logger.set_level(Log.LEVEL.DEBUG)
		"info":
			logger.set_level(Log.LEVEL.INFO)
		"warn", "warning":
			logger.set_level(Log.LEVEL.WARN)
		"error":
			logger.set_level(Log.LEVEL.ERROR)


## Return a list of loggers that are currently registered
func get_available_loggers() -> PackedStringArray:
	mutex.lock()
	var logger_names := loggers_by_name.keys()
	mutex.unlock()
	return logger_names


## Returns a named logger for logging
static func get_logger(name: String, level: LEVEL = LEVEL.INFO) -> Logger:
	# Try to load the logger if it already exists
	var res_path := "logger://" + name
	var logger: Logger
	if ResourceLoader.exists(res_path):
		logger = load(res_path)
	else:
		logger = Logger.new(name, level)
		logger.take_over_path("logger://" + name)

		# Register the logger with LogManager
		var log_manager := load("res://core/systems/debug/log_manager.tres") as Log
		log_manager.register(logger)

	return logger


## Named logger that can log text with a prefix and a name
class Logger extends Resource:
	var _level: int
	
	func _init(name: String, level: LEVEL = LEVEL.INFO):
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
	
	func set_level(level: LEVEL) -> void:
		_level = level
	
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
