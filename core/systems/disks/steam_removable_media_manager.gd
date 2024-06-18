extends Resource
class_name SteamRemovableMediaManager

var udisks2 := load("res://core/systems/disks/udisks2.tres") as UDisks2

var logger := Log.get_logger("SteaMRemovableMediaManager", Log.LEVEL.INFO)

# TODO: Fix this workaround to allow similtaneous operations. Currently more than
# one operation will reset the drive nodes and permit undefined behavior.
var block_operations: bool = false

# Polkit Script paths
const SRM_FORMAT_MEDIA = "/usr/bin/shadowblip/format-media"
const SRM_INIT_MEDIA = "/usr/bin/shadowblip/init-media"
const STEAMOS_RETRIGGER_AUTOMOUNTS = "/usr/bin/steamos-polkit-helpers/steamos-retrigger-automounts"
const STEAMOS_FORMAT_SDCARD = "/usr/bin/steamos-polkit-helpers/steamos-format-sdcard"
const STEAMOS_TRIM_DEVICES = "/usr/bin/steamos-polkit-helpers/steamos-trim-devices"
const BLOCK_PREFIX = "/org/freedesktop/UDisks2/block_devices"
const SDCARD_PATH = "/dev/mmcblk0"

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

var format_capable: bool = false
var init_capable: bool = false
var format_sd_capable: bool = false
var retrigger_capable: bool = false
var trim_capable: bool = false


signal drives_updated(device_tree: Array[BlockDevice])

## Hierarchy of drive -> block device -> partitions -> mount points
## Used to display device information to the user.
var device_tree: Array[BlockDevice]

func _init() -> void:

	# Check the required system files exist for steam_removable_media
	if FileAccess.file_exists(SRM_FORMAT_MEDIA):
		format_capable = true
	if FileAccess.file_exists(SRM_INIT_MEDIA):
		init_capable = true
	if FileAccess.file_exists(STEAMOS_RETRIGGER_AUTOMOUNTS):
		retrigger_capable = true

	# These scripts are hard coded to mmcblk0
	if FileAccess.file_exists(SDCARD_PATH):
		if FileAccess.file_exists(STEAMOS_FORMAT_SDCARD):
			format_sd_capable = true
		if FileAccess.file_exists(STEAMOS_TRIM_DEVICES):
			trim_capable = true

	logger.debug("format_capable: " + str(format_capable))
	logger.debug("init_capable: " + str(init_capable))
	logger.debug("format_sd_capable: " + str(format_sd_capable))
	logger.debug("retrigger_capable: " + str(retrigger_capable))
	logger.debug("trim_capable: " + str(trim_capable))

	# Get the current drives and ensure they are always up to date
	udisks2.devices_updated.connect(update_drives)
	update_drives()


## Rebuilds the device_tree with the current device list
func update_drives(devices: Array[BlockDevice] = []):
	if devices == []:
		logger.debug("Got empty array, grabbing devices from udisks2")
		devices = udisks2.get_devices()
	self.device_tree = []
	for block in devices:
		if not _block_device_has_protected_mount(block):
			logger.debug(block.dbus_path, "has no protected mounts.")
			device_tree.append(block)
	self.drives_updated.emit(self.device_tree)


## Calls the SteamRemovableMedia format-media script to format a drive as EXT4
## and intialize it as a steam library
func format_drive(device: BlockDevice) -> void:
	if not format_capable:
		logger.error("System is not format capable")
		return

	# This should never hit if using our device tree, but  the method is public so
	# make sure.
	if _block_device_has_protected_mount(device):
		logger.error("Attempted to format device with protected mount. Illegal Operation.")
		return

	var drive = "/dev" + device.dbus_path.trim_prefix(BLOCK_PREFIX)
	logger.debug("Formatting drive: " + drive)
	var args := ["--full", "--device", drive]
	var result = await _execute_in_thread(SRM_FORMAT_MEDIA, args)
	logger.debug("Got results: " + str(result[0]), str(result[1]))
	var success: bool = result[1] == 0
	device.format_complete.emit(success)


## Calls the SteamRemovableMedia init-media script to intialize a drive as a
## steam library
func init_steam_lib(partition: PartitionDevice) -> void:
	if not init_capable:
		logger.error("System cannot initialize steam libraries")
		return

	# This should never hit if using our device tree, but  the method is public so
	# make sure.
	if _partition_has_protected_mount(partition):
		logger.error("Attempted to initialize steam library on device with protected mount. Illegal Operation.")
		return

	var drive = "/dev" + partition.dbus_path.trim_prefix(BLOCK_PREFIX)
	logger.debug("Intitializing partition as Steam Library: " + drive)
	var args := [drive]
	var result = await _execute_in_thread(SRM_INIT_MEDIA, args)
	logger.debug("Got results: " + str(result[0]), str(result[1]))

	var success: bool = result[1] == 0
	partition.init_complete.emit(success)


## Calls the SteamRemovableMedia or SteamOS retrigger-automounts script to
## restart all the media-mount@ scripts.
func retrigger_automounts() -> void:
	if not retrigger_capable:
		logger.error("System is not retrigger capable")
		return

	logger.debug("Retriggering Steam Automounts")
	var result = await _execute_in_thread(STEAMOS_RETRIGGER_AUTOMOUNTS)
	logger.debug("Got results: " + str(result[0]), str(result[1]))

	var success: bool = result[1] == 0
	#retrigger_complete.emit(success)


## Calls the SteamRemovableMedia or SteamOS format-sd script to format mmcblk0
## as EXT4 and intialize it as a steam library
func format_sd_card() -> void:
	if not format_sd_capable:
		logger.error("System is not format capable")
		return

	# Make sure the sd card isn't being used as a protected drive.
	var sd_card: BlockDevice
	for block in device_tree:
		if not block.dbus_path.contains("mmcblk0"):
			continue
		sd_card = block
	if not sd_card:
		logger.warn("Unable to find SD Card!")
		return
	if _block_device_has_protected_mount(sd_card):
		logger.warn("Attempted to format SD Card with protected mount!")
		return

	logger.debug("Formatting SD Card: mmcblk0")
	var result = await _execute_in_thread(STEAMOS_FORMAT_SDCARD)
	logger.debug("Got results: " + str(result[0]), str(result[1]))

	var success: bool = result[1] == 0
	sd_card.format_complete.emit(success)


## Calls the SteamRemovableMedia or SteamOS trim-devices script to perform a
## trim operation on mmcblk0.
func trim_sd_card() -> void:
	if not trim_capable:
		logger.error("System is not trim capable")
		return

	# Make sure the sd card isn't being used as a protected drive.
	var sd_card: BlockDevice
	for block in device_tree:
		if not block.dbus_path.contains("mmcblk0"):
			continue
		sd_card = block
	if not sd_card:
		logger.warn("Unable to find SD Card!")
		return
	if _block_device_has_protected_mount(sd_card):
		logger.warn("Attempted to format SD Card with protected mount!")
		return

	logger.debug("Performing TRIM operation on SD Card: mmcblk0")
	var result = await _execute_in_thread(STEAMOS_TRIM_DEVICES)
	logger.debug("Got results: " + str(result[0]), str(result[1]))

	var success: bool = result[1] == 0
	sd_card.trim_complete.emit(success)


## Finds all partitions of the given block device and returns true if any of
## them have mounts in the protected_mounts list.
func _block_device_has_protected_mount(device: BlockDevice) -> bool:
	logger.debug("Checking block device", device.dbus_path, "for protected mounts.")
	# Get all the partition dbus paths of this block device
	for partition in device.partitions:
		if _partition_has_protected_mount(partition):
			return true
	return false


## Loops through all mount points of the given partition and returns true if any of
## them have mounts in the protected_mounts list.
func _partition_has_protected_mount(device: PartitionDevice) -> bool:
	logger.debug("Checking partition", device.dbus_path, "for protected mounts.")
	for mount_point in device.fs_mount_points:
		logger.debug("Checking mount point", mount_point, "for protected mounts.")
		if mount_point in protected_mounts:
			logger.debug("Found a protected mount point on drive: " + device.dbus_path)
			return true
	return false



func _execute_in_thread(path: String, args: Array = []) -> Array:
	var thread: SharedThread = SharedThread.new()
	thread.watchdog_enabled = false
	thread.start()
	var result = await thread.exec(_exec_call.bind(path, args))
	thread.stop()
	return result


## Executes the given command and arguments
func _exec_call(path: String, args: Array = []) -> Array:
	var output = []
	var exit_code := OS.execute(path, args, output)
	return [output, exit_code]
