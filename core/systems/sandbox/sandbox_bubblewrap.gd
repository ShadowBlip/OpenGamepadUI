extends Sandbox
class_name SandboxBubblewrap

var gamepad_manager := load("res://core/systems/input/gamepad_manager.tres") as GamepadManager


## Returns an array defining the command line to launch the given application
## in a sandbox.
func get_command(app: LibraryLaunchItem) -> PackedStringArray:
	# If sandboxing is available, launch the game in the sandbox 
	var sandbox := PackedStringArray()
	if not is_available():
		return sandbox
	
	# Bind the entire filesystem
	sandbox.append_array(["bwrap", "--dev-bind", "/", "/"])
	
	# Blacklist any managed gamepads
	var blacklist := gamepad_manager.get_gamepad_paths()
	for device in blacklist:
		sandbox.append_array(["--bind", "/dev/null", device])
	
	# Apply platform-specific quirks to the sandbox command
	sandbox.append_array(_apply_quirks(app))
	sandbox.append("--")
	return sandbox


## Returns whether or not the given sandbox implementation is available
func is_available() -> bool:
	return OS.execute("which", ["bwrap"]) == 0


# Applies additional blacklists depending on if we're launching a steam app
func _apply_quirks(app: LibraryLaunchItem) -> PackedStringArray:
	var args := PackedStringArray()
	# Only block device access if this is a Steam app
	if app.command != "steam":
		return args
	
	# Block any hidraw devices
	var devices := DirAccess.get_files_at("/dev")
	for dev in devices:
		if not dev.begins_with("hidraw"):
			continue
		var path := "/".join(["/dev", dev])
		args.append_array(["--bind", "/dev/null", path])
	return args
