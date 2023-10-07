extends Resource
class_name DRMCardInfo

## Data container for /sys/class/drm/cardX information

const drm_path := "/sys/class/drm"

var name: String
var vendor: String
var vendor_id: String
var device: String
var device_id: String
var device_type: String
var subdevice: String
var subdevice_id: String
var subvendor_id: String
var revision_id: String


## Returns a [Port] object for the given port directory (E.g. card1-HDMI-A-1)
func get_port(port_dir: String) -> Port:
	var port_name := port_dir.trim_prefix(name + "-")
	
	# Try to load the port info if it already exists
	var res_path := "/".join(["drmcardinfo://", vendor_id, device_id, subvendor_id, subdevice_id, port_name])
	if ResourceLoader.exists(res_path):
		var port := load(res_path) as Port
		port.update()
		return port

	# Create a new port instance and take over the caching path
	var port := Port.new()
	port.take_over_path(res_path)
	port.name = port_name
	port.path = "/".join([drm_path, port_dir])
	port.update()

	return port


## Returns an array of connectors that are attached to this GPU card
func get_ports() -> Array[Port]:
	var found_ports: Array[Port] = []
	for directory in DirAccess.get_directories_at(drm_path):
		if not directory.begins_with(name):
			continue
		if directory == name:
			continue
		
		var port := get_port(directory)
		found_ports.append(port)
		
	return found_ports


func _to_string() -> String:
	return "<DRMCardInfo:" \
		+ " Name: (" + str(name) \
		+ ") Vendor: (" + str(vendor) \
		+ ") Vendor ID: (" + str(vendor_id) \
		+ ") Device: (" + str(device) \
		+ ") Device ID: (" + str(device_id) \
		+ ") Device Type: (" + str(device_type) \
		+ ") Subdevice: (" + str(subdevice) \
		+ ") Subdevice ID: (" + str(subvendor_id) \
		+ ") Revision ID: (" + str(revision_id) \
		+ ") Ports: (" + str(get_ports()) \
		+ ")>"


## Data container for /sys/class/drm/cardX-YYYY information
class Port extends Resource:
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
			emit_signal.call_deferred("changed")
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
			emit_signal.call_deferred("changed")
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
			emit_signal.call_deferred("changed")
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
			emit_signal.call_deferred("changed")
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
			emit_signal.call_deferred("changed")

	# Updates the properties of the port
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
		var output := []
		OS.execute("cat", [prop_path], output)
		var value := output[0] as String
		return value

	func _to_string() -> String:
		return "<Port:" \
			+ " Name: (" + str(name) \
			+ ") Status: (" + str(status) \
			+ ") Enabled: (" + str(enabled) \
			+ ")>"
