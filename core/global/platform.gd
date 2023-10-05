@icon("res://assets/editor-icons/platform.svg")
extends Resource
class_name Platform

signal platform_loaded
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

const APUDatabase := preload("res://core/platform/hardware/apu_database.gd")
const APUEntry := preload("res://core/platform/hardware/apu_entry.gd")
const pci_ids_path := "/usr/share/hwdata/pci.ids"

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
var cards: Array[CardInfo]
var kernel: String
var bios: String
var loaded: bool
var product_name: String
var vendor_name: String

func _init() -> void:
	amd_apu_database = load("res://core/platform/hardware/amd_apu_database.tres")
	intel_apu_database = load("res://core/platform/hardware/intel_apu_database.tres")
	amd_apu_database.init()
	intel_apu_database.init()

	_get_system_components()

	var flags := get_platform_flags()

	# Set hardware platform provider
	if PLATFORM.ABERNIC_GEN1 in flags:
		platform = load("res://core/platform/handheld/abernic/abernic_gen1.tres") as HandheldPlatform
	if PLATFORM.ALLY_GEN1 in flags:
		platform = load("res://core/platform/handheld/asus/rog_ally_gen1.tres") as HandheldPlatform
		if FileAccess.file_exists(platform.thermal_policy_path):
			logger.debug("Platform able to set thermal policy")
			gpu.thermal_profile_capable = true
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



func _idendify_product() -> void:
	product_name = _read_sys("/sys/devices/virtual/dmi/id/product_name")
	vendor_name = _read_sys("/sys/devices/virtual/dmi/id/sys_vendor")
	logger.debug("Device identified as " + vendor_name + " " + product_name)


## Returns the hardware product name
func get_product_name() -> String:
	return product_name


## Returns the hardware vendor name
func get_vendor_name() -> String:
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
	
func get_gpu_driver() -> String:
	return gpu.driver
	
func get_kernel_version() -> String:
	return kernel

func get_bios_version() -> String:
	return bios

## Used to read values from sysfs
func _read_sys(path: String) -> String:
	var output: Array = _do_exec("cat", [path])
	return (output[0][0] as String).strip_escapes()


## returns result of OS.Execute in a reliable data structure
func _do_exec(command: String, args: Array) -> Array:
	var output = []
	var exit_code := OS.execute(command, args, output)
	return [output, exit_code]


# Reads DMI vendor and product name strings and returns an enumerated PLATFORM
func _read_dmi() -> PLATFORM:
	_idendify_product()
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


## Reads the hardware.
func _get_system_components():
	cpu = _read_cpu_info()
	gpu = _read_gpu_info()
	kernel = _get_kernel_version()
	bios = _get_bios_version()


## Provides info on the CPU vendor, model, and capabilities.
func _read_cpu_info() -> CPUInfo:
	logger.debug("Reading GPU Info")
	var cpu_info := CPUInfo.new()
	var cpu_raw := _get_lscpu_info()

	for param in cpu_raw:
		var parts := param.split(" ", false) as Array
		if parts.is_empty():
			continue
		if parts[0] == "Flags:":
			if "ht" in parts:
				cpu_info.smt_capable = true
			if "cpb" in parts and FileAccess.file_exists("/sys/devices/system/cpu/cpufreq/boost"):
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
	logger.debug("Found CPU: " + str(cpu_info))
	return cpu_info


## Provides info on the GPU vendor, model, and capabilities.
func _get_lscpu_info() -> PackedStringArray:
	var args = ["-c", "lscpu"]
	var output: Array = _do_exec("bash", args)
	var exit_code = output[1]
	if exit_code:
		return []
	return  (output[0][0] as String).split("\n") as PackedStringArray


## Reads system files and tools to fill out the GPUInfo
func _read_gpu_info() -> GPUInfo:
	logger.debug("Reading GPU Info")
	var gpu_info := GPUInfo.new()

	# Get the info reported by the current rendering driver.
	# TODO: This is much more simple than glxinfo but we need
	# to look into vulkaninfo as this can only gather the data
	# for the currently active GPU. Vulkaninfo can provide data
	# on all detected GPU devices.
	match RenderingServer.get_video_adapter_vendor():
		"AMD", "AuthenticAMD", 'AuthenticAMD Advanced Micro Devices, Inc.', "Advanced Micro Devices, Inc. [AMD/ATI]":
			gpu_info.vendor = "AMD"
		"Intel", "GenuineIntel", "Intel Corporation":
			gpu_info.vendor = "Intel"
		"Nvidia":
			gpu_info.vendor = "Trash" # :D
			logger.info("Nvidia devices are not suppored.")
			return null
		_:
			logger.warn("Device vendor string not recognized: " + RenderingServer.get_video_adapter_vendor())
			return null

	gpu_info.model = RenderingServer.get_video_adapter_name()
	gpu_info.driver = RenderingServer.get_video_adapter_api_version()

	# Identify all installed GPU's
	cards = get_gpu_cards()
	if cards.size() <= 0:
		logger.error("GPU Data could not be derived.")
		return null

	var active_gpu_data := get_active_gpu_device()
	if active_gpu_data.size() == 0:
		logger.debug("Found GPU: " + str(gpu_info))
		logger.error("Could not identify active GPU.")
		return gpu_info

	for card in cards:
		if card.vendor_id == active_gpu_data[0] and card.device_id == active_gpu_data[1]:
			gpu_info.card = card
		elif card.subvendor_id == active_gpu_data[0] and card.subdevice_id == active_gpu_data[1]:
			gpu_info.card = card

	if not gpu_info.card:
		logger.debug("Found GPU: " + str(gpu_info))
		logger.error("Could not identify active GPU.")
		return gpu_info

	if gpu_info.card.device_type != "PHYSICAL_DEVICE_TYPE_INTEGRATED_GPU":
		logger.debug("Found GPU: " + str(gpu_info))
		logger.debug("Active GPU is not an APU. Skipping APU Setup.")
		return gpu_info

	if not cpu:
		logger.debug("Found GPU: " + str(gpu_info))
		logger.debug("Cannot check APU database without CPU information.")
		return gpu_info

	# Get APU data, if it exists
	var apu_data: APUEntry = null
	match cpu.vendor:
		"AMD", "AuthenticAMD", 'AuthenticAMD Advanced Micro Devices, Inc.', "Advanced Micro Devices, Inc. [AMD/ATI]":
			apu_data = amd_apu_database.get_apu(cpu.model)
			if not apu_data:
				logger.debug("Found GPU: " + str(gpu_info))
				logger.debug("No APU Match for device: " + cpu.model)
				return gpu_info
			logger.debug("Found APU Data: " +str(apu_data.model_name))
			gpu_info.tj_temp_capable = true
			gpu_info.power_profile_capable = true
			gpu_info.clk_capable = true
			gpu_info.tdp_min = apu_data.min_tdp
			gpu_info.tdp_max = apu_data.max_tdp
			gpu_info.max_boost = apu_data.max_boost
			gpu_info.tdp_capable = true

		"Intel", "GenuineIntel", "Intel Corporation":
			apu_data = intel_apu_database.get_apu(cpu.model)
			if not apu_data:
				logger.debug("Found GPU: " + str(gpu_info))
				logger.debug("No APU Match for device: " + cpu.model)
				return gpu_info
			logger.debug("Found APU Data: " +str(apu_data.model_name))
			gpu_info.clk_capable = true
			gpu_info.tdp_min = apu_data.min_tdp
			gpu_info.tdp_max = apu_data.max_tdp
			gpu_info.max_boost = apu_data.max_boost
			gpu_info.tdp_capable = true

		_:
			logger.debug("No match: " + cpu.vendor)
			logger.debug("Found GPU: " + str(gpu_info))
			return gpu_info

	logger.debug("APU Data Loaded")
	logger.debug("Found GPU: " + str(gpu_info))
	return gpu_info


## Returns an array of CardInfo resources derived from /sys/class/drm
func get_gpu_cards() -> Array[CardInfo]:
	var path_prefix := "/sys/class/drm"
	var found_cards: Array[CardInfo] = []
	var card_dirs := DirAccess.get_directories_at(path_prefix)
	for card_name in card_dirs:

		if not "card" in card_name:
			continue
		if "-" in card_name:
			continue
		var card_info := CardInfo.new()
		var file_prefix := "/".join([path_prefix, card_name, "device"])

		card_info.name = card_name
		card_info.vendor_id = _get_card_property_from_path("/".join([file_prefix, "vendor"]))
		card_info.device_id = _get_card_property_from_path("/".join([file_prefix, "device"]))
		card_info.revision_id = _get_card_property_from_path("/".join([file_prefix, "revision"]))
		card_info.subvendor_id = _get_card_property_from_path("/".join([file_prefix, "subsystem_vendor"]))
		card_info.subdevice_id = _get_card_property_from_path("/".join([file_prefix, "subsystem_device"]))
		card_info = expound_device_from_card(card_info)

		# Sanitize the vendor strings so they are standard.
		match card_info.vendor:
			"AMD", "AuthenticAMD", 'AuthenticAMD Advanced Micro Devices, Inc.', "Advanced Micro Devices, Inc. [AMD/ATI]":
				card_info.vendor = "AMD"
			"Intel", "GenuineIntel", "Intel Corporation":
				card_info.vendor = "Intel"
			"Nvidia":
				card_info.vendor = "Trash"
				logger.info("Nvidia devices are not suppored.")
				continue
			_:
				logger.warn("Device vendor string not recognized: " + card_info.vendor)
				continue

		# TODO: Itentify ports
		found_cards.append(card_info)

	var vulkan_info := _get_cards_from_vulkan()
	if found_cards.size() == 0 or vulkan_info.size() == 0:
		logger.error("Unable to identify display adapters")
		return found_cards

	for card in found_cards:
		for info in vulkan_info:
			if card.vendor_id == info[0] and card.device_id == info[1]:
				card.device_type = info[2]
				logger.debug("Assigning type " + card.device_type + " to device " + card.device)

	return found_cards


## Helper function that simplifies reading id values from a given path.
func _get_card_property_from_path(path: String) -> String:
	return FileAccess.get_file_as_string(path).lstrip("0x").to_lower().strip_escapes()


## Returns a PackedStringArray that includes the Vendor Name, Device Name,
## and Subdevice Name as defined in /usr/share/hwdata/pci.ids byt matching
## the id values derived from /sys/class/drm/cardX/device/<property> from
## the list <vendor/device/subsystem_vendor/subsystem_device>.
func expound_device_from_card(cardinfo: CardInfo) -> CardInfo:
	var hwids := FileAccess.open(pci_ids_path, FileAccess.READ)
	var vendor_found: bool = false
	var device_found: bool = false
	logger.debug("Getting device info from: " + cardinfo.vendor_id + " " + cardinfo.device_id + " " + cardinfo.subvendor_id + " " + cardinfo.subdevice_id)
	while not hwids.eof_reached():
		var line := hwids.get_line()
		var line_clean := line.strip_escapes()

		if line.begins_with("\t") and not vendor_found:
			continue
		if line.begins_with(cardinfo.vendor_id):
			cardinfo.vendor = line.lstrip(cardinfo.vendor_id).strip_edges()
			logger.debug("Found vendor_name: " + cardinfo.vendor)
			vendor_found = true
			continue
		if vendor_found and not line.begins_with("\t"):
			if line.begins_with("#"):
				continue
			logger.debug("Got to end of vendor list. Device not found")
			break

		if line.begins_with("\t\t") and not device_found:
			continue

		if line_clean.begins_with(cardinfo.device_id):
			cardinfo.device = line_clean.lstrip(cardinfo.device_id).strip_edges()
			logger.debug("Found device_name: " + cardinfo.device)
			device_found = true

		if device_found and not line.begins_with("\t\t"):
			logger.debug("Got to end of device list. Subdevice not found")
			break

		var prefix := cardinfo.subvendor_id + " " + cardinfo.subdevice_id
		if line_clean.begins_with(prefix):
			cardinfo.subdevice = line.lstrip(prefix)
			logger.debug("Found subdevice_name: " + cardinfo.subdevice)
			break

	return cardinfo


func _get_cards_from_vulkan() ->Array[PackedStringArray]:
	var vulkan_cards: Array[PackedStringArray] = []
	var args = ["--summary"]
	var output: Array = _do_exec("vulkaninfo", args)
	var exit_code = output[1]
	if exit_code != OK:
		logger.error("Failed to run vulkaninfo")
		return []
	var stdout := (output[0][0] as String).split("\n") as PackedStringArray
	var i := 0
	for line in stdout:
		var vendor_id: String
		var device_id: String
		var device_type: String
		if not "vendorID" in line:
			i += 1
			continue
		var split_line: PackedStringArray = line.split("=")
		vendor_id = split_line[1].strip_edges().replace("0x", "").to_lower()
		split_line = stdout[i+1].split("=")
		device_id = split_line[1].strip_edges().replace("0x", "").to_lower()
		split_line = stdout[i+2].split("=")
		device_type = split_line[1].strip_edges()
		var device_info: PackedStringArray = [vendor_id, device_id, device_type]
		vulkan_cards.append(device_info)
		logger.debug("Found vulkan device: " + vendor_id + "|" + device_id + "|" + device_type)
		i += 1
	return vulkan_cards


## Returns the string of the currently active GPU
func get_active_gpu_device() -> PackedStringArray:
	var vendor: String
	var device: String
	var args = ["-B"]
	var output: Array = _do_exec("glxinfo", args)
	var exit_code = output[1]

	if exit_code != OK:
		logger.error("Failed to run glxinfo")
		return []

	var stdout := (output[0][0] as String).split("\n") as Array
	for line in stdout:
		if not "Device: " in line and not "Vendor: " in line:
			continue

		# Match on the last part of the string to get the device ID
		# E.g. Device: AMD Radeon Graphics (renoir, LLVM 16.0.6, DRM 3.54, 6.5.5-arch1-1) (0x1636)
		var regex := RegEx.new()
		regex.compile("0[xX][0-9a-fA-F]+\\)$")
		var result := regex.search(line)
		if not result:
			logger.debug("Got no result: " + str(result))
			continue

		var match_str := result.get_string()
		if "Device: " in line:
			device = match_str.replace("0x", "").replace(")", "").to_lower()
			logger.debug("Found device: " + device)
		if "Vendor: " in line:
			vendor = match_str.replace("0x", "").replace(")", "").to_lower()
			logger.debug("Found vendor: " + vendor)
		if vendor and device:
			break

	if not vendor or not device:
		logger.error("Unable to identify currently active device. ")
		return []

	return [vendor, device]


# Run uname and return the data from it.
func _get_kernel_version() -> String:
	var output: Array = _do_exec("uname", ["-s", "-r", "-m"]) # Fetches kernel name, version, and machine
	var exit_code = output[1]
	if exit_code:
		return "Unknown"
	return output[0][0] as String

# Queries /sys/class for BIOS information
func _get_bios_version() -> String:
	var output: Array = _do_exec("cat", ["/sys/class/dmi/id/bios_version"])
	var exit_code = output[1]
	if exit_code:
		return "Unknown"
	return output[0][0] as String


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
	var core_count: int = 1
	var cores_available: int = 1
	var boost_capable: bool = false
	var vendor: String
	var model: String
	var smt_capable: bool = false

	func _to_string() -> String:
		return "<CPUInfo:" \
			+ " Vendor: (" + str(vendor) \
			+ ") Model: (" + str(model) \
			+ ") Core count: (" + str(core_count) \
			+ ") Cores Enabled: (" + str(cores_available) \
			+ ") Boost Capable: (" + str(boost_capable) \
			+ ") SMT Ccapable: (" + str(smt_capable) \
			+ ")>"


## Data container for GPU information
class GPUInfo extends Resource:
	var clk_capable: bool = false
	var card: CardInfo
	var driver: String
	var freq_max: float
	var freq_min: float
	var max_boost: float = -1
	var model: String
	var power_profile_capable: bool = false
	var tdp_capable: bool = false
	var tdp_max: float = -1
	var tdp_min: float = -1
	var thermal_profile_capable: bool = false
	var tj_temp_capable: bool = false
	var vendor: String

	func _to_string() -> String:
		return "GPUInfo:" \
			+ " Vendor: (" + str(vendor) \
			+ ") Model: (" + str(model) \
			+ ") Driver: (" + str(driver) \
			+ ") TDP Min: (" + str(tdp_min) \
			+ ") TDP Max: (" + str(tdp_max) \
			+ ") TDP Max Boost Adjustment: (" + str(max_boost) \
			+ ") Clock Capable: (" + str(clk_capable) \
			+ ") Frequency Min: (" + str(freq_min) \
			+ ") Frequency Min: (" + str(freq_max) \
			+ ") Power Profile Capable: (" + str(power_profile_capable) \
			+ ") Thermal Profile Capable: (" + str(thermal_profile_capable) \
			+ ") Tjunction Temp Setable: (" + str(tj_temp_capable) \
			+ ") PCI Data: (" + str(card) \
			+ ")>"


## Data container for /sys/class/drm/cardX information
class CardInfo extends Resource:
	var name: String
	var vendor: String
	var vendor_id: String
	var device: String
	var device_id: String
	var device_type: String
	var subdevice: String
	var subdevice_id: String
	var subvendor_id: String
	var revision_id: String
	var ports: PackedStringArray

	func _to_string() -> String:
		return "<CardInfo:" \
			+ " Name: (" + str(name) \
			+ ") Vendor: (" + str(vendor) \
			+ ") Vendor ID: (" + str(vendor_id) \
			+ ") Device: (" + str(device) \
			+ ") Device ID: (" + str(device_id) \
			+ ") Device Type: (" + str(device_type) \
			+ ") Subdevice: (" + str(subdevice) \
			+ ") Subdevice ID: (" + str(subvendor_id) \
			+ ") Revision ID: (" + str(revision_id) \
			+ ") Ports: (" + str(ports) \
			+ ")>"
