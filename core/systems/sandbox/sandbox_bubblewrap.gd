extends Sandbox
class_name SandboxBubblewrap

const host_input_path := "/tmp/opengamepadui/sandbox/host/dev/input"
const child_input_path := "/tmp/opengamepadui/sandbox/child/dev/input"

var logger := Log.get_logger("SandboxBubblewrap", Log.LEVEL.DEBUG)


## Returns an array defining the command line to launch the given application
## in a sandbox.
func get_command(app: LibraryLaunchItem) -> PackedStringArray:
	# If sandboxing is available, launch the game in the sandbox 
	var sandbox := PackedStringArray()
	if not is_available():
		return sandbox
	
	# Create the necessary directories
	_ensure_sandbox_dirs()
	
	# Bind the entire filesystem
	sandbox.append_array(["bwrap", "--dev-bind", "/", "/"])
	
	# Mount the real unaltered /dev/input somewhere else in the sandbox so it can be
	# linked to
	sandbox.append_array(["--dev-bind", "/dev/input", host_input_path])
	
	# Mount a fake /dev/input inside the sandbox so only input devices that are
	# explicitly exposed will be visible to the process
	sandbox.append_array(["--dev-bind", child_input_path, "/dev/input"])
	
	# Apply platform-specific quirks to the sandbox command
	sandbox.append_array(_apply_quirks(app))
	sandbox.append("--")
	return sandbox


## Returns whether or not the given sandbox implementation is available
func is_available() -> bool:
	return OS.execute("which", ["bwrap"]) == 0


## Exposes the given event input device path inside the sandbox.
## E.g. "/dev/input/event9"
func expose_input_device(path: String) -> int:
	# Create the necessary directories
	_ensure_sandbox_dirs()
		
	# Convert the path into the host path
	# /dev/input/event9 -> /tmp/opengamepadui/sandbox/host/dev/input/event9
	var filename := path.split("/")[-1] as String
	var device_src := "/".join([host_input_path, filename])
	
	# Create a symlink from the real input device into the fake /dev/input
	# mounted in the sandbox
	var device_dst := "/".join([child_input_path, filename])
	logger.info("Exposing input device in sandbox: " + path)
	logger.debug("Creating device symlink with: ln -s {0} {1}".format([device_src, device_dst]))
	
	return OS.execute("ln", ["-s", device_src, device_dst])


## Removes the given input device from the sandbox.
func remove_input_device(path: String) -> int:
	# Convert the path into the host path
	# /dev/input/event9 -> /tmp/opengamepadui/sandbox/child/dev/input/event9
	var filename := path.split("/")[-1] as String
	var device := "/".join([child_input_path, filename])
	logger.info("Removing device from sandbox: " + path)
	logger.debug("Removing device symlink: " + device)
	
	return DirAccess.remove_absolute(device)


# Ensures the required sandboxing directories exist
func _ensure_sandbox_dirs() -> void:
	if not DirAccess.dir_exists_absolute(host_input_path):
		DirAccess.make_dir_recursive_absolute(host_input_path)
	if not DirAccess.dir_exists_absolute(child_input_path):
		DirAccess.make_dir_recursive_absolute(child_input_path)


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
