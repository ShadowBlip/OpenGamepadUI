extends VBoxContainer

var _hardware_manager := load("res://core/systems/hardware/hardware_manager.tres") as HardwareManager
var _platform := load("res://core/global/platform.tres") as Platform
var _performance_manager := load("res://core/systems/performance/performance_manager.tres") as PerformanceManager
var _power_station := load("res://core/systems/performance/power_station.tres") as PowerStationInstance
var _profiles_available: PackedStringArray

@onready var focus_group := $%FocusGroup as FocusGroup
@onready var cpu_boost_button := $CPUBoostButton as Toggle
@onready var cpu_cores_slider := $CPUCoresSlider as ValueSlider
@onready var gpu_freq_enable := $GPUFreqButton as Toggle
@onready var gpu_freq_max_slider := $GPUFreqMaxSlider as ValueSlider
@onready var gpu_freq_min_slider := $GPUFreqMinSlider as ValueSlider
@onready var gpu_temp_slider := $GPUTempSlider as ValueSlider
@onready var power_profile_dropdown := $PowerProfileDropdown as Dropdown
@onready var tdp_boost_slider := $TDPBoostSlider as ValueSlider
@onready var tdp_slider := $TDPSlider as ValueSlider
@onready var smt_button := $SMTButton as Toggle
@onready var cpu_label := $CPUSectionLabel as Control
@onready var gpu_label := $GPUSectionLabel as Control
@onready var wait_label := $WaitLabel as Control
@onready var service_timer := $ServiceTimer as Timer
@onready var apply_timer := $ApplyTimer as Timer
@onready var mangoapp_slider := $%MangoAppSlider as ValueSlider
@onready var mode_toggle := $%ModeToggle as Toggle

var _power_station_running := false
var _profile_loading := false
var _current_profile: PerformanceProfile
var logger := Log.get_logger("Performance", Log.LEVEL.INFO)


# Called when the node enters the scene tree for the first time.
# Finds default values and current settings of the hardware.
func _ready() -> void:
	# Setup dropdowns
	var i := 0
	_get_available_profiles()
	power_profile_dropdown.clear()
	for profile in _profiles_available:
		power_profile_dropdown.add_item(profile, i)
		i += 1

	# Configure the interface
	_on_profile_loaded(_performance_manager.current_profile)

	_performance_manager.profile_loaded.connect(_on_profile_loaded)
	mangoapp_slider.value_changed.connect(_on_mangoapp_changed)
	mode_toggle.toggled.connect(_on_mode_toggled)

	service_timer.timeout.connect(_on_service_timer_timeout)
	apply_timer.timeout.connect(_on_apply_timer_timeout)

	# Re-start the apply timer when changes happen
	var on_changed := func() -> void:
		if _profile_loading:
			return
		apply_timer.start()
	cpu_boost_button.pressed.connect(on_changed)
	smt_button.pressed.connect(on_changed)
	gpu_freq_enable.pressed.connect(on_changed)
	mode_toggle.pressed.connect(on_changed)

	# Set the total number of available cores if the SMT button is pressed
	var on_smt_pressed := func() -> void:
		if not _hardware_manager.cpu:
			return
		var cpu := _hardware_manager.cpu
		if smt_button.button_pressed:
			cpu_cores_slider.max_value = cpu.core_count
		else:
			var cores := cpu.core_count / 2
			if cpu_cores_slider.value > cores:
				cpu_cores_slider.value = cores
			cpu_cores_slider.max_value = cores
	smt_button.pressed.connect(on_smt_pressed)

	# Restart the timer when any slider changes happen
	var on_slider_changed := func(_value) -> void:
		if _profile_loading:
			return
		apply_timer.start()
	cpu_cores_slider.value_changed.connect(on_slider_changed)
	tdp_slider.value_changed.connect(on_slider_changed)
	tdp_boost_slider.value_changed.connect(on_slider_changed)
	gpu_freq_min_slider.value_changed.connect(on_slider_changed)
	gpu_freq_max_slider.value_changed.connect(on_slider_changed)
	gpu_temp_slider.value_changed.connect(on_slider_changed)

	# Configure GPU frequency timers so the minimum value can never go higher
	# than the maximum value slider and the maximum value can never go lower
	# than the minimum value slider.
	var on_gpu_freq_changed := func(_value: float, kind: String) -> void:
		if kind == "min" and gpu_freq_min_slider.value > gpu_freq_max_slider.value:
			gpu_freq_max_slider.value = gpu_freq_min_slider.value
			return
		if kind == "max" and gpu_freq_max_slider.value < gpu_freq_min_slider.value:
			gpu_freq_min_slider.value = gpu_freq_max_slider.value
			return
	gpu_freq_min_slider.value_changed.connect(on_gpu_freq_changed.bind("min"))
	gpu_freq_max_slider.value_changed.connect(on_gpu_freq_changed.bind("max"))

	# Also restart the apply timer when dropdown changes happen
	var on_dropdown_changed := func(index) -> void:
		if _profile_loading:
			return

		var new_profile: PerformanceProfile
		if _profiles_available[index] == "power-saving":
			new_profile = _create_powersaving_profile()
		elif _profiles_available[index] == "max-performance":
			new_profile = _create_performance_profile(false)

		if new_profile:
			_on_profile_loaded(new_profile)
			_performance_manager.apply_and_save_profile(_current_profile)
		else:
			apply_timer.start()
	power_profile_dropdown.item_selected.connect(on_dropdown_changed)

	# Toggle visibility when the GPU freq manual toggle is on
	var on_manual_freq := func() -> void:
		# Immediately apply manual GPU frequency so we can read the min/max
		# values for the sliders
		var card := _get_integrated_card()
		if not card:
			logger.warn("No integrated GPU to set manual frequency on!")
			return
		card.manual_clock = gpu_freq_enable.button_pressed

		# Update the slider values with the current values
		gpu_freq_min_slider.visible = gpu_freq_enable.button_pressed
		gpu_freq_min_slider.min_value = round(card.clock_limit_mhz_min)
		gpu_freq_min_slider.max_value = round(card.clock_limit_mhz_max)
		gpu_freq_min_slider.value = round(card.clock_value_mhz_min)
		gpu_freq_max_slider.visible = gpu_freq_enable.button_pressed
		gpu_freq_max_slider.min_value = round(card.clock_limit_mhz_min)
		gpu_freq_max_slider.max_value = round(card.clock_limit_mhz_max)
		gpu_freq_max_slider.value = round(card.clock_value_mhz_max)
	gpu_freq_enable.pressed.connect(on_manual_freq)


# Triggers when the apply timer times out. The apply timer will start/restart
# whenever the user makes a change to any item. When the timer runs out, it will
# call this to apply the current profile.
func _on_apply_timer_timeout() -> void:
	if not _current_profile:
		logger.debug("No loaded profile to apply")
		return
	logger.debug("Applying and saving profile")

	# Update the profile based on the currently set values
	var power_profile := _profiles_available[power_profile_dropdown.selected]
	_current_profile.gpu_power_profile = power_profile
	_current_profile.cpu_boost_enabled = cpu_boost_button.button_pressed
	_current_profile.cpu_smt_enabled = smt_button.button_pressed
	_current_profile.cpu_core_count_current = int(cpu_cores_slider.value)
	_current_profile.tdp_current = tdp_slider.value
	_current_profile.tdp_boost_current = tdp_boost_slider.value
	_current_profile.gpu_manual_enabled = gpu_freq_enable.button_pressed
	_current_profile.gpu_freq_min_current = gpu_freq_min_slider.value
	_current_profile.gpu_freq_max_current = gpu_freq_max_slider.value
	_current_profile.gpu_temp_current = gpu_temp_slider.value
	_current_profile.advanced_mode = mode_toggle.button_pressed

	_performance_manager.apply_and_save_profile(_current_profile)


# Triggers every timeout to monitor the PowerStation DBus
func _on_service_timer_timeout() -> void:
	var bus_running := _power_station.is_running()
	if bus_running == _power_station_running:
		return

	# If the state of powerstation changes, update the interface accordingly
	_power_station_running = bus_running
	_setup_interface()


## Called when a performance profile is loaded
func _on_profile_loaded(profile: PerformanceProfile) -> void:
	if not _power_station.is_running():
		logger.info("Unable to load performance profile. PowerStation not detected.")
		return
	var core_count := 1
	if _hardware_manager.cpu:
		core_count = _hardware_manager.cpu.core_count

	logger.debug("Updating UI with loaded performance profile")
	# Keep track of the currently loaded profile
	_current_profile = profile

	# Update UI components based on the loaded profile
	_profile_loading = true
	var idx := _profiles_available.find(profile.gpu_power_profile)
	if idx > -1:
		power_profile_dropdown.select(idx)
	_setup_interface()

	cpu_boost_button.button_pressed = profile.cpu_boost_enabled
	smt_button.button_pressed = profile.cpu_smt_enabled
	if smt_button.button_pressed:
		cpu_cores_slider.max_value = core_count
	else:
		var cores := core_count / 2
		if cpu_cores_slider.value > cores:
			cpu_cores_slider.value = cores
		cpu_cores_slider.max_value = cores
	cpu_cores_slider.value = round(profile.cpu_core_count_current)

	# Update GPU UI components
	tdp_slider.value = round(profile.tdp_current)
	tdp_boost_slider.value = round(profile.tdp_boost_current)
	gpu_freq_enable.button_pressed = profile.gpu_manual_enabled
	gpu_freq_enable.pressed.emit()
	gpu_freq_min_slider.value = round(profile.gpu_freq_min_current)
	gpu_freq_max_slider.value = round(profile.gpu_freq_max_current)
	gpu_temp_slider.value = round(profile.gpu_temp_current)

	mode_toggle.button_pressed = profile.advanced_mode

	_profile_loading = false


# Configure the min/max values and visibility based on detected performance
# features.
func _setup_interface() -> void:
	# If powerstation is not running, hide everything
	if not _power_station.is_running():
		wait_label.visible = true
		for node in get_children():
			if node == wait_label:
				continue
			if node == Control:
				(node as Control).visible = false
		return

	# Configure visibility for all components
	wait_label.visible = false

	var is_advanced := false
	if _current_profile:
		is_advanced = _current_profile.advanced_mode
	if mode_toggle.button_pressed != is_advanced:
		mode_toggle.button_pressed = is_advanced
		focus_group.current_focus = mode_toggle

	# Configure CPU components
	if _power_station.cpu:
		var cpu := _power_station.cpu
		cpu_label.visible = is_advanced
		cpu_boost_button.visible = cpu.has_feature("cpb") and is_advanced
		smt_button.visible = cpu.has_feature("ht") and is_advanced
		if cpu.smt_enabled:
			cpu_cores_slider.max_value = cpu.cores_count
		else:
			cpu_cores_slider.max_value = cpu.cores_count / 2
		cpu_cores_slider.visible = is_advanced

	# Configure GPU components
	if not _power_station.gpu:
		return
	var card := _get_integrated_card()

	# Configure based on integrated graphics card
	if not card:
		return

	gpu_label.visible = is_advanced

	tdp_slider.visible = is_advanced
	tdp_slider.min_value = round(_hardware_manager.gpu.tdp_min)
	tdp_slider.max_value = round(_hardware_manager.gpu.tdp_max)

	tdp_boost_slider.visible = is_advanced
	tdp_boost_slider.max_value = round(_hardware_manager.gpu.max_boost)

	gpu_freq_enable.visible = is_advanced

	power_profile_dropdown.visible = not is_advanced

	gpu_freq_min_slider.visible = card.manual_clock and is_advanced
	gpu_freq_min_slider.min_value = round(card.clock_limit_mhz_min)
	gpu_freq_min_slider.max_value = round(card.clock_limit_mhz_max)

	gpu_freq_max_slider.visible = card.manual_clock and is_advanced
	gpu_freq_max_slider.min_value = round(card.clock_limit_mhz_min)
	gpu_freq_max_slider.max_value = round(card.clock_limit_mhz_max)

	gpu_temp_slider.visible = is_advanced


## Returns the primary integrated GPU instance
func _get_integrated_card() -> GpuCard:
		var card: GpuCard
		var cards := _power_station.gpu.get_cards()
		for c in cards:
			if c.class != "integrated":
				continue
			card = c
		return card


# Set the mangoapp config on slider change
func _on_mangoapp_changed(value: float) -> void:
	if value == 0:
		MangoApp.set_config(MangoApp.CONFIG_NONE)
		return
	if value == 1:
		MangoApp.set_config(MangoApp.CONFIG_FPS)
		return
	if value == 2:
		MangoApp.set_config(MangoApp.CONFIG_MIN)
		return
	if value == 3:
		MangoApp.set_config(MangoApp.CONFIG_DEFAULT)
		return
	if value >= 4:
		MangoApp.set_config(MangoApp.CONFIG_INSANE)
		return


func _create_performance_profile(is_advanced: bool) -> PerformanceProfile:
	var new_profile := PerformanceProfile.new()

	# CPU Settings
	new_profile.cpu_boost_enabled = true
	new_profile.cpu_core_count_current = cpu_cores_slider.max_value
	new_profile.cpu_smt_enabled = true

	# GPU Settings
	var profiles := _performance_manager.get_power_profiles_available() as PackedStringArray
	if profiles.is_empty():
		logger.error("No _platform profiles available. Unable to assume sane performance defaults.")
		return null
	if "custom" in profiles:
		profiles.remove_at(profiles.find("custom"))
	if not "max-performance" in profiles and not "performance" in profiles:
		logger.error("Performance profile not found. Unable to assume sane performance defaults.")
		return null
	var profile_idx := profiles.find("max-performance")
	if  profile_idx == -1:
		profile_idx = profiles.find("performance")
	if profile_idx == -1:
		logger.error("Performance profile not found. Unable to assume sane performance defaults.")
		return null
	new_profile.gpu_power_profile = profiles[profile_idx]
	new_profile.gpu_freq_max_current = gpu_freq_max_slider.max_value
	new_profile.gpu_freq_min_current = gpu_freq_min_slider.min_value
	new_profile.gpu_manual_enabled = false 
	new_profile.gpu_temp_current = 95
	new_profile.tdp_boost_current = tdp_boost_slider.max_value
	new_profile.tdp_current = tdp_slider.max_value
	new_profile.advanced_mode = is_advanced 
	return new_profile


func _create_powersaving_profile() -> PerformanceProfile:
	var new_profile := PerformanceProfile.new()

	# CPU Settings
	new_profile.cpu_boost_enabled = true
	new_profile.cpu_core_count_current = cpu_cores_slider.max_value
	new_profile.cpu_smt_enabled = true

	# GPU Settings
	_get_available_profiles()

	if _profiles_available.is_empty():
		logger.error("No _platform profiles available. Unable to assume sane performance defaults.")
		return null
	if not "power-saving" in _profiles_available:
		logger.error("Power Saving profile not found. Unable to assume sane performance defaults.")
		return null
	var profile_idx := _profiles_available.find("power-saving")
	if  profile_idx == -1:
		logger.error("Performance profile not found. Unable to assume sane performance defaults.")
		return null

	new_profile.gpu_power_profile = _profiles_available[profile_idx]
	new_profile.gpu_freq_max_current = gpu_freq_max_slider.max_value
	new_profile.gpu_freq_min_current = gpu_freq_min_slider.min_value
	new_profile.gpu_manual_enabled = false 
	new_profile.gpu_temp_current = 95
	var tdp_boost_mid = ((tdp_boost_slider.max_value - tdp_boost_slider.min_value) / 2) + tdp_boost_slider.min_value
	new_profile.tdp_boost_current = tdp_boost_mid
	var tdp_mid = ((tdp_slider.max_value - tdp_slider.min_value) / 2) + tdp_slider.min_value
	new_profile.tdp_current = tdp_mid
	new_profile.advanced_mode = false 
	return new_profile


# Get
func _get_available_profiles() -> void:
	_profiles_available = _performance_manager.get_power_profiles_available()
	if "custom" in _profiles_available:
		var idx = _profiles_available.find("custom")
		_profiles_available.remove_at(idx)


# Adjust the available options based on the mode toggle
func _on_mode_toggled(pressed: bool) -> void:
	var new_profile := _create_performance_profile(pressed)
	_on_profile_loaded(new_profile)
