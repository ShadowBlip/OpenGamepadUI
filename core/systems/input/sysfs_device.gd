extends Resource
class_name SysfsDevice

## Path of the device in sysfs ATTR{phys}
## cat /proc/bus/input/devices
@export var phys_path: String
## Name of the device in sysfs ATTR{name}
@export var name: String
