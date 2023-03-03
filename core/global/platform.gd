extends Resource
class_name Platform

## Platform specific methods
##
## Used to perform platform-specific functions

## Platforms we support
enum PLATFORM {
	ABERNIC_WIN600,
	AOKZOE_A1,
	AYANEO_2,
	AYANEO_2021, ## Includes Founders Edition, Pro, and Retro Power models.
	AYANEO_AIR, ## Includes 5600U and 5925U PRO models.
	AYANEO_GEEK,
	AYANEO_NEXT, ## Includes Advance and Pro models
	GENERIC,  ## Generic platform doesn't do anything special
	GPD_WIN3,
	GPD_WIN4,
	GPD_WINMAX2,
	ONEXPLAYER_GEN1, ## All older OXP devices have the same DMI data.
	ONEXPLAYER_MINI_PRO,
	STEAMDECK,
}


var platform: PlatformProvider
var logger := Log.get_logger("Platform", Log.LEVEL.DEBUG)


func _init() -> void:
	var flags := get_platform_flags()
	if flags & PLATFORM.ABERNIC_WIN600:
		platform = load("res://core/platform/abernic_win600.tres")
		return
	if flags & PLATFORM.AOKZOE_A1:
		platform = load("res://core/platform/aokzoe_a1.tres")
		return
	if flags & PLATFORM.AYANEO_2:
		platform = load("res://core/platform/ayaneo_2.tres")
		return
	if flags & PLATFORM.AYANEO_2021:
		platform = load("res://core/platform/ayaneo_2021.tres")
		return
	if flags & PLATFORM.AYANEO_AIR:
		platform = load("res://core/platform/ayaneo_air.tres")
		return
	if flags & PLATFORM.AYANEO_GEEK:
		platform = load("res://core/platform/ayaneo_geek.tres")
		return
	if flags & PLATFORM.AYANEO_NEXT:
		platform = load("res://core/platform/ayaneo_next.tres")
		return
	if flags & PLATFORM.GENERIC:
		platform = load("res://core/platform/generic.tres")
		return
	if flags & PLATFORM.GPD_WIN3:
		platform = load("res://core/platform/gpd_win3.tres")
		return
	if flags & PLATFORM.GPD_WIN4:
		platform = load("res://core/platform/gpd_win4.tres")
		return
	if flags & PLATFORM.GPD_WINMAX2:
		platform = load("res://core/platform/gpd_winmax2.tres")
		return
	if flags & PLATFORM.ONEXPLAYER_GEN1:
		platform = load("res://core/platform/onexplayer_gen1.tres")
		return
	if flags & PLATFORM.ONEXPLAYER_MINI_PRO:
		platform = load("res://core/platform/onexplayer_mini_pro.tres")
		return
	if flags & PLATFORM.STEAMDECK:
		platform = load("res://core/platform/steamdeck.tres")
		return


## Returns all detected platform flags
func get_platform_flags() -> int:
	var dmi_flags := _read_dmi()
	return dmi_flags


# Reads DMI vendor and product name strings and returns an enumerated PLATFORM
func _read_dmi() -> PLATFORM:
	var product_name := FileAccess.get_file_as_string("/sys/devices/virtual/dmi/id/product_name")
	product_name = product_name.strip_edges()
	var vendor_name := FileAccess.get_file_as_string("/sys/devices/virtual/dmi/id/sys_vendor")
	vendor_name = vendor_name.strip_edges()
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
	elif (product_name.contains("2021") or product_name.contains("FOUNDER")) \
		and vendor_name.begins_with("AYA"):
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
