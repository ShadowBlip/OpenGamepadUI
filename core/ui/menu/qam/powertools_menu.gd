extends VBoxContainer

const powertools_path : String = "/etc/handypt/powertools"

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

@onready var cpu_boost_button := $CPUBoostButton
@onready var cpu_cores_slider := $CPUCoresSlider
@onready var gpu_freq_enable := $GPUFreqButton
@onready var gpu_freq_max_slider := $GPUFreqMaxSlider
@onready var gpu_freq_min_slider := $GPUFreqMinSlider
@onready var gpu_temp_slider := $GPUTempSlider
@onready var smt_button := $SMTButton
@onready var tdp_boost_slider := $TDPBoostSlider
@onready var tdp_slider := $TDPSlider
@onready var thread_group := ThreadGroup.new()

# Called when the node enters the scene tree for the first time.
# Finds default values and current settings of the hardware.
func _ready():
	thread_group.start()
	await _get_system_components()

	# Set UI capabilities from system capabilities
	cpu_boost_button.visible = boost_capable
	cpu_cores_slider.visible = ht_capable
	gpu_freq_enable.visible = gpu_clk_capable
	gpu_temp_slider.visible = tj_temp_capable
	smt_button.visible = ht_capable
	tdp_boost_slider.visible = tdp_capable
	tdp_slider.visible = tdp_capable

	if tdp_capable:
		await _get_tdp_range()
		await _get_current_tdp_settings()
		tdp_boost_slider.value_changed.connect(_on_tdp_boost_value_changed)
		tdp_slider.value_changed.connect(_on_tdp_value_changed)

	if gpu_clk_capable:
		await _get_gpu_perf_level()
		gpu_freq_enable.toggled.connect(_on_toggle_gpu_freq)
		gpu_freq_max_slider.value_changed.connect(_on_max_gpu_freq_changed)
		gpu_freq_min_slider.value_changed.connect(_on_min_gpu_freq_changed)
		# Set write mode for power_dpm_force_performance_level
		var output: Array = await thread_group.exec(_do_exec.bind(powertools_path, ["pdfpl", "write"]))

	if ht_capable:
		if await read_sys("/sys/devices/system/cpu/smt/control") == "on":
			smt_button.button_pressed = true
		await _get_cpu_count()
		cpu_cores_slider.value_changed.connect(_on_change_cpu_cores)
		smt_button.toggled.connect(_on_toggle_smt)

	if boost_capable:
		if await read_sys("/sys/devices/system/cpu/cpufreq/boost") == "1":
			cpu_boost_button.button_pressed = true
		cpu_boost_button.toggled.connect(_on_toggle_cpu_boost)

	if tj_temp_capable:
		gpu_temp_slider.value_changed.connect(_on_gpu_temp_limit_changed)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


# Thread safe method of calling OS.execute
func _do_exec(command: String, args: Array)-> Array:
	var output = []
	var exit_code := OS.execute(command, args, output)
	return [output, exit_code]


# Gets the total number of cores. If SMT is disabled that value is halved.
func _get_cpu_count() -> bool:
	var args = ["-c", "ls /sys/bus/cpu/devices/ | wc -l"]
	var output: Array = await thread_group.exec(_do_exec.bind("bash", args))
	var exit_code = output[1]
	if exit_code:
		return false
	var result := output[0][0].split("\n") as Array
	core_count = int(result[0])
	cpu_cores_slider.max_value = core_count
	if not smt_button.button_pressed:
		cpu_cores_slider.max_value = core_count / 2
	cpu_cores_slider.value = await _get_cpus_enabled()
	return true


# Loops through all cores and returns the count of enabled cores.
func _get_cpus_enabled() -> int:
	pass
	var active_cpus := 1
	for i in range(1, core_count):
		var args = ["-c", "cat /sys/bus/cpu/devices/cpu"+str(i)+"/online"]
		var output: Array = await thread_group.exec(_do_exec.bind("bash", args))
		active_cpus += int(output[0][0].strip_edges())
	return active_cpus


# Reads the pp_os_clk_voltage from sysfs and returns the values. This file will 
# be empty if not in "manual" for pp_od_performance_level.
func _get_gpu_clk_limits() -> bool:
	var args := ["/sys/class/drm/card0/device/pp_od_clk_voltage"]
	var output: Array = await thread_group.exec(_do_exec.bind("cat", args))
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
	return true


# Retrieves the current TDP from ryzenadj.
# TODO: make APU's a separate function, and add Intel and AMD GPU methods.
func _get_current_tdp_settings() -> bool:
	var output: Array = await thread_group.exec(_do_exec.bind(powertools_path, ["ryzenadj", "-i"]))
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
		await _on_tdp_boost_value_changed(tdp_boost_slider.max_value)
	elif current_boost <= 0:
		await _on_tdp_boost_value_changed(0)
	else:
		await _on_tdp_boost_value_changed(current_boost)
	return true	


# Called to get the current performance level and set the UI as needed.
func _get_gpu_perf_level() -> void:
	var performace_level: String = await read_sys("/sys/class/drm/card0/device/power_dpm_force_performance_level")
	if performace_level == "manual":
		gpu_freq_enable.button_pressed = true
		gpu_freq_max_slider.visible = true
		gpu_freq_min_slider.visible = true
		await _get_gpu_clk_limits()


# Reads the hardware. Only supports AMD APU's currently.
# TODO: Support more than AMD APU's
func _get_system_components() -> bool:
	var args = ["-c", "lscpu"]
	var output: Array = await thread_group.exec(_do_exec.bind("bash", args))
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
	# TODO: This is lazy and doesn't support dedicated graphics paired with APU's.
	if cpu_model in amd_apu_database:
		gpu_model = cpu_model
		gpu_vendor = cpu_vendor
		tdp_capable = true
		tj_temp_capable = true
		gpu_clk_capable = true
	if gpu_model == "" or gpu_vendor == "":
		return false
	return true


# Gets the TDP Range for the detected hardware.
# TODO: Support more than AMD APU's
func _get_tdp_range() -> bool:
	if cpu_vendor == "AuthenticAMD":
		if cpu_model in amd_apu_database:
			return _get_tdp_range_amd_apu()
	return false


# Gets the TDP range for the detected APU
func _get_tdp_range_amd_apu() -> bool:
	var apu_data := amd_apu_database[cpu_model] as Dictionary
	tdp_boost_slider.max_value = apu_data["max_boost"]
	tdp_slider.max_value = apu_data["max_tdp"]
	tdp_slider.min_value = apu_data["min_tdp"]
	return true


# Called to disable/enable cores by count as specified by value. 
func _on_change_cpu_cores(value: float):
	if smt_button.button_pressed:
		for cpu_no in range(1, core_count):
			var output := []
			if cpu_no > cpu_cores_slider.value - 1:
				output = await thread_group.exec(_do_exec.bind(powertools_path, ["togglecpu", str(cpu_no), "0"]))
			else:
				output = await thread_group.exec(_do_exec.bind(powertools_path, ["togglecpu", str(cpu_no), "1"]))

	else:
		for i in range(1, core_count/2):
			var cpu_no := i * 2
			var output := []
			if cpu_no > cpu_cores_slider.value * 2 - 1:
				output = await thread_group.exec(_do_exec.bind(powertools_path, ["togglecpu", str(cpu_no), "0"]))
			else:
				output = await thread_group.exec(_do_exec.bind(powertools_path, ["togglecpu", str(cpu_no), "1"]))


# Sets the tjunction temp using ryzenadj.
# TODO: Support more than AMD APU's
func _on_gpu_temp_limit_changed(value: float) -> bool:
	var output = await thread_group.exec(_do_exec.bind(powertools_path, ["ryzenadj", "-f", str(value)]))
	var exit_code = output[1]
	if exit_code:
		return false
	return true


# Called to set the max GPU freq
# TODO: Support more than AMD APU's
func _on_max_gpu_freq_changed(value: float) -> bool:
	if value < gpu_freq_min_slider.value:
		gpu_freq_min_slider.value = value
	var args = ["gpuclk", "1", str(value)]
	var output: Array = await thread_group.exec(_do_exec.bind(powertools_path, args))
	var exit_code = output[1]
	if exit_code:
		return false
	return true


# Called to set the min GPU freq
# TODO: Support more than AMD APU's
func _on_min_gpu_freq_changed(value: float) -> bool:
	if value > gpu_freq_max_slider.value:
		gpu_freq_max_slider.value = value
	var args = ["gpuclk", "0", str(value)]
	var output: Array = await thread_group.exec(_do_exec.bind(powertools_path, args))
	var exit_code = output[1]
	if exit_code:
		return false
	return true


# Called to set the slow/fastPPT in ryzenadj
# TODO: Support more than AMD APU's
func _on_tdp_boost_value_changed(value: float) -> bool:
	var success: bool = true
	var slowPPT: float = (floor(value/2) + tdp_slider.value) * 1000
	var fastPPT: float = (value + tdp_slider.value) * 1000
	var output: Array = await thread_group.exec(_do_exec.bind(powertools_path, ["ryzenadj", "-b", str(fastPPT)]))
	var exit_code = output[1]
	if exit_code:
		success = false
	output = await thread_group.exec(_do_exec.bind(powertools_path, ["ryzenadj", "-c", str(fastPPT)]))
	exit_code = output[1]
	if exit_code:
		success = false
	return success


# Called to set the STAPM in ryzenadj
# TODO: Support more than AMD APU's
func _on_tdp_value_changed(value: float) -> bool:
	var output: Array = await thread_group.exec(_do_exec.bind(powertools_path, ["ryzenadj", "-a", str(value * 1000)]))
	var exit_code = output[1]
	if exit_code:
		return false
	return await _on_tdp_boost_value_changed(tdp_boost_slider.value)


# Called to toggle cpu boost
func _on_toggle_cpu_boost(state: bool) -> bool:
	var args := ["cpuBoost", "0"]
	if state:
		args = ["cpuBoost", "1"]
	var output: Array = await thread_group.exec(_do_exec.bind(powertools_path, args))
	var exit_code = output[1]
	if exit_code:
		return false
	return true


# Called to toggle auo/manual gpu clocking
# TODO: Support more than AMD APU's
func _on_toggle_gpu_freq(state: bool):
	var args := ["pdfpl", "auto"]
	if state:
		args = ["pdfpl", "manual"]
	var output: Array = await thread_group.exec(_do_exec.bind(powertools_path, args))
	var exit_code = output[1]
	if exit_code:
		return false
	gpu_freq_max_slider.visible = state
	gpu_freq_min_slider.visible = state
	if state:
		await _get_gpu_clk_limits()
	return true


# Called to toggle SMT
func _on_toggle_smt(state: bool):
	var args := []
	if state:
		args = ["smt", "on"]
		cpu_cores_slider.max_value = core_count
	else:
		args = ["smt", "off"]
		cpu_cores_slider.max_value = core_count / 2
	var output: Array = await thread_group.exec(_do_exec.bind(powertools_path, args))
	var exit_code = output[1]
	if exit_code:
		return false
	cpu_cores_slider.value = await _get_cpus_enabled()
	return true


# Used to read values from sysfs
func read_sys(path: String) -> String:
	var output: Array = await thread_group.exec(_do_exec.bind("cat", [path]))
	return output[0][0].strip_escapes()


# AMD APU TDP Database
# TODO: Not this
var amd_apu_database := {'AMD Athlon Silver 3020e with Radeon Graphics': { 
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
		}
}
