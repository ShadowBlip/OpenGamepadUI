extends PlatformAction
class_name ActionStartOpenSD

var opensd := OpenSD.new()
var thread: Thread


func execute() -> void:
	logger.debug("Running OpenSD action")
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

	thread = Thread.new()
	thread.start(_run)


func _run() -> void:
	logger.info("Starting OpenSD input thread")
	Thread.set_thread_safety_checks_enabled(false)
	opensd.run()
