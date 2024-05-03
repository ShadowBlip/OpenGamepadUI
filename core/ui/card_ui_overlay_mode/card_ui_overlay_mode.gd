extends Control

var platform := preload("res://core/global/platform.tres") as Platform
var gamescope := preload("res://core/global/gamescope.tres") as Gamescope
var launch_manager := preload("res://core/global/launch_manager.tres") as LaunchManager
var settings_manager := preload("res://core/global/settings_manager.tres") as SettingsManager
var input_plumber := preload("res://core/systems/input/input_plumber.tres") as InputPlumber

var state_machine := (
	preload("res://assets/state/state_machines/global_state_machine.tres") as StateMachine
)
var quick_bar_state = preload("res://assets/state/states/quick_bar_menu.tres") as State
var settings_state = preload("res://assets/state/states/settings.tres") as State
var base_state = preload("res://assets/state/states/home.tres") as State

var PID: int = OS.get_process_id()
var args := OS.get_cmdline_user_args()
var cmdargs := OS.get_cmdline_args()
var display := Gamescope.XWAYLAND.OGUI
var game_running: bool = false
var overlay_window_id: int
var underlay_log: FileAccess
var underlay_process: int
var underlay_window_id: int

@onready var quick_bar_menu := $%QuickBarMenu
@onready var settings_menu := $%SettingsMenu

var logger := Log.get_logger("Main", Log.LEVEL.INFO)

## Sets up overlay mode.
func _init():

	logger.debug("Overlay start _init")
	# Tell gamescope that we're an overlay
	if overlay_window_id < 0:
		logger.error("Unable to detect Window ID. Overlay is not going to work!")
	logger.debug("Found primary window id: {0}".format([overlay_window_id]))

	# Back button wont close windows without this. OverlayInputManager prevents poping the last state.
	state_machine.push_state(base_state)

	# Ensure LaunchManager doesn't override our custom overlay management l
	launch_manager.should_manage_overlay = false

	# Set up plugin manager for quick-bar tags
	var plugin_loader := load("res://core/global/plugin_loader.tres") as PluginLoader
	var filters : Array[Callable] = [plugin_loader.filter_by_tag.bind("quick-bar")]
	plugin_loader.set_plugin_filters(filters)
	var plugin_manager_scene := load("res://core/systems/plugin/plugin_manager.tscn") as PackedScene
	var plugin_manager := plugin_manager_scene.instantiate()
	add_child(plugin_manager)

	# Listen for home state changes
	base_state.state_entered.connect(_on_base_state_entered)
	base_state.state_exited.connect(_on_base_state_exited)
	logger.debug("Overlay finish _init")


## Starts the --overlay-mode session.
func _ready() -> void:
	logger.debug("Overlay start _ready")
	# Workaround old versions that don't pass launch args via update pack
	# TODO: Parse the parent PID's CLI args and use those instead.
	if "--skip-update-pack" in cmdargs and args.size() == 0:
		logger.warn("Launched via update pack without arguments! Falling back to default.")
		args = ["steam", "-gamepadui", "-steamos3", "-steampal", "-steamdeck"]

	# Configure the locale
	logger.debug("Setup Locale")
	var locale := settings_manager.get_value("general", "locale", "en_US") as String
	TranslationServer.set_locale(locale)

	logger.debug("Setup Platform")
	# Load any platform-specific logic
	platform.load(get_tree().get_root())

	# Set the FPS limit
	logger.debug("Setup FPS Limit")
	Engine.max_fps = settings_manager.get_value("general", "max_fps", 60) as int
	
	# Set window size to native resolution
	logger.debug("Setup Window Size")
	var screen_size : Vector2i = DisplayServer.screen_get_size()
	var window : Window = get_window()
	window.set_size(screen_size)

	# Set up the session
	logger.debug("Setup Overlay Mode")
	_setup_overlay_mode(args)
	launch_manager.app_switched.connect(_on_app_switched)

	# Set the theme if one was set
	logger.debug("Setup Theme")
	var theme_path := settings_manager.get_value("general", "theme", "") as String
	if theme_path == "":
		logger.debug("No theme set. Using default theme.")

	var current_theme = get_theme()
	if theme_path != "" && current_theme.resource_path != theme_path:
		logger.debug("Setting theme to: " + theme_path)
		var loaded_theme = load(theme_path)
		if loaded_theme != null:
			# TODO: This is a workaround, themes aren't properly set the first time.
			call_deferred("set_theme", loaded_theme)
			call_deferred("set_theme", current_theme)
			call_deferred("set_theme", loaded_theme)
		else:
			logger.debug("Unable to load theme")


## Finds needed PID's and global vars, Starts the user defined program as an
## underlay process.
func _setup_overlay_mode(args: Array) -> void:
	overlay_window_id = gamescope.get_window_id(PID, display)
	quick_bar_state.state_entered.connect(_on_window_open)
	quick_bar_state.state_exited.connect(_on_window_closed)
	settings_state.state_entered.connect(_on_window_open)
	settings_state.state_exited.connect(_on_window_closed)

	# Don't crash if we're not launching another program.
	if args == []:
		logger.warn("overlay mode started with no launcher arguments.")
		return

	if "steam" in args:
		_start_steam_process(args)
	else:
		var log_path := OS.get_environment("HOME") + "/.underlay-stdout.log"
		_start_underlay_process(args, log_path)

	# Establish overlay focus in gamescope.
	gamescope.set_overlay(overlay_window_id, 1, display)

	# Remove unneeded/conflicting elements from default menues
	var remove_list: PackedStringArray = ["PerformanceCard", "NotifyButton", "HelpButton", "VolumeSlider", "BrightnessSlider", "PerGameToggle"]
	_run_child_killer(remove_list, quick_bar_menu)
	var settings_remove_list: PackedStringArray = ["NetworkButton", "BluetoothButton", "AudioButton"]
	_run_child_killer(settings_remove_list, settings_menu)

	# Setup inputplumber to receive guide presses.
	input_plumber.set_intercept_mode(InputPlumber.INTERCEPT_MODE.PASS)
	input_plumber.set_intercept_activation(["Gamepad:Button:Guide", "Gamepad:Button:East"], "Gamepad:Button:QuickAccess2")


## Removes specified child elements from the given Node.
func _run_child_killer(remove_list: PackedStringArray, parent:Node) -> void:
	var child_count := parent.get_child_count()
	var to_remove_list := []

	for child_idx in child_count:
		var child = parent.get_child(child_idx)
		#logger.debug("Checking if " + child.name + " in remove list...")
		if child.name in remove_list:
			#logger.debug(child.name + " queued for removal!")
			to_remove_list.append(child)
			continue

		#logger.debug(child.name + " is not a node we are looking for.")
		var grandchild_count := child.get_child_count()
		if grandchild_count > 0:
			#logger.debug("Checking " + child.name + "'s children...")
			_run_child_killer(remove_list, child)

	for child in to_remove_list:
		#logger.debug("Removing " + child.name)
		child.queue_free()

## Starts Steam as an underlay process
func _start_steam_process(args: Array) -> void:
	logger.debug("Starting steam: " + str(args))
	var underlay_log_path = OS.get_environment("HOME") + "/.steam-stdout.log"
	if not settings_manager.get_value("general.controller", "sdl_hidapi_enabled", false):
		logger.debug("SDL HIDAPI Disabled.")
		args.push_front("&&")
		args.push_front("SDL_JOYSTICK_HIDAPI=0")
		args.push_front("export")
	_start_underlay_process(args, underlay_log_path)

	_find_underlay_window_id()

	# Start timer to check if steam has exited.
	var exit_timer := Timer.new()
	exit_timer.set_one_shot(false)
	exit_timer.set_timer_process_callback(Timer.TIMER_PROCESS_IDLE)
	exit_timer.timeout.connect(_check_exit)
	add_child(exit_timer)
	exit_timer.start()


## Called to start the specified underlay process and redirects logging to a
## seperate log file.
func _start_underlay_process(args: Array, log_path: String) -> void:
	logger.debug("Starting underlay process: " + str(args))
	# Set up loggining in the new thread.
	args.append("2>&1")
	args.append(log_path)

	# Setup logging
	underlay_log = FileAccess.open(log_path, FileAccess.WRITE)
	var error := underlay_log.get_open_error()
	if error != OK:
		logger.warn("Got error opening log file.")
	else:
		logger.info("Started logging underlay process at " + log_path)
	var command: String = "bash"
	underlay_process = Reaper.create_process(command, ["-c", " ".join(args)])


## Called to identify the xwayland window ID of the underlay process.
func _find_underlay_window_id() -> void:
	# Find Steam in the display tree
	var root_win_id := gamescope.get_root_window_id(display)
	var all_windows := gamescope.get_all_windows(root_win_id, display)
	for window in all_windows:
		if window == overlay_window_id:
			continue
		if gamescope.has_xprop(window, "STEAM_OVERLAY", display):
			underlay_window_id = window
			logger.debug("Found steam! " + str(underlay_window_id))
			break

	# If we didn't find the window_id, set up a tiemr to loop back and try again.
	if not underlay_window_id:
		var underlay_window_timer := Timer.new()
		underlay_window_timer.set_one_shot(true)
		underlay_window_timer.set_timer_process_callback(Timer.TIMER_PROCESS_IDLE)
		underlay_window_timer.timeout.connect(_find_underlay_window_id)
		add_child(underlay_window_timer)
		underlay_window_timer.start()


## Called when "quick_bar_state" is entered.
func _on_window_open(from: State) -> void:
	if from:
		logger.info("Quick bar open state: " + from.name)
	input_plumber.set_intercept_mode(InputPlumber.INTERCEPT_MODE.ALL)
	if game_running:
		gamescope.set_overlay(overlay_window_id, 1, display)
		gamescope.set_overlay(underlay_window_id, 0, display)


## Called when "quick_bar_state" is exited.
func _on_window_closed(to: State) -> void:
	if to:
		logger.info("Quick bar closed state: " + to.name)
	input_plumber.set_intercept_mode(InputPlumber.INTERCEPT_MODE.PASS)
	if game_running:
		gamescope.set_overlay(overlay_window_id, 0, display)
		gamescope.set_overlay(underlay_window_id, 1, display)


## Called when a RunningApp is changed to another RunningApp, or to no app.
## Changes the overlay focus to the overlay if no game is running or to the
## underlay process if a game is running.
func _on_app_switched(_from: RunningApp, to: RunningApp) -> void:
	if to == null:
		# Establish overlay focus in gamescope.
		gamescope.set_overlay(overlay_window_id, 1, display)
		gamescope.set_overlay(underlay_window_id, 0, display)
		game_running = false
		return
	gamescope.set_overlay(overlay_window_id, 0, display)
	gamescope.set_overlay(underlay_window_id, 1, display)
	game_running = true


## Verifies steam is still running by checking for the steam overlay, closes otherwise.
func _check_exit() -> void:
	if Reaper.get_pid_state(underlay_process) in ["R (running)", "S (sleeping)"]:
		return
	if gamescope.has_xprop(underlay_window_id, "STEAM_OVERLAY", display):
		return
	logger.debug("Steam closed. Shutting down.")
	get_tree().quit()


## Sets gamescope input focus to on so the user can interact with the UI

func _on_base_state_exited(_to: State) -> void:
	if gamescope.set_input_focus(overlay_window_id, 1) != OK:
		logger.error("Unable to set STEAM_INPUT_FOCUS atom!")


## Sets gamescope input focus to off so the user can interact with the game
func _on_base_state_entered(_from: State) -> void:

	if gamescope.set_input_focus(overlay_window_id, 0) != OK:
		logger.error("Unable to set STEAM_INPUT_FOCUS atom!")
