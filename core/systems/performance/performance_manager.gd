extends Resource
class_name PerformanceManager

signal gpu_clk_limits_updated
signal perf_profile_loaded
signal perf_profile_saved
signal perf_profile_updated
signal smt_updated

const USER_PROFILES := "user://data/performance/profiles"
const POWERTOOLS_PATH : String = "/usr/share/opengamepadui/scripts/powertools"

var launch_manager := load("res://core/global/launch_manager.tres") as LaunchManager
var notification_manager := load("res://core/global/notification_manager.tres") as NotificationManager
var Platform := load("res://core/global/platform.tres")
var settings_manager := load("res://core/global/settings_manager.tres") as SettingsManager
var thread_pool := load("res://core/systems/threading/thread_pool.tres") as ThreadPool

var cpu: Platform.CPUInfo
var gpu: Platform.GPUInfo
var library_item: LibraryLaunchItem
var platform : PlatformProvider 
var profile : PerformanceProfile

var cpu_boost_enabled: bool = false
var cpu_core_count := 1
var cpu_core_count_current := 1
var cpu_cores_available := 1
var cpu_smt_enabled: bool = false
var gpu_freq_max : float
var gpu_freq_max_current : float
var gpu_freq_min: float
var gpu_freq_min_current : float
var gpu_manual_mode: bool = false
var gpu_power_profile: int
var gpu_temp_current: float
var tdp_boost_current: float
var tdp_current: float
var thermal_mode: int

var logger := Log.get_logger("PerformanceManager", Log.LEVEL.INFO)


func _ready():
	platform = Platform.platform
	await update_system_components()
	await load_profile()


## Saves a PerformanceProfile to the given path.
func save_profile() -> void:
	var notify := Notification.new("")
	if not profile:
		profile = PerformanceProfile.new()
		_update_profile()

	# Try to save the profile
	if DirAccess.make_dir_recursive_absolute(USER_PROFILES) != OK:
		logger.debug("Unable to create performance profiles directory")
		notify.text = "Unable to save performance profile"
		notification_manager.show(notify)
		return
	var filename: String =  Platform.get_product_name().replace(" ", "_") + "_default_profile.tres"
	if library_item:
		filename =   Platform.get_product_name().replace(" ", "_") + "_" + library_item.name.sha256_text() + ".tres"

	var path := "/".join([USER_PROFILES, filename])
	if ResourceSaver.save(profile, path) != OK:
		logger.error("Failed to save performance profile to: " + path)
		notify.text = "Failed to save performance profile"
		notification_manager.show(notify)
		return

	# Update the game settings to use this performance profile
	var section := "performance_profile.default_profile"
	if library_item:
		section = "performance_profile.{0}".format([library_item.name.to_lower()])

	settings_manager.set_value(section, "performace_profile", path)
	logger.debug("Saved performance profile to: " + path)
	notify.text = "Performance profile saved"
	notification_manager.show(notify)
	perf_profile_saved.emit()


## Loads a PerformanceProfile from the given path.
func load_profile(profile_path: String = "") -> void:
	var loaded: PerformanceProfile
	# If no path was specified, try to identify it.
	if profile_path == "":
		var path = Platform.get_product_name().replace(" ", "_") + "_default_profile.tres"
		if library_item:
			path = Platform.get_product_name().replace(" ", "_") + "_" + library_item.name.sha256_text() + ".tres"
		profile_path = "/".join([USER_PROFILES, path])
	
	# Check if given profile exists
	logger.debug("Load Profile: " + profile_path)
	if not FileAccess.file_exists(profile_path):
		loaded = PerformanceProfile.new()
		profile = loaded
		if library_item: 
			profile.name = library_item.name.to_lower()
		logger.debug("Created new profile for " + profile.name)
		_update_profile()
		save_profile()
		return

	else:
		loaded = load(profile_path) as PerformanceProfile
	if not loaded:
		logger.warn("Unable to access " + profile_path)
		return

	profile = loaded
	await _apply_profile()
	logger.debug("Loaded Performance Profile: " + profile.name)
	perf_profile_loaded.emit()


func _update_profile() -> void:
	if not profile:
		logger.debug("Profile not set, cannot update.")
		return
	profile.cpu_boost_enabled = cpu_boost_enabled 
	profile.cpu_core_count_current = cpu_core_count_current
	profile.cpu_smt_enabled = cpu_smt_enabled
	profile.gpu_freq_max_current = gpu_freq_max_current
	profile.gpu_freq_min_current = gpu_freq_min_current
	profile.gpu_manual_mode = gpu_manual_mode
	profile.gpu_power_profile = gpu_power_profile
	profile.gpu_temp_current = gpu_temp_current
	profile.tdp_boost_current = tdp_boost_current
	profile.tdp_current = tdp_current
	profile.thermal_mode = thermal_mode
	perf_profile_updated.emit()


func _apply_profile() -> void:
	if cpu.boost_capable:
		logger.debug("Set CPU Boost from profile: " + str(profile.cpu_boost_enabled))
		cpu_boost_enabled= profile.cpu_boost_enabled
		await _apply_cpu_boost_state()
	if cpu.smt_capable:
		logger.debug("Set SMT state from profile: " + str(profile.cpu_smt_enabled))
		cpu_smt_enabled = profile.cpu_smt_enabled
		_apply_cpu_smt_state()
		logger.debug("Set core count from profile: " + str(profile.cpu_core_count_current))
		cpu_core_count_current = profile.cpu_core_count_current
		await _change_cpu_cores()
	if gpu.clk_capable:
		logger.debug("Set gpu mode from profile: " + str(profile.gpu_manual_mode))
		gpu_manual_mode = profile.gpu_manual_mode
		await _gpu_power_profile_change()
		if gpu_manual_mode:
			logger.debug("Set gpu frequency range from profile: " + str(profile.gpu_freq_min_current) + "-" + str(profile.gpu_freq_max_current))
			gpu_freq_max = profile.gpu_freq_max_current
			gpu_freq_min = profile.gpu_freq_min_current
			await _gpu_freq_change()
	if gpu.power_profile_capable:
		logger.debug("Set gpu power profile from profile: " +str(profile.gpu_power_profile))
		gpu_power_profile = profile.gpu_power_profile
		await _gpu_power_profile_change()
	if gpu.tj_temp_capable:
		logger.debug("Set gpu temp target from profile: " +str(profile.gpu_temp_current))
		gpu_temp_current = profile.gpu_temp_current
		await _tdp_boost_value_change()
	if gpu.tdp_capable:
		logger.debug("Set tdp from profile: " + str(profile.tdp_current) + " boost:" + str(profile.tdp_boost_current))
		tdp_boost_current = profile.tdp_boost_current
		tdp_current = profile.tdp_current
		await _tdp_value_change()
	if gpu.thermal_mode_capable:
		logger.debug("Set thermal mode from profile: " +str(profile.thermal_mode))
		thermal_mode = profile.thermal_mode
		await _apply_thermal_mode()


## Looks at system file decriptors to update components and their capabilities
## and current settings. 
func update_system_components(power_profile: int = 1) -> void:
	logger.debug("Update system components started")
	if not cpu:
		cpu = Platform.get_cpu_info()
	if not gpu:
		gpu = Platform.get_gpu_info()

	if gpu.tdp_capable:
		await _update_tdp()

	if gpu.clk_capable:
		await _update_gpu_perf_level()
		await _update_gpu_clk_limits()
		await _enable_performance_write()

	if cpu.smt_capable:
		await _update_smt_enabled()
		await _update_cpu_count() 
		await _update_cpus_enabled()

	if cpu.boost_capable:
		await _update_cpu_boost_enabled()

	if gpu.thermal_mode_capable:
		await _update_thermal_mode()

	# There's currently no known way to detect the set profile. Default to
	# power_saving for now. #TODO: Fix this.
	if gpu.power_profile_capable:
		await set_gpu_power_profile(power_profile)
#		await _update_gpu_power_profile()
	logger.debug("Update system components completed")


func set_cpu_core_count(value: int) -> void:
	if cpu_core_count_current == value:
		return
	cpu_core_count_current = value
	await _change_cpu_cores()
	_update_profile()


## Called to toggle cpu boost
func set_cpu_boost_enabled(state: bool) -> void:
	if cpu_boost_enabled == state:
		return
	cpu_boost_enabled = state
	_apply_cpu_boost_state()
	_update_profile()


## Called to enable/disable CPU SMT.
func set_cpu_smt_enabled(state: bool) -> void:
	if cpu_smt_enabled == state:
		return
	cpu_smt_enabled = state
	_apply_cpu_smt_state()
	await _update_cpu_count()
	await _update_cpus_enabled()
	_update_profile()
	smt_updated.emit()

## Called when gpu_freq_max_slider.value is changed.
func set_gpu_freq_max(value: float) -> void:
	if gpu_freq_max_current == value:
		return
	gpu_freq_max_current = value
	if value < gpu_freq_min_current:
		gpu_freq_min_current = value
	await _gpu_freq_change()
	_update_profile()


## Called to set the minimum gpu clock is changed.
func set_gpu_freq_min(value: float) -> void:
	if gpu_freq_min_current == value:
		return
	gpu_freq_min_current = value
	if value > gpu_freq_max_current:
		gpu_freq_max_current = value
	await _gpu_freq_change()
	_update_profile()


## Called to toggle auto/manual gpu clocking
func set_gpu_manual_mode_enabled(state: bool) -> void:
	if gpu_manual_mode == state:
		return
	gpu_manual_mode = state
	if gpu.vendor == "AMD":
		var args := ["pdfpl", "auto"]
		if gpu_manual_mode:
			args = ["pdfpl", "manual"]
		var output: Array = _do_exec(POWERTOOLS_PATH, args)
		var exit_code = output[1]
		if exit_code:
			logger.warn("_on_toggle_gpu_freq exit code: " + str(exit_code))

	if gpu_manual_mode:
		await _update_gpu_clk_limits()
	_update_profile()


func set_gpu_power_profile(mode: int) -> void:
	if gpu_power_profile == mode:
		return
	gpu_power_profile = mode
	await _gpu_power_profile_change()
	_update_profile()


func set_gpu_temp_current(value: float) -> void:
	if gpu_temp_current == value:
		return
	gpu_temp_current = value
	await _gpu_temp_limit_change()
	_update_profile()


## Called to set the TFP boost limit.
func set_tdp_boost_value(value: float) -> void:
	if tdp_boost_current == value:
		return
	tdp_boost_current = value
	await _tdp_boost_value_change()
	_update_profile()


## Called to set the TDP average limit.
func set_tdp_value(value: float) -> void:
	if tdp_current == value:
		return
	tdp_current = value
	await _tdp_value_change()
	_update_profile()


## Sets the thermal throttle mode for ASUS devices.
func set_thermal_mode(index: int) -> void:
	if thermal_mode == index:
		return
	thermal_mode = index
	await _apply_thermal_mode()
	_update_profile()


func on_app_switched(_from: RunningApp, to: RunningApp) -> void:
	logger.debug("Detected app switch")
	library_item = null
	if to:
		library_item = to.launch_item
	load_profile()


func _apply_cpu_boost_state() -> void:
	var args := ["cpuBoost", "0"]
	if cpu_boost_enabled:
		args = ["cpuBoost", "1"]
	_do_exec(POWERTOOLS_PATH, args)


func _apply_thermal_mode() -> void:
	match thermal_mode:
			"0":
				logger.debug("Setting thermal throttle policy to Balanced")
			"1":
				logger.debug("Setting thermal throttle policy to Performance")
			"2":
				logger.debug("Setting thermal throttle policy to Silent")
	var args := ["setThermalPolicy", str(thermal_mode)]
	await _async_do_exec(platform.thermal_policy_path, args)
	_update_profile()


func _apply_cpu_smt_state() -> void:
	var args := []
	if cpu_smt_enabled:
		args = ["smtToggle", "on"]
	else:
		args = ["smtToggle", "off"]
	var output: Array = _do_exec(POWERTOOLS_PATH, args)
	var exit_code = output[1]
	if exit_code:
		logger.warn("_on_toggle_smt exit code: " + str(exit_code))


## Set STAPM on AMD APU's
func _amd_tdp_change() -> void:
	logger.debug("Doing callback func _do_amd_tdp_change")
	await _async_do_exec(POWERTOOLS_PATH, ["ryzenadj", "-a", str(tdp_current * 1000)])


## Set long/short PPT on AMD APU's
func _amd_tdp_boost_change() -> void:
	logger.debug("Doing callback func _do_amd_tdp_boost_change")
	
	var slowPPT: float = (floor(tdp_boost_current/2) + tdp_current) * 1000
	var fastPPT: float = (tdp_boost_current + tdp_current) * 1000
	await _async_do_exec(POWERTOOLS_PATH, ["ryzenadj", "-b", str(fastPPT)])
	await _async_do_exec(POWERTOOLS_PATH, ["ryzenadj", "-c", str(slowPPT)])


# Called to disable/enable cores by count as specified by value. 
func _change_cpu_cores():
	var args := []
	for cpu_no in range(1, cpu_core_count):
		args = ["cpuToggle", str(cpu_no), "1"]
		if cpu_smt_enabled and cpu_no >= cpu_core_count_current:
			args[2] = "0"
		elif not cpu_smt_enabled:
			if cpu_no % 2 != 0 or cpu_no >= (cpu_core_count_current * 2) - 1:
				args[2] = "0"
		logger.debug("Set CPU No: " + str(args[1]) + " to " + args[2])
		_do_exec(POWERTOOLS_PATH, args)


## Called to set write permissions to power_dpm_force_performace_level
func _enable_performance_write() -> void:
	match gpu.vendor:
		"AMD":
			await _async_do_exec(POWERTOOLS_PATH, ["pdfpl", "write"])
		"Intel":
			pass


## Ensures the current boost doesn't exceed the max boost.
func _ensure_tdp_boost_limited()  -> void:
	if tdp_boost_current > gpu.max_boost:
		tdp_boost_current = gpu.max_boost
	if tdp_boost_current < 0:
		tdp_boost_current = 0


## Set the GPU min/max freq.
func _gpu_freq_change() -> void:
	var cmd := ""
	match gpu.vendor:
		"AMD":
			cmd = "amdGpuClock"
		"Intel":
			cmd = "intelGpuClock"
	await _async_do_exec(POWERTOOLS_PATH, [cmd, str(gpu_freq_min_current), str(gpu_freq_max_current)])

# TODO: Support more than AMD APU's
## Sets the ryzenadj power profile
func _gpu_power_profile_change() -> void:
	var power_profile := "--max-performance"
	if gpu_power_profile == 1:
		power_profile = "--power-saving"
	match gpu.vendor:
		"AMD":
			await _async_do_exec(POWERTOOLS_PATH, ["ryzenadj", power_profile])
		"Intel":
			pass


# TODO: Support more than AMD APU's
## Sets the T-junction temp.
func _gpu_temp_limit_change() -> void:
	match gpu.vendor:
		"AMD":
			await _async_do_exec(POWERTOOLS_PATH, ["ryzenadj", "-f", str(gpu_temp_current)])
		"Intel":
			pass


# Set short/peak TDP on Intel iGPU's
func _intel_tdp_boost_change() -> void:
	logger.debug("Doing callback func _do_intel_tdp_boost_change")
	var shortTDP: float = (floor(tdp_boost_current/2) + tdp_current) * 1000000
	var peakTDP: float = (tdp_boost_current + tdp_current) * 1000000
	var results := await _async_do_exec(POWERTOOLS_PATH, ["set_rapl", "constraint_1_power_limit_uw", str(shortTDP)])
	for result in results:
		logger.debug("Result: " +str(result))
	results = await _async_do_exec(POWERTOOLS_PATH, ["set_rapl", "constraint_2_power_limit_uw", str(peakTDP)])
	for result in results:
		logger.debug("Result: " +str(result))


# Set long TDP on Intel iGPU's
func _intel_tdp_change() -> void:
	logger.debug("Doing callback func _do_intel_tdp_change")
	var results := await _async_do_exec(POWERTOOLS_PATH, ["setRapl", "constraint_0_power_limit_uw", str(tdp_current * 1000000)])
	for result in results:
		logger.debug("Result: " +str(result))


# Sets the current TDP to the midpoint of the detected hardware. Used when we're not able to
# Determine the current settings.
func _set_tdp_midpoint() -> void:
	tdp_current = float((gpu.max_tdp - gpu.min_tdp) / 2 + gpu.min_tdp)
	await _amd_tdp_change()
	await _amd_tdp_boost_change()
	await _gpu_temp_limit_change()


## Called to set the base average TDP
func _tdp_boost_value_change() -> void:
	match gpu.vendor:
		"AMD":
			await _amd_tdp_boost_change()
		"Intel":
			await _intel_tdp_boost_change()
			
		
## Called to set the base average TDP
func _tdp_value_change() -> void:
	match gpu.vendor:
		"AMD":
			await _amd_tdp_change()
		"Intel":
			await _intel_tdp_change()
	await _tdp_boost_value_change()


## Reads the pp_od_clk_voltage from sysfs and returns the values. This file will 
## be empty if not in "manual" for pp_od_performance_level.
func _update_amd_gpu_clock_limits() -> void:
	var args := ["/sys/class/drm/card0/device/pp_od_clk_voltage"]
	var output: Array = _do_exec("cat", args)
	var result := output[0][0].split("\n") as Array

	for param in result:
		var parts := param.split("\n") as Array
		for part in parts:
			part = part.strip_edges().split(" ", false)
			if part.is_empty():
				continue
			if part[0] == "SCLK:":
				gpu_freq_max = int(part[2].rstrip("Mhz"))
				gpu_freq_min = int(part[1].rstrip("Mhz"))
			elif part[0] == "0:":
				gpu_freq_min_current =  int(part[1].rstrip("Mhz"))
			elif part[0] == "1:":
				gpu_freq_max_current =  int(part[1].rstrip("Mhz"))
	logger.debug("Found GPU CLK Limits: " + str(gpu_freq_min) + " - " + str(gpu_freq_max))


func _update_amd_gpu_perf_level() -> void:
	var performance_level = _read_sys("/sys/class/drm/card0/device/power_dpm_force_performance_level")
	if performance_level == "manual":
		gpu_manual_mode = true
	else:
		gpu_manual_mode = false


# TODO: Find a way to detect this.
func _update_amd_gpu_power_profile() -> void:
	pass


## Retrieves the current TDP from ryzenadj for AMD APU's.
func _update_amd_tdp() -> void:
	var output: Array = _do_exec(POWERTOOLS_PATH, ["ryzenadj", "-i"])
	var exit_code = output[1]
	if exit_code:
		logger.info("Got exit code: " +str(exit_code) +". Unable to verify current tdp. Setting TDP to midpoint of range")
		await _set_tdp_midpoint()
		return
	var result := output[0][0].split("\n") as Array
	var current_fastppt := 0.0
	for setting in result:
		var parts := setting.split("|") as Array
		var i := 0
		for part in parts:
			parts[i] = part.strip_edges()
			i+=1
		if len(parts) < 3:
			continue
		match parts[1]:
			"PPT LIMIT FAST":
				current_fastppt = float(parts[2])
			"STAPM LIMIT":
				tdp_current = float(parts[2])
			"THM LIMIT CORE":
				gpu_temp_current = float(parts[2])
	tdp_boost_current = current_fastppt - tdp_current
	await _ensure_tdp_boost_limited()
	await _tdp_boost_value_change()


func _update_cpu_boost_enabled() -> bool:
	if FileAccess.file_exists("/sys/devices/system/cpu/cpufreq/boost"):
		var boost_set :=  await _read_sys("/sys/devices/system/cpu/cpufreq/boost")
		logger.debug("cpu boost is set to" + boost_set)
		if boost_set == "1":
			cpu_boost_enabled = true
	else:
		cpu.boost_capable = false
	return cpu_boost_enabled


## Loops through all cores and returns the count of enabled cores.
func _update_cpus_enabled() -> void:
	var active_cpus := 1
	for i in range(1, cpu_core_count):
		var args = ["-c", "cat /sys/bus/cpu/devices/cpu"+str(i)+"/online"]
		var output: Array = _do_exec("bash", args)
		logger.debug("Add to count: " + str(output[0][0].strip_edges()))
		active_cpus += int(output[0][0].strip_edges())
		logger.debug("Detected Active CPU's: " + str(active_cpus))
	cpu_core_count_current = active_cpus
	logger.debug("Total Active CPU's: " + str(cpu_core_count_current))

## Updates the total number of cores
func _update_cpu_count() -> void:
	var args = ["-c", "ls /sys/bus/cpu/devices/ | wc -l"]
	var output: Array = _do_exec("bash", args)
	var exit_code = output[1]
	if exit_code:
		logger.warn("Unable to update CPU count. Received exit code: " +str(exit_code))
		return
	cpu_core_count = output[0][0].split("\n")[0] as int
	cpu_cores_available = cpu_core_count
	if not cpu_smt_enabled:
		cpu_cores_available = cpu_core_count / 2

	logger.debug("Total CPU's: " + str(cpu_core_count) + " Available CPU's: " + str(cpu_cores_available))

## Reads the current and absolute min/max gpu clocks.
func _update_gpu_clk_limits() -> void:
	match gpu.vendor:
		"AMD":
			await _update_amd_gpu_clock_limits()
		"Intel":
			await _update_intel_gpu_clock_limits()
	gpu_clk_limits_updated.emit()

## Called to read the current performance level and set the UI as needed.
func _update_gpu_perf_level() -> void:
	match gpu.vendor:
		"AMD":
			await _update_amd_gpu_perf_level()
		_:
			pass


func _update_gpu_power_profile() -> void:
	match gpu.vendor:
		"AMD":
			await _update_amd_gpu_power_profile()
		_:
			pass

## Reads the following sysfs paths to update the current and mix/max gpu frequencies.
func _update_intel_gpu_clock_limits() -> void:
	gpu_freq_max = float(await _read_sys("/sys/class/drm/card0/gt_RP0_freq_mhz"))
	gpu_freq_max_current = float(await _read_sys("/sys/class/drm/card0/gt_max_freq_mhz"))
	gpu_freq_min = float(await _read_sys("/sys/class/drm/card0/gt_RPn_freq_mhz"))
	gpu_freq_min_current = float(await _read_sys("/sys/class/drm/card0/gt_min_freq_mhz"))
	logger.debug("Found GPU CLK Limits: " + str(gpu_freq_min) + " - " + str(gpu_freq_max))


## Retrieves the current TDP from sysfs for Intel iGPU's.
func _update_intel_tdp() -> void:
	var long_tdp: float = float(await _read_sys("/sys/class/powercap/intel-rapl/intel-rapl:0/constraint_0_power_limit_uw"))
	if not long_tdp:
		logger.warn("Unable to determine long TDP.")
		return

	tdp_current = long_tdp / 1000000
	var peak_tdp: float = float(await _read_sys("/sys/class/powercap/intel-rapl/intel-rapl:0/constraint_2_power_limit_uw"))
	if not peak_tdp:
		logger.warn("Unable to determine long TDP.")
		return
	tdp_boost_current = peak_tdp / 1000000 - tdp_current
	await _ensure_tdp_boost_limited()
	await _tdp_boost_value_change()


func _update_smt_enabled() -> void:
	if FileAccess.file_exists("/sys/devices/system/cpu/smt/control"):
		var smt_set := await _read_sys("/sys/devices/system/cpu/smt/control")
		logger.debug("SMT is set to" + smt_set)
		if smt_set == "on":
			cpu_smt_enabled = true


## Retrieves the current TDP.
func _update_tdp() -> void:
	match gpu.vendor:
		"AMD":
			await _update_amd_tdp()
		"Intel":
			await _update_intel_tdp()


## Retrieves the current thermal mode.
func _update_thermal_mode() -> int:
	thermal_mode = int(await _read_sys(platform.thermal_policy_path))
	match thermal_mode:
		0:
			logger.debug("Thermal throttle policy currently at Balanced")
		1:
			logger.debug("Thermal throttle policy currently at Performance")
		2:
			logger.debug("Thermal throttle policy currently at Silent")
	return thermal_mode


# Used to read values from sysfs
func _read_sys(path: String) -> String:
	var output: Array = _do_exec("cat", [path])
	return output[0][0].strip_escapes()


# Thread safe method of calling _do_exec
func _async_do_exec(command: String, args: Array)-> Array:
	logger.debug("Start async_do_exec : " + command)
	for arg in args:
		logger.debug(str(arg))
	return await thread_pool.exec(_do_exec.bind(command, args))


## Calls OS.execute with the provided command and args and returns an array with
## the results and exit code to catch errors.
func _do_exec(command: String, args: Array)-> Array:
	logger.debug("Start _do_exec with command : " + command)
	for arg in args:
		logger.debug(str(arg))
	var output = []
	var exit_code := OS.execute(command, args, output)
	logger.debug("Output: " + str(output))
	logger.debug("Exit code: " +str(exit_code))
	return [output, exit_code]