extends VBoxContainer

const powertools_path : String = "/usr/share/opengamepadui/scripts/powertools"

var boost_capable := false
var core_count := 0
var cpu_model := ""
var cpu_vendor := ""
var gpu_clk_capable := false
var gpu_model := ""
var gpu_vendor := ""
var ht_capable := false
var shared_thread: SharedThread
var tdp_capable := false
var tj_temp_capable := false
var smt := false

@onready var cpu_boost_button := $CPUBoostButton
@onready var cpu_cores_slider := $CPUCoresSlider
@onready var gpu_freq_enable := $GPUFreqButton
@onready var gpu_freq_max_slider := $GPUFreqMaxSlider
@onready var gpu_freq_min_slider := $GPUFreqMinSlider
@onready var gpu_temp_slider := $GPUTempSlider
@onready var smt_button := $SMTButton
@onready var tdp_boost_slider := $TDPBoostSlider
@onready var tdp_slider := $TDPSlider

var logger := Log.get_logger("PowerTools", Log.LEVEL.INFO)

var command_timer: Timer

# Called when the node enters the scene tree for the first time.
# Finds default values and current settings of the hardware.
func _ready():
	shared_thread = SharedThread.new()
	shared_thread.start()
	command_timer = Timer.new()
	command_timer.set_autostart(false)
	command_timer.set_one_shot(true)
	add_child(command_timer)

	_get_system_components()

	# Set UI capabilities from system capabilities
	cpu_boost_button.visible = boost_capable
	cpu_cores_slider.visible = ht_capable
	gpu_freq_enable.visible = gpu_clk_capable
	gpu_temp_slider.visible = tj_temp_capable
	smt_button.visible = ht_capable
	tdp_boost_slider.visible = tdp_capable
	tdp_slider.visible = tdp_capable

	if tdp_capable:
		_get_tdp_range()
		_get_tdp()
		tdp_boost_slider.value_changed.connect(_on_tdp_boost_value_changed)
		tdp_slider.value_changed.connect(_on_tdp_value_changed)

	if gpu_clk_capable:
		_get_gpu_perf_level()
		gpu_freq_enable.toggled.connect(_on_toggle_gpu_freq)
		gpu_freq_max_slider.value_changed.connect(_on_max_gpu_freq_changed)
		gpu_freq_min_slider.value_changed.connect(_on_min_gpu_freq_changed)
		# Set write mode for power_dpm_force_performance_level
		_setup_callback_exec(powertools_path, ["pdfpl", "write"])


	if ht_capable:
		if _read_sys("/sys/devices/system/cpu/smt/control") == "on":
			smt_button.button_pressed = true
			smt = true
		_get_cpu_count()
		cpu_cores_slider.value_changed.connect(_on_change_cpu_cores)
		smt_button.toggled.connect(_on_toggle_smt)

	if boost_capable:
		if _read_sys("/sys/devices/system/cpu/cpufreq/boost") == "1":
			cpu_boost_button.button_pressed = true
		cpu_boost_button.toggled.connect(_on_toggle_cpu_boost)

	if tj_temp_capable:
		gpu_temp_slider.value_changed.connect(_on_gpu_temp_limit_changed)


# Thread safe method of calling _do_exec
func _async_do_exec(command: String, args: Array)-> Array:
	logger.debug("Start async_do_exec : " + command)
	for arg in args:
		logger.debug(str(arg))
	return await shared_thread.exec(_do_exec.bind(command, args))


# Bindable function to be called when command_timer.timeout signal is emmitted
# that executes _async_do_exec with the passed command and args.
func _do_callback(command: String, args: Array)-> void:
	logger.debug("Doing callback")
	await _async_do_exec(command, args)


# Overrides or sets the _do_callback binding and (re)starts the timer.
func _setup_callback_exec(command: String, args: Array) -> void:
	logger.debug("Setting callback exec")
	_clear_callbacks()
	command_timer.timeout.connect(_do_callback.bind(command, args), CONNECT_ONE_SHOT)
	command_timer.start(.5)


# Overrides or sets the command_timer.timeout signal connection function and 
# (re)starts the timer.
func _setup_callback_func(callable: Callable) -> void:
	logger.debug("Setting callback func")
	_clear_callbacks()
	command_timer.timeout.connect(callable, CONNECT_ONE_SHOT)
	command_timer.start(.5)


# Removes any existing signal connections to command_timer.timeout.
func _clear_callbacks() -> void:
	for connection in command_timer.timeout.get_connections():
		var callable := connection["callable"] as Callable
		command_timer.timeout.disconnect(callable)


# Calls OS.execute with the provided command and args and returns an array with
# the results and exit code to catch errors.
func _do_exec(command: String, args: Array)-> Array:
	logger.debug("Start _do_exec with command : " + command)
	for arg in args:
		logger.debug(str(arg))
	var output = []
	var exit_code := OS.execute(command, args, output)
	logger.debug("Output: " + str(output))
	logger.debug("Exit code: " +str(exit_code))
	return [output, exit_code]


# Gets the total number of cores. If SMT is disabled that value is halved.
func _get_cpu_count() -> bool:
	var args = ["-c", "ls /sys/bus/cpu/devices/ | wc -l"]
	var output: Array = _do_exec("bash", args)
	var exit_code = output[1]
	if exit_code:
		return false
	var result := output[0][0].split("\n") as Array
	core_count = int(result[0])
	cpu_cores_slider.max_value = core_count
	if not smt_button.button_pressed:
		cpu_cores_slider.max_value = core_count / 2
	cpu_cores_slider.value = _get_cpus_enabled()
	logger.debug("Total CPU's: " + str(cpu_cores_slider.value))
	return true


# Loops through all cores and returns the count of enabled cores.
func _get_cpus_enabled() -> int:
	pass
	var active_cpus := 1
	for i in range(1, core_count):
		var args = ["-c", "cat /sys/bus/cpu/devices/cpu"+str(i)+"/online"]
		var output: Array = _do_exec("bash", args)
		active_cpus += int(output[0][0].strip_edges())
	logger.debug("Active CPU's: " + str(active_cpus))
	return active_cpus


# Reads the pp_os_clk_voltage from sysfs and returns the values. This file will 
# be empty if not in "manual" for pp_od_performance_level.
func _get_gpu_clk_limits() -> bool:
	var args := ["/sys/class/drm/card0/device/pp_od_clk_voltage"]
	var output: Array = _do_exec("cat", args)
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
				min_value = int(part[1].rstrip("Mhz"))
				max_value = int(part[2].rstrip("Mhz"))
			elif part[0] == "0:":
				current_min =  int(part[1].rstrip("Mhz"))
			elif part[0] == "1:":
				current_max =  int(part[1].rstrip("Mhz"))

	gpu_freq_max_slider.max_value = max_value
	gpu_freq_max_slider.min_value = min_value
	gpu_freq_max_slider.value = current_max
	gpu_freq_min_slider.max_value = max_value
	gpu_freq_min_slider.min_value = min_value
	gpu_freq_min_slider.value = current_min
	logger.debug("Found GPU CLK Limits: " + str(min_value) + " - " + str(max_value))
	return true


# Retrieves the current TDP.
func _get_tdp() -> bool:
	match gpu_vendor:
		"AuthenticAMD", 'AuthenticAMD Advanced Micro Devices, Inc.':
			return await _get_amd_tdp()
		"GenuineIntel":
			return await _get_intel_tdp()
		_:
			return false

# Retrieves the current TDP from ryzenadj for AMD APU's.
func _get_amd_tdp() -> bool:
	var output: Array = _do_exec(powertools_path, ["ryzenadj", "-i"])
	var exit_code = output[1]
	if exit_code:
		return false
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
				tdp_slider.value = float(parts[2])
			"THM LIMIT CORE":
				gpu_temp_slider.value = float(parts[2])
	var current_boost = current_fastppt - tdp_slider.value 
	if current_boost > tdp_boost_slider.max_value:
		tdp_boost_slider.value = tdp_boost_slider.max_value
	elif current_boost <= 0:
		tdp_boost_slider.value = 0
	else:
		tdp_boost_slider.value = current_boost
	return true	


# Retrieves the current TDP from sysfs for Intel iGPU's.
func _get_intel_tdp() -> bool:
	var long_tdp: float = float(_read_sys("/sys/class/powercap/intel-rapl/intel-rapl:0/constraint_0_power_limit_uw"))
	if not long_tdp:
		logger.warn("Unable to determine long TDP.")
		return false

	tdp_slider.value = long_tdp / 1000000
	var peak_tdp: float = float(_read_sys("/sys/class/powercap/intel-rapl/intel-rapl:0/constraint_2_power_limit_uw"))
	if not peak_tdp:
		logger.warn("Unable to determine long TDP.")
		return false
	logger.debug("Current TDP: " +str(long_tdp))
	logger.debug("Current TDP Slider value: " +str(tdp_slider.value))
	var current_boost = peak_tdp / 1000000 - tdp_slider.value
	if current_boost > tdp_boost_slider.max_value:
		tdp_boost_slider.value = tdp_boost_slider.max_value
	elif current_boost <= 0:
		tdp_boost_slider.value = 0
	else:
		tdp_boost_slider.value = current_boost
	return true


# Called to get the current performance level and set the UI as needed.
func _get_gpu_perf_level() -> void:
	var performace_level: String = _read_sys("/sys/class/drm/card0/device/power_dpm_force_performance_level")
	logger.debug("GPU Mode set to: " + performace_level)
	if performace_level == "manual":
		gpu_freq_enable.button_pressed = true
		gpu_freq_max_slider.visible = true
		gpu_freq_min_slider.visible = true
		_get_gpu_clk_limits()


# Reads the hardware. Only supports AMD APU's currently.
# TODO: Support more than AMD APU's
func _get_system_components() -> bool:
	var args = ["-c", "lscpu"]
	var output: Array = _do_exec("bash", args)
	var exit_code = output[1]
	if exit_code:
		return false
	var result := output[0][0].split("\n") as Array
	for param in result:
		var parts := param.split(" ", false) as Array
		if parts.is_empty():
			continue
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
			# TODO: We can get min/max CPU freq here.
	if cpu_model == "" or cpu_vendor == "":
		return false
	logger.debug("Found CPU: " + cpu_model)
	# TODO: This is lazy and doesn't support dedicated graphics paired with APU's.
	if cpu_model in amd_apu_database:
		gpu_model = cpu_model
		gpu_vendor = cpu_vendor
		tdp_capable = true
		tj_temp_capable = true
		gpu_clk_capable = true
	if cpu_model in intel_apu_database:
		gpu_model = cpu_model
		gpu_vendor = cpu_vendor
		tdp_capable = true
	if gpu_model == "" or gpu_vendor == "":
		return false
	logger.debug("Found GPU: " + gpu_model)
	return true


# Gets the TDP Range for the detected hardware.
func _get_tdp_range() -> bool:
	match gpu_vendor:
		"AuthenticAMD", 'AuthenticAMD Advanced Micro Devices, Inc.':
			return _get_tdp_range_amd_apu()
		"GenuineIntel":
			return _get_tdp_range_intel_apu()
		_:
			return false


# Gets the TDP range for the detected APU
func _get_tdp_range_amd_apu() -> bool:
	var apu_data := amd_apu_database[gpu_model] as Dictionary
	tdp_boost_slider.max_value = apu_data["max_boost"]
	tdp_slider.max_value = apu_data["max_tdp"]
	tdp_slider.min_value = apu_data["min_tdp"]
	logger.debug("Found TDP Limits: " + str(apu_data["min_tdp"]) + " - " + str(apu_data["max_tdp"]))
	return true


# Gets the TDP range for the detected APU
func _get_tdp_range_intel_apu() -> bool:
	var apu_data := intel_apu_database[gpu_model] as Dictionary
	tdp_boost_slider.max_value = apu_data["max_boost"]
	tdp_slider.max_value = apu_data["max_tdp"]
	tdp_slider.min_value = apu_data["min_tdp"]
	logger.debug("Found TDP Limits: " + str(apu_data["min_tdp"]) + " - " + str(apu_data["max_tdp"]))
	return true


# Called to disable/enable cores by count as specified by value. 
func _on_change_cpu_cores(value: float):
	var args := []
	if smt:
		for cpu_no in range(1, core_count):
			if cpu_no >= cpu_cores_slider.value:
				args = ["togglecpu", str(cpu_no), "0"]
			else:
				args = ["togglecpu", str(cpu_no), "1"]
			_setup_callback_exec(powertools_path, args)
	if not smt:
		for cpu_no in range(2, core_count, 2):
			if cpu_no >= cpu_cores_slider.value * 2:
				args = ["togglecpu", str(cpu_no), "0"]
			else:
				args = ["togglecpu", str(cpu_no), "1"]
			_setup_callback_exec(powertools_path, args)


# Sets the T-junction temp using ryzenadj.
# TODO: Support more than AMD APU's
func _on_gpu_temp_limit_changed(value: float) -> void:
	_setup_callback_exec(powertools_path, ["ryzenadj", "-f", str(value)])


# Called to set the max GPU freq
# TODO: Support more than AMD APU's
func _on_max_gpu_freq_changed(value: float) -> void:
	if value < gpu_freq_min_slider.value:
		gpu_freq_min_slider.value = value
	_setup_callback_exec(powertools_path, ["gpuclk", "1", str(value)])


# Called to set the min GPU freq
# TODO: Support more than AMD APU's
func _on_min_gpu_freq_changed(value: float) -> void:
	if value > gpu_freq_max_slider.value:
		gpu_freq_max_slider.value = value
	_setup_callback_exec(powertools_path, ["gpuclk", "0", str(value)])


# Called to set the base average TDP
func _on_tdp_value_changed(value: float) -> void:
	match gpu_vendor:
		"AuthenticAMD", 'AuthenticAMD Advanced Micro Devices, Inc.':
			_setup_callback_func(_do_amd_tdp_change)
		"GenuineIntel":
			_setup_callback_func(_do_intel_tdp_change)


# Called to set the flow and fast boost TDP
func _on_tdp_boost_value_changed(_value: float) -> void:
	match gpu_vendor:
		"AuthenticAMD", 'AuthenticAMD Advanced Micro Devices, Inc.':
			_setup_callback_func(_do_amd_tdp_boost_change)
		"GenuineIntel":
			_setup_callback_func(_do_intel_tdp_boost_change)


# Set STAPM on AMD APU's
func _do_amd_tdp_change() -> void:
	logger.debug("Doing callback func _do_amd_tdp_change")
	var value: int = tdp_slider.value
	await _async_do_exec(powertools_path, ["ryzenadj", "-a", str(value * 1000)])
	_do_amd_tdp_boost_change()


# Set long/short PPT on AMD APU's
func _do_amd_tdp_boost_change() -> void:
	logger.debug("Doing callback func _do_amd_tdp_boost_change")
	var value: int = tdp_boost_slider.value
	var slowPPT: float = (floor(value/2) + tdp_slider.value) * 1000
	var fastPPT: float = (value + tdp_slider.value) * 1000
	await _async_do_exec(powertools_path, ["ryzenadj", "-b", str(fastPPT)])
	await _async_do_exec(powertools_path, ["ryzenadj", "-c", str(slowPPT)])


# Set long TDP on Intel iGPU's
func _do_intel_tdp_change() -> void:
	logger.debug("Doing callback func _do_intel_tdp_change")
	var value: int = tdp_slider.value
	var results := await _async_do_exec(powertools_path, ["set_rapl", "constraint_0_power_limit_uw", str(value * 1000000)])
	for result in results:
		logger.debug("Result: " +str(result))
	_do_intel_tdp_boost_change()


# Set short/peak TDP on Intel iGPU's
func _do_intel_tdp_boost_change() -> void:
	logger.debug("Doing callback func _do_intel_tdp_boost_change")
	var value: int = tdp_boost_slider.value
	var shortTDP: float = (floor(value/2) + tdp_slider.value) * 1000000
	var peakTDP: float = (value + tdp_slider.value) * 1000000
	var results := await _async_do_exec(powertools_path, ["set_rapl", "constraint_1_power_limit_uw", str(shortTDP)])
	for result in results:
		logger.debug("Result: " +str(result))
	results =await _async_do_exec(powertools_path, ["set_rapl", "constraint_2_power_limit_uw", str(peakTDP)])
	for result in results:
		logger.debug("Result: " +str(result))

# Called to toggle cpu boost
func _on_toggle_cpu_boost(state: bool) -> void:
	var args := ["cpuBoost", "0"]
	if state:
		args = ["cpuBoost", "1"]
	_setup_callback_exec(powertools_path, args)


# Called to toggle auo/manual gpu clocking
# TODO: Support more than AMD APU's
func _on_toggle_gpu_freq(state: bool) -> void:
	var args := ["pdfpl", "auto"]
	if state:
		args = ["pdfpl", "manual"]
	var output: Array = _do_exec(powertools_path, args)
	var exit_code = output[1]
	if exit_code:
		logger.warn("_on_toggle_gpu_freq exit code: " + str(exit_code))
	gpu_freq_max_slider.visible = state
	gpu_freq_min_slider.visible = state
	if state:
		_get_gpu_clk_limits()


# Called to toggle SMT
func _on_toggle_smt(state: bool) -> void:
	smt = state
	var args := []
	if smt:
		args = ["smt", "on"]
		cpu_cores_slider.max_value = core_count
	else:
		args = ["smt", "off"]
		cpu_cores_slider.max_value = core_count / 2
	var output: Array = _do_exec(powertools_path, args)
	var exit_code = output[1]
	if exit_code:
		logger.warn("_on_toggle_smt exit code: " + str(exit_code))
	cpu_cores_slider.value = _get_cpus_enabled()


# Used to read values from sysfs
func _read_sys(path: String) -> String:
	var output: Array = _do_exec("cat", [path])
	return output[0][0].strip_escapes()


# AMD APU TDP Database
# TODO: Not this
var amd_apu_database := {
	'AMD Athlon Silver 3020e with Radeon Graphics': {
		"max_tdp": 12,
		"min_tdp": 2,
		"max_boost": 6
	},
	'AMD Athlon Silver 3050e with Radeon Graphics': {
		"max_tdp": 12,
		"min_tdp": 2,
		"max_boost": 6
	},
	'AMD Ryzen 3 2200U with Radeon Graphics': {
		"max_tdp": 20,
		"min_tdp": 2,
		"max_boost": 5
	},
	'AMD Ryzen 3 2300U with Radeon Graphics': {
		"max_tdp": 25,
		"min_tdp": 2,
		"max_boost": 5
	},
	'AMD Ryzen 3 3200U with Radeon Graphics': {
		"max_tdp": 20,
		"min_tdp": 2,
		"max_boost": 5
	},
	'AMD Ryzen 3 3300U with Radeon Graphics': {
		"max_tdp": 25,
		"min_tdp": 2,
		"max_boost": 5
	},
	'AMD Ryzen 3 4300U with Radeon Graphics': {
		"max_tdp": 23,
		"min_tdp": 2,
		"max_boost": 2
	},
	'AMD Ryzen 3 5125C with Radeon Graphics': {
		"max_tdp": 15,
		"min_tdp": 2,
		"max_boost": 2
	},
	'AMD Ryzen 3 5300U with Radeon Graphics': {
		"max_tdp": 23,
		"min_tdp": 5,
		"max_boost": 2
	},
	'AMD Ryzen 3 5400U with Radeon Graphics': {
		"max_tdp": 23,
		"min_tdp": 5,
		"max_boost": 2
	},
	'AMD Ryzen 3 5425C with Radeon Graphics': {
		"max_tdp": 23,
		"min_tdp": 5,
		"max_boost": 2
	},
	'AMD Ryzen 3 5425U with Radeon Graphics': {
		"max_tdp": 15,
		"min_tdp": 2,
		"max_boost": 2
	},
	'AMD Ryzen 5 2500U with Radeon Graphics': {
		"max_tdp": 25,
		"min_tdp": 5,
		"max_boost": 5
	},
	'AMD Ryzen 5 3500U with Radeon Graphics': {
		"max_tdp": 30,
		"min_tdp": 5,
		"max_boost": 5
	},
	'AMD Ryzen 5 3550H with Radeon Graphics': {
		"max_tdp": 35,
		"min_tdp": 5,
		"max_boost": 5
	},
	'AMD Ryzen 5 4500U with Radeon Graphics': {
		"max_tdp": 28,
		"min_tdp": 5,
		"max_boost": 2
	},
	'AMD Ryzen 5 4600H with Radeon Graphics': {
		"max_tdp": 55,
		"min_tdp": 5,
		"max_boost": 11
	},
	'AMD Ryzen 5 4600HS with Radeon Graphics': {
		"max_tdp": 45,
		"min_tdp": 5,
		"max_boost": 11
	},
	'AMD Ryzen 5 4600U with Radeon Graphics': {
		"max_tdp": 33,
		"min_tdp": 5,
		"max_boost": 5
	},
	'AMD Ryzen 5 5500U with Radeon Graphics': {
		"max_tdp": 28,
		"min_tdp": 5,
		"max_boost": 2
	},
	'AMD Ryzen 5 5560U with Radeon Graphics': {
		"max_tdp": 28,
		"min_tdp": 3,
		"max_boost": 2
	},
	'AMD Ryzen 5 5600H with Radeon Graphics': {
		"max_tdp": 12,
		"min_tdp": 2,
		"max_boost": 6
	},
	'AMD Ryzen 5 5600HS with Radeon Graphics': {
		"max_tdp": 45,
		"min_tdp": 5,
		"max_boost": 11
	},
	'AMD Ryzen 5 5600U with Radeon Graphics': {
		"max_tdp": 33,
		"min_tdp": 5,
		"max_boost": 5
	},
	'AMD Ryzen 5 5625C with Radeon Graphics': {
		"max_tdp": 15,
		"min_tdp": 2,
		"max_boost": 2
	},
	'AMD Ryzen 5 5625U with Radeon Graphics': {
		"max_tdp": 33,
		"min_tdp": 5,
		"max_boost": 5
	},
	'AMD Ryzen 5 6600H with Radeon Graphics': {
		"max_tdp": 58,
		"min_tdp": 5,
		"max_boost": 10
	},
	'AMD Ryzen 5 6600HS with Radeon Graphics': {
		"max_tdp": 45,
		"min_tdp": 5,
		"max_boost": 11
	},
	'AMD Ryzen 5 6600U with Radeon Graphics': {
		"max_tdp": 33,
		"min_tdp": 5,
		"max_boost": 5
	},
	'AMD Ryzen 7 2700U with Radeon Graphics': {
		"max_tdp": 25,
		"min_tdp": 5,
		"max_boost": 5
	},
	'AMD Ryzen 7 3700U with Radeon Graphics': {
		"max_tdp": 30,
		"min_tdp": 5,
		"max_boost": 10
	},
	'AMD Ryzen 7 3750H with Radeon Graphics': {
		"max_tdp": 40,
		"min_tdp": 5,
		"max_boost": 10
	},
	'AMD Ryzen 7 4700U with Radeon Graphics': {
		"max_tdp": 12,
		"min_tdp": 2,
		"max_boost": 6
	},
	'AMD Ryzen 7 4800H with Radeon Graphics': {
		"max_tdp": 60,
		"min_tdp": 5,
		"max_boost": 8
	},
	'AMD Ryzen 7 4800HS with Radeon Graphics': {
		"max_tdp": 50,
		"min_tdp": 5,
		"max_boost": 8
	},
	'AMD Ryzen 7 4800U with Radeon Graphics': {
		"max_tdp": 33,
		"min_tdp": 5,
		"max_boost": 5
	},
	'AMD Ryzen 7 4980U with Radeon Graphics': {
		"max_tdp": 15,
		"min_tdp": 10,
		"max_boost": 10
	},
	'AMD Ryzen 7 5700U with Radeon Graphics': {
		"max_tdp": 28,
		"min_tdp": 5,
		"max_boost": 2
	},
	'AMD Ryzen 7 5800H with Radeon Graphics': {
		"max_tdp": 68,
		"min_tdp": 10,
		"max_boost": 4
	},
	'AMD Ryzen 7 5800HS with Radeon Graphics': {
		"max_tdp": 50,
		"min_tdp": 10,
		"max_boost": 8
	},
	'AMD Ryzen 7 5800U with Radeon Graphics': {
		"max_tdp": 33,
		"min_tdp": 5,
		"max_boost": 5
	},
	'AMD Ryzen 7 5825C with Radeon Graphics': {
		"max_tdp": 15,
		"min_tdp": 10,
		"max_boost": 10
	},
	'AMD Ryzen 7 5825U with Radeon Graphics': {
		"max_tdp": 33,
		"min_tdp": 5,
		"max_boost": 5
	},
	'AMD Ryzen 7 6800H with Radeon Graphics': {
		"max_tdp": 58,
		"min_tdp": 10,
		"max_boost": 10
	},
	'AMD Ryzen 7 6800HS with Radeon Graphics': {
		"max_tdp": 50,
		"min_tdp": 10,
		"max_boost": 8
	},
	'AMD Ryzen 7 6800U with Radeon Graphics': {
		"max_tdp": 33,
		"min_tdp": 5,
		"max_boost": 5
	},
	'AMD Ryzen 9 4900H with Radeon Graphics': {
		"max_tdp": 60,
		"min_tdp": 10,
		"max_boost": 8
	},
	'AMD Ryzen 9 4900HS with Radeon Graphics': {
		"max_tdp": 50,
		"min_tdp": 5,
		"max_boost": 8
	},
	'AMD Ryzen 9 5900HS with Radeon Graphics': {
		"max_tdp": 50,
		"min_tdp": 10,
		"max_boost": 8
	},
	'AMD Ryzen 9 5900HX with Radeon Graphics': {
		"max_tdp": 70,
		"min_tdp": 10,
		"max_boost": 20
	},
	'AMD Ryzen 9 5980HS with Radeon Graphics': {
		"max_tdp": 50,
		"min_tdp": 10,
		"max_boost": 8
	},
	'AMD Ryzen 9 5980HX with Radeon Graphics': {
		"max_tdp": 70,
		"min_tdp": 10,
		"max_boost": 20
	},
	'AMD Ryzen 9 6900HS with Radeon Graphics': {
		"max_tdp": 50,
		"min_tdp": 10,
		"max_boost": 8
	},
	'AMD Ryzen 9 6900HX with Radeon Graphics': {
		"max_tdp": 70,
		"min_tdp": 10,
		"max_boost": 20
	},
	'AMD Ryzen 9 6980HS with Radeon Graphics': {
		"max_tdp": 50,
		"min_tdp": 10,
		"max_boost": 8
	},
	'AMD Ryzen 9 6980HX with Radeon Graphics': {
		"max_tdp": 70,
		"min_tdp": 10,
		"max_boost": 20
	},
}

var intel_apu_database := {
	'11th Gen Intel(R) Core(TM) i5-1135G7 @ 2.40GHz': {
		"max_tdp": 28,
		"min_tdp": 12,
		"max_boost": 2
	},
	'11th Gen Intel(R) Core(TM) i7-1165G7 @ 2.80GHz': {
		"max_tdp": 28,
		"min_tdp": 12,
		"max_boost": 2
	},
	'11th Gen Intel(R) Core(TM) i7-1195G7 @ 2.90GHz': {
		"max_tdp": 28,
		"min_tdp": 12,
		"max_boost": 2
	},
}
