extends PlatformProvider
class_name PlatformOneXPlayerGen4


func get_handheld_gamepad() -> HandheldGamepad:
	logger.info("Using OneXPlayer Gen 4 platform configuration.")
	var cmd := Command.new("/usr/share/opengamepadui/scripts/manage_input", ["turbo_takeover", "1"])
	var code := await cmd.execute() as int
	if code != OK:
		logger.warn("Unable to take over turbo button: " + cmd.stdout)

	return load("res://core/platform/onexplayer_gen4_gamepad.tres")
