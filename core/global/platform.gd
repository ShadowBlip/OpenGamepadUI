extends Resource
class_name Platform

## Platform specific methods
##
## Used to perform platform-specific functions

## Possible platforms we support
enum PLATFORM {
	GENERIC,  ## Generic platform doesn't do anything special
	STEAMDECK,  ## SteamDeck platform
	STEAMOS,
}

var platform: PlatformProvider
var logger := Log.get_logger("Platform", Log.LEVEL.DEBUG)


func _init() -> void:
	var flags := get_platform_flags()
	if flags & PLATFORM.STEAMDECK:
		platform = load("res://core/platform/steamdeck.tres")
		return


## Returns all detected platform flags
func get_platform_flags() -> int:
	var hardware := _detect_hardware()
	return hardware


func _detect_hardware() -> PLATFORM:
	var product_name := FileAccess.get_file_as_string("/sys/devices/virtual/dmi/id/product_name")
	product_name = product_name.strip_edges()
	var vendor_name := FileAccess.get_file_as_string("/sys/devices/virtual/dmi/id/sys_vendor")
	vendor_name = vendor_name.strip_edges()
	logger.debug("Product: " + product_name)
	logger.debug("Vendor: " + vendor_name)
	if product_name.begins_with("Jupiter") and vendor_name.begins_with("Valve"):
		logger.debug("Detected SteamDeck platform")
		return PLATFORM.STEAMDECK
	logger.debug("Detected generic platform")
	return PLATFORM.GENERIC


func _detect_os() -> void:
	pass
