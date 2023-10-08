extends Resource
class_name DRMCardPort

## GPU connector port state
##
## Represents the data contained in /sys/class/drm/cardX-YYYY and includes
## an update function that can be called to update the state of the connector
## port.

## Mutex used for thread safety
var mutex := Mutex.new()
## Name of the port. E.g. HDMI-A-1
var name: String
## Full path to the port. E.g. /sys/class/drm/card1-HDMI-A-1
var path: String
## The connector id. E.g. /sys/class/drm/card1-HDMI-A-1/connector_id
var connector_id := -1:
	get:
		mutex.lock()
		var prop := connector_id
		mutex.unlock()
		return prop
	set(v):
		if connector_id == v:
			return
		mutex.lock()
		connector_id = v
		mutex.unlock()
		emit_changed.call_deferred()
## Whether or not the port is enabled
var enabled := false:
	get:
		mutex.lock()
		var prop := enabled
		mutex.unlock()
		return prop
	set(v):
		if enabled == v:
			return
		mutex.lock()
		enabled = v
		mutex.unlock()
		emit_changed.call_deferred()
## An array of valid modes (E.g. ["1024x768", "1920x1080"])
var modes := PackedStringArray():
	get:
		mutex.lock()
		var prop := modes
		mutex.unlock()
		return prop
	set(v):
		if modes == v:
			return
		mutex.lock()
		modes = v
		mutex.unlock()
		emit_changed.call_deferred()
## Status of the port (e.g. "connected")
var status: String:
	get:
		mutex.lock()
		var prop := status
		mutex.unlock()
		return prop
	set(v):
		if status == v:
			return
		mutex.lock()
		status = v
		mutex.unlock()
		emit_changed.call_deferred()
## Display power management signaling
var dpms: bool:
	get:
		mutex.lock()
		var prop := dpms
		mutex.unlock()
		return prop
	set(v):
		if dpms == v:
			return
		mutex.lock()
		dpms = v
		mutex.unlock()
		emit_changed.call_deferred()

## Updates the properties of the port
func update() -> void:
	connector_id = get_connector_id()
	enabled = get_enabled()
	modes = get_modes()
	status = get_status()
	dpms = get_dpms()

func get_connector_id() -> int:
	var id_str := _get_property("connector_id").strip_escapes()
	if id_str.is_valid_int():
		return id_str.to_int()
	return -1

func get_enabled() -> bool:
	return _get_property("enabled").strip_escapes() == "enabled"

func get_modes() -> PackedStringArray:
	var found_modes := PackedStringArray()
	var modes_str := _get_property("modes")
	for mode in modes_str.split("\n"):
		found_modes.append(mode.strip_escapes())
	return found_modes
	
func get_status() -> String:
	return _get_property("status").strip_escapes()

func get_dpms() -> bool:
	return _get_property("dpms").strip_escapes() == "On"

func _get_property(prop: String) -> String:
	var prop_path := "/".join([path, prop])
	if not FileAccess.file_exists(prop_path):
		return ""
	var file := FileAccess.open(prop_path, FileAccess.READ)
	var length := file.get_length()
	var bytes := file.get_buffer(length)

	return bytes.get_string_from_utf8()

func _to_string() -> String:
	return "<Port:" \
		+ " Name: (" + str(name) \
		+ ") Status: (" + str(status) \
		+ ") Enabled: (" + str(enabled) \
		+ ")>"
