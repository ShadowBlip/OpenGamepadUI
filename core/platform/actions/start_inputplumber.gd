extends PlatformAction
class_name ActionStartInputPlumber

const INPUT_PLUMBER_PATH := "/usr/share/opengamepadui/scripts/manage_input"


func execute() -> void:
	logger.info("Starting InputPlumber")
	var cmd := Command.create(INPUT_PLUMBER_PATH, ["startInputPlumber"])
	if cmd.execute_blocking() != OK:
		logger.warn("Failed to start InputPlumber: " + cmd.stdout)
