extends PlatformAction
class_name ActionStartOpenSD

var opensd: OpenSD


func execute() -> void:
	var config := FileAccess.open("res://assets/gamepad/opensd/config/config.ini", FileAccess.READ)
	var config_bytes := config.get_buffer(20480)
	var user_config := (
		FileAccess.open("user://data/gamepad/opensd/config/config.ini", FileAccess.WRITE_READ)
	)
	user_config.store_buffer(config_bytes)

	var profile := (
		FileAccess.open("res://assets/gamepad/opensd/profiles/default.profile", FileAccess.READ)
	)
	var profile_bytes := profile.get_buffer(20480)
	var user_profile := (
		FileAccess.open("user://data/gamepad/opensd/profiles/default.profile", FileAccess.WRITE_READ)
	)
	user_profile.store_buffer(profile_bytes)

	logger.info("Starting OpenSD input thread")
	var thread := Thread.new()
	opensd = OpenSD.new()
	thread.start(opensd.run)
