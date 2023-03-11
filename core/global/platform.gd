extends Resource
class_name Platform

## Platform specific methods
##
## Used to perform platform-specific functions

## Platforms we support
enum PLATFORM {
	# Hardware platforms
	ABERNIC_GEN1,
	AYANEO_GEN1,  ## Includes Founders Edition, Pro, and Retro Power models.
	AYANEO_GEN2,  ## Includes AIR and NEXT models.
	AYANEO_GEN3,  ## Includes 2 and GEEK models
	GENERIC,  ## Generic platform doesn't do anything special
	GPD_GEN1,
	ONEXPLAYER_GEN1,  ## Includes most OXP and AOKZOE devices
	ONEXPLAYER_GEN2,  ## GUNDAM edition.
	STEAMDECK,
	# OS Platforms
	CHIMERAOS,
	STEAMOS,
}

var platform: PlatformProvider
var logger := Log.get_logger("Platform", Log.LEVEL.DEBUG)


func _init() -> void:
	var flags := get_platform_flags()
	if PLATFORM.ABERNIC_GEN1 in flags:
		platform = load("res://core/platform/abernic_gen1.tres")
		return
	if PLATFORM.AYANEO_GEN1 in flags:
		platform = load("res://core/platform/ayaneo_gen1.tres")
		return
	if PLATFORM.AYANEO_GEN2 in flags:
		platform = load("res://core/platform/ayaneo_gen2.tres")
		return
	if PLATFORM.AYANEO_GEN3 in flags:
		platform = load("res://core/platform/ayaneo_gen3.tres")
		return
	if PLATFORM.GENERIC in flags:
		platform = load("res://core/platform/generic.tres")
		return
	if PLATFORM.GPD_GEN1 in flags:
		platform = load("res://core/platform/gpd_gen1.tres")
		return
	if PLATFORM.ONEXPLAYER_GEN1 in flags:
		platform = load("res://core/platform/onexplayer_gen1.tres")
		return
	if PLATFORM.ONEXPLAYER_GEN2 in flags:
		platform = load("res://core/platform/onexplayer_gen2.tres")
		return
	if PLATFORM.STEAMDECK in flags:
		platform = load("res://core/platform/steamdeck.tres")
		return


## Returns the handheld gamepad for the detected platform
func get_handheld_gamepad() -> HandheldGamepad:
	if not platform:
		return null
	return platform.get_handheld_gamepad()


## Returns all detected platform flags
func get_platform_flags() -> Array[PLATFORM]:
	var dmi_flags := _read_dmi()
	return [dmi_flags]


## Returns the hardware product name
func get_product_name() -> String:
	var product_name := FileAccess.get_file_as_string("/sys/devices/virtual/dmi/id/product_name")
	product_name = product_name.strip_edges()
	return product_name


## Returns the hardware vendor name
func get_vendor_name() -> String:
	var vendor_name := FileAccess.get_file_as_string("/sys/devices/virtual/dmi/id/sys_vendor")
	vendor_name = vendor_name.strip_edges()
	return vendor_name


# Reads DMI vendor and product name strings and returns an enumerated PLATFORM
func _read_dmi() -> PLATFORM:
	var product_name := get_product_name()
	var vendor_name := get_vendor_name()
	logger.debug("Product: " + product_name)
	logger.debug("Vendor: " + vendor_name)

	if product_name == "Win600" and vendor_name == "ABERNIC":
		logger.debug("Detected Win600 platform")
		return PLATFORM.ABERNIC_GEN1
	elif product_name == "AOKZOE A1 AR07" and vendor_name == "AOKZOE":
		logger.debug("Detected AOKZOE A1 platform")
		return PLATFORM.ONEXPLAYER_GEN1
	elif product_name in ["AYANEO 2", "GEEK"] and vendor_name == "AYANEO":
		logger.debug("Detected AYANEO 2 platform")
		return PLATFORM.AYANEO_GEN3
	elif (
		(product_name.contains("2021") or product_name.contains("FOUNDER"))
		and vendor_name.begins_with("AYA")
	):
		logger.debug("Detected AYANEO 2021 platform")
		return PLATFORM.AYANEO_GEN1
	elif product_name.contains("AIR") and vendor_name == "AYANEO":
		logger.debug("Detected AYANEO AIR platform")
		return PLATFORM.AYANEO_GEN2
	elif product_name.contains("NEXT") and vendor_name == "AYANEO":
		logger.debug("Detected AYANEO NEXT platform")
		return PLATFORM.AYANEO_GEN2
	elif product_name in ["G1618-03", "G1618-04", "G1619-04"] and vendor_name == "GPD":
		logger.debug("Detected GPD Gen1 platform")
		return PLATFORM.GPD_GEN1
	elif product_name == "ONE XPLAYER" and vendor_name == ("ONE-NETBOOK"):
		logger.debug("Detected OneXPlayer GEN 1 platform")
		return PLATFORM.ONEXPLAYER_GEN1
	elif product_name.contains("ONEXPLAYER") and vendor_name == ("ONE-NETBOOK"):
		logger.debug("Detected OneXPlayer GEN 1 platform")
		return PLATFORM.ONEXPLAYER_GEN1
	elif product_name.begins_with("Jupiter") and vendor_name.begins_with("Valve"):
		logger.debug("Detected SteamDeck platform")
		return PLATFORM.STEAMDECK
	logger.debug("Detected generic platform")
	return PLATFORM.GENERIC


func _detect_os() -> void:
	pass
