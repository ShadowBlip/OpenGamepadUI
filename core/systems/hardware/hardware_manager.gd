extends Resource
class_name HardwareManager

## Discover and queries different aspects of the hardware
##
## HardwareManager is responsible for providing a way to discover and query
## different aspects of the current hardware.

const pci_ids_path := "/usr/share/hwdata/pci.ids"

var amd_apu_database := load("res://core/platform/hardware/amd_apu_database.tres") as APUDatabase
var intel_apu_database := load("res://core/platform/hardware/intel_apu_database.tres") as APUDatabase
var logger := Log.get_logger("HardwareManager", Log.LEVEL.INFO)
var cards := get_gpu_cards()
var card_ports: Array[DRMCardPort]
var cpu := get_cpu_info()
var gpu := get_gpu_info()
var bios := get_bios_version()
var kernel := get_kernel_version()
var product_name := get_product_name()
var vendor_name := get_vendor_name()
var thread := load("res://core/systems/threading/io_thread.tres") as SharedThread


## Queries /sys/class for BIOS information
func get_bios_version() -> String:
	var output: Array = _exec("cat", ["/sys/class/dmi/id/bios_version"])
	var exit_code = output[1]
	if exit_code:
		return "Unknown"
	return output[0][0] as String


## Returns the hardware product name
func get_product_name() -> String:
	return _read_sys("/sys/devices/virtual/dmi/id/product_name")


## Returns the hardware vendor name
func get_vendor_name() -> String:
	return _read_sys("/sys/devices/virtual/dmi/id/sys_vendor")


## Provides info on the CPU vendor, model, and capabilities.
func get_cpu_info() -> CPUInfo:
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


## Returns the GPUInfo
func get_gpu_info() -> GPUInfo:
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


## Returns the kernel version
func get_kernel_version() -> String:
	var output: Array = _exec("uname", ["-s", "-r", "-m"]) # Fetches kernel name, version, and machine
	var exit_code = output[1]
	if exit_code:
		return "Unknown"
	return output[0][0] as String


## Returns GPU card info for the given card directory in /sys/class/drm
## (e.g. get_gpu_card("card1"))
func get_gpu_card(card_dir: String) -> DRMCardInfo:
	var file_prefix := "/".join(["/sys/class/drm", card_dir, "device"])
	var vendor_id := _get_card_property_from_path("/".join([file_prefix, "vendor"]))
	var device_id := _get_card_property_from_path("/".join([file_prefix, "device"]))
	var revision_id := _get_card_property_from_path("/".join([file_prefix, "revision"]))
	var subvendor_id := _get_card_property_from_path("/".join([file_prefix, "subsystem_vendor"]))
	var subdevice_id := _get_card_property_from_path("/".join([file_prefix, "subsystem_device"]))

	# Try to load the card info if it already exists
	var res_path := "/".join(["drmcardinfo://", vendor_id, device_id, subvendor_id, subdevice_id])
	if ResourceLoader.exists(res_path):
		var card_info := load(res_path) as DRMCardInfo
		if card_info.name != card_dir:
			card_info.name = card_dir
		return card_info

	# Create a new card instance and take over the caching path
	var card_info := DRMCardInfo.new()
	card_info.take_over_path(res_path)
	card_info.name = card_dir
	card_info.vendor_id = vendor_id
	card_info.device_id = device_id
	card_info.revision_id = revision_id
	card_info.subvendor_id = subvendor_id
	card_info.subdevice_id = subdevice_id
	
	# Lookup the card details
	var hwids := FileAccess.open(pci_ids_path, FileAccess.READ)
	var vendor_found: bool = false
	var device_found: bool = false
	logger.debug("Getting device info from: " + vendor_id + " " + device_id + " " + subvendor_id + " " + subdevice_id)
	while not hwids.eof_reached():
		var line := hwids.get_line()
		var line_clean := line.strip_escapes()

		if line.begins_with("\t") and not vendor_found:
			continue
		if line.begins_with(vendor_id):
			card_info.vendor = line.lstrip(vendor_id).strip_edges()
			logger.debug("Found vendor name: " + card_info.vendor)
			vendor_found = true
			continue
		if vendor_found and not line.begins_with("\t"):
			if line.begins_with("#"):
				continue
			logger.debug("Got to end of vendor list. Device not found")
			break

		if line.begins_with("\t\t") and not device_found:
			continue

		if line_clean.begins_with(device_id):
			card_info.device = line_clean.lstrip(device_id).strip_edges()
			logger.debug("Found device name: " + card_info.device)
			device_found = true

		if device_found and not line.begins_with("\t\t"):
			logger.debug("Got to end of device list. Subdevice not found")
			break

		var prefix := subvendor_id + " " + subdevice_id
		if line_clean.begins_with(prefix):
			card_info.subdevice = line.lstrip(prefix)
			logger.debug("Found subdevice name: " + card_info.subdevice)
			break

	# Sanitize the vendor strings so they are standard.
	match card_info.vendor:
		"AMD", "AuthenticAMD", 'AuthenticAMD Advanced Micro Devices, Inc.', "Advanced Micro Devices, Inc. [AMD/ATI]":
			card_info.vendor = "AMD"
		"Intel", "GenuineIntel", "Intel Corporation":
			card_info.vendor = "Intel"
		"Nvidia":
			card_info.vendor = "Trash"
			logger.warn("Nvidia devices are not suppored.")
			# TODO: Handle this case
			return null
		_:
			logger.warn("Device vendor string not recognized: " + card_info.vendor)
			# TODO: Handle this case
			return null

	return card_info


## Returns an array of CardInfo resources derived from /sys/class/drm
func get_gpu_cards() -> Array[DRMCardInfo]:
	var path_prefix := "/sys/class/drm"
	var found_cards: Array[DRMCardInfo] = []
	var card_dirs := DirAccess.get_directories_at(path_prefix)

	for card_name in card_dirs:
		if not "card" in card_name:
			continue
		if "-" in card_name:
			continue
		var card_info := get_gpu_card(card_name)
		if not card_info:
			continue
		
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


## Returns the string of the currently active GPU
func get_active_gpu_device() -> PackedStringArray:
	var vendor: String
	var device: String
	var args = ["-B"]
	var output: Array = _exec("glxinfo", args)
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


## Starts watching for GPU connector port state changes in a separate thread,
## updating the properties of [DRMCardPort] objects and emitting signals
## when their state changes.
func start_gpu_watch() -> void:
	# Don't start again if already ran
	if card_ports.size() > 0:
		logger.debug("GPU state watch already started")
		return
	
	# Create a function to get called every thread "tick"
	var port_update := func(_delta: float, port: DRMCardPort) -> void:
		port.update()

	# Poll GPU port state in a thread
	# TODO: handle hot-swappable GPUs
	for card in cards:
		var ports := card.get_ports()
		for port in ports:
			thread.add_process(port_update.bind(port))
		card_ports.append_array(ports)

	thread.start()


## Provides info on the GPU vendor, model, and capabilities.
func _get_lscpu_info() -> PackedStringArray:
	var output: Array = _exec("lscpu")
	var exit_code = output[1]
	if exit_code:
		return []
	return  (output[0][0] as String).split("\n") as PackedStringArray


## Helper function that simplifies reading id values from a given path.
func _get_card_property_from_path(path: String) -> String:
	return FileAccess.get_file_as_string(path).lstrip("0x").to_lower().strip_escapes()


## Returns a an array of PackedStringArray's that each represent a sing GPU
## identified in vulkaninfo.
func _get_cards_from_vulkan() ->Array[PackedStringArray]:
	var vulkan_cards: Array[PackedStringArray] = []
	var args = ["--summary"]
	var output: Array = _exec("vulkaninfo", args)
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


## returns result of OS.Execute in a reliable data structure
func _exec(command: String, args: PackedStringArray = []) -> Array:
	var output = []
	var exit_code := OS.execute(command, args, output)
	return [output, exit_code]


## Used to read values from sysfs
func _read_sys(path: String) -> String:
	var file := FileAccess.open(path, FileAccess.READ)
	var length := file.get_length()
	var bytes := file.get_buffer(length)
	return bytes.get_string_from_utf8().strip_escapes()


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
	var card: DRMCardInfo
	var driver: String
	var freq_max: float
	var freq_min: float
	var max_boost: float = -1
	var model: String
	var power_profile_capable: bool = false
	var tdp_capable: bool = false
	var tdp_max: float = -1
	var tdp_min: float = -1
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
			+ ") Tjunction Temp Setable: (" + str(tj_temp_capable) \
			+ ") PCI Data: (" + str(card) \
			+ ")>"
