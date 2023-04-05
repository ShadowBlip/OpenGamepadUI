extends Resource
class_name AudioManager

## Manage system volume and audio devices
## 
## The AudioManager is responsible for managing the system volume and audio
## devices if the host supports it.

signal volume_changed(value: float)
signal volume_mute_toggled()

## Types of volume changes that are supported
enum VOLUME {
	ABSOLUTE,
	RELATIVE,
}

## Limit the maximum volume to 200%
const volume_limit := "2.0"

## Thread to run audio changes on
var thread := load("res://core/systems/threading/audio_thread.tres") as SharedThread

## Current volume
var current_volume := await _get_current_volume()
var _muted := false
var _output_devices := PackedStringArray()
var _current_output := ""


func _init() -> void:
	thread.start()
	current_volume = await _get_current_volume()
	_output_devices = await _get_output_devices()


## Returns true if the system has audio controls we support
func supports_audio() -> bool:
	var code := OS.execute("which", ["wpctl"])
	return code == 0


## Sets the current audio device volume based on the given value. The volume
## value should be in the form of a percent where 1.0 equals 100%. The type
## can be either absolute (default) or relative volume values.[br][br]
##     [codeblock]
##     const AudioManager := preload("res://core/global/audio_manager.tres")
##     ...
##     AudioManager.set_volume(1.0) # Set volume to 100%
##     AudioManager.set_volume(-0.06, AudioManager.TYPE.RELATIVE) # Decrease volume by 6%
##     [/codeblock]
func set_volume(value: float, type: VOLUME = VOLUME.ABSOLUTE) -> int:
	# Clamp the value to min and max values
	value = minf(volume_limit.to_float(), value)
	value = maxf(0, value)
	
	# Set the volume immediately and async control the system volume
	var last_volume := current_volume
	if type == VOLUME.ABSOLUTE:
		current_volume = value
	else:
		current_volume += value
	if last_volume != current_volume:
		volume_changed.emit(current_volume)

	# Build the wireplumber arguments
	var suffix := "%"
	if type == VOLUME.RELATIVE:
		if value < 0:
			suffix = "%-"
			value = abs(value)
		else:
			suffix = "%+"
		
	var percent := value * 100
	var args := ["set-volume", "--limit", volume_limit, "@DEFAULT_AUDIO_SINK@", str(percent) + suffix]
	var code := await thread.exec(OS.execute.bind("wpctl", args)) as int
	
	return code


## Toggles mute on the current audio device
func toggle_mute() -> int:
	_muted = !_muted
	volume_mute_toggled.emit()
	var code := await thread.exec(OS.execute.bind("wpctl", ["set-mute", "@DEFAULT_AUDIO_SINK@", "toggle"])) as int
	return code


## Sets the current output device to the given device
func set_output_device(device: String) -> int:
	var ids := PackedStringArray()
	var devices := PackedStringArray()
	for id in await _get_wpctl_object_ids():
		var lines := await _wpctl_inspect(id)
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

	return await thread.exec(OS.execute.bind("wpctl", ["set-default", device_id]))


## Returns the currently set output device
func get_current_output_device() -> String:
	var lines := await _wpctl_inspect("@DEFAULT_AUDIO_SINK@")
	for line in lines:
		if line.contains("node.description"):
			return line.split('"', false)[-1]
	return ""


## Returns the current volume as a percentage. E.g. 0.52 is 52%
func get_current_volume() -> float:
	return current_volume


## Fetch the volume for the current output device
func _get_current_volume() -> float:
	var output := []
	var code := await thread.exec(OS.execute.bind("wpctl", ["get-volume", "@DEFAULT_AUDIO_SINK@"], output)) as int
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


## Returns a list of audio output devices
func get_output_devices() -> PackedStringArray:
	return await _get_output_devices()
	
	
func _get_output_devices() -> PackedStringArray:
	var devices := PackedStringArray()
	for id in await _get_wpctl_object_ids():
		var lines := await _wpctl_inspect(id)
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
func _wpctl_inspect(id: String) -> PackedStringArray:
	var out := PackedStringArray()
	var output := []
	var code := await thread.exec(OS.execute.bind("wpctl", ["inspect", id], output)) as int
	if code != 0:
		return out
	if output.size() == 0:
		return out
	var text := output[0] as String
	return text.split("\n")


# Returns an array of discovered Wirepipe object IDs
func _get_wpctl_object_ids() -> PackedStringArray:
	var ids := PackedStringArray()

	var output := []
	var code := await thread.exec(OS.execute.bind("wpctl", ["status"], output)) as int
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
