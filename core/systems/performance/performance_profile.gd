extends Resource

class_name PerformanceProfile

@export var name: String = "default"

@export var cpu_boost_enabled: bool
@export var cpu_core_count_current: float
@export var cpu_smt_enabled: bool
@export var gpu_freq_max_current: float
@export var gpu_freq_min_current: float
@export var gpu_manual_enabled: bool
@export var gpu_power_profile: int
@export var gpu_temp_current: float
@export var tdp_boost_current: float
@export var tdp_current: float
@export var thermal_mode: int
