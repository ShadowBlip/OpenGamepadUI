extends PlatformAction
class_name ActionTurboTakeover


func execute() -> void:
	var cmd := Command.new("/usr/share/opengamepadui/scripts/manage_input", ["turbo_takeover", "1"])
	var code := await cmd.execute() as int
	if code != OK:
		logger.warn("Unable to take over turbo button: " + cmd.stdout)
