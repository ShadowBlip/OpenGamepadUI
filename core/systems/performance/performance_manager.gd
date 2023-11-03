extends Resource
class_name PerformanceManager

## Manages, sets, and loads performance profiles
##
## The PerformanceManager is responsible for applying the appropriate performance
## profile when games launch and when the device is plugged in or unplugged.

signal profile_applied(profile: PerformanceProfile)
signal profile_loaded(profile: PerformanceProfile)
signal profile_saved(profile: PerformanceProfile, path: String)

const USER_PROFILES := "user://data/performance/profiles"
const DOCKED_STATES := [PowerManager.DEVICE_STATE.CHARGING, PowerManager.DEVICE_STATE.FULLY_CHARGED, PowerManager.DEVICE_STATE.PENDING_CHARGE]

## Performance profiles are separated into these states, so users can have different
## performance depending on whether or not they are plugged in to an external power
## source.
enum PROFILE_STATE {
	DOCKED,
	UNDOCKED,
}

var _hardware_manager := load("res://core/systems/hardware/hardware_manager.tres") as HardwareManager
var _power_manager := load("res://core/systems/power/power_manager.tres") as PowerManager
var _settings_manager := load("res://core/global/settings_manager.tres") as SettingsManager
var _power_station := load("res://core/systems/performance/power_station.tres") as PowerStation
var _launch_manager := load("res://core/global/launch_manager.tres") as LaunchManager

var current_profile: PerformanceProfile
var current_profile_state: PROFILE_STATE # docked or undocked
var logger := Log.get_logger("PerformanceManager", Log.LEVEL.DEBUG)


func _init() -> void:
	# Listen for signals when the current app switches so we can update the profile
	# accordingly.
	_launch_manager.app_switched.connect(_on_app_switched)
	
	# Connect to battery state changes to switch between "docked" and "undocked"
	# performance profiles.
	var batteries := _power_manager.get_devices_by_type(PowerManager.DEVICE_TYPE.BATTERY)
	if batteries.size() > 1:
		logger.warn("You somehow have more than one battery. We don't know what to do with that.")
	if batteries.size() > 0:
		var battery := batteries[0]
		battery.updated.connect(_on_battery_updated.bind(battery))
	
	# Load and apply the default profile
	var profile_state := get_profile_state()
	var path := get_profile_filename(profile_state)
	current_profile = load_or_create_profile(path)
	apply_profile(current_profile)


## Returns a profile filename generated from the given profile state and library item.
## E.g. "Bravo_15_A4DDR_docked_default_profile.tres"
func get_profile_filename(profile_state: PROFILE_STATE, library_item: LibraryLaunchItem = null) -> String:
	var profile_state_name := "docked"
	if profile_state == PROFILE_STATE.UNDOCKED:
		profile_state_name = "undocked"

	var prefix: String = _hardware_manager.get_product_name().replace(" ", "_") + "_" + profile_state_name
	var postfix: String = "_default_profile.tres"
	if library_item:
		postfix = "_" + library_item.name.sha256_text() + ".tres"

	return prefix+postfix


## Saves the given PerformanceProfile to the given path. If a library item
## is passed, the user's settings will be updated to use the given profile.
func save_profile(profile: PerformanceProfile, profile_path: String, library_item: LibraryLaunchItem = null) -> void:
	# Try to save the profile
	if DirAccess.make_dir_recursive_absolute(USER_PROFILES) != OK:
		logger.debug("Unable to create performance profiles directory")
		return
	#var profile_path := "/".join([USER_PROFILES, _get_profile_name()])
	if ResourceSaver.save(profile, profile_path) != OK:
		logger.error("Failed to save performance profile to: " + profile_path)
		return

	# Update the game settings to use this performance profile
	var section := "game.default_profile"
	if library_item:
		section = "game.{0}".format([library_item.name.to_lower()])

	_settings_manager.set_value(section, "performace_profile", profile_path)
	logger.info("Saved performance profile to: " + profile_path)
	profile_saved.emit(profile, profile_path)


## Create a new [PerformanceProfile] from the current performance settings. If
## a library item is passed, the profile will be named after the library item.
func create_profile(library_item: LibraryLaunchItem = null) -> PerformanceProfile:
	var profile := PerformanceProfile.new()
	if library_item:
		profile.name = library_item.name
	
	# Configure the CPU settings
	if _power_station.cpu:
		profile.cpu_boost_enabled = _power_station.cpu.boost_enabled
		profile.cpu_core_count_current = _power_station.cpu.cores_enabled
		profile.cpu_smt_enabled = _power_station.cpu.smt_enabled

	# Detect all GPU cards
	var cards: Array[PowerStation.GPUCard] = []
	if _power_station.gpu:
		cards = _power_station.gpu.get_cards()

	# Configure GPU settings
	# TODO: Support multiple GPUs?
	for card in cards:
		if card.class_type != "integrated":
			continue

		profile.tdp_current = card.tdp
		profile.tdp_boost_current = card.boost
		profile.gpu_freq_min_current = card.clock_value_mhz_min
		profile.gpu_freq_max_current = card.clock_value_mhz_max
		profile.gpu_manual_enabled = card.manual_clock
		#profile.gpu_power_profile = card.power_profile # TODO: Fix this
		profile.gpu_temp_current = card.thermal_throttle_limit_c

	logger.debug("Created performance profile: " + profile.name)
	return profile


## Loads a PerformanceProfile from the given path. Returns null if the profile
## fails to load.
func load_profile(profile_path: String) -> PerformanceProfile:
	logger.debug("Loading profile: " + profile_path)
	if not FileAccess.file_exists(profile_path):
		return null
	var loaded_profile := load(profile_path) as PerformanceProfile
	if not loaded_profile:
		logger.warn("Unable to load profile at: " + profile_path)
	return loaded_profile


## Loads a PerformanceProfile from the given path. If the profile does not exist,
## it will create a new profile using the currently applied performance settings.
func load_or_create_profile(profile_path: String, library_item: LibraryLaunchItem = null) -> PerformanceProfile:
	# Try to load the profile if it exists
	var profile := load_profile(profile_path)
	if profile:
		return profile
	
	# If the profile does not exist, create one with the currently applied
	# performance settings.
	return create_profile(library_item)


## Applies the given performance profile to the system
func apply_profile(profile: PerformanceProfile) -> void:
	logger.info("Applying performance profile: " + profile.name)

	# Apply CPU settings from the given profile
	if _power_station.cpu:
		logger.debug("Applying CPU performance settings from profile")
		_power_station.cpu.boost_enabled = profile.cpu_boost_enabled
		_power_station.cpu.smt_enabled = profile.cpu_smt_enabled
		if profile.cpu_core_count_current > 0:
			_power_station.cpu.cores_enabled = profile.cpu_core_count_current

	# Detect all GPU cards
	var cards: Array[PowerStation.GPUCard] = []
	if _power_station.gpu:
		cards = _power_station.gpu.get_cards()

	# Configure GPU settings
	# TODO: Support mutliple GPUs?
	for card in cards:
		if card.class_type != "integrated":
			continue
		logger.debug("Applying GPU performance settings from profile")
		if profile.tdp_current > 0:
			card.tdp = profile.tdp_current
		if profile.tdp_boost_current > 0:
			card.boost = profile.tdp_boost_current
		if profile.gpu_freq_min_current > 0:
			card.clock_value_mhz_min = profile.gpu_freq_min_current
		if profile.gpu_freq_max_current > 0:
			card.clock_value_mhz_max = profile.gpu_freq_max_current
		card.manual_clock = profile.gpu_manual_enabled
		#if profile.gpu_power_profile > 0:
		#	card.power_profile = profile.gpu_power_profile # TODO: Fix this
		if profile.gpu_temp_current > 0:
			card.thermal_throttle_limit_c = profile.gpu_temp_current

	logger.info("Applied Performance Profile: " + profile.name)
	profile_applied.emit(profile)


## Applies the given performance profile to the system and saves it based on
## the current profile state (e.g. docked or undocked) and current running app.
func apply_and_save_profile(profile: PerformanceProfile) -> void:
	# Get the current profile state to see if we need to load the docked or
	# undocked profile.
	var profile_state := get_profile_state()

	# Get the currently running app, if there is one.
	var current_app := _launch_manager.get_current_app()
	var library_item: LibraryLaunchItem
	if current_app:
		library_item = current_app.launch_item

	# Load the performance profile based on the running game
	var profile_path := get_profile_filename(profile_state, library_item)
	profile_path = "/".join([USER_PROFILES, profile_path])
	apply_profile(profile)
	save_profile(profile, profile_path, library_item)


## Returns the current profile state. I.e. whether or not the "docked" or "undocked"
## performance profiles should be used.
func get_profile_state() -> PROFILE_STATE:
	var batteries := _power_manager.get_devices_by_type(PowerManager.DEVICE_TYPE.BATTERY)
	if batteries.size() > 1:
		logger.warn("You somehow have more than one battery. We don't know what to do with that.")
	if batteries.size() > 0:
		var battery := batteries[0]
		return get_profile_state_from_battery(battery)

	return PROFILE_STATE.DOCKED


## Returns the current profile state. I.e. whether or not the "docked" or "undocked"
## performance profiles should be used.
func get_profile_state_from_battery(battery: PowerManager.Device) -> PROFILE_STATE:
	if battery.state not in DOCKED_STATES:
		return PROFILE_STATE.UNDOCKED
	return PROFILE_STATE.DOCKED


## Called whenever a battery is updated
func _on_battery_updated(battery: PowerManager.Device) -> void:
	# Get the current profile state to see if we need to load the docked or
	# undocked profile.
	var profile_state := get_profile_state_from_battery(battery)

	# If the profile state hasn't changed, do nothing. Otherwise update the
	# state and load/apply the appropriate profile
	if current_profile_state == profile_state:
		return
	current_profile_state = profile_state

	# Get the currently running app, if there is one.
	var current_app := _launch_manager.get_current_app()
	var library_item: LibraryLaunchItem
	if current_app:
		library_item = current_app.launch_item

	# Load the performance profile based on the running game
	var profile_path := get_profile_filename(profile_state, library_item)
	profile_path = "/".join([USER_PROFILES, profile_path])
	var profile := load_or_create_profile(profile_path, library_item)
	current_profile = profile
	profile_loaded.emit(profile)
	apply_profile(profile)


## Called whenever an app is switched. E.g. when a game is launched
func _on_app_switched(_from: RunningApp, to: RunningApp) -> void:
	logger.debug("Detected app switch")
	if not to:
		return

	# Get the current profile state to see if we need to load the docked or
	# undocked profile.
	var profile_state := get_profile_state()

	# Load the performance profile based on the running game
	var profile_path := get_profile_filename(profile_state, to.launch_item)
	var profile := load_or_create_profile(profile_path, to.launch_item)
	current_profile = profile
	profile_loaded.emit(profile)
	apply_profile(profile)
