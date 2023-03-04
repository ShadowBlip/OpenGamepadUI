extends Resource
class_name Platform

## Platform specific methods
##
## Used to perform platform-specific functions

## Platforms we support
enum PLATFORM {
	# Hardware platforms
	ABERNIC_WIN600,
	AOKZOE_A1,
	AYANEO_2,
	AYANEO_2021,  ## Includes Founders Edition, Pro, and Retro Power models.
	AYANEO_AIR,  ## Includes 5600U and 5925U PRO models.
	AYANEO_GEEK,
	AYANEO_NEXT,  ## Includes Advance and Pro models
	GENERIC,  ## Generic platform doesn't do anything special
	GPD_WIN3,
	GPD_WIN4,
	GPD_WINMAX2,
	ONEXPLAYER_GEN1,  ## All older OXP devices have the same DMI data.
	ONEXPLAYER_MINI_PRO,
	STEAMDECK,
	# OS Platforms
	CHIMERAOS,
	STEAMOS,
}

var platform: PlatformProvider
var logger := Log.get_logger("Platform", Log.LEVEL.DEBUG)


func _init() -> void:
	var flags := get_platform_flags()
	if PLATFORM.ABERNIC_WIN600 in flags:
		platform = load("res://core/platform/abernic_win600.tres")
		return
	if PLATFORM.AOKZOE_A1 in flags:
		platform = load("res://core/platform/aokzoe_a1.tres")
		return
	if PLATFORM.AYANEO_2 in flags:
		platform = load("res://core/platform/ayaneo_2.tres")
		return
	if PLATFORM.AYANEO_2021 in flags:
		platform = load("res://core/platform/ayaneo_2021.tres")
		return
	if PLATFORM.AYANEO_AIR in flags:
		platform = load("res://core/platform/ayaneo_air.tres")
		return
	if PLATFORM.AYANEO_GEEK in flags:
		platform = load("res://core/platform/ayaneo_geek.tres")
		return
	if PLATFORM.AYANEO_NEXT in flags:
		platform = load("res://core/platform/ayaneo_next.tres")
		return
	if PLATFORM.GENERIC in flags:
		platform = load("res://core/platform/generic.tres")
		return
	if PLATFORM.GPD_WIN3 in flags:
		platform = load("res://core/platform/gpd_win3.tres")
		return
	if PLATFORM.GPD_WIN4 in flags:
		platform = load("res://core/platform/gpd_win4.tres")
		return
	if PLATFORM.GPD_WINMAX2 in flags:
		platform = load("res://core/platform/gpd_winmax2.tres")
		return
	if PLATFORM.ONEXPLAYER_GEN1 in flags:
		platform = load("res://core/platform/onexplayer_gen1.tres")
		return
	if PLATFORM.ONEXPLAYER_MINI_PRO in flags:
		platform = load("res://core/platform/onexplayer_mini_pro.tres")
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
		return PLATFORM.ABERNIC_WIN600
	elif product_name == "AOKZOE A1 AR07" and vendor_name == "AOKZOE":
		logger.debug("Detected AOKZOE A1 platform")
		return PLATFORM.AOKZOE_A1
	elif product_name == "AYANEO 2" and vendor_name == "AYANEO":
		logger.debug("Detected AYANEO 2 platform")
		return PLATFORM.AYANEO_2
	elif (
		(product_name.contains("2021") or product_name.contains("FOUNDER"))
		and vendor_name.begins_with("AYA")
	):
		logger.debug("Detected AYANEO 2021 platform")
		return PLATFORM.AYANEO_2021
	elif product_name.contains("AIR") and vendor_name == "AYANEO":
		logger.debug("Detected AYANEO AIR platform")
		return PLATFORM.AYANEO_AIR
	elif product_name == "GEEK" and vendor_name == "AYANEO":
		logger.debug("Detected AYANEO GEEK platform")
		return PLATFORM.AYANEO_GEEK
	elif product_name.contains("NEXT") and vendor_name == "AYANEO":
		logger.debug("Detected AYANEO NEXT platform")
		return PLATFORM.AYANEO_NEXT
	elif product_name == "G1618-03" and vendor_name == "GPD":
		logger.debug("Detected GPD Win3 platform")
		return PLATFORM.GPD_WIN3
	elif product_name == "G1618-04" and vendor_name == "GPD":
		logger.debug("Detected GPD Win4 platform")
		return PLATFORM.GPD_WIN4
	elif product_name == "G1619-04" and vendor_name == "GPD":
		logger.debug("Detected GPD WinMax2 platform")
		return PLATFORM.GPD_WINMAX2
	elif product_name == "ONE XPLAYER" and vendor_name.begins_with("ONE"):
		logger.debug("Detected OneXPlayer GEN 1 platform")
		return PLATFORM.ONEXPLAYER_GEN1
	elif product_name == "ONEXPLAYER Mini Pro" and vendor_name.begins_with("ONE"):
		logger.debug("Detected OneXPlayer Mini Proplatform")
		return PLATFORM.ONEXPLAYER_MINI_PRO
	elif product_name.begins_with("Jupiter") and vendor_name.begins_with("Valve"):
		logger.debug("Detected SteamDeck platform")
		return PLATFORM.STEAMDECK
	logger.debug("Detected generic platform")
	return PLATFORM.GENERIC


func _detect_os() -> void:
	pass
