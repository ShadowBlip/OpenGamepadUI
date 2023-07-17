extends PlatformProvider
class_name PlatformAOKZOEGen1


func get_handheld_gamepad() -> HandheldGamepad:
	logger.info("Using AOKZOE Gen 1 platform configuration.")
	var cmd := Command.new("/usr/share/opengamepadui/scripts/manage_input", ["turbo_takeover", "1"])
	var code := await cmd.execute() as int
	if code != OK:
		logger.warn("Unable to take over turbo button: " + cmd.stdout)

	return load("res://core/platform/aokzoe_gen1_gamepad.tres")
