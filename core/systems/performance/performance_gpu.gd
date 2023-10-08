extends RefCounted
class_name PerformanceGPU

## GPU performance implementation class
##
## This should be overridden by a child class with implementations for controlling
## GPU performance.

const POWERTOOLS_PATH := "/usr/share/opengamepadui/scripts/powertools"

enum POWER_PROFILE {
	MAX_PERFORMANCE,
	POWER_SAVINGS,
}

enum THERMAL_THROTTLE_POLICY {
	SILENT,
	BALANCED,
	PERFORMANCE,
}


## Returns the current TDP values
func get_tdp() -> Info:
	return null


## Gets the clock limits of the gpu
func get_gpu_clock_limits() -> void:
	pass


## Gets the current clock of the gpu
func get_gpu_clock_current() -> void:
	pass


## Sets the GPU frequency range to the given values
func set_gpu_freq(freq_min: int, freq_max: int) -> int:
	return -1


## Called when gpu_freq_max_slider.value is changed.
func set_gpu_freq_max(value: float) -> void:
	pass


## Called to set the minimum gpu clock is changed.
func set_gpu_freq_min(value: float) -> void:
	pass


## Called to toggle auto/manual gpu clocking
func set_gpu_manual_enabled(state: bool) -> void:
	pass


## Called to set the GPU Power Profile
func set_gpu_power_profile(mode: POWER_PROFILE) -> void:
	pass


## Called to set the GPU Thermal Throttle Limit
func set_gpu_temp_current(value: float) -> void:
	pass


## Called to set the TFP boost limit.
func set_tdp_boost_value(value: float) -> void:
	pass


## Called to set the TDP average limit.
func set_tdp_value(value: float) -> void:
	pass


## Sets the thermal throttle mode for ASUS devices.
func set_thermal_profile(index: THERMAL_THROTTLE_POLICY) -> void:
	pass


func enable_performance_write() -> void:
	pass


## Used to read values from sysfs
func _read_sys(path: String) -> String:
	var file := FileAccess.open(path, FileAccess.READ)
	var length := file.get_length()
	var bytes := file.get_buffer(length)
	return bytes.get_string_from_utf8().strip_escapes()


## Structure for holding GPU performance info
class Info:
	var gpu_freq_max_current: float
	var gpu_freq_min_current: float
	var gpu_manual_enabled: bool
	var gpu_power_profile: int
	var gpu_temp_current: float
	var tdp_boost_current: float
	var tdp_current: float
	var thermal_profile: int

	func _to_string() -> String:
		return "<PerformanceGPUInfo: "\
			+ "gpu_freq_max_current: " + str(gpu_freq_max_current) +  ", " \
			+ "gpu_freq_min_current: " + str(gpu_freq_min_current) +  ", " \
			+ "gpu_manual_enabled: " + str(gpu_manual_enabled) +  ", " \
			+ "gpu_power_profile: " + str(gpu_power_profile) +  ", " \
			+ "gpu_temp_current: " + str(gpu_temp_current) +  ", " \
			+ "tdp_boost_current: " + str(tdp_boost_current) +  ", " \
			+ "tdp_current: " + str(tdp_current) +  ", " \
			+ "thermal_profile: " + str(thermal_profile) + ">"
