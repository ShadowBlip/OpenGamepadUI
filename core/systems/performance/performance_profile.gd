extends Resource

class_name PerformanceProfile

@export var name: String = "default"

@export var cpu_boost_enabled: bool
@export var cpu_core_count_current: int
@export var cpu_smt_enabled: bool
@export var gpu_freq_max_current: float
@export var gpu_freq_min_current: float
@export var gpu_manual_enabled: bool
@export var gpu_power_profile: int
@export var gpu_temp_current: float
@export var tdp_boost_current: float
@export var tdp_current: float
@export var thermal_profile: int


func _to_string() -> String:
	return "<PerformanceProfile: " + name +  ", " \
		+ "cpu_boost_enabled: " + str(cpu_boost_enabled) +  ", " \
		+ "cpu_core_count_current: " + str(cpu_core_count_current) +  ", " \
		+ "cpu_smt_enabled: " + str(cpu_smt_enabled) +  ", " \
		+ "gpu_freq_max_current: " + str(gpu_freq_max_current) +  ", " \
		+ "gpu_freq_min_current: " + str(gpu_freq_min_current) +  ", " \
		+ "gpu_manual_enabled: " + str(gpu_manual_enabled) +  ", " \
		+ "gpu_power_profile: " + str(gpu_power_profile) +  ", " \
		+ "gpu_temp_current: " + str(gpu_temp_current) +  ", " \
		+ "tdp_boost_current: " + str(tdp_boost_current) +  ", " \
		+ "tdp_current: " + str(tdp_current) +  ", " \
		+ "thermal_profile: " + str(thermal_profile) + ">"
