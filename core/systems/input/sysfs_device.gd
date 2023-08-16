extends Resource
class_name SysfsDevice

## Container for sysfs input devices
##
## This contains parsed data from a single device entry in /proc/bus/input/devices.

## Path of the device in sysfs ATTR{phys}
## cat /proc/bus/input/devices
@export var phys_path: String
## Name of the device in sysfs ATTR{name}
@export var name: String

## ID of the device
## E.g. I: Bus=0003 Vendor=045e Product=028e Version=0120
var id: ID
## Sysfs path
## E.g. S: Sysfs=/devices/pci0000:00/0000:00:08.1/0000:03:00.3/usb1/1-4/1-4:1.0/input/input117
var sysfs_path: String
## Unique identification code for the device (if device has it)
## E.g. U: Uniq=abc
var unique_id: String
## List of input handlers associated with the device (e.g. ["event17", "js0"])
## E.g. H: Handlers=kbd event13
var handlers: PackedStringArray
## Bitmaps
## E.g. B: KEY=7cdb000000000000 0 0 0 0
var bitmaps: Array[Bitmap]


func _to_string() -> String:
	var values := [name, str(handlers)]
	return "<SysfsDevice Name=\"{0}\", Handlers={1}>".format(values)


## Returns a list of sysfs input devices that are currently detected. This
## function parses the file at /proc/bus/input/devices
static func get_all() -> Array[SysfsDevice]:
	var devices: Array[SysfsDevice] = []
	
	# Get the contents of the input devices file
	var output := []
	var code := OS.execute("cat", ["/proc/bus/input/devices"], output)
	var stdout: String = output[0]
	var lines := stdout.split("\n")
	
	# Parse the output
	var device: SysfsDevice
	for line in lines:
		if line.begins_with("I: "):
			device = SysfsDevice.new()
			device.id = SysfsDevice.ID.new()
			line = line.replace("I: ", "")
			
			var parts := line.split(" ")
			for part in parts:
				var pair := part.split("=")
				if pair.size() != 2:
					continue
				if pair[0] == "Bus":
					device.id.bus_type = pair[1]
				elif pair[0] == "Vendor":
					device.id.vendor = pair[1]
				elif pair[0] == "Product":
					device.id.product = pair[1]
				elif pair[0] == "Version":
					device.id.version = pair[1]
		
		elif line.begins_with("N: "):
			if not device:
				continue
			line = line.replace("N: ", "")
			var parts := line.split("=", true, 1)
			if parts.size() != 2:
				continue
			device.name = parts[1].replace("\"", "")
		
		elif line.begins_with("P: "):
			if not device:
				continue
			line = line.replace("P: ", "")
			var parts := line.split("=", true, 1)
			if parts.size() != 2:
				continue
			device.phys_path = parts[1]
		
		elif line.begins_with("S: "):
			if not device:
				continue
			line = line.replace("S: ", "")
			var parts := line.split("=", true, 1)
			if parts.size() != 2:
				continue
			device.sysfs_path = parts[1]
		
		elif line.begins_with("U: "):
			if not device:
				continue
			line = line.replace("U: ", "")
			var parts := line.split("=", true, 1)
			if parts.size() != 2:
				continue
			device.unique_id = parts[1]
		
		elif line.begins_with("H: "):
			if not device:
				continue
			line = line.replace("H: ", "")
			var parts := line.split("=", true, 1)
			if parts.size() != 2:
				continue
			
			var list := parts[1].split(" ", false)
			device.handlers = PackedStringArray()
			for handler in list:
				device.handlers.append(handler)
		
		elif line.begins_with("B: "):
			if not device:
				continue
			line = line.replace("B: ", "")
			var parts := line.split("=", true, 1)
			if parts.size() != 2:
				continue
			
			var bitmap := SysfsDevice.Bitmap.new()
			bitmap.type = parts[0]
			bitmap.values = PackedStringArray()
			
			var list := parts[1].split(" ")
			for value in list:
				bitmap.values.append(value)
			device.bitmaps.append(bitmap)
			
		elif line == "":
			if device:
				devices.append(device)
			device = null
		
	return devices


## Container for a sysfs ID
## E.g. I: Bus=0003 Vendor=045e Product=028e Version=0120
class ID:
	var bus_type: String
	var vendor: String
	var product: String
	var version: String

## Container representing a device bitmap
## E.g. B: KEY=7cdb000000000000 0 0 0 0
class Bitmap:
	var type: String
	var values: PackedStringArray
