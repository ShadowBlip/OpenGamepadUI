extends Control

# Managers
var platform := load("res://core/global/platform.tres") as Platform
var gamescope := load("res://core/systems/gamescope/gamescope.tres") as GamescopeInstance
var launch_manager := load("res://core/global/launch_manager.tres") as LaunchManager
var settings_manager := load("res://core/global/settings_manager.tres") as SettingsManager
var input_plumber := load("res://core/systems/input/input_plumber.tres") as InputPlumberInstance

# State
var state_machine := (
	preload("res://assets/state/state_machines/global_state_machine.tres") as StateMachine
)
var menu_state_machine := preload("res://assets/state/state_machines/menu_state_machine.tres") as StateMachine
var popup_state_machine := preload("res://assets/state/state_machines/popup_state_machine.tres") as StateMachine
var menu_state := preload("res://assets/state/states/menu.tres") as State
var popup_state := preload("res://assets/state/states/popup.tres") as State
var quick_bar_state := preload("res://assets/state/states/quick_bar_menu.tres") as State
var settings_state := preload("res://assets/state/states/settings.tres") as State
var gamepad_state := preload("res://assets/state/states/gamepad_settings.tres") as State
var base_state := preload("res://assets/state/states/in_game.tres") as State

# Xwayland 
var managed_states: Array[State] = [quick_bar_state, settings_state, gamepad_state]
var xwayland_primary := gamescope.get_xwayland(gamescope.XWAYLAND_TYPE_PRIMARY)
var xwayland_ogui := gamescope.get_xwayland(gamescope.XWAYLAND_TYPE_OGUI)
var overlay_window_id := 0
var set_steam_overlay_focus := false

# Process
var PID: int = OS.get_process_id()
var launch_args := OS.get_cmdline_user_args()
var cmdargs := OS.get_cmdline_args()
var underlay_log: FileAccess
var underlay_process: int
var underlay_window_id: int

# UI References
@onready var quick_bar_menu := $%QuickBarMenu
@onready var settings_menu := $%SettingsMenu

# Constants

const remove_list: PackedStringArray = [
	"KeyboardButton",
	"NotifyButton",
	"HelpButton",
	"VolumeSlider",
	"BrightnessSlider",
	"PerGameToggle",
	"MangoAppSlider",
	"FramerateLimitSlider",
	"RefreshRateSlider"
	]

const settings_remove_list: PackedStringArray = [
	"LibraryButton",
	"NetworkButton",
	"BluetoothButton",
	"AudioButton"
	]

# Logger
var logger := Log.get_logger("Main", Log.LEVEL.INFO)

## Sets up overlay mode.
func _init():
	# Discover the OpenGamepadUI window ID
	if xwayland_ogui:
		var ogui_windows := xwayland_ogui.get_windows_for_pid(PID)
		if not ogui_windows.is_empty():
			overlay_window_id = ogui_windows[0]
	if overlay_window_id <= 0:
		logger.error("Unable to detect Window ID. Overlay is not going to work!")
	logger.info("Found primary window id: {0}".format([overlay_window_id]))

	# Ensure LaunchManager doesn't override our custom overlay management l
	launch_manager.should_manage_overlay = false

	# Set up plugin manager for quick-bar tags
	var plugin_loader := load("res://core/global/plugin_loader.tres") as PluginLoader
	var filters : Array[Callable] = [plugin_loader.filter_by_tag.bind("quick-bar")]
	plugin_loader.set_plugin_filters(filters)
	var plugin_manager_scene := load("res://core/systems/plugin/plugin_manager.tscn") as PackedScene
	var plugin_manager := plugin_manager_scene.instantiate()
	add_child(plugin_manager)


## Starts the --overlay-mode session.
func _ready() -> void:
	# Workaround old versions that don't pass launch args via update pack
	# TODO: Parse the parent PID's CLI args and use those instead.
	if "--skip-update-pack" in cmdargs and launch_args.size() == 0:
		logger.warn("Launched via update pack without arguments! Falling back to default.")
		launch_args = PackedStringArray(["steam", "-gamepadui", "-steamos3", "-steampal", "-steamdeck"])

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
	_setup_overlay_mode(launch_args)

	# Set the theme if one was set
	var theme_path := settings_manager.get_value("general", "theme", "res://assets/themes/card_ui-darksoul.tres") as String
	if theme_path.is_empty():
		logger.error("Failed to load theme from settings manager.")
		return
	logger.debug("Setting theme to: " + theme_path)
	var loaded_theme = load(theme_path)
	if loaded_theme != null:
		@warning_ignore("unsafe_call_argument")
		set_theme(loaded_theme)
	else:
		logger.debug("Unable to load theme")


## Finds needed PID's and global vars, Starts the user defined program as an
## underlay process.
func _setup_overlay_mode(args: PackedStringArray) -> void:
	# Always push the base state if we end up with an empty stack.
	var on_states_emptied := func():
		state_machine.push_state.call_deferred(base_state)
	state_machine.emptied.connect(on_states_emptied)

	# Back button wont close windows without this. OverlayInputManager prevents poping the last state.
	state_machine.push_state(base_state)

	# Whenever the menu state is refreshed, refresh the menu state machine to
	# re-grab focus.
	var on_menu_refreshed := func():
		menu_state_machine.refresh()
	menu_state.refreshed.connect(on_menu_refreshed)

	# Whenever the menu state is entered, refresh the menu state machine to
	# re-grab focus
	var on_menu_state_entered := func(_from: State):
		menu_state_machine.refresh()
	menu_state.state_entered.connect(on_menu_state_entered)
	var on_menu_state_removed := func():
		menu_state_machine.clear_states()
	menu_state.state_removed.connect(on_menu_state_removed)
	var on_menu_states_empty := func():
		state_machine.remove_state(menu_state)
	menu_state_machine.emptied.connect(on_menu_states_empty)

	# Whenever an popup state is pushed, update the global state
	var on_popup_state_changed := func(_from: State, to: State):
		if to:
			state_machine.push_state(popup_state)
		else:
			state_machine.remove_state(popup_state)
	popup_state_machine.state_changed.connect(on_popup_state_changed)

	# Show/hide the overlay when we enter/exit the in-game state
	base_state.state_entered.connect(_on_base_state_entered)
	base_state.state_exited.connect(_on_base_state_exited)

	# Don't crash if we're not launching another program.
	if args.is_empty():
		logger.warn("overlay mode started with no launcher arguments.")
		return

	if "steam" in args:
		logger.info("Starting Steam with args:", args)
		_start_steam_process(args)
	else:
		logger.info("Starting underlay process with args:", args)
		var log_path := OS.get_environment("HOME") + "/.underlay-stdout.log"
		_start_underlay_process(args, log_path)

	# Remove unneeded/conflicting elements from default menues

	_remove_children(remove_list, quick_bar_menu)
	_remove_children(settings_remove_list, settings_menu)

	# Enable InputPlumber management of all supported input devices
	input_plumber.manage_all_devices = true

	# Setup inputplumber to receive guide presses.
	input_plumber.set_intercept_mode(InputPlumberInstance.INTERCEPT_MODE_PASS)
	input_plumber.set_intercept_activation(PackedStringArray(["Gamepad:Button:Guide", "Gamepad:Button:East"]), "Gamepad:Button:QuickAccess2")

	# Sets the intercept mode and intercept activation keys to what overlay_mode expects.
	var on_device_changed := func(device: CompositeDevice):
		var intercept_mode := input_plumber.intercept_mode
		logger.debug("Setting intercept mode to: " + str(intercept_mode))
		device.intercept_mode = intercept_mode
		device.set_intercept_activation(PackedStringArray(["Gamepad:Button:Guide", "Gamepad:Button:East"]), "Gamepad:Button:QuickAccess2")
	input_plumber.composite_device_added.connect(on_device_changed)


# Removes specified child elements from the given Node.
func _remove_children(remove_list: PackedStringArray, parent:Node) -> void:
	var child_count := parent.get_child_count()
	var to_remove_list: Array[Node] = []

	for child_idx in child_count:
		var child := parent.get_child(child_idx)
		logger.trace("Checking if " + child.name + " in remove list...")
		if child.name in remove_list:
			logger.trace(child.name + " queued for removal!")
			to_remove_list.append(child)
			continue

		logger.trace(child.name + " is not a node we are looking for.")
		var grandchild_count := child.get_child_count()
		if grandchild_count > 0:
			logger.trace("Checking " + child.name + "'s children...")
			_remove_children(remove_list, child)

	for child in to_remove_list:
		logger.trace("Removing " + child.name)
		child.queue_free()


## Starts Steam as an underlay process
func _start_steam_process(args: PackedStringArray) -> void:
	logger.debug("Starting steam: " + str(args))
	var underlay_log_path := OS.get_environment("HOME") + "/.steam-stdout.log"
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
func _start_underlay_process(args: PackedStringArray, _log_path: String) -> void:
	logger.debug("Starting underlay process: " + str(args))
	## TODO: Fix this so it works
	## Set up logging in the new thread.
	#args.append("2>&1")
	#args.append(log_path)

	# Setup logging
	#underlay_log = FileAccess.open(log_path, FileAccess.WRITE)
	#var error := FileAccess.get_open_error()
	#if error != OK:
		#logger.warn("Got error opening log file.")
	#else:
		#logger.info("Started logging underlay process at " + log_path)
	var command: String = args[0]
	args.remove_at(0)
	underlay_process = Reaper.create_process(command, args)


## Called to identify the xwayland window ID of the underlay process.
func _find_underlay_window_id() -> void:
	# Find Steam in the display tree
	var root_win_id := xwayland_ogui.root_window_id
	var all_windows := xwayland_ogui.get_all_windows(root_win_id)
	for window in all_windows:
		if window == overlay_window_id:
			continue
		if xwayland_ogui.has_notification(window):
			underlay_window_id = window
			logger.info("Found steam! " + str(underlay_window_id))
			break

	# If we didn't find the window_id, set up a tiemr to loop back and try again.
	if underlay_window_id <= 0:
		logger.debug("Unable to find steam PID. Checking again in 1 second...")
		var underlay_window_timer := Timer.new()
		underlay_window_timer.set_one_shot(true)
		underlay_window_timer.set_timer_process_callback(Timer.TIMER_PROCESS_IDLE)
		underlay_window_timer.timeout.connect(_find_underlay_window_id)
		add_child(underlay_window_timer)
		underlay_window_timer.start()


## Called when the base state is entered.
func _on_base_state_entered(_from: State) -> void:
	logger.debug("Setting Underlay proccess window as overlay")

	# Manage input focus
	input_plumber.set_intercept_mode(InputPlumberInstance.INTERCEPT_MODE_PASS)
	if xwayland_ogui.set_input_focus(overlay_window_id, 0) != OK:
		logger.error("Unable to set STEAM_INPUT_FOCUS atom!")
	if xwayland_ogui.set_input_focus(underlay_window_id, 1) != OK:
		logger.error("Unable to set STEAM_INPUT_FOCUS atom!")

	# Manage overlay
	xwayland_ogui.set_overlay(overlay_window_id, 0)
	if self.set_steam_overlay_focus:
		xwayland_ogui.set_overlay(underlay_window_id, 1)


## Called when a the base state is exited.
func _on_base_state_exited(_to: State) -> void:
	logger.debug("Setting OpenGamepadUI window as overlay")

	# Manage input focus
	input_plumber.set_intercept_mode(InputPlumberInstance.INTERCEPT_MODE_ALL)
	if xwayland_ogui.set_input_focus(overlay_window_id, 1) != OK:
		logger.error("Unable to set STEAM_INPUT_FOCUS atom!")
	if xwayland_ogui.set_input_focus(underlay_window_id, 0) != OK:
		logger.error("Unable to set STEAM_INPUT_FOCUS atom!")

	# Manage overlay
	self.set_steam_overlay_focus = xwayland_ogui.get_overlay(underlay_window_id) == 1
	xwayland_ogui.set_overlay(overlay_window_id, 1)
	if self.set_steam_overlay_focus:
		xwayland_ogui.set_overlay(underlay_window_id, 0)


## Verifies steam is still running by checking for the steam overlay, closes otherwise.
func _check_exit() -> void:
	if Reaper.get_pid_state(underlay_process) in ["R (running)", "S (sleeping)"]:
		return
	if xwayland_ogui.has_overlay(underlay_window_id):
		return
	logger.debug("Steam closed. Shutting down.")
	get_tree().quit()
