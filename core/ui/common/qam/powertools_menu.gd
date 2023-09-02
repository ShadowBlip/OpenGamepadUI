extends VBoxContainer

const AMD_GPU_MIN_MHZ: float = 200
const POWERTOOLS_PATH : String = "/usr/share/opengamepadui/scripts/powertools"

@onready var performance_manager := load("res://core/systems/performance/performance_manager.tres") as PerformanceManager
@onready var launch_manager := load("res://core/global/launch_manager.tres") as LaunchManager

var command_timer: Timer
var update_timer: Timer

@onready var cpu_boost_button := $CPUBoostButton as Toggle
@onready var cpu_cores_slider := $CPUCoresSlider as ValueSlider
@onready var gpu_freq_enable := $GPUFreqButton as Toggle
@onready var gpu_freq_max_slider := $GPUFreqMaxSlider as ValueSlider
@onready var gpu_freq_min_slider := $GPUFreqMinSlider as ValueSlider
@onready var gpu_temp_slider := $GPUTempSlider as ValueSlider
@onready var power_profile_dropdown := $PowerProfileDropdown as Dropdown
@onready var tdp_boost_slider := $TDPBoostSlider as ValueSlider
@onready var tdp_slider := $TDPSlider as ValueSlider
@onready var thermal_profile_dropdown := $ThermalProfileDropdown as Dropdown
@onready var smt_button := $SMTButton as Toggle

var logger := Log.get_logger("PowerTools", Log.LEVEL.INFO)


# Called when the node enters the scene tree for the first time.
# Finds default values and current settings of the hardware.
func _ready() -> void:
	await performance_manager.read_system_components()
	_setup_interface()
	performance_manager.load_profile()
	launch_manager.app_switched.connect(_on_app_switched)

	command_timer = Timer.new()
	command_timer.set_autostart(false)
	command_timer.set_one_shot(true)
	add_child(command_timer)


func _setup_interface() -> void:
	if performance_manager.cpu.smt_capable:
		logger.debug("CPU is SMT Capable")
		_setup_cpu_core_range()
	if performance_manager.cpu.boost_capable:
		logger.debug("CPU is Boost Capable")
		_setup_cpu_boost()
	if performance_manager.gpu.tdp_capable:
		logger.debug("SOC is TDP Capable")
		_setup_tdp_range()
	if performance_manager.gpu.clk_capable:
		logger.debug("GPU is Reclock Capable")
		_setup_gpu_freq_range()
	if performance_manager.gpu.power_profile_capable:
		logger.debug("GPU is Power Profile Capable")
		_setup_power_profile()
	if performance_manager.gpu.tj_temp_capable:
		logger.debug("GPU is TJ Temp Configurable")
		_setup_gpu_temp()
	if performance_manager.gpu.thermal_profile_capable:
		logger.debug("GPU is Thermal Mode Configurable")
		_setup_thermal_profile()


# Overrides or sets the command_timer.timeout signal connection function and
# (re)starts the timer.
func _setup_callback_func(callable: Callable, arg: Variant) -> void:
	logger.debug("Setting callback func")
	_clear_callbacks()
	command_timer.timeout.connect(callable.bind(arg), CONNECT_ONE_SHOT)
	command_timer.start(.65)


# Removes any existing signal connections to command_timer.timeout.
func _clear_callbacks() -> void:
	for connection in command_timer.timeout.get_connections():
		var callable := connection["callable"] as Callable
		command_timer.timeout.disconnect(callable)


func _on_app_switched(from: RunningApp, to: RunningApp) -> void:
	var app_name = "default"
	if to:
		app_name = to.launch_item.name
	logger.debug("Detected app switch to " + app_name)
	performance_manager.on_app_switched(from, to)


func _setup_cpu_boost() -> void:
	cpu_boost_button.visible = true
	cpu_boost_button.toggled.connect(_on_cpu_boost_button_toggled)
	performance_manager.cpu_boost_toggled.connect(_update_cpu_boost)


func _update_cpu_boost(state: bool) -> void:
	logger.debug("Received update for cpu_boost " +str(state))
	cpu_boost_button.button_pressed = state


func _setup_cpu_core_range() -> void:
	smt_button.visible = true
	cpu_cores_slider.visible = true
	smt_button.toggled.connect(_on_smt_button_toggled)
	cpu_cores_slider.value_changed.connect(_on_cpu_cores_slider_changed)
	performance_manager.smt_toggled.connect(_update_smt_enabled)
	performance_manager.cpu_cores_available_updated.connect(_update_cpu_cores_available)
	performance_manager.cpu_cores_used.connect(_update_cpu_cores_used)


func _update_smt_enabled(smt_enabled) -> void:
	logger.debug("Received update for cpu_core_range: " + str(smt_enabled))
	smt_button.button_pressed = smt_enabled


func _update_cpu_cores_available(available: int) -> void:
	logger.debug("Received update for cpu_cores_available: " + str(available))
	cpu_cores_slider.max_value = available


func _update_cpu_cores_used(count: int) -> void:
	logger.debug("Received update for cpu_cores_used: "+ str(count))
	cpu_cores_slider.value = count


# Gets the TDP Range for the detected hardware.
func _setup_tdp_range() -> void:
	tdp_slider.max_value = performance_manager.gpu.max_tdp
	tdp_slider.min_value = performance_manager.gpu.min_tdp
	tdp_boost_slider.max_value = performance_manager.gpu.max_boost
	tdp_boost_slider.visible = true
	tdp_slider.visible = true
	tdp_boost_slider.value_changed.connect(_on_tdp_boost_value_slider_changed)
	tdp_slider.value_changed.connect(_on_tdp_value_slider_changed)
	performance_manager.tdp_updated.connect(_update_tdp)


func _update_tdp(tdp_current: float, boost_current: float) -> void:
	logger.debug("Received update for tdp_updated: " + str(tdp_current) + "  " + str(boost_current))
	tdp_slider.value = tdp_current
	tdp_boost_slider.value = boost_current


func _setup_gpu_freq_range() -> void:
	gpu_freq_enable.visible = true
	gpu_freq_enable.toggled.connect(_on_gpu_freq_enable_button_toggled)
	gpu_freq_max_slider.value_changed.connect(_on_max_gpu_freq_slider_changed)
	gpu_freq_min_slider.value_changed.connect(_on_min_gpu_freq_slider_changed)
	performance_manager.gpu_clk_limits_updated.connect(_update_gpu_freq_range)
	performance_manager.gpu_manual_enabled_updated.connect(_update_gpu_manual_enabled)


func _update_gpu_freq_range(min: float, max: float, current_min: float, current_max: float)-> void:
	logger.debug("Received update for gpu_clk_limits_updated: " + str(min) + "  " + str(max) + "  " + str(current_min) + "  " + str(current_max)) 
	gpu_freq_max_slider.max_value = max
	gpu_freq_max_slider.min_value = min
	gpu_freq_min_slider.max_value = max
	gpu_freq_min_slider.min_value = min
	gpu_freq_max_slider.value = current_max
	gpu_freq_min_slider.value = current_min


func _update_gpu_manual_enabled(state: bool) -> void:
	logger.debug("Received update for gpu_manual_enabled: " + str(state)) 
	gpu_freq_enable.button_pressed = state
	gpu_freq_max_slider.visible = state
	gpu_freq_min_slider.visible = state


# Gets the TDP Range for the detected hardware.
func _setup_gpu_temp() -> void:
	gpu_temp_slider.visible = true
	gpu_temp_slider.value_changed.connect(_on_gpu_temp_limit_slider_changed)
	performance_manager.gpu_temp_limit_updated.connect(_update_gpu_temp)


# Gets the TDP Range for the detected hardware.
func _update_gpu_temp(current: float) -> void:
	logger.debug("Received update for gpu_temp_limit_updated: " +str(current))
	gpu_temp_slider.value = current


func _setup_power_profile() -> void:
	power_profile_dropdown.visible = true
	power_profile_dropdown.clear()
	power_profile_dropdown.add_item("Max Performance", 0)
	power_profile_dropdown.add_item("Power Saving", 1)
	power_profile_dropdown.item_selected.connect(_on_power_profile_dropdown_changed)
	performance_manager.gpu_power_profile_updated.connect(_update_power_profile)


func _update_power_profile(index: int) -> void:
	logger.debug("Received update for gpu_power_profile_updated: " +str(index))
	power_profile_dropdown.select(index)
	match index:
		0:
			logger.debug("Power Profile at Max Performance")
		1:
			logger.debug("Power Profile at Power Saving")


func _setup_thermal_profile() -> void:
	thermal_profile_dropdown.visible = true
	thermal_profile_dropdown.clear()
	thermal_profile_dropdown.add_item("Balanced", 0)
	thermal_profile_dropdown.add_item("Performance", 1)
	thermal_profile_dropdown.add_item("Silent", 2)
	thermal_profile_dropdown.item_selected.connect(_on_thermal_policy_dropdown_changed)
	performance_manager.thermal_profile_updated.connect(_update_thermal_profile)


func _update_thermal_profile(index: int) -> void:
	logger.debug("Received update for thermal_profile_updated: " +str(index))
	thermal_profile_dropdown.select(index)
	match index:
		0:
			logger.debug("Thermal throttle policy currently at Balanced")
		1:
			logger.debug("Thermal throttle policy currently at Performance")
		2:
			logger.debug("Thermal throttle policy currently at Silent")


### UI Callback functions

func _on_cpu_cores_slider_changed(value: float)-> void:
	if value == performance_manager.cpu_core_count_current:
		return
	logger.debug("cpu_cores_slider_changed: " + str (value))
	_setup_callback_func(performance_manager.set_cpu_core_count, value)


# Called to toggle cpu boost
func _on_cpu_boost_button_toggled(state: bool) -> void:
	if state == performance_manager.cpu_boost_enabled:
		return
	logger.debug("cpu_boost_button_toggled: " + str (state))
	_setup_callback_func(performance_manager.set_cpu_boost_enabled, state)


# Called to toggle auo/manual gpu clocking
func _on_gpu_freq_enable_button_toggled(state: bool) -> void:
	if state == performance_manager.gpu_manual_enabled:
		return
	logger.debug("gpu_freq_enable_button_toggled: " + str (state))
	_setup_callback_func(performance_manager.set_gpu_manual_enabled, state)


# Sets the T-junction temp using ryzenadj.
func _on_gpu_temp_limit_slider_changed(value: float) -> void:
	if value == performance_manager.gpu_temp_current:
		return
	logger.debug("gpu_temp_limit_slider_changed: " + str (value))
	_setup_callback_func(performance_manager.set_gpu_temp_current, value)


# Called when gpu_freq_max_slider.value is changed.
func _on_max_gpu_freq_slider_changed(value: float) -> void:
	if value == performance_manager.gpu_freq_max_current:
		return
	logger.debug("max_gpu_freq_slider_changed: " + str (value))
	if value < gpu_freq_min_slider.value:
		gpu_freq_min_slider.value = value
	_setup_callback_func(performance_manager.set_gpu_freq_max, value)


# Called when gpu_freq_min_slider.value is changed.
func _on_min_gpu_freq_slider_changed(value: float) -> void:
	if value == performance_manager.gpu_freq_min_current:
		return
	logger.debug("min_gpu_freq_slider_changed: " + str (value))
	if value > gpu_freq_max_slider.value:
		gpu_freq_max_slider.value = value
	_setup_callback_func(performance_manager.set_gpu_freq_min, value)


func _on_power_profile_dropdown_changed(index: int) -> void:
	if index == performance_manager.gpu_power_profile:
		return
	logger.debug("power_profile_dropdown_changed: " + str (index))
	_setup_callback_func(performance_manager.set_gpu_power_profile, index)


# Called to set the flow and fast boost TDP
func _on_tdp_boost_value_slider_changed(value: float) -> void:
	if value == performance_manager.tdp_boost_current:
		return
	logger.debug("tdp_boost_value_slider_changed: " + str (value))
	_setup_callback_func(performance_manager.set_tdp_boost_value, value)


# Called to set the base average TDP
func _on_tdp_value_slider_changed(value: float) -> void:
	if value == performance_manager.tdp_current:
		return
	logger.debug("tdp_value_slider_changed: " + str (value))
	_setup_callback_func(performance_manager.set_tdp_value, value)


# Sets the thermal throttle policy for ASUS devices.
func _on_thermal_policy_dropdown_changed(index: int) -> void:
	if index == performance_manager.thermal_mode:
		return
	logger.debug("thermal_policy_dropdown_changed: " + str (index))
	_setup_callback_func(performance_manager.set_thermal_mode, index)


# Called to toggle SMT
func _on_smt_button_toggled(state: bool) -> void:
	if state == performance_manager.cpu_smt_enabled:
		return
	logger.debug("smt_button_toggled: " + str (state))
	_setup_callback_func(performance_manager.set_cpu_smt_enabled, state)
