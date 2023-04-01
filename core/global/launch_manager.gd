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

var _sandbox := Sandbox.get_sandbox()
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
	
	# Set the OGUI ID environment variable
	env["OGUI_ID"] = app.name

	# Build any environment variables to include in the command
	var env_vars := PackedStringArray()
	for key in env.keys():
		env_vars.append("{0}={1}".format([key, env[key]]))
	
	# If sandboxing is available, launch the game in the sandbox 
	var sandbox := _sandbox.get_command(app)

	# Build the launch command to run
	var exec := "env"
	var command := ["-C", cwd]
	command.append_array(env_vars)
	command.append_array(sandbox)
	command.append(cmd)
	command.append_array(args)
	logger.info("Launching game with command: {0} {1}".format([exec, str(command)]))

	# Launch the application process
	var pid = Reaper.create_process(exec, command)
	logger.info("Launched with PID: {0}".format([pid]))

	# Create a running app instance
	if not app.name in _all_apps_by_name:
		_all_apps_by_name[app.name] = RunningApp.new(app, pid, display)
	var running_app := _all_apps_by_name[app.name] as RunningApp
	running_app.launch_item = app
	running_app.pid = pid
	running_app.display = display
	running_app.command = command
	running_app.environment = env

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
	app.kill()
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

	# Return if we are switching to null
	if not app:
		return

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

	# Check all running apps
	var to_remove := []
	for app in _running:
		var app_name := app.launch_item.name
		# Ensure that all windows related to the app have an app ID set
		app.ensure_app_id()
		
		# Ensure that the running app has a corresponding window ID
		if app.needs_window_id():
			var window_id := app.discover_window_id()
			if window_id > 0:
				logger.debug("Setting window ID " + str(window_id) + " for " + app_name)
				app.window_id = window_id
		
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
