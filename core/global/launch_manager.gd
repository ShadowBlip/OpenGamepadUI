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
const NotificationManager := preload("res://core/global/notification_manager.tres")

var gamepad_manager := load("res://core/systems/input/gamepad_manager.tres") as GamepadManager

var Gamescope := preload("res://core/global/gamescope.tres") as Gamescope

var state_machine := preload("res://assets/state/state_machines/global_state_machine.tres") as StateMachine
var in_game_state := preload("res://assets/state/states/in_game.tres") as State
var in_game_menu_state := preload("res://assets/state/states/in_game_menu.tres") as State

var PID: int = OS.get_process_id()
var _sandbox := Sandbox.get_sandbox()
var _current_app: RunningApp
var _pid_to_windows := {}
var _running: Array[RunningApp] = []
var _stopping: Array[RunningApp] = []
var _apps_by_pid: Dictionary = {}
var _apps_by_name: Dictionary = {}
var _data_dir: String = ProjectSettings.get_setting("OpenGamepadUI/data/directory")
var _persist_path: String = "/".join([_data_dir, "launcher.json"])
var _persist_data: Dictionary = {"version": 1}
var logger := Log.get_logger("LaunchManager", Log.LEVEL.INFO)
var should_manage_overlay := true

# Connect to Gamescope signals
func _init() -> void:

	# When window focus changes, update the current app and gamepad profile
	var on_focus_changed := func(from: int, to: int):
		logger.info("Window focus changed from " + str(from) + " to: " + str(to))
		var last_app := _current_app
		_current_app = get_running_from_window_id(to)
		# If there is no _current_app then another process opened this window. Find it.
		if _current_app == null:
			_current_app = _detect_running_app(to)

		logger.debug("Last app: " + str(last_app) + " current_app: " + str(_current_app))
		app_switched.emit(last_app, _current_app)
		# If the app has a gamepad profile, set it
		set_app_gamepad_profile(_current_app)

		# If we don't want LaunchManager to manage overlay (I.E. overlay mode), return false always.
		if not should_manage_overlay:
			return

		# Check to see if the overlay property needs updating
		var focusable_apps := Gamescope.get_focusable_apps()
		if _should_set_overlay(focusable_apps):
			var ogui_window_id = Gamescope.get_window_id(PID, Gamescope.XWAYLAND.OGUI)
			Gamescope.set_overlay(ogui_window_id, 1)
			return

	Gamescope.focused_window_updated.connect(on_focus_changed)

	# Ensure that the overlay property is set when other apps are launched.
	var on_focusable_apps_changed := func(from: PackedInt32Array, to: PackedInt32Array):
		# If we don't want LaunchManager to manage overlay (I.E. overlay mode), return false always.
		if not should_manage_overlay:
			return

		# Check to see if the overlay property needs updating
		logger.debug("Apps changed from " + str(from) + " to " + str(to))
		var ogui_window_id = Gamescope.get_window_id(PID, Gamescope.XWAYLAND.OGUI)
		if _should_set_overlay(to):
			logger.debug("Other focusable apps exist. Enabling STEAM_OVERLAY.")
			Gamescope.set_overlay(ogui_window_id, 1)
			return

		logger.debug("No other focusable apps. Removing STEAM_OVERLAY.")
		Gamescope.set_overlay(ogui_window_id, 0)

	Gamescope.focusable_apps_updated.connect(on_focusable_apps_changed)

	# Debug print when the focused app changed
	var on_focused_app_changed := func(from: int, to: int) -> void:
		logger.debug("Focused app changed from " + str(from) + " to " + str(to))
	Gamescope.focused_app_updated.connect(on_focused_app_changed)

	# Whenever the in-game state is entered, set the gamepad profile
	var on_game_state_entered := func(from: State):
		if _current_app:
			set_app_gamepad_profile(_current_app)

	in_game_state.state_entered.connect(on_game_state_entered)


# Returns true if the 'STEAM_OVERLAY' prop should be set. This property should
# ALWAYS be set to '1' if there are any other windows/apps. Only when OGUI
# is the last remaining app should it be disabled.
func _should_set_overlay(focusable_apps: PackedInt32Array) -> bool:
	# If there are no focusable apps, then the overlay property should be disabled.
	if focusable_apps.size() == 0:
		return false

	var ogui_window_id = Gamescope.get_window_id(PID, Gamescope.XWAYLAND.OGUI)
	var focused_window := Gamescope.get_focused_window()

	# If the focused app is 769 (Steam), but its window is different, overlay should be enabled.
	# This means that Steam was launched and is focused.
	if focusable_apps.size() == 1 and focusable_apps[0] == Gamescope.OVERLAY_GAME_ID and focused_window != ogui_window_id:
		logger.debug("Steam appears to be focused.")
		return true

	# If OGUI is the only focused and remaining app, overlay should be disabled.
	if focusable_apps.size() == 1 and focusable_apps[0] == Gamescope.OVERLAY_GAME_ID and focused_window == ogui_window_id:
		return false

	return true


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
	var sandboxing_key := ".".join(["use_sandboxing", app._provider_id])
	var use_sandboxing := SettingsManager.get_value(section, sandboxing_key, true) as bool
	
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
	var sandbox := PackedStringArray()
	if use_sandboxing:
		sandbox = _sandbox.get_command(app)

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
	var running_app := _make_running_app(app, pid, display)
	running_app.command = command
	running_app.environment = env

	# Add the running app to our list and change to the IN_GAME state
	_add_running(running_app)
	state_machine.set_state([in_game_state])
	_update_recent_apps(app)
	return running_app


## Stops the game and all its children with the given PID
func stop(app: RunningApp) -> void:
	if app.state == app.STATE.STOPPING:
		app.kill(Reaper.SIG.KILL)
		return
	app.kill()


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


# Updates our list of recently launched apps
func _update_recent_apps(app: LibraryLaunchItem) -> void:
	if not "recent" in _persist_data:
		_persist_data["recent"] = []
	var recent: Array = _persist_data["recent"]
	recent.erase(app.name)
	recent.push_front(app.name)

	if recent.size() > 30:
		recent.pop_back()
	_persist_data["recent"] = recent
	_save_persist_data()
	recent_apps_changed.emit()


## Returns a list of currently running apps
func get_running() -> Array[RunningApp]:
	return _running.duplicate()


## Returns the running app from the given window id
func get_running_from_window_id(window_id: int) -> RunningApp:
	for app in _running:
		if window_id == app.window_id:
			return app
		if window_id in app.window_ids:
			return app
	return null


## Returns the currently running app
func get_current_app() -> RunningApp:
	return _current_app


## Sets the gamepad profile for the running app with the given profile
func set_app_gamepad_profile(app: RunningApp) -> void:
	# If no app was specified, unset the current gamepad profile
	if not app or not app.launch_item:
		set_gamepad_profile("")
		return
	# Check to see if this game has any gamepad profiles. If so, set our 
	# gamepads to use them.
	var section := ".".join(["game", app.launch_item.name.to_lower()])
	var profile_path = SettingsManager.get_value(section, "gamepad_profile", "")
	set_gamepad_profile(profile_path)


## Sets the gamepad profile for the running app with the given profile
func set_gamepad_profile(path: String) -> void:
	# If no profile was specified, unset the gamepad profiles
	if path == "":
		for gamepad in gamepad_manager.get_gamepad_paths():
			gamepad_manager.set_gamepad_profile(gamepad, null)
		return
	
	# Try to load the profile and set it
	var profile := load(path)

	# TODO: Save profiles for individual controllers?
	for gamepad in gamepad_manager.get_gamepad_paths():
		gamepad_manager.set_gamepad_profile(gamepad, profile)
	if not profile:
		logger.warn("Gamepad profile not found: " + path)
		return
	var notify := Notification.new("Using gamepad profile: " + profile.name)
	NotificationManager.show(notify)


## Sets the given running app as the current app
func set_current_app(app: RunningApp, switch_baselayer: bool = true) -> void:
	if app == null:
		return
	app.grab_focus()


## Returns true if the given app can be switched to via Gamescope
func can_switch_app(app: RunningApp) -> bool:
	if app == null:
		logger.warn("Unable to switch to null app")
		return false
	return app.can_focus()


## Returns whether the given app is running
func is_running(app_name: String) -> bool:
	return app_name in _apps_by_name


# Adds the given PID to our list of running apps
func _add_running(app: RunningApp):
	_apps_by_pid[app.pid] = app
	_apps_by_name[app.launch_item.name] = app
	app.state_changed.connect(_on_app_state_changed.bind(app))
	_running.append(app)
	app_launched.emit(app)


## Called when a running app's state changes
func _on_app_state_changed(_from: RunningApp.STATE, to: RunningApp.STATE, app: RunningApp) -> void:
	if to != RunningApp.STATE.STOPPED:
		return
	_remove_running(app)
	if state_machine.has_state(in_game_state) and _running.size() == 0:
		logger.info("No more apps are running. Removing in-game state.")
		Gamescope.remove_baselayer_window()
		state_machine.remove_state(in_game_state)
		state_machine.remove_state(in_game_menu_state)


# Removes the given PID from our list of running apps
func _remove_running(app: RunningApp):
	logger.info("Cleaning up pid {0}".format([app.pid]))
	_running.erase(app)
	_apps_by_name.erase(app.launch_item.name)
	_apps_by_pid.erase(app.pid)
	
	app_stopped.emit(app)


# Checks for running apps and updates our state accordingly
func _check_running() -> void:
	# Find the root window
	var root_id := Gamescope.get_root_window_id(Gamescope.XWAYLAND.GAME)
	if root_id < 0:
		return
	
	# Update the Gamescope state
	Gamescope.update()
	
	# Update our view of running processes and what windows they have
	_update_pids(root_id)
	
	# Update the state of all running apps
	for app in _running:
		app.update()


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


# Below functions detect launched game from other processes
# Returns the process ID
func _get_pid_from_focused_window(window_id: int) -> int:
	var pid := -1
	logger.debug(str(Gamescope.get_xwayland(Gamescope.XWAYLAND.GAME).list_xprops(window_id)))
	pid = Gamescope.get_xwayland(Gamescope.XWAYLAND.GAME).get_xprop(window_id, "_NET_WM_PID")
	logger.debug("PID: " + str(pid))
	return pid


# First method, try to get the name from the window_id using gamescope.
func _get_app_name_from_window_id(window_id: int) -> String:
	return Gamescope.get_window_name(window_id)


# Last resort, try to use the parent dir of the executable from /proc/pid/cwd to return
# the name of the game.
func _get_app_name_from_proc(pid: int) -> String:
	var process_name: String
	var path := "/proc/" + str(pid) + "/cwd"
	var output := []
	var exit_code := OS.execute("ls", ["-l", path], output)
	var process_path: PackedStringArray = output[0].strip_edges().split("/")
	process_name = process_path[process_path.size()-1]
	return process_name


# Primary nw app ID method. Identifies the running app from steam's library.vdf
# and appmanifest_<app_id>.acf files.
func _get_name_from_steam_library() -> String:
	var missing_app_id := Gamescope.get_focused_app()

	logger.debug("Found unclaimed app id: " +str(missing_app_id))
	var steam_library_path := OS.get_environment("HOME") +"/.steam/steam"
	var library_data := _parse_data_from_steam_file(steam_library_path + "/steamapps/libraryfolders.vdf")
	for library in library_data:
		logger.debug("Library: " + library + " : " + str(library_data[library]))
		if library_data[library]["apps"].has(str(missing_app_id)):
			var app_path : String = library_data[library]["path"] +"/steamapps/appmanifest_" + str(missing_app_id) + ".acf"
			logger.debug("Found app ID in a steam library:" + app_path)
			var app_data := _parse_data_from_steam_file(app_path, 2)
			if app_data["AppState"].has("name"):
				return app_data["AppState"]["name"]
	return ""


# Returns true if the given app_id is the same as a currently running app.
func _is_app_id_running(app_id) -> bool:
	for app in _running:
		if str(app_id) == app.launch_item._id:
			return true
	return false


# Identifies the running app from the given window_id. If none is found,
# creates a new RunningApp instance.
func _detect_running_app(window_id: int) -> RunningApp:
	logger.debug("No known running app in focused window. Attempting to detect the running app.")
	var app_name: String

	# Check if this window ID is a child of an existing RunningApp
	var running_app := get_running_from_window_id(window_id)
	if running_app:
		logger.debug("Process is a child of " + running_app.launch_item.name)
		return running_app

	# Identify the process ID. This is used to make the RunningApp as well as
	# for the backup methods for identifying the app name.
	var pid := _get_pid_from_focused_window(window_id)
	if pid < 0:
		logger.debug("Unable to locate PID for window: " + str(window_id) +  " on XWAYLAND.GAME.")
		return null

	# Check if we can find the PID in any currently running apps.
	running_app = _get_app_from_running_pid_groups(pid)
	if running_app:
		logger.debug("Process is a child of " + running_app.launch_item.name)
		return running_app

	# If we couldn't find it, identify the app name and create a new RunningApp
	logger.debug("Attmpting to identify app from the steam database.")
	app_name = _get_name_from_steam_library()
	if app_name == "":
		logger.debug("Not found. Attmpting to identify app from the window title.")
		app_name = _get_app_name_from_window_id(window_id)
	if app_name == "":
		logger.debug("Not found. Attmpting to identify app from the process running directory.")
		app_name = _get_app_name_from_proc(pid)
	if app_name == "":
		logger.error("Unable to identify the currently focused app.")
		return null

	logger.debug("Found app name : " + app_name)
	return _make_running_app_from_process(app_name, pid, window_id)


# Creates a new RunningApp instance from a given name, PID, and window_id. Used
# when an app launch is detcted that wasn't launched by an OGUI library.
func _make_running_app_from_process(name: String, pid: int, window_id: int) -> RunningApp:
	logger.debug("Creating running app from process")

	# Create a dummy LibraryLaunchItem to make our RunningApp.
	var lauch_dict = {
		"_id": "",
		"_provider_id": "",
		"provider_app_id": "",
		"name": name,
		"command": "",
		"args": [],
		"tags": [],
		"categories": [],
		"installed": true,
	}

	var launch_item: LibraryLaunchItem = LibraryLaunchItem.from_dict(lauch_dict)
	var display:= Gamescope.get_display_name(Gamescope.XWAYLAND.GAME)
	var running_app: RunningApp = _make_running_app(launch_item, pid, display)
	running_app.window_id = window_id
	running_app.state = RunningApp.STATE.RUNNING
	running_app.is_ogui_managed = false

	# Add the running app to our list and change to the IN_GAME state
	_add_running(running_app)
#	state_machine.set_state([in_game_state])

	return running_app


# Creates a new RunningApp instance from a given LibraryLaunchItem, PID, and
# xwayland instance. 
func _make_running_app(launch_item: LibraryLaunchItem, pid: int, display: String) -> RunningApp:
	var running_app: RunningApp = RunningApp.new(launch_item, pid, display)
	running_app.launch_item = launch_item
	running_app.pid = pid
	running_app.display = display
	return running_app


# Returns the parent app if the focused app is a child of a currently running app.
func _get_app_from_running_pid_groups(pid: int) -> RunningApp:
	for app in _running:
		if pid in app.get_child_pids():
			return app
	return null


# Reads .vdf and .acf files and returns a dictionary of their contents.
func _parse_data_from_steam_file(path: String, search_depth = 3) -> Dictionary:
	var library_data: Dictionary
	var library_raw: PackedStringArray = []
	logger.debug("Read from file: " + path)
	# Read the file
	var library_file := FileAccess.open(path, FileAccess.READ)
	var result := FileAccess.get_open_error()
	if result != OK:
		logger.debug("Failed to open " + path + ". Result: " +str(result))
		return library_data
	while library_file.get_position() < library_file.get_length():
		var line: String = library_file.get_line()
		library_raw.append(line)
	library_file.close()
#	logger.debug("Got library: " +str(library_raw))

	# Read each line and build a dictionary
	var index := 0
	var dict_level := 0
	var last_top = null
	var last_sub = null
	for raw_line in library_raw:
		var line := raw_line
#		logger.debug("raw:" + line)
		var broke_line := line.split("\t", false) as Array
		var clean_line : Array = []
		for line_part in broke_line:
			clean_line.append(line_part.lstrip("\"").rstrip("\""))
#		logger.debug("clean line: " +str(clean_line))
#		logger.debug("split: " + " ".join(broke_line) + " size: " + str(broke_line.size()))
		if clean_line[0] == "{":
#			logger.debug("Found '{', increasing indent level")
			dict_level += 1
			if dict_level == search_depth - 1:
				last_top = library_raw[index-1].split("\t", false)[0].lstrip("\"").rstrip("\"")
#				logger.debug("Found new top level: " + library_raw[index-1].split("\t", false)[0])
			elif dict_level == search_depth:
				last_sub = library_raw[index-1].split("\t", false)[0].lstrip("\"").rstrip("\"")
#				logger.debug("Found new sub level: " + library_raw[index-1].split("\t", false)[0])
			index +=1
			continue

		if clean_line[0] == "}":
#			logger.debug("Found '}', reducing indent level")
			dict_level -= 1
			if dict_level == search_depth-1:
				last_sub = null
			elif dict_level == search_depth - 2:
				last_top = null
			index +=1
			continue
		if last_top:
			if last_sub:
				if not library_data[last_top].has(last_sub):
#					logger.debug("Added new sub level: " + last_sub)
					library_data[last_top][last_sub] = []
				for part in clean_line:
#					logger.debug("Added new data: " + " ".join(clean_line))
					library_data[last_top][last_sub].append(part)
				index +=1
				continue
			if not library_data.has(last_top):
#				logger.debug("Added new top level: " + last_top)
				library_data[last_top] = {}
			if clean_line.size() > 1:
				library_data[last_top][clean_line[0]] = clean_line[1]
				index += 1
				continue
		index +=1
#	logger.debug("Library Data: " +str(library_data))
	return library_data
