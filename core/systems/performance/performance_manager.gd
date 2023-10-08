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
var _hardware_manager := load("res://core/systems/hardware/hardware_manager.tres") as HardwareManager
var _power_manager := load("res://core/systems/power/power_manager.tres") as PowerManager
var _settings_manager := load("res://core/global/settings_manager.tres") as SettingsManager
var _shared_thread := load("res://core/systems/threading/utility_thread.tres") as SharedThread

var cpu := _hardware_manager.get_cpu()
var batteries: Array[PowerManager.Device]
var library_item: LibraryLaunchItem
var profile: PerformanceProfile
var profile_state: String # docked or undocked
var initialized: bool = false
var logger := Log.get_logger("PerformanceManager", Log.LEVEL.INFO)


func _init():
	# Connect to CPU signals
	var on_smt_updated := func(enabled: bool) -> void:
		smt_toggled.emit(enabled)
	cpu.smt_updated.connect(on_smt_updated)
	
	_shared_thread.start()
	profile = PerformanceProfile.new()
	if not _platform.loaded:
		_platform.platform_loaded.connect(_setup, CONNECT_ONE_SHOT)
		return
	_setup()


func _setup():
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


## Returns the GPU performance manager
func get_gpu_performance_manager() -> PerformanceGPU:
	var gpu := _hardware_manager.gpu
	match gpu.vendor:
		"AMD":
			return PerformanceAMDGPU.new()
		"Intel":
			return PerformanceIntelGPU.new()
	
	return null


## Looks at system file decriptors to update components and their capabilities
## and current settings. 
func read_system_components(power_profile: int = 1) -> void:
	logger.debug("Update system components started")
	var cpu := _hardware_manager.cpu
	var gpu := _hardware_manager.gpu
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

	if _platform.platform is HandheldPlatform:
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
	var prefix: String = _hardware_manager.get_product_name().replace(" ", "_") + "_" + profile_state
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


func apply_profile(profile: PerformanceProfile) -> void:
	var cpu := _hardware_manager.cpu
	var gpu := _hardware_manager.gpu
	var gpu_performance := get_gpu_performance_manager()
	
	if cpu.boost_capable:
		logger.debug("Set CPU Boost from profile: " + str(profile.cpu_boost_enabled))
		cpu.set_boost_enabled(profile.cpu_boost_enabled)
		
	if cpu.smt_capable:
		logger.debug("Set SMT state from profile: " + str(profile.cpu_smt_enabled))
		await cpu.set_smt_enabled(profile.cpu_smt_enabled)
		logger.debug("Set core count from profile: " + str(profile.cpu_core_count_current))
		cpu.set_cpu_core_count(profile.cpu_core_count_current)
		
	if gpu.clk_capable:
		logger.debug("Set gpu mode from profile: " + str(profile.gpu_manual_enabled))
		gpu_performance.set_gpu_manual_enabled(profile.gpu_manual_enabled)
		if profile.gpu_manual_enabled:
			logger.debug("Set gpu frequency range from profile: " + str(profile.gpu_freq_min_current) + "-" + str(profile.gpu_freq_max_current))
			gpu_performance.set_gpu_freq(profile.gpu_freq_min_current, profile.gpu_freq_max_current)
			
	if gpu.power_profile_capable:
		logger.debug("Set gpu power profile from profile: " +str(profile.gpu_power_profile))
		gpu_performance.set_gpu_power_profile(profile.gpu_power_profile)
		
	if gpu.tj_temp_capable:
		logger.debug("Set gpu temp target from profile: " +str(profile.gpu_temp_current))
		gpu_performance.set_gpu_temp_current(profile.gpu_temp_current)
		
	if gpu.tdp_capable:
		logger.debug("Set tdp from profile: " + str(profile.tdp_current) + " boost:" + str(profile.tdp_boost_current))
		gpu_performance.set_tdp_value(profile.tdp_current)
		gpu_performance.set_tdp_boost_value(profile.tdp_boost_current)
		
	if _platform.platform is HandheldPlatform:
		logger.debug("Set thermal mode from profile: " +str(profile.thermal_profile))
		gpu_performance.set_thermal_profile(profile.thermal_profile)
		
	logger.info("Applied Performance Profile: " + profile_state + " " + profile.name)
	perfomance_profile_applied.emit(profile)


func emit_profile_signals() -> void:
	var cpu := _hardware_manager.cpu
	var gpu := _hardware_manager.gpu
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
	var gpu := _hardware_manager.gpu
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
	if not _platform.platform is HandheldPlatform:
		logger.warn("Attempt to apply thermal profile on platform that is not HandheldPlatform.")
		return
	var platform_provider := _platform.platform as HandheldPlatform
	if not FileAccess.file_exists(platform_provider.thermal_policy_path):
		logger.warn("Thermal policy path does not exist.")
		return
	match profile.thermal_profile:
			"0":
				logger.debug("Setting thermal throttle policy to Balanced")
			"1":
				logger.debug("Setting thermal throttle policy to Performance")
			"2":
				logger.debug("Setting thermal throttle policy to Silent")
	var args := ["setThermalPolicy", str(profile.thermal_profile)]
	await _async_do_exec(platform_provider.thermal_policy_path, args)
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


# Called to disable/enable cores by count as specified by value. 
func _change_cpu_cores():
	var cpu := _hardware_manager.cpu
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


## Ensures the current boost doesn't exceed the max boost.
func _ensure_tdp_boost_limited()  -> void:
	var gpu := _hardware_manager.gpu
	if profile.tdp_boost_current > gpu.max_boost:
		profile.tdp_boost_current = gpu.max_boost
	if profile.tdp_boost_current < 0:
		profile.tdp_boost_current = 0


# Sets the current TDP to the midpoint of the detected hardware. Used when we're not able to
# Determine the current settings.
func _set_sane_defaults() -> void:
	var gpu := _hardware_manager.gpu
	if not profile.tdp_current:
		profile.tdp_current = float((gpu.tdp_max - gpu.tdp_min) / 2 + gpu.tdp_min)
	if not profile.tdp_boost_current:
		profile.tdp_boost_current = 0
	if not profile.gpu_temp_current:
		profile.gpu_temp_current = FALLBACK_GPU_TEMP
	await _tdp_value_change()
	await _gpu_temp_limit_change()

