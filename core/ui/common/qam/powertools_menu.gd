extends VBoxContainer

@onready var performance_manager := load("res://core/systems/performance/performance_manager.tres") as PerformanceManager
@onready var launch_manager := load("res://core/global/launch_manager.tres") as LaunchManager


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
@onready var cpu_label := $CPUSectionLabel as Control
@onready var gpu_label := $GPUSectionLabel as Control
@onready var wait_label := $WaitLabel as Control
@onready var _to_visible: Array[Control] = [cpu_label, gpu_label]

var command_timer: Timer
var logger := Log.get_logger("PowerTools", Log.LEVEL.INFO)


# Called when the node enters the scene tree for the first time.
# Finds default values and current settings of the hardware.
func _ready() -> void:
	
	if not performance_manager.initialized:
		performance_manager.pm_ready.connect(_set_initial_visibility.bind(performance_manager.profile), CONNECT_ONE_SHOT)
	else:
		_set_initial_visibility(performance_manager.profile)

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

	launch_manager.app_switched.connect(_on_app_switched)


func _set_initial_visibility(_profile: PerformanceProfile) -> void:
	_setup_interface()
	wait_label.visible = false
	for control in _to_visible:
		control.visible = true
		logger.debug(control.name + " set to visible.")
	performance_manager.emit_profile_signals()


# Overrides or sets the command_timer.timeout signal connection function and
# (re)starts the timer.
func _setup_callback_func(callable: Callable, arg: Variant, delay: float = 1.2) -> void:
	logger.debug("Setting callback func: " + callable.get_method() + " args: " + str(arg))
	_clear_callbacks(callable)
	command_timer.timeout.connect(callable.bind(arg), CONNECT_ONE_SHOT)
	command_timer.start(delay)


# Removes any existing signal connections to command_timer.timeout.
func _clear_callbacks(callable: Callable) -> void:
	for connection in command_timer.timeout.get_connections():
		var old_callable := connection["callable"] as Callable
		# Only clear methods that interfere with eachother. Otherwise we might miss
		# a callback if multiple UI elements are used in less time than the delay
		# in _setup_callback_func. (I.E. set toggle after slider)
		if old_callable.get_method() == callable.get_method():
			command_timer.timeout.disconnect(old_callable)
			logger.debug("Removed " + callable.get_method() + " as callback func.")


func _on_app_switched(from: RunningApp, to: RunningApp) -> void:
	var app_name = "default"
	if to:
		app_name = to.launch_item.name
	logger.debug("Detected app switch to " + app_name)
	performance_manager.on_app_switched(from, to)


func _setup_cpu_boost() -> void:
	_to_visible.append(cpu_boost_button)
	cpu_boost_button.toggled.connect(_on_cpu_boost_button_toggled)
	performance_manager.cpu_boost_toggled.connect(_update_cpu_boost)


func _update_cpu_boost(state: bool) -> void:
	logger.debug("Received update for cpu_boost " +str(state))
	cpu_boost_button.button_pressed = state


func _setup_cpu_core_range() -> void:
	_to_visible.append(smt_button)
	_to_visible.append(cpu_cores_slider)
	smt_button.toggled.connect(_on_smt_button_toggled)
	cpu_cores_slider.value_changed.connect(_on_cpu_cores_slider_changed)
	performance_manager.smt_toggled.connect(_update_smt_enabled)
	performance_manager.cpu_cores_available_updated.connect(_update_cpu_cores_available)
	performance_manager.cpu_cores_used.connect(_update_cpu_cores_used)


func _update_smt_enabled(smt_enabled) -> void:
	logger.debug("Received update for smt_enabled: " + str(smt_enabled))
	smt_button.button_pressed = smt_enabled


func _update_cpu_cores_available(available: int) -> void:
	logger.debug("Received update for cpu_cores_available: " + str(available))
	cpu_cores_slider.max_value = available


func _update_cpu_cores_used(count: int) -> void:
	logger.debug("Received update for cpu_cores_used: "+ str(count))
	cpu_cores_slider.value = count


# Gets the TDP Range for the detected hardware.
func _setup_tdp_range() -> void:
	_to_visible.append(tdp_boost_slider)
	_to_visible.append(tdp_slider)
	tdp_slider.max_value = performance_manager.gpu.tdp_max
	tdp_slider.min_value = performance_manager.gpu.tdp_min
	tdp_boost_slider.max_value = performance_manager.gpu.max_boost
	tdp_boost_slider.value_changed.connect(_on_tdp_boost_value_slider_changed)
	tdp_slider.value_changed.connect(_on_tdp_value_slider_changed)
	performance_manager.tdp_updated.connect(_update_tdp)


func _update_tdp(tdp_current: float, boost_current: float) -> void:
	logger.debug("Received update for tdp_updated: " + str(tdp_current) + "  " + str(boost_current))
	tdp_slider.value = tdp_current
	tdp_boost_slider.value = boost_current


func _setup_gpu_freq_range() -> void:
	_to_visible.append(gpu_freq_enable)
	gpu_freq_enable.toggled.connect(_on_gpu_freq_enable_button_toggled)
	performance_manager.gpu_clk_limits_updated.connect(_update_gpu_freq_range)
	performance_manager.gpu_clk_current_updated.connect(_update_gpu_freq_current)
	performance_manager.gpu_manual_enabled_updated.connect(_update_gpu_manual_enabled)


func _update_gpu_freq_current(current_min: float, current_max: float) -> void:
	logger.debug("Received update for gpu_clk_current_updated: " + str(current_min) + "  " + str(current_max))
	gpu_freq_max_slider.value = current_max
	gpu_freq_min_slider.value = current_min
	logger.debug("gpu_clk_current_updated done.")


func _update_gpu_freq_range(gpu_freq_min: float, gpu_freq_max: float) -> void:
	logger.debug("Received update for gpu_clk_limits_updated: " + str(gpu_freq_min) + "  " + str(gpu_freq_max))
	# By default the sliders will set to the new mininum value if thier current value is
	# less than the new minimim. On first run we dont want to override the max_freq so
	# we connect the value changed signals after we have modified the min/max values.
	# This can also happen the first time the slider is enabled.
	var first_run: bool = false
	if gpu_freq_max_slider.value == 0:
		first_run = true
		if gpu_freq_max_slider.value_changed.is_connected(_on_max_gpu_freq_slider_changed):
			gpu_freq_max_slider.value_changed.disconnect(_on_max_gpu_freq_slider_changed)
		if gpu_freq_min_slider.value_changed.is_connected(_on_min_gpu_freq_slider_changed):
			gpu_freq_min_slider.value_changed.disconnect(_on_min_gpu_freq_slider_changed)

	gpu_freq_max_slider.max_value = gpu_freq_max
	gpu_freq_max_slider.min_value = gpu_freq_min
	gpu_freq_min_slider.max_value = gpu_freq_max
	gpu_freq_min_slider.min_value = gpu_freq_min

	if first_run:
		logger.debug("Set first run values: "  + str(gpu_freq_min) + "  " + str(gpu_freq_max))
		gpu_freq_max_slider.value = gpu_freq_max
		gpu_freq_min_slider.value = gpu_freq_min
		gpu_freq_max_slider.value_changed.connect(_on_max_gpu_freq_slider_changed)
		gpu_freq_min_slider.value_changed.connect(_on_min_gpu_freq_slider_changed)
	logger.debug("gpu_clk_limits_updated done.")


func _update_gpu_manual_enabled(state: bool) -> void:
	logger.debug("Received update for gpu_manual_enabled: " + str(state)) 
	gpu_freq_enable.button_pressed = state
	gpu_freq_max_slider.visible = state
	gpu_freq_min_slider.visible = state


# Gets the TDP Range for the detected hardware.
func _setup_gpu_temp() -> void:
	_to_visible.append(gpu_temp_slider)
	gpu_temp_slider.value_changed.connect(_on_gpu_temp_limit_slider_changed)
	performance_manager.gpu_temp_limit_updated.connect(_update_gpu_temp)


# Gets the TDP Range for the detected hardware.
func _update_gpu_temp(current: float) -> void:
	logger.debug("Received update for gpu_temp_limit_updated: " +str(current))
	gpu_temp_slider.value = current


func _setup_power_profile() -> void:
	_to_visible.append(power_profile_dropdown)
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
	_to_visible.append(thermal_profile_dropdown)
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

func _on_cpu_cores_slider_changed(value: float) -> void:
	if value == performance_manager.profile.cpu_core_count_current:
		return
	logger.debug("cpu_cores_slider_changed: " + str (value))
	_setup_callback_func(performance_manager.set_cpu_core_count, value)


# Called to toggle cpu boost
func _on_cpu_boost_button_toggled(state: bool) -> void:
	if state == performance_manager.profile.cpu_boost_enabled:
		return
	logger.debug("cpu_boost_button_toggled: " + str (state))
	_setup_callback_func(performance_manager.set_cpu_boost_enabled, state, 0)


# Called to toggle auo/manual gpu clocking
func _on_gpu_freq_enable_button_toggled(state: bool) -> void:
	if state == performance_manager.profile.gpu_manual_enabled:
		return
	logger.debug("gpu_freq_enable_button_toggled: " + str (state))
	_setup_callback_func(performance_manager.set_gpu_manual_enabled, state, 0)


# Sets the T-junction temp using ryzenadj.
func _on_gpu_temp_limit_slider_changed(value: float) -> void:
	if value == performance_manager.profile.gpu_temp_current:
		return
	logger.debug("gpu_temp_limit_slider_changed: " + str (value))
	_setup_callback_func(performance_manager.set_gpu_temp_current, value, 0)


# Called when gpu_freq_max_slider.value is changed.
func _on_max_gpu_freq_slider_changed(value: float) -> void:
	if value == performance_manager.profile.gpu_freq_max_current:
		return
	logger.debug("max_gpu_freq_slider_changed: " + str (value))
	if value < gpu_freq_min_slider.value:
		gpu_freq_min_slider.value = value
	_setup_callback_func(performance_manager.set_gpu_freq_max, value)


# Called when gpu_freq_min_slider.value is changed.
func _on_min_gpu_freq_slider_changed(value: float) -> void:
	if value == performance_manager.profile.gpu_freq_min_current:
		return
	logger.debug("min_gpu_freq_slider_changed: " + str (value))
	if value > gpu_freq_max_slider.value:
		gpu_freq_max_slider.value = value
	_setup_callback_func(performance_manager.set_gpu_freq_min, value)


func _on_power_profile_dropdown_changed(index: int) -> void:
	if index == performance_manager.profile.gpu_power_profile:
		return
	logger.debug("power_profile_dropdown_changed: " + str (index))
	_setup_callback_func(performance_manager.set_gpu_power_profile, index, 0)


# Called to set the flow and fast boost TDP
func _on_tdp_boost_value_slider_changed(value: float) -> void:
	if value == performance_manager.profile.tdp_boost_current:
		return
	logger.debug("tdp_boost_value_slider_changed: " + str (value))
	_setup_callback_func(performance_manager.set_tdp_boost_value, value)


# Called to set the base average TDP
func _on_tdp_value_slider_changed(value: float) -> void:
	if value == performance_manager.profile.tdp_current:
		return
	logger.debug("tdp_value_slider_changed: " + str (value))
	_setup_callback_func(performance_manager.set_tdp_value, value)


# Sets the thermal throttle policy for ASUS devices.
func _on_thermal_policy_dropdown_changed(index: int) -> void:
	if index == performance_manager.profile.thermal_profile:
		return
	logger.debug("thermal_policy_dropdown_changed: " + str (index))
	_setup_callback_func(performance_manager.set_thermal_profile, index, 0)


# Called to toggle SMT
func _on_smt_button_toggled(state: bool) -> void:
	if state == performance_manager.profile.cpu_smt_enabled:
		return
	logger.debug("smt_button_toggled: " + str (state))
	_setup_callback_func(performance_manager.set_cpu_smt_enabled, state, 0)
