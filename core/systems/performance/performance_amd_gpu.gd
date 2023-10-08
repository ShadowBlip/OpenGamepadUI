extends PerformanceGPU
class_name PerformanceAMDGPU

const FALLBACK_GPU_TEMP: float = 80

var hardware_manager := load("res://core/systems/hardware/hardware_manager.tres") as HardwareManager
var ryzenadj := RyzenAdj.new()
var logger := Log.get_logger("PerformanceAMDGPU")


## Retrieves the current TDP from ryzenadj for AMD APU's.
func get_tdp() -> Info:
	var gpu := hardware_manager.gpu

	# Fetch the current info from ryzenadj
	var info := await ryzenadj.get_info()
	if not info:
		logger.info("Unable to verify current tdp. Setting TDP to midpoint of range")
		return null

	# Handle cases where ryzenadj failed to read particular values
	var tdp_info := Info.new()
	var current_fastppt := 0.0
	if info.ppt_limit_fast > 0:
		current_fastppt = info.ppt_limit_fast
	else:
		logger.warn("RyzenAdj unable to read current PPT LIMIT FAST value. Setting to sane default.")
		current_fastppt = float((gpu.tdp_max - gpu.tdp_min) / 2 + gpu.tdp_min)

	if info.stapm_limit > 0:
		tdp_info.tdp_current = info.stapm_limit
	else:
		logger.warn("RyzenAdj unable to read current STAPM value. Setting to sane default.")
		tdp_info.tdp_current = float((gpu.tdp_max - gpu.tdp_min) / 2 + gpu.tdp_min)

	if info.thm_limit_core > 0:
		tdp_info.gpu_temp_current = info.thm_limit_core
	else:
		logger.warn("RyzenAdj unable to read current THM value. Setting to sane default.")
		tdp_info.gpu_temp_current = FALLBACK_GPU_TEMP

	# Set the TDP boost
	tdp_info.tdp_boost_current = current_fastppt - tdp_info.tdp_current

	return tdp_info


## Returns a string of the performance level. E.g. "manual", "auto"
func get_perf_level() -> String:
	var card := hardware_manager.get_active_gpu_card()
	if not card:
		logger.warn("Unable to find active GPU to get perf level")
		return ""

	return _read_sys("/sys/class/drm/" + card.name + "/device/power_dpm_force_performance_level")


## Called to set the maximum gpu clock
func set_gpu_freq_max(value: float) -> void:
	if value == 0:
		logger.warn("Cowardly refusing to set maximum clock rate to 0")
		return

	# Get the active GPU
	var card := hardware_manager.get_active_gpu_card()
	if not card:
		logger.warn("Unable to detect active GPU card to set frequency")
		return
	
	# Get the current minimum clock rate
	var values := card.get_clock_values()
	if values == Vector2.ZERO:
		logger.warn("Unable to read clock values to set frequency")
		return
	
	if await set_gpu_freq(values.x, value) != OK:
		logger.warn("Error setting GPU max frequency")


## Called to set the minimum gpu clock
func set_gpu_freq_min(value: float) -> void:
	if value == 0:
		logger.warn("Cowardly refusing to set minimum clock rate to 0")
		return

	# Get the active GPU
	var card := hardware_manager.get_active_gpu_card()
	if not card:
		logger.warn("Unable to detect active GPU card to set frequency")
		return
	
	# Get the current maximum clock rate
	var values := card.get_clock_values()
	if values == Vector2.ZERO:
		logger.warn("Unable to read clock values to set frequency")
		return
	
	if await set_gpu_freq(value, values.y) != OK:
		logger.warn("Error setting GPU min frequency")


# Sets the GPU frequency range to the given values
func set_gpu_freq(freq_min: int, freq_max: int) -> int:
	# Get the active GPU
	var card := hardware_manager.get_active_gpu_card()
	if not card:
		logger.warn("Unable to detect active GPU card to set frequency")
		return -1

	var args := ["amdGpuClock", str(freq_min), str(freq_max), card.name]
	var cmd := Command.new(POWERTOOLS_PATH, args)
	return await cmd.execute()


## Called to toggle auto/manual gpu clocking
func set_gpu_manual_enabled(enabled: bool) -> void:
	logger.debug("Setting manual GPU clocking enabled: " + str(enabled))
	var card := hardware_manager.get_active_gpu_card()
	if not card:
		logger.warn("Unable to find active GPU to set manual mode")
		return

	var mode := "manual" if enabled else "auto"
	var args := ["pdfpl", mode, card.name]
	var cmd := Command.new(POWERTOOLS_PATH, args)
	if await cmd.execute() != OK:
		logger.warn("Failed to set GPU frequency mode")


## Called to set the GPU Power Profile
func set_gpu_power_profile(mode: POWER_PROFILE) -> void:
	logger.debug("Setting GPU power profile to: " + str(mode))
	var power_profile := ryzenadj.POWER_PROFILE.MAX_PERFORMANCE
	if mode == POWER_PROFILE.POWER_SAVINGS:
		power_profile = ryzenadj.POWER_PROFILE.POWER_SAVINGS

	if await ryzenadj.set_power_profile(power_profile) != OK:
		logger.warn("Failed to set GPU power profile")


## Called to set the GPU Thermal Throttle Limit
func set_gpu_temp_current(value: float) -> void:
	logger.debug("Setting GPU temperature limit to: " + str(value) + "C")
	if await ryzenadj.set_tctl_temp(value) != OK:
		logger.warn("Failed to set GPU temperature limit")


## Set long/short PPT on AMD APU's
func set_tdp_boost_value(value: float) -> void:
	logger.debug("Setting TDP boost value to: " + str(value))
	var info := await get_tdp()
	if await _set_ppt_limits(info.tdp_current, value) != OK:
		logger.warn("Failed to set TDP boost values")


## Called to set the TDP average limit (STAPM on AMD APU's)
func set_tdp_value(value: float) -> void:
	logger.debug("Setting STAPM limit to: " + str(value))
	await ryzenadj.set_stapm_limit(value * 1000)
	
	# Update the boost values as well
	var info := await get_tdp()
	if await _set_ppt_limits(value, info.tdp_boost_current) != OK:
		logger.warn("Failed to set TDP values")


## Sets the thermal throttle mode for ASUS devices.
func set_thermal_profile(policy: THERMAL_THROTTLE_POLICY) -> void:
	var platform := load("res://core/global/platform.tres") as Platform
	if not platform.platform is HandheldPlatform:
		logger.warn("Attempt to apply thermal profile on platform that is not HandheldPlatform.")
		return

	var platform_provider := platform.platform as HandheldPlatform
	if not FileAccess.file_exists(platform_provider.thermal_policy_path):
		logger.warn("Thermal policy path does not exist.")
		return

	var policy_str := "0"
	match policy:
			THERMAL_THROTTLE_POLICY.BALANCED:
				logger.debug("Setting thermal throttle policy to Balanced")
				policy_str = "0"
			THERMAL_THROTTLE_POLICY.PERFORMANCE:
				logger.debug("Setting thermal throttle policy to Performance")
				policy_str = "1"
			THERMAL_THROTTLE_POLICY.SILENT:
				logger.debug("Setting thermal throttle policy to Silent")
				policy_str = "2"
	
	var cmd := Command.new(POWERTOOLS_PATH, ["setThermalPolicy", policy_str])
	if await cmd.execute() != OK:
		logger.warn("Failed to set thermal profile")


func enable_performance_write() -> void:
	var card := hardware_manager.get_active_gpu_card()
	if not card:
		logger.warn("Unable to find active GPU to enable performance write on")
		return

	var cmd := Command.new(POWERTOOLS_PATH, ["pdfpl", "write", card.name])
	if await cmd.execute() != OK:
		logger.warn("Failed to set GPU performance write mode")


# Set the slow and fast ppt limits to allow "boost"
func _set_ppt_limits(tdp_current: float, boost_value: float) -> int:
	var slowPPT: float = (floor(boost_value/2) + tdp_current) * 1000
	var fastPPT: float = (boost_value + tdp_current) * 1000
	var code: int
	code += await ryzenadj.set_fast_limit(fastPPT)
	code += await ryzenadj.set_slow_limit(slowPPT)

	return code
