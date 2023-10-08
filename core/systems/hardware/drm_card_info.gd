extends Resource
class_name DRMCardInfo

## GPU card state
##
## Represents the data contained in /sys/class/drm/cardX

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


## Returns a [DRMCardPort] object for the given port directory (E.g. card1-HDMI-A-1)
func get_port(port_dir: String) -> DRMCardPort:
	var port_name := port_dir.trim_prefix(name + "-")
	
	# Try to load the port info if it already exists
	var res_path := "/".join(["drmcardinfo:/", vendor_id, device_id, subvendor_id, subdevice_id, port_name])
	if ResourceLoader.exists(res_path):
		var port := load(res_path) as DRMCardPort
		port.update()
		return port

	# Create a new port instance and take over the caching path
	var port := DRMCardPort.new()
	port.take_over_path(res_path)
	port.name = port_name
	port.path = "/".join([drm_path, port_dir])
	port.update()

	return port


## Returns an array of connectors that are attached to this GPU card
func get_ports() -> Array[DRMCardPort]:
	var found_ports: Array[DRMCardPort] = []
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
