extends Sandbox
class_name SandboxFirejail

const InputManager := preload("res://core/global/input_manager.tres")


## Returns an array defining the command line to launch the given application
## in a sandbox.
func get_command(app: LibraryLaunchItem) -> PackedStringArray:
	# If sandboxing is available, launch the game in the sandbox 
	var sandbox := PackedStringArray()
	if is_available():
		sandbox.append_array(["firejail", "--noprofile"])
		var blacklist := InputManager.get_managed_gamepads()
		for device in blacklist:
			sandbox.append("--blacklist=%s" % device)
		sandbox.append("--")
	return sandbox


## Returns whether or not the given sandbox implementation is available
func is_available() -> bool:
	return OS.execute("which", ["firejail"]) == 0
