extends VBoxContainer

var hardware_manager := load("res://core/systems/hardware/hardware_manager.tres") as HardwareManager
var platform := load("res://core/global/platform.tres") as Platform
var performance_manager := load("res://core/systems/performance/performance_manager.tres") as PerformanceManager
var power_station := load("res://core/systems/performance/power_station.tres") as PowerStation

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
@onready var service_timer := $ServiceTimer as Timer
@onready var apply_timer := $ApplyTimer as Timer

var power_station_running := false
var profile_loading := false
var current_profile: PerformanceProfile
var logger := Log.get_logger("PowerTools", Log.LEVEL.DEBUG)


# Called when the node enters the scene tree for the first time.
# Finds default values and current settings of the hardware.
func _ready() -> void:
	# Listen for signals from performance manager
	performance_manager.profile_loaded.connect(_on_profile_loaded)

	# Configure a timer that will monitor the PowerStation DBus service
	service_timer.timeout.connect(_on_service_timer_timeout)
	# Configure a timer that will apply and save the performance profile
	apply_timer.timeout.connect(_on_apply_timer_timeout)

	# Configure the interface
	_setup_interface()

	# Re-start the apply timer when changes happen
	var on_changed := func() -> void:
		if profile_loading:
			return
		apply_timer.start()
	cpu_boost_button.pressed.connect(on_changed)
	smt_button.pressed.connect(on_changed)
	gpu_freq_enable.pressed.connect(on_changed)

	# Restart the timer when any slider changes happen
	var on_slider_changed := func(_value) -> void:
		if profile_loading:
			return
		apply_timer.start()
	cpu_cores_slider.value_changed.connect(on_slider_changed)
	tdp_slider.value_changed.connect(on_slider_changed)
	tdp_boost_slider.value_changed.connect(on_slider_changed)
	gpu_freq_min_slider.value_changed.connect(on_slider_changed)
	gpu_freq_max_slider.value_changed.connect(on_slider_changed)
	gpu_temp_slider.value_changed.connect(on_slider_changed)

	# Also restart the apply timer when dropdown changes happen
	var on_dropdown_changed := func(_index) -> void:
		if profile_loading:
			return
		apply_timer.start()
	power_profile_dropdown.item_selected.connect(on_dropdown_changed)
	thermal_profile_dropdown.item_selected.connect(on_dropdown_changed)
	
	# Toggle visibility when the GPU freq manual toggle is on
	var on_manual_freq := func() -> void:
		gpu_freq_min_slider.visible = gpu_freq_enable.button_pressed
		gpu_freq_max_slider.visible = gpu_freq_enable.button_pressed
	gpu_freq_enable.pressed.connect(on_manual_freq)
	
	# Setup dropdowns
	thermal_profile_dropdown.clear()
	thermal_profile_dropdown.add_item("Balanced", 0)
	thermal_profile_dropdown.add_item("Performance", 1)
	thermal_profile_dropdown.add_item("Silent", 2)
	power_profile_dropdown.clear()
	power_profile_dropdown.add_item("Max Performance", 0)
	power_profile_dropdown.add_item("Power Saving", 1)
	
	# Set the initial values
	_on_profile_loaded(performance_manager.current_profile)


# Triggers when the apply timer times out. The apply timer will start/restart
# whenever the user makes a change to any item. When the timer runs out, it will
# call this to apply the current profile.
func _on_apply_timer_timeout() -> void:
	if not current_profile:
		logger.debug("No loaded profile to apply")
		return
	logger.debug("Applying and saving profile")

	# Update the profile based on the currently set values
	current_profile.cpu_boost_enabled = cpu_boost_button.button_pressed
	current_profile.cpu_smt_enabled = smt_button.button_pressed
	print(smt_button.button_pressed)
	current_profile.cpu_core_count_current = cpu_cores_slider.value
	current_profile.tdp_current = tdp_slider.value
	current_profile.tdp_boost_current = tdp_boost_slider.value
	current_profile.gpu_manual_enabled = gpu_freq_enable.button_pressed
	current_profile.gpu_freq_min_current = gpu_freq_min_slider.value
	current_profile.gpu_freq_max_current = gpu_freq_max_slider.value
	current_profile.gpu_temp_current = gpu_temp_slider.value

	performance_manager.apply_and_save_profile(current_profile)


# Triggers every timeout to monitor the PowerStation DBus
func _on_service_timer_timeout() -> void:
	var bus_running := power_station.supports_power_station()
	if bus_running == power_station_running:
		return

	# If the state of powerstation changes, update the interface accordingly
	power_station_running = bus_running
	_setup_interface()


## Called when a performance profile is loaded
func _on_profile_loaded(profile: PerformanceProfile) -> void:
	if not power_station.supports_power_station():
		logger.info("Unable to load performance profile. PowerStation not detected.")
		return
	
	logger.debug("Updating UI with loaded performance profile")
	# Keep track of the currently loaded profile
	current_profile = profile
	
	# Update all UI components based on the loaded profile
	profile_loading = true
	cpu_boost_button.button_pressed = profile.cpu_boost_enabled
	smt_button.button_pressed = profile.cpu_smt_enabled
	cpu_cores_slider.value = profile.cpu_core_count_current
	tdp_slider.value = profile.tdp_current
	tdp_boost_slider.value = profile.tdp_boost_current
	gpu_freq_enable.button_pressed = profile.gpu_manual_enabled
	gpu_freq_enable.pressed.emit()
	gpu_freq_min_slider.value = profile.gpu_freq_min_current
	gpu_freq_max_slider.value = profile.gpu_freq_max_current
	gpu_temp_slider.value = profile.gpu_temp_current

	power_profile_dropdown.select(profile.gpu_power_profile)
	thermal_profile_dropdown.select(profile.thermal_profile)
	profile_loading = false


# Configure the min/max values and visibility
func _setup_interface() -> void:
	# If powerstation is not running, disable everything
	if not power_station.supports_power_station():
		wait_label.visible = true
		for node in get_children():
			if node == wait_label:
				continue
			if node == Control:
				(node as Control).visible = false
		return
	
	# Configure visibility for all components
	wait_label.visible = false
	
	# Configure CPU components
	if power_station.cpu:
		var cpu := power_station.cpu
		cpu_label.visible = true
		cpu_boost_button.visible = cpu.has_feature("cpb")
		smt_button.visible = cpu.has_feature("ht")
		cpu_cores_slider.max_value = cpu.cores_count
		cpu_cores_slider.visible = true
	
	# Configure GPU components
	if power_station.gpu:
		var card: PowerStation.GPUCard
		var cards := power_station.gpu.get_cards()
		for c in cards:
			if c.class_type != "integrated":
				continue
			card = c
		
		# Configure based on integrated graphics card
		if card:
			gpu_label.visible = true
			tdp_slider.visible = true
			tdp_slider.min_value = hardware_manager.gpu.tdp_min
			tdp_slider.max_value = hardware_manager.gpu.tdp_max
			tdp_boost_slider.visible = true
			tdp_boost_slider.max_value = hardware_manager.gpu.max_boost
