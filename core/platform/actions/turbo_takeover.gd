extends PlatformAction
class_name ActionTurboTakeover


func execute() -> void:
	var cmd := Command.create("/usr/share/opengamepadui/scripts/manage_input", ["turbo_takeover", "1"])
	cmd.execute()
	var code := await cmd.finished as int
	if code != OK:
		logger.warn("Unable to take over turbo button: " + cmd.stdout + " " + cmd.stderr)
