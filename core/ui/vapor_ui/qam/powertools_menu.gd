extends VBoxContainer

var Platform := load("res://core/global/platform.tres")

const AMD_GPU_MIN_MHZ: float = 200
const POWERTOOLS_PATH : String = "/usr/share/opengamepadui/scripts/powertools"

@onready var performance_manager := load("res://core/systems/performance/performance_manager.tres") as PerformanceManager

var command_timer: Timer
var update_timer: Timer

@onready var cpu_boost_button := $CPUBoostButton
@onready var cpu_cores_slider := $CPUCoresSlider
@onready var gpu_freq_enable := $GPUFreqButton
@onready var gpu_freq_max_slider := $GPUFreqMaxSlider
@onready var gpu_freq_min_slider := $GPUFreqMinSlider
@onready var gpu_temp_slider := $GPUTempSlider
@onready var smt_button := $SMTButton
@onready var tdp_boost_slider := $TDPBoostSlider
@onready var tdp_slider := $TDPSlider
@onready var thermal_profile_dropdown := $ThermalProfileDropdown
@onready var platform : PlatformProvider = Platform.platform

var logger := Log.get_logger("PowerTools", Log.LEVEL.INFO)


# Called when the node enters the scene tree for the first time.
# Finds default values and current settings of the hardware.
func _ready():
	command_timer = Timer.new()
	command_timer.set_autostart(false)
	command_timer.set_one_shot(true)
	add_child(command_timer)
	
	_setup_interface()
#	update_timer = Timer.new()
#	update_timer.set_autostart(true)
#	update_timer.timeout.connect()
#	add_child(update_timer)


func _setup_interface() -> void:
	performance_manager.update_system_components()
	if performance_manager.cpu.smt_capable:
		_setup_cpu_core_range()
	if performance_manager.cpu.boost_capable:
		_setup_cpu_boost()
	if performance_manager.gpu.tdp_capable:
		_setup_tdp_range()
	if performance_manager.gpu.clk_capable:
		_setup_gpu_freq_range()
	if performance_manager.gpu.tj_temp_capable:
		_setup_gpu_temp_range()
	if performance_manager.gpu.thermal_mode_capable:
		_setup_thermal_profile()


func _update_interface() -> void:
	performance_manager.update_system_components()
	_update_cpu_core_range()
	_update_cpu_boost()
	_update_tdp_range()
	_update_gpu_freq_range()
	_update_gpu_temp_range()
	_update_thermal_profile()


# Overrides or sets the command_timer.timeout signal connection function and
# (re)starts the timer.
func _setup_callback_func(callable: Callable, arg: Variant) -> void:
	logger.debug("Setting callback func")
	_clear_callbacks()
	command_timer.timeout.connect(callable.bind(arg), CONNECT_ONE_SHOT)
	command_timer.start(.5)


# Removes any existing signal connections to command_timer.timeout.
func _clear_callbacks() -> void:
	for connection in command_timer.timeout.get_connections():
		var callable := connection["callable"] as Callable
		command_timer.timeout.disconnect(callable)


func _setup_cpu_core_range() -> void:
	if performance_manager.cpu_smt_enabled:
		smt_button.button_pressed = true
	smt_button.visible = true
	smt_button.toggled.connect(_on_toggle_smt)

	_update_cpu_core_range()
	cpu_cores_slider.visible = true
	cpu_cores_slider.value_changed.connect(_on_change_cpu_cores)


func _update_cpu_core_range() -> void:
	cpu_cores_slider.max_value = performance_manager.cpu_core_count
	cpu_cores_slider.value = performance_manager.cpu_core_count_current


func _setup_cpu_boost() -> void:
	if performance_manager.cpu.boost_capable:
		_update_cpu_boost()
		cpu_boost_button.toggled.connect(_on_toggle_cpu_boost)
		cpu_boost_button.visible = true


func _update_cpu_boost() -> void:
	if performance_manager.cpu_boost_enabled:
		cpu_boost_button.button_pressed = true
	else:
		cpu_boost_button.button_pressed = false


# Gets the TDP Range for the detected hardware.
func _setup_tdp_range() -> void:
	tdp_slider.max_value = performance_manager.gpu.max_tdp
	tdp_slider.min_value = performance_manager.gpu.min_tdp
	tdp_boost_slider.max_value = performance_manager.gpu.max_boost
	_update_tdp_range()
	tdp_boost_slider.value_changed.connect(_on_tdp_boost_value_changed)
	tdp_slider.value_changed.connect(_on_tdp_value_changed)
	tdp_boost_slider.visible = true
	tdp_slider.visible = true


func _update_tdp_range() -> void:
	tdp_slider.value = performance_manager.tdp_current
	tdp_boost_slider.value = performance_manager.tdp_boost_current


func _setup_gpu_freq_range() -> void:
	gpu_freq_max_slider.max_value = performance_manager.gpu_freq_max
	gpu_freq_max_slider.min_value = performance_manager.gpu_freq_min
	gpu_freq_min_slider.max_value = performance_manager.gpu_freq_max
	gpu_freq_min_slider.min_value = performance_manager.gpu_freq_min
	_update_gpu_freq_range()
	gpu_freq_enable.toggled.connect(_on_toggle_gpu_freq)
	gpu_freq_max_slider.value_changed.connect(_on_max_gpu_freq_changed)
	gpu_freq_min_slider.value_changed.connect(_on_min_gpu_freq_changed)
	gpu_freq_enable.visible = true


func _update_gpu_freq_range() -> void:
	gpu_freq_max_slider.value = performance_manager.gpu_freq_max_current
	gpu_freq_min_slider.value = performance_manager.gpu_freq_min_current


# Gets the TDP Range for the detected hardware.
func _setup_gpu_temp_range() -> void:
	_update_gpu_temp_range()
	gpu_temp_slider.value_changed.connect(_on_gpu_temp_limit_changed)
	gpu_temp_slider.visible = true


# Gets the TDP Range for the detected hardware.
func _update_gpu_temp_range() -> void:
	gpu_temp_slider.value = performance_manager.gpu_temp_current


func _setup_thermal_profile() -> void:
	thermal_profile_dropdown.clear()
	thermal_profile_dropdown.add_item("Balanced", 0)
	thermal_profile_dropdown.add_item("Performance", 1)
	thermal_profile_dropdown.add_item("Silent", 2)
	_update_thermal_profile()
	thermal_profile_dropdown.visible = true
	thermal_profile_dropdown.item_selected.connect(_on_thermal_policy_changed)


func _update_thermal_profile() -> void:
	thermal_profile_dropdown.select(performance_manager.thermal_mode)


func _on_change_cpu_cores(value: float)-> void:
	_setup_callback_func(performance_manager.set_cpu_core_count, value)


# Sets the T-junction temp using ryzenadj.
func _on_gpu_temp_limit_changed(value: float) -> void:
	_setup_callback_func(performance_manager.set_gpu_temp_current, value)


# Called when gpu_freq_max_slider.value is changed.
func _on_max_gpu_freq_changed(value: float) -> void:
	if value < gpu_freq_min_slider.value:
		gpu_freq_min_slider.value = value
	_setup_callback_func(performance_manager.set_gpu_freq_max, value)


# Called when gpu_freq_min_slider.value is changed.
func _on_min_gpu_freq_changed(value: float) -> void:
	if value > gpu_freq_max_slider.value:
		gpu_freq_max_slider.value = value
	_setup_callback_func(performance_manager.set_gpu_freq_min, value)


# Called to set the flow and fast boost TDP
func _on_tdp_boost_value_changed(value: float) -> void:
	_setup_callback_func(performance_manager.set_tdp_boost_value, value)


# Called to set the base average TDP
func _on_tdp_value_changed(value: float) -> void:
	_setup_callback_func(performance_manager.set_tdp_value, value)


# Sets the thermal throttle policy for ASUS devices.
func _on_thermal_policy_changed(index: int) -> void:
	_setup_callback_func(performance_manager.set_thermal_mode, index)


# Called to toggle cpu boost
func _on_toggle_cpu_boost(state: bool) -> void:
	_setup_callback_func(performance_manager.set_cpu_boost_enabled, state)


# Called to toggle auo/manual gpu clocking
func _on_toggle_gpu_freq(state: bool) -> void:
	_setup_callback_func(performance_manager.set_gpu_manual_mode_enabled, state)


# Called to toggle SMT
func _on_toggle_smt(state: bool) -> void:
	_setup_callback_func(performance_manager.set_cpu_smt_enabled, state)

