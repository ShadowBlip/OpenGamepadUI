@icon("res://assets/editor-icons/platform.svg")
extends Resource
class_name Platform

## Platform specific methods
##
## Used to perform platform-specific functions

signal platform_loaded

## Platforms we support
enum PLATFORM {
	# Hardware platforms
	ABERNIC_GEN1, ## Win600
	AOKZOE_GEN1,  ## A1 AR07, A1 Pro
	ALLY_GEN1,    ## ASUS ROG Ally RC71L
	AYANEO_GEN1,  ## Includes Founders Edition, Pro, and Retro Power models.
	AYANEO_GEN2,  ## Includes NEXT models.
	AYANEO_GEN3,  ## Includes AIR and AIR Pro models
	AYANEO_GEN4,  ## Includes 2 and GEEK models
	AYANEO_GEN5,  ## AIR Plus 6800U
	AYANEO_GEN6,  ## Includes 2S,GEEK 1S, AIR 1S
	AYANEO_GEN7,  ## AIR Plus i3 1215U
	AYN_GEN1, ## Loki Max
	AYN_GEN2, ## Loki Zero
	AYN_GEN3, ## Loki MiniPro
	GENERIC,  ## Generic platform doesn't do anything special
	GPD_GEN1, ## Win3
	GPD_GEN2, ## WinMax2
	GPD_GEN3, ## Win4
	ONEXPLAYER_GEN1,  ## Intel OXP Devices
	ONEXPLAYER_GEN2,  ## AMD OXP Devices 5800U and older.
	ONEXPLAYER_GEN3,  ## AMD OXP Mini A07.
	ONEXPLAYER_GEN4,  ## AMD OXP Mini Pro 6800U.
	STEAMDECK,
	
	# OS Platforms
	CHIMERAOS,
	STEAMOS,
	ARCH_LIKE,
}

var hardware_manager := load("res://core/systems/hardware/hardware_manager.tres") as HardwareManager

## Detected Operating System information
var os_info := _detect_os()
## The OS platform provider detected
var os: PlatformProvider
## The hardware platform provider detected
var platform: PlatformProvider
var logger := Log.get_logger("Platform", Log.LEVEL.INFO)
var loaded: bool


func _init() -> void:
	var flags := get_platform_flags()

	# Set hardware platform provider
	if PLATFORM.ABERNIC_GEN1 in flags:
		platform = load("res://core/platform/handheld/abernic/abernic_gen1.tres") as HandheldPlatform
	if PLATFORM.ALLY_GEN1 in flags:
		platform = load("res://core/platform/handheld/asus/rog_ally_gen1.tres") as HandheldPlatform
	if PLATFORM.AOKZOE_GEN1 in flags:
		platform = load("res://core/platform/handheld/aokzoe/aokzoe_gen1.tres") as HandheldPlatform
	if PLATFORM.AYANEO_GEN1 in flags:
		platform = load("res://core/platform/handheld/ayaneo/ayaneo_gen1.tres") as HandheldPlatform
	if PLATFORM.AYANEO_GEN2 in flags:
		platform = load("res://core/platform/handheld/ayaneo/ayaneo_gen2.tres") as HandheldPlatform
	if PLATFORM.AYANEO_GEN3 in flags:
		platform = load("res://core/platform/handheld/ayaneo/ayaneo_gen3.tres") as HandheldPlatform
	if PLATFORM.AYANEO_GEN4 in flags:
		platform = load("res://core/platform/handheld/ayaneo/ayaneo_gen4.tres") as HandheldPlatform
	if PLATFORM.AYANEO_GEN5 in flags:
		platform = load("res://core/platform/handheld/ayaneo/ayaneo_gen5.tres") as HandheldPlatform
	if PLATFORM.AYANEO_GEN6 in flags:
		platform = load("res://core/platform/handheld/ayaneo/ayaneo_gen6.tres") as HandheldPlatform
	if PLATFORM.AYANEO_GEN7 in flags:
		platform = load("res://core/platform/handheld/ayaneo/ayaneo_gen7.tres") as HandheldPlatform
	if PLATFORM.AYN_GEN1 in flags:
		platform = load("res://core/platform/handheld/ayn/ayn_gen1.tres") as HandheldPlatform
	if PLATFORM.AYN_GEN2 in flags:
		platform = load("res://core/platform/handheld/ayn/ayn_gen2.tres") as HandheldPlatform
	if PLATFORM.AYN_GEN3 in flags:
		platform = load("res://core/platform/handheld/ayn/ayn_gen3.tres") as HandheldPlatform
	if PLATFORM.GENERIC in flags:
		platform = load("res://core/platform/generic.tres")
	if PLATFORM.GPD_GEN1 in flags:
		platform = load("res://core/platform/handheld/gpd/gpd_gen1.tres") as HandheldPlatform
	if PLATFORM.GPD_GEN2 in flags:
		platform = load("res://core/platform/handheld/gpd/gpd_gen2.tres") as HandheldPlatform
	if PLATFORM.GPD_GEN3 in flags:
		platform = load("res://core/platform/handheld/gpd/gpd_gen3.tres") as HandheldPlatform
	if PLATFORM.ONEXPLAYER_GEN1 in flags:
		platform = load("res://core/platform/handheld/onexplayer/onexplayer_gen1.tres") as HandheldPlatform
	if PLATFORM.ONEXPLAYER_GEN2 in flags:
		platform = load("res://core/platform/handheld/onexplayer/onexplayer_gen2.tres") as HandheldPlatform
	if PLATFORM.ONEXPLAYER_GEN3 in flags:
		platform = load("res://core/platform/handheld/onexplayer/onexplayer_gen3.tres") as HandheldPlatform
	if PLATFORM.ONEXPLAYER_GEN4 in flags:
		platform = load("res://core/platform/handheld/onexplayer/onexplayer_gen4.tres") as HandheldPlatform
	if PLATFORM.STEAMDECK in flags:
		platform = load("res://core/platform/handheld/steamdeck/steamdeck.tres") as HandheldPlatform

	if platform:
		for action in platform.startup_actions:
			action.execute()

	# Set OS platform provider
	if PLATFORM.STEAMOS in flags:
		os = load("res://core/platform/os/steamos.tres")
	if PLATFORM.CHIMERAOS in flags:
		os = load("res://core/platform/os/chimeraos.tres")

	if os:
		for action in os.startup_actions:
			action.execute()
	logger.debug("Platform loaded.")
	platform_loaded.emit()
	loaded = true


## Loads the detected platforms. This should be called once when OpenGamepadUI
## first starts. It takes the root window to give platform providers the
## opportinity to modify the scene tree.
@warning_ignore("shadowed_global_identifier")
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


# Reads DMI vendor and product name strings and returns an enumerated PLATFORM
func _read_dmi() -> PLATFORM:
	var product_name := hardware_manager.product_name
	var vendor_name := hardware_manager.vendor_name
	var cpu := hardware_manager.cpu
	logger.debug("Device identified as " + vendor_name + " " + product_name)

	# ANBERNIC
	if product_name == "Win600" and vendor_name == "ANBERNIC":
		logger.debug("Detected Win600 platform")
		return PLATFORM.ABERNIC_GEN1

	# AOKZOE
	elif product_name in ["AOKZOE A1 AR07", "AOKZOE A1 Pro"] and vendor_name == "AOKZOE":
		logger.debug("Detected AOKZOE Gen 1 platform")
		return PLATFORM.AOKZOE_GEN1

	# ASUS
	elif product_name == "ROG Ally RC71L_RC71L" and vendor_name == "ASUSTeK COMPUTER INC.":
		logger.debug("Detected ROG Ally Gen 1 platform")
		return PLATFORM.ALLY_GEN1

	# AYANEO
	elif product_name in ["AYANEO 2", "GEEK"] and vendor_name == "AYANEO":
		logger.debug("Detected AYANEO Gen 4 platform")
		return PLATFORM.AYANEO_GEN4
	elif product_name in ["AYANEO 2S", "GEEK 1S", "AIR 1S"] and vendor_name == "AYANEO":
		logger.debug("Detected AYANEO Gen 6 platform")
		return PLATFORM.AYANEO_GEN6
	elif (
		(product_name.contains("2021") or product_name.contains("FOUNDER"))
		and vendor_name.begins_with("AYA")
	):
		logger.debug("Detected AYANEO 2021 platform")
		return PLATFORM.AYANEO_GEN1
	elif product_name in ["AIR", "AIR Pro"] and vendor_name == "AYANEO":
		logger.debug("Detected AYANEO Gen 3 platform")
		return PLATFORM.AYANEO_GEN3
	elif product_name.contains("AIR Plus") and vendor_name == "AYANEO":
		match cpu.vendor:
			"GenuineIntel":
				logger.debug("Detected AYANEO Gen 7 platform")
				return PLATFORM.AYANEO_GEN7
			'AuthenticAMD', 'AuthenticAMD Advanced Micro Devices, Inc.':
				logger.debug("Detected AYANEO Gen 5 platform")
				return PLATFORM.AYANEO_GEN5
	elif product_name.contains("NEXT") and vendor_name == "AYANEO":
		logger.debug("Detected AYANEO Gen 2 platform")
		return PLATFORM.AYANEO_GEN2

	# AYN
	elif product_name.contains("Loki Max") and vendor_name == "ayn":
		logger.debug("Detected Ayn Gen 1 platform")
		return PLATFORM.AYN_GEN1
	elif product_name.contains("Loki Zero") and vendor_name == "ayn":
		logger.debug("Detected Ayn Gen 2 platform")
		return PLATFORM.AYN_GEN2
	elif product_name.contains("Loki MiniPro") and vendor_name == "ayn":
		logger.debug("Detected Ayn Gen 3 platform")
		return PLATFORM.AYN_GEN3

	# GPD
	elif product_name.contains("G1618-03") and vendor_name == "GPD":
		logger.debug("Detected GPD Gen 1 platform")
		return PLATFORM.GPD_GEN1
	elif product_name.contains("G1619-04") and vendor_name == "GPD":
		logger.debug("Detected GPD Gen 2 platform")
		return PLATFORM.GPD_GEN2
	elif product_name.contains("G1618-04") and vendor_name == "GPD":
		logger.debug("Detected GPD Gen 3 platform")
		return PLATFORM.GPD_GEN3

	# OneXPlayer
	elif product_name in ["ONEXPLAYER Mini Pro"] and vendor_name.contains("ONE-NETBOOK"):
		logger.debug("Detected OneXPlayer Gen 4 platform")
		return PLATFORM.ONEXPLAYER_GEN4
	elif product_name in ["ONEXPLAYER mini A07"] and vendor_name.contains("ONE-NETBOOK"):
		logger.debug("Detected OneXPlayer Gen 3 platform")
		return PLATFORM.ONEXPLAYER_GEN3
	elif product_name in ["ONE XPLAYER", "ONEXPLAYER"] and vendor_name.contains("ONE-NETBOOK"):
		match cpu.vendor:
			"GenuineIntel":
				logger.debug("Detected OneXPlayer Gen 1 platform")
				return PLATFORM.ONEXPLAYER_GEN1
			'AuthenticAMD', 'AuthenticAMD Advanced Micro Devices, Inc.':
				logger.debug("Detected OneXPlayer Gen 2 platform")
				return PLATFORM.ONEXPLAYER_GEN2

	# Valve
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
	if os_info.id == "chimeraos":
		flags.append(PLATFORM.CHIMERAOS)
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


## Data container for OS information
class OSInfo extends Resource:
	var name: String
	var id: String
	var id_like: String
	var pretty_name: String
	var version_codename: String
	var variant_id: String
