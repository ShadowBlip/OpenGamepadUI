extends Control

var settings_manager := preload("res://core/global/settings_manager.tres") as SettingsManager
var state_machine := preload("res://assets/state/state_machines/global_state_machine.tres") as StateMachine
var quick_bar_menu_state = preload("res://assets/state/states/quick_bar_menu.tres") as State
var settings_state = preload("res://assets/state/states/settings.tres") as State
var home_state = preload("res://assets/state/states/home.tres") as State

var gamescope := load("res://core/global/gamescope.tres") as Gamescope
var gamepad_manager := load("res://core/systems/input/gamepad_manager.tres") as GamepadManager
var launch_manager := load("res://core/global/launch_manager.tres") as LaunchManager
var default_gamepad_profile := load("res://assets/gamepad/profiles/default_overlay.tres") as GamepadProfile

var args := OS.get_cmdline_user_args()
var cmdargs := OS.get_cmdline_args()
var display := Gamescope.XWAYLAND.OGUI
var game_running: bool = false
var window_id: int
var pid: int = OS.get_process_id()
var shared_thread: SharedThread
var underlay_log: FileAccess
var underlay_process: InteractiveProcess
var underlay_window_id: int

@onready var quick_bar_menu := $%QuickBarMenu
@onready var settings_menu := $%SettingsMenu

var logger := Log.get_logger("Main", Log.LEVEL.INFO)

## Sets up PluginManager for overlay mode.
func _init():
	# Back button wont close windows without this. InputManager prevents poping the last state.
	state_machine.push_state(home_state)
	launch_manager.should_manage_overlay = false
	var plugin_loader := load("res://core/global/plugin_loader.tres") as PluginLoader
	var filters : Array[Callable] = [plugin_loader.filter_by_tag.bind("quick-bar")]
	plugin_loader.set_plugin_filters(filters)
	var plugin_manager_scene := load("res://core/systems/plugin/plugin_manager.tscn") as PackedScene
	var plugin_manager := plugin_manager_scene.instantiate()
	add_child(plugin_manager)

	# Set up our default gamepad profiles.
	gamepad_manager.default_profile = "res://assets/gamepad/profiles/default_overlay.tres"
	for gamepad in gamepad_manager.get_gamepad_paths():
		gamepad_manager.set_gamepad_profile(gamepad, default_gamepad_profile)
	
	# Whenever a gamepad is added/removed, set the correct intercept mode on it
	var on_gamepads_changed := func():
		var intercept := ManagedGamepad.INTERCEPT_MODE.PASS_QB
		if state_machine.has_state(quick_bar_menu_state):
			intercept = ManagedGamepad.INTERCEPT_MODE.ALL
		gamepad_manager.set_intercept(intercept)
	gamepad_manager.gamepads_changed.connect(on_gamepads_changed)
	
	# Listen for home state changes
	home_state.state_entered.connect(_on_home_state_entered)
	home_state.state_exited.connect(_on_home_state_exited)


## Starts the --overlay-mode session.
func _ready() -> void:
	# Workaround old versions that don't pass launch args via update pack
	# TODO: Parse the parent PID's CLI args and use those instead.
	if "--skip-update-pack" in cmdargs and args.size() == 0:
		logger.warn("Launched via update pack without arguments! Falling back to default.")
		args = ["steam", "-gamepadui", "-steamos3", "-steampal", "-steamdeck"]

	# Set the theme if one was set
	var theme_path := settings_manager.get_value("general", "theme", "") as String
	if theme_path == "":
		logger.debug("No theme set. Using default theme.")
	if theme_path != "":
		logger.debug("Setting theme to: " + theme_path)
		var loaded_theme = load(theme_path)
		if loaded_theme != null:
			theme = loaded_theme
		else:
			logger.debug("Unable to load theme")

	# Set window size to native resolution
	var screen_size : Vector2i = DisplayServer.screen_get_size()
	var window : Window = get_window()
	window.set_size(screen_size)

	# Set up the session
	_setup_overlay_mode(args)
	launch_manager.app_switched.connect(_on_app_switched)

## Finds needed PID's and global vars, Starts the user defined program in the sandbox.
func _setup_overlay_mode(args: Array) -> void:
	window_id = gamescope.get_window_id(pid, display)
	quick_bar_menu_state.state_entered.connect(_on_window_open)
	quick_bar_menu_state.state_exited.connect(_on_window_closed)
	settings_state.state_entered.connect(_on_window_open)
	settings_state.state_exited.connect(_on_window_closed)

	gamepad_manager.set_intercept(ManagedGamepad.INTERCEPT_MODE.PASS_QB)

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
	gamescope.set_overlay(window_id, 1, display)

	# Remove unneeded/conflicting elements from default menues
	var remove_list: PackedStringArray = ["PerformanceCard", "NotifyButton", "HelpButton", "VolumeSlider", "BrightnessSlider", "PerGameToggle"]
	_run_child_killer(remove_list, quick_bar_menu)
	var settings_remove_list: PackedStringArray = ["NetworkButton", "BluetoothButton", "AudioButton"]
	_run_child_killer(settings_remove_list, settings_menu)


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


func _start_steam_process(args: Array) -> void:
	# Setup steam
	var underlay_log_path = OS.get_environment("HOME") + "/.steam-stdout.log"
	_start_underlay_process(args, underlay_log_path)

	# Look for steam and save window ID
	while not underlay_window_id:
		# Find Steam in the display tree
		var root_win_id := gamescope.get_root_window_id(display)
		var all_windows := gamescope.get_all_windows(root_win_id, display)
		for window in all_windows:
			if window == window_id:
				continue
			if gamescope.has_xprop(window, "STEAM_OVERLAY", display):
				underlay_window_id = window
				logger.debug("Found steam! " + str(underlay_window_id))
				break
		# Wait a bit to reduce cpu load.
		OS.delay_msec(1000)

	# Start timer to check if steam has exited.
	var exit_timer := Timer.new()
	exit_timer.set_one_shot(false)
	exit_timer.set_timer_process_callback(Timer.TIMER_PROCESS_IDLE)
	exit_timer.timeout.connect(_check_exit)
	add_child(exit_timer)
	exit_timer.start()


func _start_underlay_process(args: Array, log_path: String) -> void:
	# Start the shared thread we use for logging.
	shared_thread = SharedThread.new()
	shared_thread.start()

	# Setup logging
	underlay_log = FileAccess.open(log_path, FileAccess.WRITE)
	var error := underlay_log.get_open_error()
	if error != OK:
		logger.warn("Got error opening log file.")
	else:
		logger.info("Started logging underlay process at " + log_path)
	var command: String = args[0]
	args.remove_at(0)
	underlay_process = InteractiveProcess.new(command, args)
	if underlay_process.start() != OK:
		logger.error("Failed to start child process.")
		return
	var logger_func := func(delta: float):
		underlay_process.output_to_log_file(underlay_log)
	shared_thread.add_process(logger_func)


## Called when "quick_bar_menu_state" is entered.
func _on_window_open(_from: State) -> void:
	if _from:
		logger.info("Quick bar open state: " + _from.name)
	gamepad_manager.set_intercept(ManagedGamepad.INTERCEPT_MODE.ALL)
	if game_running:
		gamescope.set_overlay(window_id, 1, display)
		gamescope.set_overlay(underlay_window_id, 0, display)


## Called when "quick_bar_menu_state" is exited.
func _on_window_closed(_to: State) -> void:
	if _to:
		logger.info("Quick bar closed state: " + _to.name)
	gamepad_manager.set_intercept(ManagedGamepad.INTERCEPT_MODE.PASS_QB)
	if game_running:
		gamescope.set_overlay(window_id, 0, display)
		gamescope.set_overlay(underlay_window_id, 1, display)


func _on_app_switched(_from: RunningApp, to: RunningApp) -> void:
	if to == null:
		# Establish overlay focus in gamescope.
		gamescope.set_overlay(window_id, 1, display)
		gamescope.set_overlay(underlay_window_id, 0, display)
		game_running = false
		return
	gamescope.set_overlay(window_id, 0, display)
	gamescope.set_overlay(underlay_window_id, 1, display)
	game_running = true


## Verifies steam is still running by checking for the steam overlay, closes otherwise.
func _check_exit() -> void:
	if gamescope.has_xprop(underlay_window_id, "STEAM_OVERLAY", display):
		return
	logger.debug("Steam closed. Shutting down.")
	get_tree().quit()


func _on_home_state_exited(_to: State) -> void:
	# Set gamescope input focus to on so the user can interact with the UI
	if gamescope.set_input_focus(window_id, 1) != OK:
		logger.error("Unable to set STEAM_INPUT_FOCUS atom!")


func _on_home_state_entered(_from: State) -> void:
	# Set gamescope input focus to off so the user can interact with the game
	if gamescope.set_input_focus(window_id, 0) != OK:
		logger.error("Unable to set STEAM_INPUT_FOCUS atom!")
