extends Resource
class_name PerformanceManager

var Platform := load("res://core/global/platform.tres")
var thread_pool := load("res://core/systems/threading/thread_pool.tres") as ThreadPool

const POWERTOOLS_PATH : String = "/usr/share/opengamepadui/scripts/powertools"

var cpu: Platform.CPUInfo
var cpu_core_count := 1
var cpu_core_count_current: int = 1
var cpu_boost_enabled: bool = false
var cpu_smt_enabled: bool = false
var gpu: Platform.GPUInfo
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

var platform : PlatformProvider 
var profile : PerformanceProfile

var logger := Log.get_logger("PerformanceManager", Log.LEVEL.INFO)


func _ready():
	platform = Platform.platform
	await update_system_components()


## Looks at system file decriptors to update components and their capabilities
## and current settings. 
func update_system_components() -> void:
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


func set_cpu_core_count(value: int) -> void:
	if cpu_core_count_current == value:
		return
	cpu_core_count_current = value
	await _change_cpu_cores()


## Called to toggle cpu boost
func set_cpu_boost_enabled(state: bool) -> void:
	if cpu_boost_enabled == state:
		return
	cpu_boost_enabled = state
	var args := ["cpuBoost", "0"]
	if cpu_boost_enabled:
		args = ["cpuBoost", "1"]
	await _do_exec(POWERTOOLS_PATH, args)


## Called to enable/disable CPU SMT.
func set_cpu_smt_enabled(state: bool) -> void:
	if cpu_smt_enabled == state:
		return
	cpu_smt_enabled = state
	var args := []
	if cpu_smt_enabled:
		args = ["smtToggle", "on"]
	else:
		args = ["smtToggle", "off"]
	var output: Array = await _do_exec(POWERTOOLS_PATH, args)
	var exit_code = output[1]
	if exit_code:
		logger.warn("_on_toggle_smt exit code: " + str(exit_code))
	await _update_cpus_enabled()


## Called when gpu_freq_max_slider.value is changed.
func set_gpu_freq_max(value: float) -> void:
	if gpu_freq_max_current == value:
		return
	gpu_freq_max_current = value
	if value < gpu_freq_min_current:
		gpu_freq_min_current = value
	await _gpu_freq_change()


## Called to set the minimum gpu clock is changed.
func set_gpu_freq_min(value: float) -> void:
	if gpu_freq_min_current == value:
		return
	gpu_freq_min_current = value
	if value > gpu_freq_max_current:
		gpu_freq_max_current = value
	await _gpu_freq_change()


## Called to toggle auto/manual gpu clocking
func set_gpu_manual_mode_enabled(state: bool) -> void:
	if gpu_manual_mode == state:
		return
	gpu_manual_mode = state
	if gpu.vendor == "AMD":
		var args := ["pdfpl", "auto"]
		if gpu_manual_mode:
			args = ["pdfpl", "manual"]
		var output: Array = await _do_exec(POWERTOOLS_PATH, args)
		var exit_code = output[1]
		if exit_code:
			logger.warn("_on_toggle_gpu_freq exit code: " + str(exit_code))

	if gpu_manual_mode:
		await _update_gpu_clk_limits()


func set_gpu_power_profile(mode: int) -> void:
	if gpu_power_profile == mode:
		return
	gpu_power_profile = mode
	_gpu_power_profile_change()


func set_gpu_temp_current(value: float) -> void:
	if gpu_temp_current == value:
		return
	gpu_temp_current = value
	_gpu_temp_limit_change()


## Called to set the TFP boost limit.
func set_tdp_boost_value(value: float) -> void:
	if tdp_boost_current == value:
		return
	tdp_boost_current = value
	await _tdp_boost_value_change()


## Called to set the TDP average limit.
func set_tdp_value(value: float) -> void:
	if tdp_current == value:
		return
	tdp_current = value
	await _tdp_value_change()


## Sets the thermal throttle mode for ASUS devices.
func set_thermal_mode(index: int) -> void:
	if thermal_mode == index:
		return
	thermal_mode = index
	match thermal_mode:
			"0":
				logger.debug("Setting thermal throttle policy to Balanced")
			"1":
				logger.debug("Setting thermal throttle policy to Performance")
			"2":
				logger.debug("Setting thermal throttle policy to Silent")
	var args := ["setThermalPolicy", str(thermal_mode)]
	await _async_do_exec(platform.thermal_policy_path, args)


## Set STAPM on AMD APU's
func _amd_tdp_change() -> void:
	logger.debug("Doing callback func _do_amd_tdp_change")
	await _async_do_exec(POWERTOOLS_PATH, ["ryzenadj", "-a", str(tdp_current * 1000)])
	await _amd_tdp_boost_change()


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
		if cpu_no >= cpu_core_count_current:
			args = ["cpuToggle", str(cpu_no), "0"]
		else:
			args = ["cpuToggle", str(cpu_no), "1"]
		await _do_exec(POWERTOOLS_PATH, args)


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
	if gpu_power_profile == 2:
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
	await _intel_tdp_boost_change()


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
	var output: Array = await _do_exec("cat", args)
	var result := output[0][0].split("\n") as Array
	var current_max := 0
	var current_min := 0
	var max_value := 0
	var min_value := 0

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
	logger.debug("Found GPU CLK Limits: " + str(min_value) + " - " + str(max_value))


func _update_amd_gpu_perf_level() -> String:
	return await _read_sys("/sys/class/drm/card0/device/power_dpm_force_performance_level")


## Retrieves the current TDP from ryzenadj for AMD APU's.
func _update_amd_tdp() -> void:
	var output: Array = await _do_exec(POWERTOOLS_PATH, ["ryzenadj", "-i"])
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
		var output: Array = await _do_exec("bash", args)
		active_cpus += int(output[0][0].strip_edges())
	logger.debug("Active CPU's: " + str(active_cpus))
	cpu_core_count_current = active_cpus


## updates the total number of cores and total enabled cores.
func _update_cpu_count() -> int:
	var args = ["-c", "ls /sys/bus/cpu/devices/ | wc -l"]
	var output: Array = await _do_exec("bash", args)
	var exit_code = output[1]
	if exit_code:
		logger.warn("Unable to update CPU count. Received exit code: " +str(exit_code))
		return 0
	var result := output[0][0].split("\n") as Array
	return int(result[0])


## reads the current and absolute min/max gpu clocks.
func _update_gpu_clk_limits() -> void:
	match gpu.vendor:
		"AMD":
			await _update_amd_gpu_clock_limits()
		"Intel":
			await _update_intel_gpu_clock_limits()


## Called to read the current performance level and set the UI as needed.
func _update_gpu_perf_level() -> void:
	match gpu.vendor:
		"AMD":
			await _update_amd_gpu_perf_level()
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
	var output: Array = await _do_exec("cat", [path])
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
