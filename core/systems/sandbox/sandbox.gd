extends Resource
class_name Sandbox


## Returns an array defining the command line to launch the given application
## in a sandbox.
## E.g. ["firejail", "--noprofile", "--"]
func get_command(app: LibraryLaunchItem) -> PackedStringArray:
	return []


## Returns whether or not the given sandbox implementation is available
func is_available() -> bool:
	return false


## Exposes the given event input device path inside the sandbox.
## E.g. "/dev/input/event9"
func expose_input_device(path: String) -> int:
	return OK


## Removes the given input device from the sandbox.
func remove_input_device(path: String) -> int:
	return OK


## Returns the best sandbox to use for launching apps
static func get_sandbox() -> Sandbox:
	var logger := Log.get_logger("Sandbox", Log.LEVEL.INFO)
	var bubblewrap := SandboxBubblewrap.new()
	if bubblewrap.is_available():
		logger.info("Using sandboxing: bubblewrap")
		return bubblewrap
	var firejail := SandboxFirejail.new()
	if firejail.is_available():
		logger.info("Using sandboxing: firejail")
		return firejail
	logger.info("No sandboxing provider was found")
	return Sandbox.new()
