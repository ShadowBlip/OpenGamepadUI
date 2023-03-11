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
	AYANEO_GEN2,  ## Includes NEXT models.
	AYANEO_GEN3,  ## Includes AIR models
	AYANEO_GEN4,  ## Includes 2 and GEEK models
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

var thread_group: ThreadGroup

# Placeholder stuff until Billy decides how he wants to do this for real.
var boost_capable := false
var core_count := 0
var cpu_model := ""
var cpu_vendor := ""
var gpu_clk_capable := false
var gpu_model := ""
var gpu_vendor := ""
var ht_capable := false
var tdp_capable := false
var tj_temp_capable := false
var smt := false


func _init() -> void:
	thread_group = ThreadGroup.new()
	thread_group.start()
	_id_system_cpu()
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
	if PLATFORM.AYANEO_GEN4 in flags:
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
	elif product_name in ["G1618-03", "G1618-04", "G1619-04"] and vendor_name == "GPD":
		logger.debug("Detected GPD Gen1 platform")
		return PLATFORM.GPD_GEN1
	elif product_name == "ONE XPLAYER" and vendor_name == ("ONE-NETBOOK"):
		if cpu_vendor == "GenuineIntel":
			logger.debug("Detected OneXPlayer GEN 1 platform")
			return PLATFORM.ONEXPLAYER_GEN1
		logger.debug("Detected OneXPlayer GEN 2 platform")
		return PLATFORM.ONEXPLAYER_GEN2
	elif product_name.contains("ONEXPLAYER") and vendor_name == ("ONE-NETBOOK"):
		if cpu_vendor == "GenuineIntel":
			logger.debug("Detected OneXPlayer GEN 1 platform")
			return PLATFORM.ONEXPLAYER_GEN1
		logger.debug("Detected OneXPlayer GEN 2 platform")
		return PLATFORM.ONEXPLAYER_GEN2
	elif product_name.begins_with("Jupiter") and vendor_name.begins_with("Valve"):
		logger.debug("Detected SteamDeck platform")
		return PLATFORM.STEAMDECK
	logger.debug("Detected generic platform")
	return PLATFORM.GENERIC


# Used to read values from sysfs
func read_sys(path: String) -> String:
	var output: Array = await thread_group.exec(_do_exec.bind("cat", [path]))
	return output[0][0].strip_escapes()


## Reads the CPU and gets its capabilities. Only supports AMD APU's currently.
## TODO: Support more than AMD APU's
func _id_system_cpu() -> void:
	var args = ["-c", "lscpu"]
	var output: Array = await thread_group.exec(_do_exec.bind("bash", args))
	var exit_code = output[1]
	if exit_code:
		logger.warn("Failed to read CPU. Exit code: " + str(exit_code))
		return
	var result := output[0][0].split("\n") as Array
	for param in result:
		var parts := param.split(" ", false) as Array
		if parts.is_empty():
			continue
		# Read CPU capabilities
		if parts[0] == "Flags:":
			if "ht" in parts:
				ht_capable = true
			if "cpb" in parts:
				boost_capable = true
		if parts[0] == "Vendor" and parts[1] == "ID:":
			# Delete parts of the string we don't want
			parts.remove_at(1)
			parts.remove_at(0)
			cpu_vendor = str(" ".join(parts))
		if parts[0] == "Model" and parts[1] == "name:":
			# Delete parts of the string we don't want
			parts.remove_at(1)
			parts.remove_at(0)
			cpu_model = str(" ".join(parts))

# Thread safe method of calling OS.execute
func _do_exec(command: String, args: Array)-> Array:
	var output = []
	var exit_code := OS.execute(command, args, output)
	return [output, exit_code]

func _detect_os() -> void:
	pass
