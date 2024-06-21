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
	DEBUG,	## Log debug, info, warnings, and errors
	TRACE,	## Log everything
}

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

		# TODO: This is a circular dependency that causes compilation errors.
		# get_logger needs to be static to be used to instantiate loggers in
		# other scripts outside of _ready. Register can't be static. A true
		# LogManager class might fix this.
		# Register the logger with LogManager
		var log_manager := load("res://core/systems/debug/log_manager.tres") as LogManager
		log_manager.register(logger)

	return logger
