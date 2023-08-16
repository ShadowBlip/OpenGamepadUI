extends Resource
class_name DeviceHider

## Hide yo wife, hide yo devices

const input_default_path := "/dev/input"
const input_hidden_path := "/dev/input/.hidden"
var logger := Log.get_logger("DeviceHider")


## Try to hide the given event device
func hide_event_device(phys_path: String) -> String:
	logger.debug("Hiding " + phys_path)
	return await _manage_event_path("hide", get_event_from_phys(phys_path))


## Try to unhide the given event device
func restore_event_device(phys_path: String) -> String:
	logger.debug("Restoring " + phys_path)
	return await _manage_event_path("restore", get_event_from_phys(phys_path))


## Return the file names of any hidden devices (e.g. "event1")
func get_hidden_devices() -> PackedStringArray:
	if DirAccess.dir_exists_absolute(input_hidden_path):
		return DirAccess.get_files_at(input_hidden_path)
	return PackedStringArray()


## Return the event filename from the given path
func get_event_from_phys(phys_path: String)  -> String:
	var event := phys_path.split("/")[-1] as String
	return event 


## Unhide all hidden devices
func restore_all_hidden() -> void:
	logger.info("Restoring hidden UInput devices.")
	if not DirAccess.dir_exists_absolute(input_hidden_path):
		logger.debug("No hidden devices found")
		return

	var files := DirAccess.get_files_at(input_hidden_path)
	if files.size() == 0:
		logger.debug("Found no hidden files at " + input_hidden_path + ". Nothing to do.")
		return

	for file_name in files:
		if not file_name.begins_with("event"):
			continue
		logger.debug("Found hidden file: " + file_name)
		await restore_event_device(file_name)

	logger.info("Restore hidden UInput devices completed.")


# Returns the path that the device was moved to
func _manage_event_path(action: String, event_name: String) -> String:
	var cmd := Command.new("/usr/share/opengamepadui/scripts/manage_input", [action, event_name])
	logger.debug("Start _manage_event_path with command : " + cmd.cmd + " " + "  ".join(cmd.args))
	var exit_code := await cmd.execute()
	logger.debug("Output: " + str(cmd.stdout))
	logger.debug("Exit code: " +str(exit_code))
	if exit_code != OK:
		return ""
	if action == "hide":
		return "/".join([input_hidden_path, event_name])
	return "/".join([input_default_path, event_name])

