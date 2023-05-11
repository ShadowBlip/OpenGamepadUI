extends Resource
class_name LogManager

## Interface to control logging across an array of loggers
##
## LogManager provides an interface to control the logging level of various
## components in OpenGamepadUI.

signal logger_registered(logger: Log.Logger)
signal logger_unregistered
signal loggers_changed

## Mapping of loggers by their name. This is in the form of {"<logger name>": [<logger>, ...]}
var loggers_by_name: Dictionary = {}
## Mutex to allow register/unregister through threads
var mutex := Mutex.new()


## Register the given logger with the LogManager
func register(logger: Log.Logger) -> void:
	if logger.get_name() == "":
		return
	mutex.lock()
	if not logger.get_name() in loggers_by_name:
		loggers_by_name[logger.get_name()] = []
	loggers_by_name[logger.get_name()].append(logger)
	mutex.unlock()

	# If the global log level variable was set on start, update the logger's log level.
	# E.g. LOG_LEVEL=debug opengamepadui
	var env_level := OS.get_environment("LOG_LEVEL")
	if env_level != "":
		match env_level.to_lower():
			"debug", "trace":
				logger.set_level(Log.LEVEL.DEBUG)
			"info":
				logger.set_level(Log.LEVEL.INFO)
			"warn", "warning":
				logger.set_level(Log.LEVEL.WARN)
			"error":
				logger.set_level(Log.LEVEL.ERROR)
	
	# Check to see if there is a named logger log level variable set. If there is,
	# update the log level.
	# E.g. LOG_LEVEL_BOXARTMANAGER=debug opengamepadui
	var env_suffix := logger.get_name().to_upper().replace(" ", "")
	var env_named_level := OS.get_environment("LOG_LEVEL_" + env_suffix)
	if env_named_level != "":
		match env_named_level.to_lower():
			"debug", "trace":
				logger.set_level(Log.LEVEL.DEBUG)
			"info":
				logger.set_level(Log.LEVEL.INFO)
			"warn", "warning":
				logger.set_level(Log.LEVEL.WARN)
			"error":
				logger.set_level(Log.LEVEL.ERROR)

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
		var logger := l as Log.Logger
		logger.set_level(level)


## Return a list of loggers that are currently registered
func get_available_loggers() -> PackedStringArray:
	mutex.lock()
	var logger_names := loggers_by_name.keys()
	mutex.unlock()
	return logger_names
