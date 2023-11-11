extends PlatformAction
class_name ActionStartPowerStation

const POWERTOOLS_PATH := "/usr/share/opengamepadui/scripts/powertools"


func execute() -> void:
	logger.info("Starting PowerStation")
	var cmd := CommandSync.new(POWERTOOLS_PATH, ["startPowerStation"])
	if cmd.execute() != OK:
		logger.warn("Failed to start PowerStation: " + cmd.stdout)
