@icon("res://assets/icons/upload.svg")
extends Resource
class_name LaunchManager

## Launch and manage the lifecycle of subprocesses
##
## The LaunchManager class is responsible starting and managing the lifecycle of 
## games and is one of the most complex systems in OpenGamepadUI. Using 
## gamescope, it manages what games start, if their process is still running, 
## and fascilitates window switching between games. It also provides a mechanism 
## to kill running games and discover child processes. It uses a timer to 
## periodically check on launched games to see if they have exited, or are 
## opening new windows that might need attention. Example:
##     [codeblock]
##     const LaunchManager := preload("res://core/global/launch_manager.tres")
##     ...
##     # Create a LibraryLaunchItem to run something
##     var item := LibraryLaunchItem.new()
##     item.command = "vkcube"
##     
##     # Launch the app with LaunchManager
##     var running_app := LaunchManager.launch(item)
##     
##     # Get a list of running apps
##     var running := LaunchManager.get_running()
##     print(running)
##     
##     # Stop an app with LaunchManager
##     LaunchManager.stop(running_app)
##     [/codeblock]

signal app_launched(app: RunningApp)
signal app_stopped(app: RunningApp)
signal app_switched(from: RunningApp, to: RunningApp)
signal recent_apps_changed()

const SettingsManager := preload("res://core/global/settings_manager.tres")
const InputManager := preload("res://core/global/input_manager.tres")
const NotificationManager := preload("res://core/global/notification_manager.tres")
const Gamescope := preload("res://core/global/gamescope.tres")

var state_machine := preload("res://assets/state/state_machines/global_state_machine.tres") as StateMachine
var in_game_state := preload("res://assets/state/states/in_game.tres") as State
var in_game_menu_state := preload("res://assets/state/states/in_game_menu.tres") as State

var _current_app: RunningApp
var _pid_to_windows := {}
var _running: Array[RunningApp] = []
var _apps_by_pid: Dictionary = {}
var _apps_by_name: Dictionary = {}
var _all_apps_by_name: Dictionary = {}
var _data_dir: String = ProjectSettings.get_setting("OpenGamepadUI/data/directory")
var _persist_path: String = "/".join([_data_dir, "launcher.json"])
var _persist_data: Dictionary = {"version": 1}
var logger := Log.get_logger("LaunchManager", Log.LEVEL.DEBUG)


# Loads persistent data like recent games launched, etc.
func _load_persist_data():
	# Create the data directory if it doesn't exist
	DirAccess.make_dir_absolute(_data_dir)
	
	# Create our data file if it doesn't exist
	if not FileAccess.file_exists(_persist_path):
		logger.debug("LaunchManager: Launcher data does not exist. Creating it.")
		_save_persist_data()
	
	# Read our persistent data and parse it
	var file: FileAccess = FileAccess.open(_persist_path, FileAccess.READ)
	var data: String = file.get_as_text()
	_persist_data = JSON.parse_string(data)
	logger.debug("LaunchManager: Loaded persistent data")
	

# Saves our persistent data
func _save_persist_data():
	var file: FileAccess = FileAccess.open(_persist_path, FileAccess.WRITE_READ)
	file.store_string(JSON.stringify(_persist_data))
	file.flush()


## Returns whether or not we can launch via sandboxing
func has_sandboxing() -> bool:
	return OS.execute("which", ["firejail"]) == 0


## Launches the given command on the target xwayland display. Returns a PID
## of the launched process.
func launch(app: LibraryLaunchItem) -> RunningApp:
	var cmd: String = app.command
	var args: PackedStringArray = app.args
	var env: Dictionary = app.env.duplicate()
	var cwd: String = OS.get_environment("HOME")
	if app.cwd != "":
		cwd = app.cwd

	# Override any parameters that may be in the user's config for this game
	var section := ".".join(["game", app.name.to_lower()])
	var cmd_key := ".".join(["command", app._provider_id])
	var user_cmd = SettingsManager.get_value(section, cmd_key)
	if user_cmd and user_cmd is String:
		cmd = user_cmd
	var args_key := ".".join(["args", app._provider_id])
	var user_args = SettingsManager.get_value(section, args_key)
	if user_args and user_args is PackedStringArray:
		args = user_args
	var cwd_key := ".".join(["cwd", app._provider_id])
	var user_cwd = SettingsManager.get_value(section, cwd_key)
	if user_cwd and user_cwd is String:
		cwd = user_cwd
	var env_key := ".".join(["env", app._provider_id])
	var user_env = SettingsManager.get_value(section, env_key)
	if user_env and user_env is Dictionary:
		env = user_env
	
	# Set the display environment if one was not set.
	if not "DISPLAY" in env:
		env["DISPLAY"] = Gamescope.get_display_name(Gamescope.XWAYLAND.GAME)
	var display := env["DISPLAY"] as String

	# Build any environment variables to include in the command
	var env_vars := PackedStringArray()
	for key in env.keys():
		env_vars.append("{0}={1}".format([key, env[key]]))
	
	# If sandboxing is available, launch the game in the sandbox 
	var sandbox := PackedStringArray()
	if has_sandboxing():
		sandbox.append_array(["firejail", "--noprofile"])
		var blacklist := InputManager.get_managed_gamepads()
		for device in blacklist:
			sandbox.append("--blacklist=%s" % device)
		sandbox.append("--")

	# Build the launch command to run
	var exec := "env"
	var command := ["-C", cwd]
	command.append_array(env_vars)
	command.append_array(sandbox)
	command.append(cmd)
	command.append_array(args)
	logger.info("Launching game with command: {0} {1}".format([exec, str(command)]))

	# Launch the application process
	var pid = OS.create_process(exec, command)
	logger.info("Launched with PID: {0}".format([pid]))

	# Create a running app instance
	if not app.name in _all_apps_by_name:
		_all_apps_by_name[app.name] = RunningApp.new(app, pid, display)
	var running_app := _all_apps_by_name[app.name] as RunningApp
	running_app.launch_item = app
	running_app.pid = pid
	running_app.display = display

	# Check to see if this game has any gamepad profiles. If so, set our 
	# gamepads to use them.
	var profile_path = SettingsManager.get_value(section, "gamepad_profile", "")
	set_gamepad_profile(profile_path)

	# Add the running app to our list and change to the IN_GAME state
	_add_running(running_app)
	state_machine.set_state([in_game_state])
	_update_recent_apps(app)
	return running_app


## Sets the gamepad profile for the running app with the given profile
func set_gamepad_profile(path: String) -> void:
	# If no profile was specified, unset the gamepad profiles
	if path == "":
		for gamepad in InputManager.get_managed_gamepads():
			InputManager.set_gamepad_profile(gamepad, null)
		return
	
	# Try to load the profile and set it
	var profile := load(path)

	# TODO: Save profiles for individual controllers?
	for gamepad in InputManager.get_managed_gamepads():
		InputManager.set_gamepad_profile(gamepad, profile)
	if not profile:
		logger.warn("Gamepad profile not found: " + path)
		return
	var notify := Notification.new("Using gamepad profile: " + profile.name)
	NotificationManager.show(notify)


## Stops the game and all its children with the given PID
func stop(app: RunningApp) -> void:
	Reaper.reap(app.pid)
	_remove_running(app)


## Returns a list of apps that have been launched recently
func get_recent_apps() -> Array:
	var recent := []
	if not "recent" in _persist_data:
		return recent
	var max_recent := SettingsManager.get_value("general.home", "max_home_items", 10) as int
	var i := 1
	for app in _persist_data["recent"]:
		if i > max_recent:
			break
		recent.push_back(app)
		i += 1
	return recent


## Returns a list of currently running apps
func get_running() -> Array[RunningApp]:
	return _running


## Returns the currently running app
func get_current_app() -> RunningApp:
	return _current_app


## Sets the given running app as the current app
func set_current_app(app: RunningApp, switch_baselayer: bool = true) -> void:
	if switch_baselayer:
		if not can_switch_app(app):
			return
		Gamescope.set_baselayer_window(app.window_id)
	var old := _current_app
	_current_app = app
	app_switched.emit(old, app)

	# Check to see if this game has any gamepad profiles. If so, set our 
	# gamepads to use them.
	var section := ".".join(["game", app.launch_item.name.to_lower()])
	var profile_path = SettingsManager.get_value(section, "gamepad_profile", "")
	set_gamepad_profile(profile_path)


## Returns true if the given app can be switched to via Gamescope
func can_switch_app(app: RunningApp) -> bool:
	if app == null:
		logger.warn("Unable to switch to null app")
		return false
	if not app.window_id > 0:
		logger.warn("No Window ID was found for given app")
		return false
	return true


## Returns whether the given app is running
func is_running(app_name: String) -> bool:
	if app_name in _apps_by_name:
		return true
	return false


## Returns a list of window IDs that don't have a corresponding RunningApp
func get_orphan_windows(focusable: PackedInt32Array) -> Array[int]:
	var orphans: Array[int] = []
	
	var windows_with_app := []
	for app in _running:
		if app.window_id in focusable:
			windows_with_app.push_back(app.window_id)
	for window_id in focusable:
		if window_id in windows_with_app:
			continue
		orphans.push_back(window_id)
	return orphans


# Updates our list of recently launched apps
func _update_recent_apps(app: LibraryLaunchItem) -> void:
	if not "recent" in _persist_data:
		_persist_data["recent"] = []
	var recent: Array = _persist_data["recent"]
	recent.erase(app.name)
	recent.push_front(app.name)

	if len(recent) > 30:
		recent.pop_back()
	_persist_data["recent"] = recent
	_save_persist_data()
	recent_apps_changed.emit()


# Adds the given PID to our list of running apps
func _add_running(app: RunningApp):
	_apps_by_pid[app.pid] = app
	_apps_by_name[app.launch_item.name] = app
	_running.append(app)
	set_current_app(app, false)
	app_launched.emit(app)


# Removes the given PID from our list of running apps
func _remove_running(app: RunningApp):
	logger.info("Cleaning up pid {0}".format([app.pid]))
	_running.erase(app)
	_apps_by_name.erase(app.launch_item.name)
	_apps_by_pid.erase(app.pid)

	if app == _current_app:
		if _running.size() > 0:
			set_current_app(_running[-1])
		else:
			set_current_app(null, false)

	# If no more apps are running, clear the in-game state
	if len(_running) == 0:
		Gamescope.remove_baselayer_window()
		state_machine.remove_state(in_game_state)
		state_machine.remove_state(in_game_menu_state)
	
	app_stopped.emit(app)
	app.app_killed.emit()


# Checks for running apps and updates our state accordingly
func _check_running():
	# Find the root window
	var root_id := Gamescope.get_root_window_id(Gamescope.XWAYLAND.GAME)
	if root_id < 0:
		return
	
	# Update our view of running processes and what windows they have
	_update_pids(root_id)
	
	# If nothing should is running, skip our window checks
	if len(_running) == 0:
		return

	# TODO: Maybe start a timer for any apps that haven't produced a window
	# in a certain timeframe? If the timer ends, kill everything.

	var focusable_windows := Gamescope.get_window_children(root_id, Gamescope.XWAYLAND.GAME)
	var focusable_apps := Gamescope.get_focusable_apps()

	# Get a list of orphaned windows to try and pair windows with running apps
	var orphan_windows := get_orphan_windows(focusable_windows) as Array
	
	# Hacky?
	# Don't consider windows that come from a process in our blacklist
	var pid_blacklist := ["steam", "default ime"] # "gamescope-wl"?
	for pid in _pid_to_windows.keys():
		var pid_info := Reaper.get_pid_status(pid)
		var pid_name := ""
		if "Name" in pid_info:
			pid_name = pid_info["Name"]
		if not pid_name in pid_blacklist:
			continue
		for window in _pid_to_windows[pid]:
			orphan_windows.erase(window)
	
	# Check all running apps
	var to_remove := []
	for app in _running:
		# Ensure that the running app has a corresponding window ID and app ID
		_ensure_window_id(app, focusable_windows, orphan_windows)
		_ensure_app_id(app, focusable_windows, focusable_apps)
		
		# If our app is still running, great!
		if app.is_running():
			continue
		
		# If it's not running, make sure we remove it from our list
		to_remove.push_back(app)
		
	# Remove any non-running apps
	for app in to_remove:
		_remove_running(app)


# Updates our mapping of PIDs to Windows. This gives us a good view of what
# processes are running, and what windows they have.
func _update_pids(root_id: int):
	var pids := {}
	var all_windows := Gamescope.get_all_windows(root_id, Gamescope.XWAYLAND.GAME)
	for window in all_windows:
		var pid := Gamescope.get_window_pid(window, Gamescope.XWAYLAND.GAME)
		if not pid in pids:
			pids[pid] = []
		pids[pid].append(window)
	_pid_to_windows = pids


# Ensures that the given app has a window id associated with it
func _ensure_window_id(app: RunningApp, focusable: Array, orphan_windows: Array) -> void:
	# Try to set the window ID to allow app switching
	var needs_window_id := false
	if app.window_id <= 0:
		logger.debug(app.launch_item.name + " has a bad window ID: " + str(app.window_id))
		needs_window_id = true
	elif not app.window_id in focusable:
		logger.debug(str(app.window_id) + " is not in the list of focusable windows")
		needs_window_id = true
	elif app.app_id < 1:
		logger.debug(app.launch_item.name + " has no valid app ID")
		needs_window_id = true
	#elif app.window_id > 0 and not Gamescope.is_focusable_app(overlay_display, app.window_id):
	#	needs_window_id = true
	if not needs_window_id:
		return
	var discovered := _discover_window_id(app, orphan_windows)
	if discovered <= 0:
		return
	
	# Set the window ID
	logger.debug("Setting app '" + app.launch_item.name + "' to window ID: " + str(discovered))
	app.window_id = discovered


func _ensure_app_id(app: RunningApp, focusable_windows: Array, focusable_apps: Array):
	if app.window_id <= 0 or not app.window_id in focusable_windows:
		logger.debug("No valid window ID to set app ID on")
		return
	if app.app_id > 0 and app.app_id in focusable_apps:
		logger.debug("App ID already exists in focusable apps")
		return
	var app_id := Gamescope.get_app_id(app.window_id)
	if app_id > 0:
		if app.app_id == app_id:
			return
		logger.debug("Window already has app ID set. Using app ID from window: " + str(app_id))
		app.app_id = app_id
		return
	
	# Set the app ID atom so the app is focusable by Gamescope in Steam mode
	if app.launch_item.provider_app_id.is_valid_int():
		app.app_id = app.launch_item.provider_app_id.to_int()
		logger.debug("Setting window {0} to use provider app ID: {1}".format([app.window_id, app.app_id]))

	elif Gamescope.get_app_id(app.window_id) < 0:
		app.app_id = app.window_id
		logger.debug("Setting window {0} to use window app ID: {1}".format([app.window_id, app.app_id]))
		
	if app.app_id > 0:
		Gamescope.set_app_id(app.window_id, app.app_id)


# Try to discover the window id of the given app
func _discover_window_id(app: RunningApp, orphan_windows: Array[int]) -> int:
	var window_id := app.get_window_id_from_pid()
	if window_id > 0:
		logger.debug("Found window ID for {0} from PID: {1}".format([app.launch_item.name, window_id]))
		return window_id
		
	# Look through orphan windows for a possible match
	# TODO: Any way we can do this better?
	var blacklist := ["steam", "steamcompmgr"]
	var candidates := [[], [], [], []]  # High, medium, low, garbage chance window candidates
	for window in orphan_windows:
		# Find by app ID atom (High chance match)
		var app_id := Gamescope.get_app_id(window)
		if app_id > 0:
			logger.debug("Orphan window {0} has an app id set: {1}".format([window, app_id]))
			candidates[0].append(window)
			continue
			
		# Find by window name (Medium chance match)
		var window_name := Gamescope.get_window_name(window)
		if app.launch_item.name.to_lower() == window_name.to_lower():
			logger.debug("Orphan window name {0} matches {1}".format([window, app.launch_item.name]))
			candidates[1].append(window)
			continue
		
		# Garbage chance matches
		if window_name == "":
			candidates[3].append(window)
			continue
		if window_name.to_lower() in blacklist:
			continue
		
		# Low chance matches
		candidates[2].append(window)
	
	# Return the window ID of the best candidate that matches the app
	var i := 0
	var chance_map := ["high", "medium", "low", "garbage"]
	for windows in candidates:
		if windows.size() > 0:
			var window: int = windows[0]
			var window_name := Gamescope.get_window_name(window)
			logger.debug("Found {0} chance that window '{1}' ({2}) is {3}".format([
				chance_map[i], window_name, window, app.launch_item.name
			]))
			return windows[0]
		i += 1
	logger.debug("Unable to discover window for: " + app.launch_item.name)
	return -1

