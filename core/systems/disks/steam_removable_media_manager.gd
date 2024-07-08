extends Resource
class_name SteamRemovableMediaManager

var udisks2 := load("res://core/systems/disks/udisks2.tres") as UDisks2

var logger := Log.get_logger("SteamRemovableMediaManager", Log.LEVEL.INFO)

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

var format_capable: bool = false
var init_capable: bool = false
var format_sd_capable: bool = false
var retrigger_capable: bool = false
var trim_capable: bool = false


func _init() -> void:
	if not udisks2.supports_disk_management():
		return

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

	logger.debug("format_capable:", format_capable)
	logger.debug("init_capable:", init_capable)
	logger.debug("format_sd_capable:", format_sd_capable)
	logger.debug("retrigger_capable:", retrigger_capable)
	logger.debug("trim_capable:", trim_capable)


## Calls the SteamRemovableMedia format-media script to format a drive as EXT4
## and intialize it as a steam library
func format_drive(device: BlockDevice) -> Error:
	if not format_capable:
		logger.error("System is not format capable")
		return ERR_UNAVAILABLE

	# This should never hit if using our device tree, but  the method is public so
	# make sure.
	if udisks2.block_device_has_protected_mount(device):
		logger.error("Attempted to format device with protected mount. Illegal Operation.")
		return ERR_UNAUTHORIZED

	var drive = "/dev" + device.dbus_path.trim_prefix(BLOCK_PREFIX)
	logger.debug("Formatting drive:", drive)
	var args := ["--full", "--device", drive]
	var result = await _execute_in_thread(SRM_FORMAT_MEDIA, args)

	logger.debug("Got results: ", result[0], result[1])
	var success: bool = result[1] == 0
	if success:
		return OK
	return ERR_SCRIPT_FAILED


## Calls the SteamRemovableMedia init-media script to intialize a drive as a
## steam library
func init_steam_lib(partition: PartitionDevice) -> Error:
	if not init_capable:
		logger.error("System cannot initialize steam libraries")
		return ERR_UNAVAILABLE

	# This should never hit if using our device tree, but  the method is public so
	# make sure.
	if udisks2.partition_has_protected_mount(partition):
		logger.error("Attempted to initialize steam library on device with protected mount. Illegal Operation.")
		return ERR_UNAUTHORIZED

	var drive := "/dev" + partition.dbus_path.trim_prefix(BLOCK_PREFIX)
	logger.debug("Intitializing partition as Steam Library: " + drive)
	var args := [drive]
	var result = await _execute_in_thread(SRM_INIT_MEDIA, args)
	logger.debug("Got results:", result[0], result[1])

	var success: bool = result[1] == 0
	if success:
		return OK
	return ERR_SCRIPT_FAILED


## Calls the SteamRemovableMedia or SteamOS retrigger-automounts script to
## restart all the media-mount@ scripts.
func retrigger_automounts() -> Error:
	if not retrigger_capable:
		logger.error("System is not retrigger capable")
		return ERR_UNAVAILABLE

	logger.debug("Retriggering Steam Automounts")
	var result = await _execute_in_thread(STEAMOS_RETRIGGER_AUTOMOUNTS)
	logger.debug("Got results:", result[0], result[1])

	var success: bool = result[1] == 0
	if success:
		return OK
	return ERR_SCRIPT_FAILED


## Calls the SteamRemovableMedia or SteamOS format-sd script to format mmcblk0
## as EXT4 and intialize it as a steam library
func format_sd_card() -> Error:
	if not format_sd_capable:
		logger.error("System is not format capable")
		return ERR_UNAVAILABLE

	# Make sure the sd card isn't being used as a protected drive.
	var sd_card: BlockDevice
	for block in udisks2.get_unprotected_devices():
		if not block.dbus_path.contains("mmcblk0"):
			continue
		sd_card = block
	if not sd_card:
		logger.warn("Unable to find SD Card!")
		return ERR_UNAUTHORIZED

	logger.debug("Formatting SD Card: mmcblk0")
	var result = await _execute_in_thread(STEAMOS_FORMAT_SDCARD)
	logger.debug("Got results:", result[0], result[1])

	var success: bool = result[1] == 0
	if success:
		return OK
	return ERR_SCRIPT_FAILED


## Calls the SteamRemovableMedia or SteamOS trim-devices script to perform a
## trim operation on mmcblk0.
func trim_sd_card() -> Error:
	if not trim_capable:
		logger.error("System is not trim capable")
		return ERR_UNAVAILABLE

	# Make sure the sd card isn't being used as a protected drive.
	var sd_card: BlockDevice
	for block in udisks2.get_unprotected_devices():
		if not block.dbus_path.contains("mmcblk0"):
			continue
		sd_card = block

	if not sd_card:
		logger.warn("Unable to find SD Card!")
		return ERR_UNAUTHORIZED

	logger.debug("Performing TRIM operation on SD Card: mmcblk0")
	var result = await _execute_in_thread(STEAMOS_TRIM_DEVICES)
	logger.debug("Got results:", result[0], result[1])

	var success: bool = result[1] == 0
	if success:
		return OK
	return ERR_SCRIPT_FAILED


func _execute_in_thread(path: String, args: Array = []) -> Array:
	block_operations = true
	var thread_options := SharedThread.Option.NONE
	var thread := SharedThread.new(thread_options)
	thread.start()
	var cmd := Command.new(path, args, thread)
	var code := await cmd.execute() as int
	thread.stop()
	block_operations = false
	return [cmd.stdout, code]
