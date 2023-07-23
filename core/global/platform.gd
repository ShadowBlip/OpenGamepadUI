@icon("res://assets/editor-icons/platform.svg")
extends Resource
class_name Platform

## Platform specific methods
##
## Used to perform platform-specific functions

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
	AYANEO_GEN6,  ## Includes 2S and GEEK 1S
	AYN_GEN1,  ## Includes Loki Max, possibly others at release.
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

const APUDatabase := preload("res://core/platform/hardware/apu_database.gd")
const APUEntry := preload("res://core/platform/hardware/apu_entry.gd")
var amd_apu_database: APUDatabase
var intel_apu_database: APUDatabase

## Detected Operating System information
var os_info := _detect_os()
## The OS platform provider detected
var os: PlatformProvider
## The hardware platform provider detected
var platform: PlatformProvider
var logger := Log.get_logger("Platform", Log.LEVEL.INFO)
var cpu: CPUInfo
var gpu: GPUInfo


func _init() -> void:
	amd_apu_database = load("res://core/platform/hardware/amd_apu_database.tres")
	intel_apu_database = load("res://core/platform/hardware/intel_apu_database.tres")
	amd_apu_database.init()
	intel_apu_database.init()

	_get_system_components()

	var flags := get_platform_flags()
	
	# Set hardware platform provider
	if PLATFORM.ABERNIC_GEN1 in flags:
		platform = load("res://core/platform/handheld/abernic/abernic_gen1.tres")
	if PLATFORM.ALLY_GEN1 in flags:
		platform = load("res://core/platform/handheld/ally/ally_gen1.tres")
		if FileAccess.file_exists(platform.thermal_policy_path):
			logger.debug("Platform able to set thermal policy")
			gpu.thermal_mode_capable = true
	if PLATFORM.AOKZOE_GEN1 in flags:
		platform = load("res://core/platform/handheld/aokzoe/aokzoe_gen1.tres")
	if PLATFORM.AYANEO_GEN1 in flags:
		platform = load("res://core/platform/handheld/ayaneo/ayaneo_gen1.tres")
	if PLATFORM.AYANEO_GEN2 in flags:
		platform = load("res://core/platform/handheld/ayaneo/ayaneo_gen2.tres")
	if PLATFORM.AYANEO_GEN3 in flags:
		platform = load("res://core/platform/handheld/ayaneo/ayaneo_gen3.tres")
	if PLATFORM.AYANEO_GEN4 in flags:
		platform = load("res://core/platform/handheld/ayaneo/ayaneo_gen4.tres")
	if PLATFORM.AYANEO_GEN5 in flags:
		platform = load("res://core/platform/handheld/ayaneo/ayaneo_gen5.tres")
	if PLATFORM.AYN_GEN1 in flags:
		platform = load("res://core/platform/handheld/ayn/ayn_gen1.tres")
	if PLATFORM.GENERIC in flags:
		platform = load("res://core/platform/generic.tres")
	if PLATFORM.GPD_GEN1 in flags:
		platform = load("res://core/platform/handheld/gpd/gpd_gen1.tres")
	if PLATFORM.GPD_GEN2 in flags:
		platform = load("res://core/platform/handheld/gpd/gpd_gen2.tres")
	if PLATFORM.GPD_GEN3 in flags:
		platform = load("res://core/platform/handheld/gpd/gpd_gen3.tres")
	if PLATFORM.ONEXPLAYER_GEN1 in flags:
		platform = load("res://core/platform/handheld/onexplayer/onexplayer_gen1.tres")
	if PLATFORM.ONEXPLAYER_GEN2 in flags:
		platform = load("res://core/platform/handheld/onexplayer/onexplayer_gen2.tres")
	if PLATFORM.ONEXPLAYER_GEN3 in flags:
		platform = load("res://core/platform/handheld/onexplayer/onexplayer_gen3.tres")
	if PLATFORM.ONEXPLAYER_GEN4 in flags:
		platform = load("res://core/platform/handheld/onexplayer/onexplayer_gen4.tres")
	if PLATFORM.STEAMDECK in flags:
		platform = load("res://core/platform/handheld/steamdeck/steamdeck.tres")

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
	return await platform.get_handheld_gamepad()


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
	logger.debug("Product Name: " + product_name)
	return product_name


## Returns the hardware vendor name
func get_vendor_name() -> String:
	var vendor_name := _read_sys("/sys/devices/virtual/dmi/id/sys_vendor")
	logger.debug("Vendor Name: " + vendor_name)
	return vendor_name


## Returns the CPUInfo
func get_cpu_info() -> CPUInfo:
	return cpu


func get_cpu_model() -> String:
	return cpu.model


## Returns the GPUInfo
func get_gpu_info() -> GPUInfo:
	return gpu


func get_gpu_model() -> String:
	return gpu.model


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
	# ANBERNIC
	if product_name == "Win600" and vendor_name == "ANBERNIC":
		logger.debug("Detected Win600 platform")
		return PLATFORM.ABERNIC_GEN1
	# AOKZOE
	elif product_name in ["AOKZOE A1 AR07", "AOKZOE A1 Pro"] and vendor_name == "AOKZOE":
		logger.debug("Detected AOKZOE Gen1 platform")
		return PLATFORM.AOKZOE_GEN1
	# ASUS
	elif product_name == "ROG Ally RC71L_RC71L" and vendor_name == "ASUSTeK COMPUTER INC.":
		logger.debug("Detected ROG Ally Gen1 platform")
		return PLATFORM.ALLY_GEN1
	# AYANEO
	elif product_name in ["AYANEO 2", "GEEK"] and vendor_name == "AYANEO":
		logger.debug("Detected AYANEO Gen4 platform")
		return PLATFORM.AYANEO_GEN4
	elif product_name in ["AYANEO 2S", "GEEK 1S"] and vendor_name == "AYANEO":
		logger.debug("Detected AYANEO Gen6 platform")
		return PLATFORM.AYANEO_GEN6
	elif (
		(product_name.contains("2021") or product_name.contains("FOUNDER"))
		and vendor_name.begins_with("AYA")
	):
		logger.debug("Detected AYANEO 2021 platform")
		return PLATFORM.AYANEO_GEN1
	elif product_name in ["AIR", "AIR Pro"] and vendor_name == "AYANEO":
		logger.debug("Detected AYANEO Gen3 platform")
		return PLATFORM.AYANEO_GEN3
	elif product_name.contains("AIR Plus") and vendor_name == "AYANEO":
		logger.debug("Detected AYANEO Gen5 platform")
		return PLATFORM.AYANEO_GEN5
	elif product_name.contains("NEXT") and vendor_name == "AYANEO":
		logger.debug("Detected AYANEO Gen2 platform")
		return PLATFORM.AYANEO_GEN2
	# AYN
	elif product_name.contains("Loki Max") and vendor_name == "ayn":
		logger.debug("Detected Ayn Gen1 platform")
		return PLATFORM.AYN_GEN1
	# GPD
	elif product_name.contains("G1618-03") and vendor_name == "GPD":
		logger.debug("Detected GPD Gen1 platform")
		return PLATFORM.GPD_GEN1
	elif product_name.contains("G1619-04") and vendor_name == "GPD":
		logger.debug("Detected GPD Gen2 platform")
		return PLATFORM.GPD_GEN2
	elif product_name.contains("G1618-04") and vendor_name == "GPD":
		logger.debug("Detected GPD Gen3 platform")
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


# Reads the hardware.
func _get_system_components():
	cpu = _read_cpu_info()
	gpu = _read_gpu_info()


# Provides info on the CPU vendor, model, and capabilities.
func _read_cpu_info() -> CPUInfo:
	var cpu_info := CPUInfo.new()
	var cpu_raw := _get_lscpu_info()

	for param in cpu_raw:
		var parts := param.split(" ", false) as Array
		if parts.is_empty():
			continue
		if parts[0] == "Flags:":
			if "ht" in parts:
				cpu_info.smt_capable = true
			if "cpb" in parts:
				cpu_info.boost_capable = true
		if parts[0] == "Vendor" and parts[1] == "ID:":
			# Delete parts of the string we don't want
			parts.remove_at(1)
			parts.remove_at(0)
			cpu_info.vendor = str(" ".join(parts))
		if parts[0] == "Model" and parts[1] == "name:":
			# Delete parts of the string we don't want
			parts.remove_at(1)
			parts.remove_at(0)
			cpu_info.model = str(" ".join(parts))
		# TODO: We can get min/max CPU freq here.
	logger.debug("Found CPU: Vendor: " + cpu_info.vendor + " Model: " + cpu_info.model)
	return cpu_info


# Provides info on the GPU vendor, model, and capabilities.
func _get_lscpu_info() -> Array:
	var args = ["-c", "lscpu"]
	var output: Array = _do_exec("bash", args)
	var exit_code = output[1]
	if exit_code:
		return []
	return  output[0][0].split("\n") as Array


# Reads system files and tools to fill out the GPUInfo
func _read_gpu_info() -> GPUInfo:
	var gpu_info := GPUInfo.new()
	var gpu_raw := _get_glxinfo()

	# Get the GPU Vendor and Model
	for param in gpu_raw:
		var parts := param.split(" ", false) as Array
		if parts.is_empty():
			continue
		if parts[0] == "OpenGL" and parts[1] == "vendor" and parts[2] == "string:":
			parts.remove_at(2)
			parts.remove_at(1)
			parts.remove_at(0)
			gpu_info.vendor = str(" ".join(parts))
		if parts[0] == "OpenGL" and parts[1] == "renderer" and parts[2] == "string:":
			parts.remove_at(2)
			parts.remove_at(1)
			parts.remove_at(0)
			gpu_info.model = str(" ".join(parts))
	logger.debug("Found GPU: Vendor: " + gpu_info.vendor + "Model: " + gpu_info.model)

	if not cpu:
		return gpu_info

	# Get APU data, if it exists
	var apu_data: APUEntry = null
	match cpu.vendor:
		"AuthenticAMD", 'AuthenticAMD Advanced Micro Devices, Inc.':
			apu_data = amd_apu_database.get_apu(cpu.model)
			if apu_data:
				gpu_info.tj_temp_capable = true
		"GenuineIntel":
			apu_data = intel_apu_database.get_apu(cpu.model)
	if not apu_data:
		logger.info("No APU data for " + cpu.model)
		return gpu_info

	gpu_info.min_tdp = apu_data.min_tdp
	gpu_info.max_tdp = apu_data.max_tdp
	gpu_info.max_boost = apu_data.max_boost
	gpu_info.clk_capable = true
	gpu_info.tdp_capable = true
	logger.debug("Found all APU data")

	return gpu_info


# Run glxinfo and return the data from it.
# TODO: Maybe use vulkaninfo? Need a way to get vendor string in that. It can
# output to JSON so it might be easier to get more info like driver name and info,
# device type (dedicated or integrated), etc.
func _get_glxinfo() -> Array:
	var args = ["-c", "glxinfo", "-B"]
	var output: Array = _do_exec("bash", args)
	var exit_code = output[1]
	if exit_code:
		return []
	return  output[0][0].split("\n") as Array


## Data container for OS information
class OSInfo extends Resource:
	var name: String
	var id: String
	var id_like: String
	var pretty_name: String
	var version_codename: String
	var variant_id: String


## Data container for CPU information
class CPUInfo extends Resource:
	var model: String
	var vendor: String
	var smt_capable: bool = false
	var boost_capable: bool = false


## Data container for GPU information
class GPUInfo extends Resource:
	var model: String
	var vendor: String
	var tdp_capable: bool = false
	var thermal_mode_capable: bool = false
	var tj_temp_capable: bool = false
	var clk_capable: bool = false
	var min_tdp: float = -1
	var max_tdp: float = -1
	var max_boost: float = -1
