extends Resource
class_name PerformanceManager

signal cpu_boost_toggled(state: bool)
signal cpu_cores_available_updated(available: int)
signal cpu_cores_used(count: int)
signal gpu_clk_current_updated(current_min: float, current_max: float)
signal gpu_clk_limits_updated(min: float, max: float)
signal gpu_manual_enabled_updated(state: bool)
signal gpu_power_profile_updated(index: int)
signal gpu_temp_limit_updated(current: float)
signal smt_toggled(state: bool)
signal tdp_updated(tdp_current: float, boost_current: float)
signal thermal_profile_updated(index: int)
signal perfomance_profile_applied(profile: PerformanceProfile)
signal pm_ready

const USER_PROFILES := "user://data/performance/profiles"
const POWERTOOLS_PATH := "/usr/share/opengamepadui/scripts/powertools"
const FALLBACK_GPU_TEMP: float = 80
var _notification_manager := load("res://core/global/notification_manager.tres") as NotificationManager
var _platform := load("res://core/global/platform.tres") as Platform
var _power_manager := load("res://core/systems/power/power_manager.tres") as PowerManager
var _settings_manager := load("res://core/global/settings_manager.tres") as SettingsManager
var _shared_thread := load("res://core/systems/threading/utility_thread.tres") as SharedThread

var ryzenadj := RyzenAdj.new()
var batteries: Array[PowerManager.Device]
var cpu: Platform.CPUInfo
var gpu: Platform.GPUInfo
var library_item: LibraryLaunchItem
var platform_provider: PlatformProvider
var profile: PerformanceProfile
var profile_state: String # docked or undocked
var initialized: bool = false
var logger := Log.get_logger("PerformanceManager", Log.LEVEL.INFO)


func _init():
	_shared_thread.start()
	profile = PerformanceProfile.new()
	if not _platform.loaded:
		_platform.platform_loaded.connect(_setup, CONNECT_ONE_SHOT)
		return
	_setup()


func _setup():
	platform_provider = _platform.platform
	batteries = _power_manager.get_devices_by_type(PowerManager.DEVICE_TYPE.BATTERY)
	if batteries.size() > 1:
		logger.warn("You somehow have more than one battery. We don't know what to do with that.")
	if batteries.size() > 0:
		var battery := batteries[0]
		_update_profile_state(battery)
		battery.updated.connect(_on_update_battery.bind(battery))

	_shared_thread.exec(read_system_components)


func _on_update_battery(item: PowerManager.Device):
	_update_profile_state(item)
	load_profile()


func _update_profile_state(item: PowerManager.Device) -> void:
	var to_state: String = "docked"
	if item.state not in [PowerManager.DEVICE_STATE.CHARGING, PowerManager.DEVICE_STATE.FULLY_CHARGED, PowerManager.DEVICE_STATE.PENDING_CHARGE]:
		to_state = "undocked"

	if profile_state != to_state:
		logger.debug("Setting system to " + to_state)
		profile_state = to_state


## Looks at system file decriptors to update components and their capabilities
## and current settings. 
func read_system_components(power_profile: int = 1) -> void:
	logger.debug("Update system components started")
	if not cpu:
		cpu = _platform.get_cpu_info()
	if not gpu:
		gpu = _platform.get_gpu_info()
	logger.debug("CPU Data: " + str(cpu))
	logger.debug("GPU Data: " + str(gpu))

	if gpu.tdp_capable:
		await _read_tdp()

	if gpu.clk_capable:
		await _enable_performance_write()
		await _read_gpu_perf_level()
		if profile.gpu_manual_enabled:
			await _read_gpu_clk_limits()
			await _read_gpu_clk_current()

	if cpu.smt_capable:
		await _read_smt_enabled()
		await _read_cpu_count()
		await _read_cpus_enabled()

	if cpu.boost_capable:
		await _read_cpu_boost_enabled()

	if gpu.thermal_profile_capable:
		await _read_thermal_profile()

	# There's currently no known way to detect the set profile. Default to
	# setting power_saving at startup for now. #TODO: Fix this?
	if gpu.power_profile_capable:
		profile.gpu_power_profile = power_profile
		await _gpu_power_profile_change()
	logger.debug("Update system components completed")
	logger.debug(profile)
	initialized = true
	pm_ready.emit()

### Manage PerformanceProfile funcs

func _get_profile_name() -> String:
	var prefix: String = _platform.get_product_name().replace(" ", "_") + "_" + profile_state
	var postfix: String = "_default_profile.tres"
	if library_item:
		postfix = "_" + library_item.name.sha256_text() + ".tres"
		profile.name = library_item.name
	return prefix+postfix


## Saves a PerformanceProfile to the given path.
func save_profile() -> void:
	var notify := Notification.new("")

	# Try to save the profile
	if DirAccess.make_dir_recursive_absolute(USER_PROFILES) != OK:
		logger.debug("Unable to create performance profiles directory")
		notify.text = "Unable to save performance profile"
		_notification_manager.show(notify)
		return
	var profile_path := "/".join([USER_PROFILES, _get_profile_name()])
	if ResourceSaver.save(profile, profile_path) != OK:
		logger.error("Failed to save performance profile to: " + profile_path)
		notify.text = "Failed to save performance profile"
		_notification_manager.show(notify)
		return

	# Update the game settings to use this performance profile
	var section := "game.default_profile"
	if library_item:
		section = "game.{0}".format([library_item.name.to_lower()])

	_settings_manager.set_value(section, "performace_profile", profile_path)
	logger.info("Saved performance profile to: " + profile_path)


## Loads a PerformanceProfile from the given path.
func load_profile(profile_path: String = "") -> void:
	if not initialized:
		logger.warn("Attempt to load profile before PerformanceManager was fully initialized.")
		return
	var notify := Notification.new("")
	var loaded: PerformanceProfile
	# If no path was specified, try to identify it.
	if profile_path == "":
		profile_path = "/".join([USER_PROFILES, _get_profile_name()])

	# Check if given profile exists
	logger.debug("Load Profile: " + profile_path)
	if not FileAccess.file_exists(profile_path):
		if library_item: 
			profile.name = library_item.name
		notify.text = "Created new performance profile for " + profile_state + " " + profile.name 
		logger.debug(notify.text)
		_notification_manager.show(notify)
		save_profile()
		_shared_thread.exec(_apply_profile)
		return

	else:
		loaded = load(profile_path) as PerformanceProfile
	if not loaded:
		notify.text = "Unable to load profile at: " + profile_path
		logger.warn(notify.text)
		_notification_manager.show(notify)
		return

	if profile == loaded:
		logger.debug("Loaded profile is current profile. Nothing to do.")
		return

	profile = loaded
	notify.text = "Loaded performance profile: " + profile_state + " " + profile.name 
	logger.info(notify.text)
	logger.debug(profile)
	_notification_manager.show(notify)
	_shared_thread.exec(_apply_profile)


func emit_profile_signals() -> void:
	cpu_boost_toggled.emit(profile.cpu_boost_enabled)
	cpu_cores_available_updated.emit(cpu.cores_available)
	cpu_cores_used.emit(profile.cpu_core_count_current)
	gpu_clk_limits_updated.emit(gpu.freq_min, gpu.freq_max)
	gpu_clk_current_updated.emit(profile.gpu_freq_min_current, profile.gpu_freq_max_current)
	gpu_manual_enabled_updated.emit(profile.gpu_manual_enabled)
	gpu_power_profile_updated.emit(profile.gpu_power_profile)
	gpu_temp_limit_updated.emit(profile.gpu_temp_current)
	smt_toggled.emit(profile.cpu_smt_enabled)
	tdp_updated.emit(profile.tdp_current, profile.tdp_boost_current)
	thermal_profile_updated.emit(profile.thermal_profile)


func _apply_profile() -> void:
	if cpu.boost_capable:
		logger.debug("Set CPU Boost from profile: " + str(profile.cpu_boost_enabled))
		await _apply_cpu_boost_state()
	if cpu.smt_capable:
		logger.debug("Set SMT state from profile: " + str(profile.cpu_smt_enabled))
		await _apply_cpu_smt_state()
		logger.debug("Set core count from profile: " + str(profile.cpu_core_count_current))
		await _change_cpu_cores()
	if gpu.clk_capable:
		logger.debug("Set gpu mode from profile: " + str(profile.gpu_manual_enabled))
		await _gpu_manual_change()
		if profile.gpu_manual_enabled:
			if not gpu.freq_min or gpu.freq_max:
				await _read_gpu_clk_limits()
			logger.debug("Set gpu frequency range from profile: " + str(profile.gpu_freq_min_current) + "-" + str(profile.gpu_freq_max_current))
			await _gpu_freq_change()
	if gpu.power_profile_capable:
		logger.debug("Set gpu power profile from profile: " +str(profile.gpu_power_profile))
		await _gpu_power_profile_change()
	if gpu.tj_temp_capable:
		logger.debug("Set gpu temp target from profile: " +str(profile.gpu_temp_current))
		await _gpu_temp_limit_change()
	if gpu.tdp_capable:
		logger.debug("Set tdp from profile: " + str(profile.tdp_current) + " boost:" + str(profile.tdp_boost_current))
		await _tdp_value_change()
	if gpu.thermal_profile_capable:
		logger.debug("Set thermal mode from profile: " +str(profile.thermal_profile))
		await _apply_thermal_profile()
	logger.info("Applied Performance Profile: " + profile_state + " " + profile.name)
	perfomance_profile_applied.emit(profile)


func on_app_switched(_from: RunningApp, to: RunningApp) -> void:
	logger.debug("Detected app switch")
	library_item = null
	if to:
		library_item = to.launch_item
	load_profile()


### Adjust sysfs and update profile funcs

## Called to set the number of enabled CPU's
func set_cpu_core_count(value: int) -> void:
	if profile.cpu_core_count_current == value:
		return
	profile.cpu_core_count_current = value
	await _change_cpu_cores()
	save_profile()


## Called to toggle cpu boost
func set_cpu_boost_enabled(state: bool) -> void:
	if profile.cpu_boost_enabled == state:
		return
	profile.cpu_boost_enabled = state
	await _apply_cpu_boost_state()
	save_profile()


## Called to enable/disable CPU SMT.
func set_cpu_smt_enabled(state: bool) -> void:
	if profile.cpu_smt_enabled == state:
		return
	profile.cpu_smt_enabled = state
	await _apply_cpu_smt_state()
	save_profile()


## Called when gpu_freq_max_slider.value is changed.
func set_gpu_freq_max(value: float) -> void:
	if profile.gpu_freq_max_current == value:
		return
	profile.gpu_freq_max_current = value
	if value < profile.gpu_freq_min_current:
		profile.gpu_freq_min_current = value
	await _gpu_freq_change()
	save_profile()


## Called to set the minimum gpu clock is changed.
func set_gpu_freq_min(value: float) -> void:
	if profile.gpu_freq_min_current == value:
		return
	profile.gpu_freq_min_current = value
	if value > profile.gpu_freq_max_current:
		profile.gpu_freq_max_current = value
	await _gpu_freq_change()
	save_profile()


## Called to toggle auto/manual gpu clocking
func set_gpu_manual_enabled(state: bool) -> void:
	if profile.gpu_manual_enabled == state:
		return
	profile.gpu_manual_enabled = state
	await _gpu_manual_change()

	if profile.gpu_manual_enabled:
		if not gpu.freq_max or not gpu.freq_min:
			await _read_gpu_clk_limits()
		await _read_gpu_clk_current()
	save_profile()


## Called to set the GPU Power Profile
func set_gpu_power_profile(mode: int) -> void:
	if profile.gpu_power_profile == mode:
		return
	profile.gpu_power_profile = mode
	await _gpu_power_profile_change()
	save_profile()


## Called to set the GPU Thermal Throttle Limit
func set_gpu_temp_current(value: float) -> void:
	if profile.gpu_temp_current == value:
		return
	profile.gpu_temp_current = value
	await _gpu_temp_limit_change()
	save_profile()


## Called to set the TFP boost limit.
func set_tdp_boost_value(value: float) -> void:
	if profile.tdp_boost_current == value:
		return
	profile.tdp_boost_current = value
	await _tdp_boost_value_change()
	save_profile()


## Called to set the TDP average limit.
func set_tdp_value(value: float) -> void:
	if profile.tdp_current == value:
		return
	profile.tdp_current = value
	await _tdp_value_change()
	save_profile()


## Sets the thermal throttle mode for ASUS devices.
func set_thermal_profile(index: int) -> void:
	if profile.thermal_profile == index:
		return
	profile.thermal_profile = index
	await _apply_thermal_profile()
	save_profile()


### Adjust sysfs funcs
func _apply_cpu_boost_state() -> void:
	var args := ["cpuBoost", "0"]
	if profile.cpu_boost_enabled:
		args = ["cpuBoost", "1"]
	await _async_do_exec(POWERTOOLS_PATH, args)
	cpu_boost_toggled.emit(profile.cpu_boost_enabled)


func _apply_thermal_profile() -> void:
	if not platform_provider is HandheldPlatform:
		logger.warn("Attempt to apply thermoal profile on platform that is not HandheldPlatform.")
		return
	match profile.thermal_profile:
			"0":
				logger.debug("Setting thermal throttle policy to Balanced")
			"1":
				logger.debug("Setting thermal throttle policy to Performance")
			"2":
				logger.debug("Setting thermal throttle policy to Silent")
	var args := ["setThermalPolicy", str(profile.thermal_profile)]
	await _async_do_exec((platform_provider as HandheldPlatform).thermal_policy_path, args)
	thermal_profile_updated.emit(profile.thermal_profile)


func _apply_cpu_smt_state() -> void:
	var args := []
	if profile.cpu_smt_enabled:
		args = ["smtToggle", "on"]
	else:
		args = ["smtToggle", "off"]
	var output: Array = await _async_do_exec(POWERTOOLS_PATH, args)
	var exit_code = output[1]
	if exit_code:
		logger.warn("_on_toggle_smt exit code: " + str(exit_code))
		return
	smt_toggled.emit(profile.cpu_smt_enabled)
	await _read_cpu_count()
	await _read_cpus_enabled()


## Set STAPM on AMD APU's
func _amd_tdp_change() -> void:
	logger.debug("Doing callback func _do_amd_tdp_change")
	await ryzenadj.set_stapm_limit(profile.tdp_current * 1000)


## Set long/short PPT on AMD APU's
func _amd_tdp_boost_change() -> void:
	logger.debug("Doing callback func _do_amd_tdp_boost_change")
	
	var slowPPT: float = (floor(profile.tdp_boost_current/2) + profile.tdp_current) * 1000
	var fastPPT: float = (profile.tdp_boost_current + profile.tdp_current) * 1000
	await ryzenadj.set_fast_limit(fastPPT)
	await ryzenadj.set_slow_limit(slowPPT)


# Called to disable/enable cores by count as specified by value. 
func _change_cpu_cores():
	logger.debug("Enable cpu_cores: " +str(profile.cpu_core_count_current) + "/" + str(cpu.core_count))
	var args := []
	for cpu_no in range(1, cpu.core_count):
		args = ["cpuToggle", str(cpu_no), "1"]
		if profile.cpu_smt_enabled and cpu_no >= profile.cpu_core_count_current:
			args[2] = "0"
		elif not profile.cpu_smt_enabled:
			if cpu_no % 2 != 0 or cpu_no >= (profile.cpu_core_count_current * 2) - 1:
				args[2] = "0"
		logger.debug("Set CPU No: " + str(args[1]) + " to " + args[2])
		await _async_do_exec(POWERTOOLS_PATH, args)
	cpu_cores_used.emit(profile.cpu_core_count_current)


## Called to set write permissions to power_dpm_force_performace_level
func _enable_performance_write() -> void:
	match gpu.vendor:
		"AMD":
			await _async_do_exec(POWERTOOLS_PATH, ["pdfpl", "write", gpu.card.name])
		"Intel":
			pass


## Ensures the current boost doesn't exceed the max boost.
func _ensure_tdp_boost_limited()  -> void:
	if profile.tdp_boost_current > gpu.max_boost:
		profile.tdp_boost_current = gpu.max_boost
	if profile.tdp_boost_current < 0:
		profile.tdp_boost_current = 0


## Set the GPU min/max freq.
func _gpu_freq_change() -> void:
	var cmd := ""
	match gpu.vendor:
		"AMD":
			cmd = "amdGpuClock"
		"Intel":
			cmd = "intelGpuClock"
	await _async_do_exec(POWERTOOLS_PATH, [cmd, str(profile.gpu_freq_min_current), str(profile.gpu_freq_max_current), gpu.card.name])
	gpu_clk_current_updated.emit(profile.gpu_freq_min_current, profile.gpu_freq_max_current)


func _gpu_manual_change() -> void:
	if gpu.vendor == "AMD":
		var args := ["pdfpl", "auto", gpu.card.name]
		if profile.gpu_manual_enabled:
			args = ["pdfpl", "manual", gpu.card.name]
		var output: Array = await _async_do_exec(POWERTOOLS_PATH, args)
		var exit_code = output[1]
		if exit_code:
			logger.warn("_on_toggle_gpu_freq exit code: " + str(exit_code))

		gpu_manual_enabled_updated.emit(profile.gpu_manual_enabled)

	if gpu.vendor == "Intel":
		gpu_manual_enabled_updated.emit(profile.gpu_manual_enabled)


# TODO: Support more than AMD APU's
## Sets the ryzenadj power profile
func _gpu_power_profile_change() -> void:
	var power_profile := ryzenadj.POWER_PROFILE.MAX_PERFORMANCE
	if profile.gpu_power_profile == 1:
		power_profile = ryzenadj.POWER_PROFILE.POWER_SAVINGS
	match gpu.vendor:
		"AMD":
			await ryzenadj.set_power_profile(power_profile)
		"Intel":
			pass
	gpu_power_profile_updated.emit(profile.gpu_power_profile)


# TODO: Support more than AMD APU's
## Sets the T-junction temp.
func _gpu_temp_limit_change() -> void:
	match gpu.vendor:
		"AMD":
			await ryzenadj.set_tctl_temp(profile.gpu_temp_current)
		"Intel":
			pass
	gpu_temp_limit_updated.emit(profile.gpu_temp_current)


# Set short/peak TDP on Intel iGPU's
func _intel_tdp_boost_change() -> void:
	logger.debug("Doing callback func _do_intel_tdp_boost_change")
	var shortTDP: float = (floor(profile.tdp_boost_current/2) + profile.tdp_current) * 1000000
	var peakTDP: float = (profile.tdp_boost_current + profile.tdp_current) * 1000000
	var results := await _async_do_exec(POWERTOOLS_PATH, ["setRapl", "constraint_1_power_limit_uw", str(shortTDP)])
	for result in results:
		logger.debug("Result: " +str(result))
	results = await _async_do_exec(POWERTOOLS_PATH, ["setRapl", "constraint_2_power_limit_uw", str(peakTDP)])
	for result in results:
		logger.debug("Result: " +str(result))


# Set long TDP on Intel iGPU's
func _intel_tdp_change() -> void:
	logger.debug("Doing callback func _do_intel_tdp_change")
	var results := await _async_do_exec(POWERTOOLS_PATH, ["setRapl", "constraint_0_power_limit_uw", str(profile.tdp_current * 1000000)])
	for result in results:
		logger.debug("Result: " +str(result))


## Called to set the base average TDP
func _tdp_boost_value_change(emit_change: bool = true) -> void:
	match gpu.vendor:
		"AMD":
			await _amd_tdp_boost_change()
		"Intel":
			await _intel_tdp_boost_change()
	if emit_change:
		tdp_updated.emit(profile.tdp_current, profile.tdp_boost_current)



## Called to set the base average TDP
func _tdp_value_change() -> void:
	match gpu.vendor:
		"AMD":
			await _amd_tdp_change()
		"Intel":
			await _intel_tdp_change()
	await _tdp_boost_value_change(false)
	tdp_updated.emit(profile.tdp_current, profile.tdp_boost_current)


# Sets the current TDP to the midpoint of the detected hardware. Used when we're not able to
# Determine the current settings.
func _set_sane_defaults() -> void:
	if not profile.tdp_current:
		profile.tdp_current = float((gpu.tdp_max - gpu.tdp_min) / 2 + gpu.tdp_min)
	if not profile.tdp_boost_current:
		profile.tdp_boost_current = 0
	if not profile.gpu_temp_current:
		profile.gpu_temp_current = FALLBACK_GPU_TEMP
	await _tdp_value_change()
	await _gpu_temp_limit_change()


### Read from sysfs funcs

## Reads the pp_od_clk_voltage from sysfs and returns the OD_RANGE values. This file will 
## be empty if not in "manual" for pp_od_performance_level.
func _read_amd_gpu_clock_limits() -> void:
	var args := ["/sys/class/drm/" + gpu.card.name + "/device/pp_od_clk_voltage"]
	var output: Array = await _async_do_exec("cat", args)
	@warning_ignore("unsafe_method_access")
	var result := (output[0][0] as String).split("\n")
	logger.debug(result)
	for param in result:
		var parts := param.split("\n")
		for part in parts:
			var fixed_part := part.strip_edges().split(" ", false)
			if fixed_part.is_empty() or fixed_part in ["0:", "1:"]:
				continue
			if fixed_part[0] == "SCLK:":
				gpu.freq_min = int(fixed_part[1].rstrip("Mhz"))
				gpu.freq_max = int(fixed_part[2].rstrip("Mhz"))
	logger.debug("Found GPU CLK Limits: " + str(gpu.freq_min) + " - " + str(gpu.freq_max))


## Reads the pp_od_clk_voltage from sysfs and returns the OD_SCLK values. This file will 
## be empty if not in "manual" for pp_od_performance_level.
func _read_amd_gpu_clock_current() -> void:
	var args := ["/sys/class/drm/" + gpu.card.name + "/device/pp_od_clk_voltage"]
	var output: Array = await _async_do_exec("cat", args)
	@warning_ignore("unsafe_method_access")
	var result := (output[0][0] as String).split("\n")

	for param in result:
		var parts := param.split("\n")
		for part in parts:
			var fixed_part := part.strip_edges().split(" ", false)
			if fixed_part.is_empty() or fixed_part[0] == "SCLK:" :
				continue
			if fixed_part[0] == "0:":
				profile.gpu_freq_min_current =  int(fixed_part[1].rstrip("Mhz"))
			elif fixed_part[0] == "1:":
				profile.gpu_freq_max_current =  int(fixed_part[1].rstrip("Mhz"))
	logger.debug("Found GPU CLK Current: " + str(profile.gpu_freq_min_current) + " - " + str(profile.gpu_freq_max_current))


func _read_amd_gpu_perf_level() -> void:
	var performance_level = await  _read_sys("/sys/class/drm/" + gpu.card.name + "/device/power_dpm_force_performance_level")
	if performance_level == "manual":
		profile.gpu_manual_enabled = true
	else:
		profile.gpu_manual_enabled = false


# TODO: Find a way to detect this.
func _read_amd_gpu_power_profile() -> void:
	pass


## Retrieves the current TDP from ryzenadj for AMD APU's.
func _read_amd_tdp() -> void:
	var set_sane_defaults := false

	# Fetch the current info from ryzenadj
	var info := await ryzenadj.get_info()
	if not info:
		logger.info("Unable to verify current tdp. Setting TDP to midpoint of range")
		await _set_sane_defaults()
		return

	# Handle cases where ryzenadj failed to read particular values
	var current_fastppt := 0.0
	if info.ppt_limit_fast > 0:
		current_fastppt = info.ppt_limit_fast
	else:
		logger.warn("RyzenAdj unable to read current PPT LIMIT FAST value. Setting to sane default.")
		current_fastppt = float((gpu.tdp_max - gpu.tdp_min) / 2 + gpu.tdp_min)
		set_sane_defaults = true

	if info.stapm_limit > 0:
		profile.tdp_current = info.stapm_limit
	else:
		logger.warn("RyzenAdj unable to read current STAPM value. Setting to sane default.")
		profile.tdp_current = float((gpu.tdp_max - gpu.tdp_min) / 2 + gpu.tdp_min)
		set_sane_defaults = true
	
	if info.thm_limit_core > 0:
		profile.gpu_temp_current = info.thm_limit_core
	else:
		logger.warn("RyzenAdj unable to read current THM value. Setting to sane default.")
		profile.gpu_temp_current = FALLBACK_GPU_TEMP
		set_sane_defaults = true

	# Set the TDP boost
	profile.tdp_boost_current = current_fastppt - profile.tdp_current
	_ensure_tdp_boost_limited()
	if set_sane_defaults:
		await _set_sane_defaults()
		return
	await _tdp_boost_value_change()


func _read_cpu_boost_enabled() -> void:
	if not  FileAccess.file_exists("/sys/devices/system/cpu/cpufreq/boost"):
		logger.warn("Attempted to read CPU boost when CPU is not possible.")

	var boost_set :=  await  _read_sys("/sys/devices/system/cpu/cpufreq/boost")
	profile.cpu_boost_enabled = boost_set == "1"

	logger.debug("CPU boost enabled: " + str(profile.cpu_boost_enabled))
	cpu_boost_toggled.emit(profile.cpu_boost_enabled)


## Loops through all cores and returns the count of enabled cores.
func _read_cpus_enabled() -> void:
	var active_cpus := 1
	for i in range(1, cpu.core_count):
		var args = ["-c", "cat /sys/bus/cpu/devices/cpu"+str(i)+"/online"]
		var output: Array = await _async_do_exec("bash", args)
		logger.debug("Add to count: " + str((output[0][0] as String).strip_edges()))
		active_cpus += int((output[0][0] as String).strip_edges())
		logger.debug("Detected Active CPU's: " + str(active_cpus))
	profile.cpu_core_count_current = active_cpus
	logger.debug("Total Active CPU's: " + str(profile.cpu_core_count_current))
	cpu_cores_used.emit(profile.cpu_core_count_current)


## Updates the total number of cores
func _read_cpu_count() -> void:
	var args = ["-c", "ls /sys/bus/cpu/devices/ | wc -l"]
	var output: Array = await _async_do_exec("bash", args)
	var exit_code = output[1]
	if exit_code:
		logger.warn("Unable to update CPU count. Received exit code: " +str(exit_code))
		return
	cpu.core_count = (output[0][0] as String).split("\n")[0] as int
	cpu.cores_available = cpu.core_count
	if not profile.cpu_smt_enabled:
		@warning_ignore("integer_division")
		cpu.cores_available = cpu.core_count / 2
	logger.debug("Total CPU's: " + str(cpu.core_count) + " Available CPU's: " + str(cpu.cores_available))
	cpu_cores_available_updated.emit(cpu.cores_available)


## Reads the current and absolute min/max gpu clocks.
func _read_gpu_clk_limits() -> void:
	match gpu.vendor:
		"AMD":
			await _read_amd_gpu_clock_limits()
		"Intel":
			await _read_intel_gpu_clock_limits()
	gpu_clk_limits_updated.emit(gpu.freq_min, gpu.freq_max)


func _read_gpu_clk_current() -> void:
	match gpu.vendor:
		"AMD":
			await _read_amd_gpu_clock_current()
		"Intel":
			await _read_intel_gpu_clock_current()
	gpu_clk_current_updated.emit(profile.gpu_freq_min_current, profile.gpu_freq_max_current)


## Called to read the current performance level and set the UI as needed.
func _read_gpu_perf_level() -> void:
	match gpu.vendor:
		"AMD":
			await _read_amd_gpu_perf_level()
		_:
			return
	gpu_manual_enabled_updated.emit(profile.gpu_manual_enabled)


func _read_gpu_power_profile() -> void:
	match gpu.vendor:
		"AMD":
			_read_amd_gpu_power_profile()
		_:
			return
	gpu_power_profile_updated.emit(profile.gpu_power_profile)


## Reads the following sysfs paths to update the current and mix/max gpu frequencies.
func _read_intel_gpu_clock_limits() -> void:
	gpu.freq_max = float(await _read_sys("/sys/class/drm/" + gpu.card.name + "/gt_RP0_freq_mhz"))
	gpu.freq_min = float(await _read_sys("/sys/class/drm/" + gpu.card.name + "/gt_RPn_freq_mhz"))
	logger.debug("Found GPU CLK Limits: " + str(gpu.freq_min) + " - " + str(gpu.freq_max))


func _read_intel_gpu_clock_current() -> void:
	profile.gpu_freq_max_current = float(await _read_sys("/sys/class/drm/" + gpu.card.name + "/gt_max_freq_mhz"))
	profile.gpu_freq_min_current = float(await _read_sys("/sys/class/drm/" + gpu.card.name + "/gt_min_freq_mhz"))
	logger.debug("Found GPU CLK Current: " + str(profile.gpu_freq_min_current) + " - " + str(profile.gpu_freq_max_current))


## Retrieves the current TDP from sysfs for Intel iGPU's.
func _read_intel_tdp() -> void:
	var long_tdp: float = float(await _read_sys("/sys/class/powercap/intel-rapl/intel-rapl:0/constraint_0_power_limit_uw"))
	if not long_tdp:
		logger.warn("Unable to determine long TDP.")
		return

	profile.tdp_current = long_tdp / 1000000
	var peak_tdp: float = float(await _read_sys("/sys/class/powercap/intel-rapl/intel-rapl:0/constraint_2_power_limit_uw"))
	if not peak_tdp:
		logger.warn("Unable to determine long TDP.")
		return
	profile.tdp_boost_current = peak_tdp / 1000000 - profile.tdp_current
	_ensure_tdp_boost_limited()
	await _tdp_boost_value_change()


func _read_smt_enabled() -> void:
	if FileAccess.file_exists("/sys/devices/system/cpu/smt/control"):
		var smt_set := await  _read_sys("/sys/devices/system/cpu/smt/control")
		logger.debug("SMT is set to" + smt_set)
		if smt_set == "on":
			profile.cpu_smt_enabled = true
	await _read_cpus_enabled()
	await _read_cpu_count()
	smt_toggled.emit(profile.cpu_smt_enabled)


## Retrieves the current TDP.
func _read_tdp() -> void:
	match gpu.vendor:
		"AMD":
			await _read_amd_tdp()
		"Intel":
			await _read_intel_tdp()
	tdp_updated.emit(profile.tdp_current, profile.tdp_boost_current)


## Retrieves the current thermal mode.
func _read_thermal_profile() -> void:
	if not platform_provider is HandheldPlatform:
		logger.warn("Attempted to call thermal profile property on a platform that is not a HandheldPlatform.")
		return
	if not _platform.gpu.thermal_profile_capable:
		logger.warn("Attempted to call thermal profile property on a Platform that is not thermal profile capable.")
		return

	profile.thermal_profile = int(await _read_sys((platform_provider as HandheldPlatform).thermal_policy_path))
	match profile.thermal_profile:
		0:
			logger.debug("Thermal throttle policy currently at Balanced")
		1:
			logger.debug("Thermal throttle policy currently at Performance")
		2:
			logger.debug("Thermal throttle policy currently at Silent")
	thermal_profile_updated.emit(profile.thermal_profile)


# Used to read values from sysfs
func _read_sys(path: String) -> String:
	var result := await _async_do_exec("cat", [path])
	if result[1] != OK:
		logger.warn("failed to read path: " + path)
		return ""
	return (result[0][0] as String).strip_escapes()


# Thread safe method of calling _do_exec
func _async_do_exec(command: String, args: Array)-> Array:
	logger.debug("Start async_do_exec : " + command + " " + str(args))
#	var cmd := Command.new(command, args)
#	var exit_code := await cmd.execute()
#	return [cmd.stdout, exit_code]
	return await _shared_thread.exec(_do_exec.bind(command, args))


## Calls OS.execute with the provided command and args and returns an array with
## the results and exit code to catch errors.
func _do_exec(command: String, args: Array)-> Array:
	logger.debug("Start _do_exec with command : " + command)
	for arg in args:
		logger.debug(str(arg))
	var output = []
	var exit_code := OS.execute(command, args, output)
#	logger.debug("Output: " + str(output))
#	logger.debug("Exit code: " +str(exit_code))
	return [output, exit_code]
