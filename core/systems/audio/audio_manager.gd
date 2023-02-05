extends Object
class_name AudioManager


# Returns true if the system has audio controls we support
static func supports_audio() -> bool:
	var code := OS.execute("which", ["wpctl"])
	return code == 0


# Sets the current audio device volume
static func set_volume(value: float) -> int:
	if value > 2:
		value = 2
	var percent := value * 100
	var code := OS.execute("wpctl", ["set-volume", "@DEFAULT_AUDIO_SINK@", str(percent) + "%"])
	return code


# Sets the current output device to the given device
static func set_output_device(device: String) -> int:
	var ids := PackedStringArray()
	var devices := PackedStringArray()
	for id in _get_wpctl_object_ids():
		var lines := _wpctl_inspect(id)
		var node_name: String
		var is_output := false
		for line in lines:
			if line.contains("node.description"):
				node_name = line.split('"', false)[-1]
			if line.contains("media.class") and line.contains("Audio/Sink"):
				is_output = true
		if is_output and node_name != "":
			devices.append(node_name)
			ids.append(id)

	if not device in devices:
		return -1
	var i := devices.find(device)
	var device_id := ids[i]

	return OS.execute("wpctl", ["set-default", device_id])


# Returns the currently set output device
static func get_current_output_device() -> String:
	var lines := _wpctl_inspect("@DEFAULT_AUDIO_SINK@")
	for line in lines:
		if line.contains("node.description"):
			return line.split('"', false)[-1]
	return ""


# Returns the current volume as a percentage. E.g. 0.52 is 52%
static func get_current_volume() -> float:
	var output := []
	var code := OS.execute("wpctl", ["get-volume", "@DEFAULT_AUDIO_SINK@"], output)
	if code != 0:
		return -1
	if output.size() == 0:
		return -1

	# Parse the output of wpctl
	# Example: Volume: 0.52
	var text := output[0] as String
	var parts := text.split(" ")
	if parts.size() < 2:
		return -1
	var vol_text := parts[1].strip_edges()
	if not vol_text.is_valid_float():
		return -1
	return vol_text.to_float()


# Returns a list of audio output devices
static func get_output_devices() -> PackedStringArray:
	var devices := PackedStringArray()
	for id in _get_wpctl_object_ids():
		var lines := _wpctl_inspect(id)
		var node_name: String
		var is_output := false
		for line in lines:
			if line.contains("node.description"):
				node_name = line.split('"', false)[-1]
			if line.contains("media.class") and line.contains("Audio/Sink"):
				is_output = true
		if is_output and node_name != "":
			devices.append(node_name)

	return devices


# Inspects the given wirepipe object
static func _wpctl_inspect(id: String) -> PackedStringArray:
	var out := PackedStringArray()
	var output := []
	var code := OS.execute("wpctl", ["inspect", id], output)
	if code != 0:
		return out
	if output.size() == 0:
		return out
	var text := output[0] as String
	return text.split("\n")


# Returns an array of discovered Wirepipe object IDs
static func _get_wpctl_object_ids() -> PackedStringArray:
	var ids := PackedStringArray()

	var output := []
	var code := OS.execute("wpctl", ["status"], output)
	if code != 0:
		return ids
	if output.size() == 0:
		return ids
	var text := output[0] as String
	var parts := text.split(" ")
	if parts.size() < 2:
		return ids

	var lines := text.split("\n")
	var regex := RegEx.new()
	regex.compile("  [0-9]+\\.")
	for line in lines:
		var result := regex.search(line)
		if not result:
			continue
		var id_text := result.get_string()
		ids.append(id_text.strip_edges().replace(".", ""))

	return ids
