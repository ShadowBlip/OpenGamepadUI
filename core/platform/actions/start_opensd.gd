extends PlatformAction
class_name ActionStartOpenSD

var opensd: OpenSD
var thread: Thread


func execute() -> void:
	DirAccess.make_dir_recursive_absolute("user://data/gamepad/opensd/config")
	var config := FileAccess.open("res://assets/gamepad/opensd/config/config.ini", FileAccess.READ)
	var config_bytes := config.get_buffer(20480)
	var user_config := (
		FileAccess.open("user://data/gamepad/opensd/config/config.ini", FileAccess.WRITE_READ)
	)
	user_config.store_buffer(config_bytes)

	DirAccess.make_dir_recursive_absolute("user://data/gamepad/opensd/profiles")
	var profile := (
		FileAccess.open("res://assets/gamepad/opensd/profiles/default.profile", FileAccess.READ)
	)
	var profile_bytes := profile.get_buffer(20480)
	var user_profile := (
		FileAccess.open("user://data/gamepad/opensd/profiles/default.profile", FileAccess.WRITE_READ)
	)
	user_profile.store_buffer(profile_bytes)

	logger.info("Starting OpenSD input thread")
	thread = Thread.new()
	thread.set_thread_safety_checks_enabled(false)
	opensd = OpenSD.new()
	thread.start(opensd.run)
