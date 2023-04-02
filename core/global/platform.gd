extends Resource
class_name Platform

## Platform specific methods
##
## Used to perform platform-specific functions

## Platforms we support
enum PLATFORM {
	# Hardware platforms
	ABERNIC_GEN1,
	AOKZOE_GEN1,
	AYANEO_GEN1,  ## Includes Founders Edition, Pro, and Retro Power models.
	AYANEO_GEN2,  ## Includes NEXT models.
	AYANEO_GEN3,  ## Includes AIR models
	AYANEO_GEN4,  ## Includes 2 and GEEK models
	GENERIC,  ## Generic platform doesn't do anything special
	GPD_GEN1, ## Win3
	GPD_GEN2, ## WinMax2
	GPD_GEN3, ## Win4
	ONEXPLAYER_GEN1,  ## Includes most OXP and AOKZOE devices
	ONEXPLAYER_GEN2,  ## GUNDAM edition.
	STEAMDECK,
	
	# OS Platforms
	CHIMERAOS,
	STEAMOS,
	ARCH_LIKE,
}

## Data container for OS information
class OSInfo:
	var name: String
	var id: String
	var id_like: String
	var pretty_name: String
	var version_codename: String
	var variant_id: String

## Detected Operating System information
var os_info := _detect_os()
## The OS platform provider detected
var os: PlatformProvider
## The hardware platform provider detected
var platform: PlatformProvider
var logger := Log.get_logger("Platform", Log.LEVEL.DEBUG)

func _init() -> void:
	var flags := get_platform_flags()
	
	# Set hardware platform provider
	if PLATFORM.ABERNIC_GEN1 in flags:
		platform = load("res://core/platform/abernic_gen1.tres")
	if PLATFORM.AOKZOE_GEN1 in flags:
		platform = load("res://core/platform/aokzoe_gen1.gd")
	if PLATFORM.AYANEO_GEN1 in flags:
		platform = load("res://core/platform/ayaneo_gen1.tres")
	if PLATFORM.AYANEO_GEN2 in flags:
		platform = load("res://core/platform/ayaneo_gen2.tres")
	if PLATFORM.AYANEO_GEN3 in flags:
		platform = load("res://core/platform/ayaneo_gen3.tres")
	if PLATFORM.AYANEO_GEN4 in flags:
		platform = load("res://core/platform/ayaneo_gen4.tres")
	if PLATFORM.GENERIC in flags:
		platform = load("res://core/platform/generic.tres")
	if PLATFORM.GPD_GEN1 in flags:
		platform = load("res://core/platform/gpd_gen1.tres")
	if PLATFORM.GPD_GEN2 in flags:
		platform = load("res://core/platform/gpd_gen2.tres")
	if PLATFORM.GPD_GEN3 in flags:
		platform = load("res://core/platform/gpd_gen3.tres")
	if PLATFORM.ONEXPLAYER_GEN1 in flags:
		platform = load("res://core/platform/onexplayer_gen1.tres")
	if PLATFORM.ONEXPLAYER_GEN2 in flags:
		platform = load("res://core/platform/onexplayer_gen2.tres")
	if PLATFORM.STEAMDECK in flags:
		platform = load("res://core/platform/steamdeck.tres")
	
	# Set OS platform provider
	if PLATFORM.STEAMOS in flags:
		os = load("res://core/platform/steamos.tres")


## Loads the detected platforms. This should be called once when OpenGamepadUI
## first starts. It takes the root window to give platform providers the
## opportinity to modify the scene tree.
func load(root: Window) -> void:
	if platform:
		platform.ready(root)
	if os:
		os.ready(root)


## Returns the handheld gamepad for the detected platform
func get_handheld_gamepad() -> HandheldGamepad:
	if not platform:
		return null
	return platform.get_handheld_gamepad()


## Returns all detected platform flags
func get_platform_flags() -> Array[PLATFORM]:
	var flags: Array[PLATFORM] = []
	var dmi_flags := _read_dmi()
	flags.append(dmi_flags)
	flags.append_array(_read_os())
	return flags


## Returns the hardware product name
func get_product_name() -> String:
	var product_name := _read_sys("/sys/devices/virtual/dmi/id/product_name")
	return product_name


## Returns the hardware vendor name
func get_vendor_name() -> String:
	var vendor_name := _read_sys("/sys/devices/virtual/dmi/id/sys_vendor")
	return vendor_name


## Used to read values from sysfs
func _read_sys(path: String) -> String:
	var output: Array = _do_exec("cat", [path])
	return output[0][0].strip_escapes()


## returns result of OS.Execute in a reliable data structure
func _do_exec(command: String, args: Array) -> Array:
	var output = []
	var exit_code := OS.execute(command, args, output)
	return [output, exit_code]


# Reads DMI vendor and product name strings and returns an enumerated PLATFORM
func _read_dmi() -> PLATFORM:
	var product_name := get_product_name()
	var vendor_name := get_vendor_name()
	logger.debug("Product: " + product_name)
	logger.debug("Vendor: " + vendor_name)

	if product_name == "Win600" and vendor_name == "ABERNIC":
		logger.debug("Detected Win600 platform")
		return PLATFORM.ABERNIC_GEN1
	if product_name == "AOKZOE A1 AR07" and vendor_name == "AOKZOE":
		logger.debug("Detected AOKZOE A1 platform")
		return PLATFORM.ONEXPLAYER_GEN2
	elif product_name in ["AYANEO 2", "GEEK"] and vendor_name == "AYANEO":
		logger.debug("Detected AYANEO 2 platform")
		return PLATFORM.AYANEO_GEN4
	elif (
		(product_name.contains("2021") or product_name.contains("FOUNDER"))
		and vendor_name.begins_with("AYA")
	):
		logger.debug("Detected AYANEO 2021 platform")
		return PLATFORM.AYANEO_GEN1
	elif product_name.contains("AIR") and vendor_name == "AYANEO":
		logger.debug("Detected AYANEO AIR platform")
		return PLATFORM.AYANEO_GEN3
	elif product_name.contains("NEXT") and vendor_name == "AYANEO":
		logger.debug("Detected AYANEO NEXT platform")
		return PLATFORM.AYANEO_GEN2
	elif product_name.contains("G1618-03") and vendor_name == "GPD":
		logger.debug("Detected GPD Gen1 platform")
		return PLATFORM.GPD_GEN1
	elif product_name.contains("G1618-04") and vendor_name == "GPD":
		logger.debug("Detected GPD Gen2 platform")
		return PLATFORM.GPD_GEN2
	elif product_name.contains("G1619-04") and vendor_name == "GPD":
		logger.debug("Detected GPD Gen1 platform")
		return PLATFORM.GPD_GEN3
	elif product_name == "ONE XPLAYER" and vendor_name == ("ONE-NETBOOK TECHNOLOGY CO., LTD."):
		logger.debug("Detected OneXPlayer Intel platform")
		return PLATFORM.ONEXPLAYER_GEN1
	elif product_name == "ONE XPLAYER" and vendor_name == ("ONE-NETBOOK"):
		logger.debug("Detected OneXPlayer AMD platform")
		return PLATFORM.ONEXPLAYER_GEN2
	elif product_name.contains("ONEXPLAYER") and vendor_name == ("ONE-NETBOOK"):
		logger.debug("Detected OneXPlayer AMD platform")
		return PLATFORM.ONEXPLAYER_GEN2
	elif product_name.begins_with("Jupiter") and vendor_name.begins_with("Valve"):
		logger.debug("Detected SteamDeck platform")
		return PLATFORM.STEAMDECK
	logger.debug("Detected generic platform")
	return PLATFORM.GENERIC


# Read OS information and return flags that match
func _read_os() -> Array[PLATFORM]:
	var flags: Array[PLATFORM] = []
	if not os_info:
		return flags
	if os_info.id == "steamos":
		flags.append(PLATFORM.STEAMOS)
	if os_info.id_like == "arch":
		flags.append(PLATFORM.ARCH_LIKE)
	return flags


## Detect the currently running OS
func _detect_os() -> OSInfo:
	if not FileAccess.file_exists("/etc/os-release"):
		return null
	var os_file := FileAccess.open("/etc/os-release", FileAccess.READ)
	var content := os_file.get_as_text()
	var lines := content.split("\n")
	var info := OSInfo.new()
	for line in lines:
		var key_value := line.split("=")
		if key_value.size() != 2:
			continue
		var key := key_value[0]
		var value := key_value[1].replace('"', "")
		
		if key == "ID":
			info.id = value
		if key == "ID_LIKE":
			info.id_like = value
		if key == "NAME":
			info.name = value
		if key == "PRETTY_NAME":
			info.pretty_name = value
		if key == "VERSION_CODENAME":
			info.version_codename = value
		if key == "VARIANT_ID":
			info.variant_id = value
			
	return info
