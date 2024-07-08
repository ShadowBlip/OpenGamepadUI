extends Resource
class_name UDisks2

## Manages disk discovery.
##
## The UDisks2 class is responsible for handling dbus messages to and
## from the UDisks2 daemon for disk management.

# Paths
const UDISKS2_PATH := "/org/freedesktop/UDisks2"
const BLOCK_DEVICES_PATH := UDISKS2_PATH + "/block_devices"
const DRIVES_PATH := UDISKS2_PATH + "/drives"
const UDISKS2_MANAGER_PATH := UDISKS2_PATH + "/Manager"
# Interfaces
const UDISKS2_BUS := "org.freedesktop.UDisks2"
const IFACE_MANAGER := UDISKS2_BUS + ".Manager"
const IFACE_BLOCK := UDISKS2_BUS + ".Block"
const IFACE_FILESYSTEM := UDISKS2_BUS + ".Filesystem"
const IFACE_PARTITION := UDISKS2_BUS + ".Partition"
const IFACE_PARTITION_TABLE := UDISKS2_BUS + ".PartitionTable"
const IFACE_DRIVE := UDISKS2_BUS + ".Drive"
const IFACE_NVME_CONTROLLER := UDISKS2_BUS + ".NVMe.Controller"

const protected_mounts = [
	"/",
	"/boot",
	"/boot/efi",
	"/efi",
	"/frzr_root",
	"/frzr_root/boot",
	"/home",
	"/var",
	"/var/cache",
	"/var/log",
	]

var dbus := load("res://core/global/dbus_system.tres") as DBusManager
var manager := Manager.new(dbus.create_proxy(UDISKS2_BUS, UDISKS2_MANAGER_PATH))
var object_manager := dbus.ObjectManager.new(dbus.create_proxy(UDISKS2_BUS, UDISKS2_PATH))

signal devices_updated(devices: Array[BlockDevice])
signal unprotected_devices_updated(unprotected_devices: Array[BlockDevice])

var logger := Log.get_logger("UDisks2", Log.LEVEL.INFO)


## Returns true if UDisks2 can be used on this system
func supports_disk_management() -> bool:
	return true
	return dbus.bus_exists(UDISKS2_BUS)


func _init() -> void:
	logger.debug("Initalizing UDisks2 Dbus interface.")
	object_manager.interfaces_added.connect(_drives_updated)
	object_manager.interfaces_removed.connect(_drives_updated)


## Signals when a changes to drives are detected
func _drives_updated(iface: String) -> void:
	logger.trace("Update from interface:", iface)
	var devices = get_devices()
	devices_updated.emit(devices)
	var unprotected_devices = get_unprotected_devices(devices)
	unprotected_devices_updated.emit(unprotected_devices)


## Returns all the current block devices detected by UDisks2
func get_devices() -> Array[BlockDevice]:
	var block_array: Array[BlockDevice] = []
	var partition_array: Array[PartitionDevice] = []
	var drive_array: Array[DriveDevice] = []
	var device_paths := dbus.get_managed_objects(UDISKS2_BUS, UDISKS2_PATH)
	logger.trace("Searching for UDisks2 DBus objects.")

	# Loop through all objects on the bus
	for obj in device_paths:
		var object := obj as DBusManager.ManagedObject
		var path := object.path
		var proxy := dbus.create_proxy(UDISKS2_BUS, path)
		logger.trace("Found object: " + str(object) + " with path " + path)
		logger.trace("Object data: " + str(object.data))

		if path.contains("block_devices"):
			if object.has_interface(IFACE_PARTITION):
				logger.trace("Found Partition Device:", path)
				var device := PartitionDevice.new(proxy)
				if object.has_interface(IFACE_FILESYSTEM):
					logger.trace(path + " has Filesystem")
					device.has_filesystem = true
				partition_array.append(device)
				continue
			logger.trace("Found Block Device:", path)
			var device := BlockDevice.new(proxy)
			block_array.append(device)

		if path.contains("drives"):
			var res_path := "drive://" + path
			logger.trace("Found Drive Device:", path)
			var device := DriveDevice.new(proxy)
			device.take_over_path(res_path)
			device.interface_type = _id_type(device)
			drive_array.append(device)
			continue

	for block in block_array:
		for partition in partition_array:
			if partition.partition_table == block.dbus_path:
				block.partitions.append(partition)
		for drive in drive_array:
			if block.drive_path == drive.dbus_path:
				block.drive = drive

	return block_array


## Returns all current devices that don't have protected mounts
func get_unprotected_devices(devices: Array[BlockDevice] = []):
	var device_tree: Array[BlockDevice]
	if devices == []:
		logger.debug("Got empty array, grabbing devices from udisks2")
		devices = get_devices()
	for block in devices:
		if not block_device_has_protected_mount(block):
			logger.debug(block.dbus_path, "has no protected mounts.")
			device_tree.append(block)
	return device_tree


## Finds all partitions of the given block device and returns true if any of
## them have mounts in the protected_mounts list.
func block_device_has_protected_mount(device: BlockDevice) -> bool:
	logger.debug("Checking block device", device.dbus_path, "for protected mounts.")
	# Get all the partition dbus paths of this block device
	for partition in device.partitions:
		if partition_has_protected_mount(partition):
			return true
	return false


## Loops through all mount points of the given partition and returns true if any of
## them have mounts in the protected_mounts list.
func partition_has_protected_mount(device: PartitionDevice) -> bool:
	logger.debug("Checking partition", device.dbus_path, "for protected mounts.")
	for mount_point in device.fs_mount_points:
		logger.debug("Checking mount point", mount_point, "for protected mounts.")
		if mount_point in protected_mounts:
			logger.debug("Found a protected mount point on drive: " + device.dbus_path)
			return true
	return false


func _id_type(device: DriveDevice) -> DriveDevice.INTERFACE_TYPE:
	if device.connection_bus == "usb":
		return DriveDevice.INTERFACE_TYPE.USB
	elif device.connection_bus == "sdio":
		return DriveDevice.INTERFACE_TYPE.SD
	elif device.connection_bus == "":
		if device.sort_key.contains("hotplug"):
			return DriveDevice.INTERFACE_TYPE.USB
		elif device.sort_key.contains("removable"):
			return DriveDevice.INTERFACE_TYPE.USB
		elif device.sort_key.contains("nvme"):
			return DriveDevice.INTERFACE_TYPE.NVME
		elif device.sort_key.contains("sd_"):
			if device.rotation_rate > 0:
				return DriveDevice.INTERFACE_TYPE.HDD
			return DriveDevice.INTERFACE_TYPE.SSD
	return DriveDevice.INTERFACE_TYPE.UNKNOWN

# Unused. Usefull?
class Manager extends Resource:
	signal updated
	var _proxy: DBusManager.Proxy

	func _init(proxy: DBusManager.Proxy) -> void:
		_proxy = proxy
		_proxy.properties_changed.connect(_on_properties_changed)

	func _on_properties_changed(_iface: String, _props: Dictionary) -> void:
		updated.emit()

