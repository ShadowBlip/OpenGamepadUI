@icon("res://assets/editor-icons/ph-rocket-launch-fill.svg")
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
##     var launch_manager := load("res://core/global/launch_manager.tres") as LaunchManager
##     ...
##     # Create a LibraryLaunchItem to run something
##     var item := LibraryLaunchItem.new()
##     item.command = "vkcube"
##     
##     # Launch the app with LaunchManager
##     var running_app := launch_manager.launch(item)
##     
##     # Get a list of running apps
##     var running := launch_manager.get_running()
##     print(running)
##     
##     # Stop an app with LaunchManager
##     launch_manager.stop(running_app)
##     [/codeblock]

signal all_apps_stopped()
signal app_launched(app: RunningApp)
signal app_stopped(app: RunningApp)
signal app_switched(from: RunningApp, to: RunningApp)
signal app_lifecycle_progressed(progress: float, type: AppLifecycleHook.TYPE)
signal app_lifecycle_notified(text: String, type: AppLifecycleHook.TYPE)
signal recent_apps_changed()

const settings_manager := preload("res://core/global/settings_manager.tres")
const notification_manager := preload("res://core/global/notification_manager.tres")
const library_manager := preload("res://core/global/library_manager.tres")

var gamescope := preload("res://core/systems/gamescope/gamescope.tres") as GamescopeInstance
var input_plumber := load("res://core/systems/input/input_plumber.tres") as InputPlumberInstance

var state_machine := preload("res://assets/state/state_machines/global_state_machine.tres") as StateMachine
var in_game_state := preload("res://assets/state/states/in_game.tres") as State
var in_game_menu_state := preload("res://assets/state/states/in_game_menu.tres") as State

var PID: int = OS.get_process_id()
var _xwayland_primary := gamescope.get_xwayland(gamescope.XWAYLAND_TYPE_PRIMARY)
var _xwayland_ogui := gamescope.get_xwayland(gamescope.XWAYLAND_TYPE_OGUI)
var _xwayland_game := gamescope.get_xwayland(gamescope.XWAYLAND_TYPE_GAME)
var _sandbox := Sandbox.get_sandbox()
var _current_app: RunningApp
var _pid_to_windows := {}
var _running: Array[RunningApp] = []
var _running_background: Array[RunningApp] = []
var _apps_by_pid: Dictionary = {}
var _apps_by_name: Dictionary = {}
var _data_dir: String = ProjectSettings.get_setting("OpenGamepadUI/data/directory")
var _persist_path: String = "/".join([_data_dir, "launcher.json"])
var _persist_data: Dictionary = {"version": 1}
var _ogui_window_id := 0
var should_manage_overlay := true
var logger := Log.get_logger("LaunchManager", Log.LEVEL.INFO)
var _focused_app_id := 0
var _input_manager: InputManager

# Connect to Gamescope signals
func _init() -> void:
	_load_persist_data()

	# Get the window ID of OpenGamepadUI
	if _xwayland_ogui:
		var ogui_windows := _xwayland_ogui.get_windows_for_pid(PID)
		if not ogui_windows.is_empty():
			_ogui_window_id = ogui_windows[0]

	# Listen for signals from the primary Gamescope XWayland
	if _xwayland_primary:
		# Debug print when the focused window changes
		var on_focus_changed := func(from: int, to: int):
			if from == to:
				return
			logger.info("Window focus changed from " + str(from) + " to: " + str(to))
			self.check_running.call_deferred()
		_xwayland_primary.focused_window_updated.connect(on_focus_changed)

		# When focused app changes, update the current app and gamepad profile
		var on_focused_app_changed := func(_from: int, to: int) -> void:
			if _focused_app_id == to:
				return
			logger.debug("Focused app changed from " + str(_focused_app_id) + " to " + str(to))
			_focused_app_id = to

			# If OGUI was focused, set the global gamepad profile
			if to in [gamescope.OVERLAY_GAME_ID, 0, 1]:
				set_gamepad_profile("")
				return

			# Find the running app for the given app id
			var last_app := self._current_app
			var detected_app: RunningApp
			for app in _running:
				if app.app_id == to:
					detected_app = app

			# If the running app was not launched by OpenGamepadUI, then detect it.
			if not detected_app:
				detected_app = _detect_running_app(to)
			self._current_app = detected_app

			logger.debug("Last app: " + str(last_app) + " current_app: " + str(self._current_app))
			app_switched.emit(last_app, self._current_app)

			# If the app has a gamepad profile, set it
			if self._current_app:
				set_app_gamepad_profile(self._current_app)
		_xwayland_primary.focused_app_updated.connect(on_focused_app_changed)

		# Listen for when focusable apps change
		var on_focusable_apps_changed := func(from: PackedInt64Array, to: PackedInt64Array):
			if from == to:
				return
			logger.debug("Focusable apps changed from", from, "to", to)
			self.check_running.call_deferred()
		_xwayland_primary.focusable_apps_updated.connect(on_focusable_apps_changed)

		# Listen for when focusable windows change
		var on_focusable_windows_changed := func(_from: PackedInt64Array, to: PackedInt64Array):
			# If focusable windows has changed and the currently focused window no longer exists,
			# remove the manual focus
			var baselayer_window := _xwayland_primary.baselayer_window
			if baselayer_window > 0 and not baselayer_window in to:
				_xwayland_primary.remove_baselayer_window()
		_xwayland_primary.focusable_windows_updated.connect(on_focusable_windows_changed)

	# Listen for signals from the secondary Gamescope XWayland
	if _xwayland_game:
		# Listen for window created/destroyed events
		var on_window_created := func(window_id: int):
			logger.debug("Window created:", window_id)
			self.check_running.call_deferred()
		_xwayland_game.window_created.connect(on_window_created)

	# Whenever the in-game state is entered, set the gamepad profile
	var on_game_state_entered := func(_from: State):
		if _current_app:
			set_app_gamepad_profile(_current_app)

		# If we don't want LaunchManager to manage overlay (I.E. overlay mode), return false always.
		if not should_manage_overlay:
			return

		if _xwayland_ogui:
			logger.debug("Enabling STEAM_OVERLAY atom")
			_xwayland_ogui.set_overlay(_ogui_window_id, 1)

	var on_game_state_exited := func(_to: State):
		# Set the gamepad profile to the global profile
		set_gamepad_profile("")

		# If we don't want LaunchManager to manage overlay (I.E. overlay mode), return false always.
		if not should_manage_overlay:
			return

		if _xwayland_ogui:
			logger.debug("Disabling STEAM_OVERLAY atom")
			_xwayland_ogui.set_overlay(_ogui_window_id, 1)

	in_game_state.state_entered.connect(on_game_state_entered)
	in_game_state.state_exited.connect(on_game_state_exited)


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


# Get access to nodes from the scene tree and other goodies
func setup(input_manager: InputManager):
	if not input_manager:
		logger.error("No input manager found.")
		return
	if not is_instance_valid(input_manager):
		logger.error("Input Manager instance is not valid")
		return

	_input_manager = input_manager
	set_gamepad_profile("")


## Launches the given application and switches to the in-game state. Returns a
## [RunningApp] instance of the application.
func launch(app: LibraryLaunchItem) -> RunningApp:
	# Create a running app from the launch item
	var running_app := _launch(app)

	# Add the running app to our list and change to the IN_GAME state
	_add_running(running_app)
	state_machine.set_state([in_game_state])
	update_recent_apps(app)

	# Execute any pre-launch hooks and start the app
	await _execute_hooks(app, AppLifecycleHook.TYPE.PRE_LAUNCH)

	# Call any hooks at different points in the app's lifecycle
	var on_app_state_changed := func(_from: RunningApp.STATE, to: RunningApp.STATE):
		if to == RunningApp.STATE.RUNNING:
			_execute_hooks(app, AppLifecycleHook.TYPE.LAUNCH)
		elif to == RunningApp.STATE.STOPPED:
			_execute_hooks(app, AppLifecycleHook.TYPE.EXIT)
	running_app.state_changed.connect(on_app_state_changed)

	# Focus any new windows that get created
	var switch_to_new_window := func(old_windows: PackedInt64Array, new_windows: PackedInt64Array):
		for window in new_windows:
			if window in old_windows:
				continue
			running_app.switch_window(window)
			break
	running_app.window_ids_changed.connect(switch_to_new_window)

	# Remove/restore focus if any windows get removed
	var remove_focus := func(old_windows: PackedInt64Array, new_windows: PackedInt64Array):
		if not _xwayland_primary:
			return
		var focused_window := _xwayland_primary.baselayer_window
		if not focused_window in old_windows:
			return
		if not focused_window in new_windows:
			_xwayland_primary.remove_baselayer_window()
			return
		# TODO: Use the most recently created window instead of just the first in the list
		var new_window := new_windows[0]
		running_app.switch_window(new_window)
	running_app.window_ids_changed.connect(remove_focus)

	# Run the application
	running_app.start()

	return running_app


## Launches the given app in the background. Returns the [RunningApp] instance.
func launch_in_background(app: LibraryLaunchItem) -> RunningApp:
	# Start the application
	var running_app := _launch(app)
	running_app.start()

	# Listen for app state changes
	var on_app_state_changed := func(from: RunningApp.STATE, to: RunningApp.STATE):
		if to != RunningApp.STATE.STOPPED:
			return
		logger.debug("Cleaning up pid {0}".format([running_app.pid]))
		_running_background.erase(running_app)
		logger.debug("Currently running background apps:", _running_background)
	running_app.state_changed.connect(on_app_state_changed)
	_running_background.append(running_app)
	
	return running_app


## Executes application lifecycle hooks for the given app
func _execute_hooks(app: LibraryLaunchItem, type: AppLifecycleHook.TYPE) -> void:
	var library := library_manager.get_library_by_id(app._provider_id)
	if not library:
		logger.warn("Unable to find library for app:", app)
		return
	var hooks := library.get_app_lifecycle_hooks()

	# Filter based on hook type
	var hooks_to_run: Array[AppLifecycleHook] = []
	for item in hooks:
		if item.get_type() != type:
			continue
		hooks_to_run.push_back(item)

	# Emit signals if the hook has progress
	var on_hook_progress := func(progress: float):
		self.app_lifecycle_progressed.emit(progress, type)
	var on_hook_notify := func(text: String):
		self.app_lifecycle_notified.emit(text, type)

	# Run each hook and emit signals on hook progress
	for hook in hooks_to_run:
		logger.info("Executing lifecycle hook:", hook)
		hook.progressed.connect(on_hook_progress)
		hook.notified.connect(on_hook_notify)
		await hook.execute(app)
		hook.notified.disconnect(on_hook_notify)
		hook.progressed.disconnect(on_hook_progress)


## Launches the given app
func _launch(app: LibraryLaunchItem) -> RunningApp:
	var cmd: String = app.command
	var args: PackedStringArray = app.args
	var env: Dictionary = app.env.duplicate()
	var cwd: String = OS.get_environment("HOME")
	if app.cwd != "":
		cwd = app.cwd

	# Override any parameters that may be in the user's config for this game
	var section := ".".join(["game", app.name.to_lower()])
	var cmd_key := ".".join(["command", app._provider_id])
	var user_cmd = settings_manager.get_value(section, cmd_key, "")
	if user_cmd and user_cmd is String and not (user_cmd as String).is_empty():
		cmd = user_cmd
	var args_key := ".".join(["args", app._provider_id])
	var user_args = settings_manager.get_value(section, args_key, PackedStringArray())
	if user_args and user_args is PackedStringArray and not (user_args as PackedStringArray).is_empty():
		args = user_args
	var cwd_key := ".".join(["cwd", app._provider_id])
	var user_cwd = settings_manager.get_value(section, cwd_key, "")
	if user_cwd and user_cwd is String and not (user_cwd as String).is_empty():
		cwd = user_cwd
	var env_key := ".".join(["env", app._provider_id])
	var user_env = settings_manager.get_value(section, env_key, {})
	if user_env and user_env is Dictionary and not (user_env as Dictionary).is_empty():
		env = user_env
	var inherit_environment_key := ".".join(["inherit_parent_environment", app._provider_id])
	var inherit_environment := settings_manager.get_value(section, inherit_environment_key, true) as bool
	var sandboxing_key := ".".join(["use_sandboxing", app._provider_id])
	var use_sandboxing := settings_manager.get_value(section, sandboxing_key, false) as bool

	# Set the display environment if one was not set.
	if not "DISPLAY" in env:
		if _xwayland_game:
			env["DISPLAY"] = _xwayland_game.name
		else:
			env["DISPLAY"] = ""

	# Set the OGUI ID environment variable
	env["OGUI_ID"] = app.name

	# Set certain environment variables when not inheriting the parent environment
	if not inherit_environment:
		if not "HOME" in env:
			env["HOME"] = OS.get_environment("HOME")
		if not "XDG_SESSION_TYPE" in env:
			env["XDG_SESSION_TYPE"] = "x11"
		if not "XDG_RUNTIME_DIR" in env:
			env["XDG_RUNTIME_DIR"] = OS.get_environment("XDG_RUNTIME_DIR")

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
	if not inherit_environment:
		command.push_front("-i")
	command.append_array(env_vars)
	command.append_array(sandbox)
	command.append(cmd)
	command.append_array(args)
	logger.info("Launching game with command: {0} {1}".format([exec, str(command)]))

	# Create the running app instance, but do not start it yet.
	var running_app := RunningApp.create(app, env, exec, command)
	
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
	var max_recent := settings_manager.get_value("general.home", "max_home_items", 10) as int
	var i := 1
	for app in _persist_data["recent"]:
		if i > max_recent:
			break
		recent.push_back(app)
		i += 1
	return recent


# Updates our list of recently launched apps
func update_recent_apps(app: LibraryLaunchItem) -> void:
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


## Returns a list of currently running background apps
func get_running_background() -> Array[RunningApp]:
	return _running_background.duplicate()


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


## Returns the library item for the currently running app (if one is running).
func get_current_app_library_item() -> LibraryItem:
	var current_app := get_current_app()
	if not current_app or not current_app.launch_item:
		return
	var library_item := LibraryItem.new_from_launch_item(_current_app.launch_item)
	return library_item


## Sets the gamepad profile for the running app with the given profile
func set_app_gamepad_profile(app: RunningApp) -> void:
	# If no app was specified, unset the current gamepad profile
	if not app or not app.launch_item:
		logger.debug("No app available to set gamepad profile")
		set_gamepad_profile("")
		return

	# Check to see if this game has any gamepad profiles. If so, set our 
	# gamepads to use them.
	var section := ".".join(["game", app.launch_item.name.to_lower()])
	var profile_path := settings_manager.get_value(section, "gamepad_profile", "") as String
	var profile_gamepad := settings_manager.get_value(section, "gamepad_profile_target", "") as String
	if profile_path.is_empty():
		logger.debug("Using global gamepad profile")
	else:
		logger.debug("Using profile '" + profile_path + "' with gamepad type '" + profile_gamepad + "'")
	set_gamepad_profile(profile_path, profile_gamepad)


## Sets the gamepad profile for the running app with the given profile
func set_gamepad_profile(profile_path: String, target_gamepad: String = "") -> void:
	# Discover the currently set target for each gamepad to properly add additional
	# capabilities based on that target
	for device: CompositeDevice in input_plumber.get_composite_devices():
		if target_gamepad.is_empty():
			# First, find the currently set gamepad on the composite device
			var targets = device.get_target_devices()
			for target in targets:
				var target_dbus_path: String = target.get("dbus_path")
				if not target_dbus_path.contains("target/gamepad"):
					continue
				target_gamepad = target.get("device_type")
				break
			if not target_gamepad.is_empty():
				break
			# Then, if overriden by settings, use that instead
			#TODO: This is a global setting, refactor settings to permit individual gamepads to have different targets
			target_gamepad = settings_manager.get_value("input", "gamepad_profile_target", target_gamepad) as String

		# If no profile was specified, unset the gamepad profiles
		if profile_path == "":
			# Get the input manager default path
			if is_instance_valid(_input_manager):
				profile_path = _input_manager.get_default_global_profile_path()

			# Try check to see if there is a global gamepad setting
			#TODO: This is a global setting, refactor settings to permit individual gamepads to have different profiles
			profile_path = settings_manager.get_value("input", "gamepad_profile", profile_path) as String

			# Verify can load a valid profile, or fallback.
			if not profile_path.ends_with(".json") or not FileAccess.file_exists(profile_path):
					logger.warn("Profile path is not valid: \"" + profile_path + "\"")
					return

			# Load the profile to get its name
			logger.info("Loading gamepad profile: " + profile_path)
			var profile := InputPlumberProfile.load(profile_path)
			if not profile:
				logger.warn("Failed to load gamepad profile: " + profile_path)
				return

		InputPlumber.load_target_modified_profile(device, profile_path, target_gamepad)

		# Set the target gamepad if one was specified
		if not target_gamepad.is_empty():
			var target_devices := PackedStringArray([target_gamepad, "keyboard", "mouse"])
			match target_gamepad:
				"xb360", "xbox-series", "xbox-elite", "gamepad", "hori-steam", "deck", "deck-uhid":
					target_devices.append("touchpad")
				_:
					logger.debug(target_gamepad, "needs no additional target devices.")
			logger.info("Setting target devices to: ", target_devices)
			device.set_target_devices(target_devices)

	#var notify := Notification.new("Using gamepad profile: " + profile.name)
	#notification_manager.show(notify)


## Sets the given running app as the current app
func set_current_app(app: RunningApp, _switch_baselayer: bool = true) -> void:
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
func _on_app_state_changed(from: RunningApp.STATE, to: RunningApp.STATE, app: RunningApp) -> void:
	logger.debug("App state changed from", from, "to", to, "for app:", app)
	if to != RunningApp.STATE.STOPPED:
		return
	logger.debug("Cleaning up pid {0}".format([app.pid]))
	_remove_running(app)
	logger.debug("Currently running apps:", _running)
	if state_machine.has_state(in_game_state) and _running.size() == 0:
		logger.info("No more apps are running. Removing in-game state.")
		_current_app = null
		_xwayland_primary.remove_baselayer_window()
		state_machine.remove_state(in_game_state)
		state_machine.remove_state(in_game_menu_state)
		all_apps_stopped.emit()


# Removes the given PID from our list of running apps
func _remove_running(app: RunningApp):
	logger.info("Removing app", app, "from running apps.")
	if app == _current_app:
		_current_app = null
	_running.erase(app)
	_apps_by_name.erase(app.launch_item.name)
	_apps_by_pid.erase(app.pid)
	app_stopped.emit(app)


# Checks for running apps and updates our state accordingly
func check_running() -> void:
	# Find the root window
	if not _xwayland_game:
		logger.warn("No XWayland instance exists to check for running apps")
		return
	var root_id := _xwayland_game.root_window_id
	if root_id < 0:
		return

	# Get all windows and their geometry
	var all_windows := _xwayland_game.get_all_windows(root_id)
	var all_window_sizes := _xwayland_game.get_window_sizes(all_windows)
	logger.trace("Found windows:", all_windows)
	logger.trace("Found window sizes:", all_window_sizes)

	# Only consider valid windows of a certain size
	var all_valid_windows := PackedInt64Array()
	var i := 0
	for window in all_windows:
		var size := all_window_sizes[i]
		if size.x > 20 and size.y > 20:
			all_valid_windows.push_back(window)
		i += 1
	logger.trace("Found valid windows:", all_valid_windows)

	# Get a list of all running processes
	var all_pids := Reaper.get_pids()

	# All OGUI processes should have an OGUI_ID environment variable set. Look
	# at every running process and sort them by OGUI_ID.
	var ogui_id_to_pids: Dictionary[String, PackedInt64Array] = {}
	for pid in all_pids:
		var env := Reaper.get_pid_environment(pid)
		if not env.is_empty():
			logger.trace("Found environment for pid", pid, ":", env)
		if not "OGUI_ID" in env:
			continue
		var id := env["OGUI_ID"] as String
		if not id in ogui_id_to_pids:
			ogui_id_to_pids[id] = PackedInt64Array()
		ogui_id_to_pids[id].push_back(pid)
	if !ogui_id_to_pids.is_empty():
		logger.debug("Running processes:", ogui_id_to_pids)

	# Update our view of running processes and what windows they have
	_update_pids(all_valid_windows)

	# Update the state of all running apps
	var windows_with_app := PackedInt64Array()
	var orphan_windows := PackedInt64Array()
	for app in _running:
		var app_pids := PackedInt64Array()
		if app.ogui_id in ogui_id_to_pids:
			app_pids = ogui_id_to_pids[app.ogui_id]
		app.update(all_valid_windows, app_pids)
		windows_with_app.append_array(app.window_ids.duplicate())
	for app in _running_background:
		var app_pids := PackedInt64Array()
		if app.ogui_id in ogui_id_to_pids:
			app_pids = ogui_id_to_pids[app.ogui_id]
		app.update(all_valid_windows, app_pids)
		windows_with_app.append_array(app.window_ids.duplicate())

	# Look for orphan windows
	for window in all_valid_windows:
		if window in windows_with_app:
			continue
		orphan_windows.push_back(window)
	if not orphan_windows.is_empty():
		logger.warn("Found orphan windows:", orphan_windows)


# Updates our mapping of PIDs to Windows. This gives us a good view of what
# processes are running, and what windows they have.
func _update_pids(all_windows: PackedInt64Array):
	if not _xwayland_game:
		return
	var pids := {}
	for window in all_windows:
		var window_pids := _xwayland_game.get_pids_for_window(window)
		for window_pid in window_pids:
			if not window_pid in pids:
				pids[window_pid] = []
			pids[window_pid].append(window)
	_pid_to_windows = pids


# Below functions detect launched game from other processes
# Returns the process ID
func _get_pid_from_focused_window(window_id: int) -> int:
	if not _xwayland_game:
		return -1
	var window_pids := _xwayland_game.get_pids_for_window(window_id)
	if window_pids.is_empty():
		return -1
	return window_pids[0]


# First method, try to get the name from the window_id using gamescope.
func _get_app_name_from_window_id(window_id: int) -> String:
	return _xwayland_game.get_window_name(window_id)


# Last resort, try to use the parent dir of the executable from /proc/pid/cwd to return
# the name of the game.
func _get_app_name_from_proc(pid: int) -> String:
	var process_name: String
	var path := "/proc/" + str(pid) + "/cwd"
	var output := []
	var _exit_code := OS.execute("ls", ["-l", path], output)
	var process_path: PackedStringArray = output[0].strip_edges().split("/")
	process_name = process_path[process_path.size()-1]
	return process_name


# Primary new app ID method. Identifies the running app from steam's library.vdf
# and appmanifest_<app_id>.acf files.
func _get_name_from_steam_library() -> String:
	var missing_app_id := -1
	if _xwayland_primary:
		missing_app_id = _xwayland_primary.focused_app

	logger.debug("Found unclaimed app id: " +str(missing_app_id))
	var steam_library_path := OS.get_environment("HOME") +"/.steam/steam"
	var library_data := _parse_data_from_steam_file(steam_library_path + "/steamapps/libraryfolders.vdf")
	for library in library_data:
		logger.debug("Library: " + library + " : " + str(library_data[library]))
		if not "apps" in library_data[library]:
			continue
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
func _detect_running_app(app_id: int) -> RunningApp:
	logger.debug("No known running app in focused window. Attempting to detect the running app.")
	
	# Get the currently focused window id
	var window_id := _xwayland_primary.focused_window
	if window_id == _ogui_window_id:
		return null

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
	return _make_running_app_from_process(app_name, pid, window_id, app_id)


# Creates a new RunningApp instance from a given name, PID, and window_id. Used
# when an app launch is detcted that wasn't launched by an OGUI library.
func _make_running_app_from_process(name: String, pid: int, window_id: int, app_id: int) -> RunningApp:
	logger.debug("Creating running app from process")

	# Create a dummy LibraryLaunchItem to make our RunningApp.
	var lauch_dict := {
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
	var display := ""
	if _xwayland_game:
		display = _xwayland_game.name
	var running_app: RunningApp = _make_running_app(launch_item, pid, display)
	running_app.app_id = app_id
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
	var running_app: RunningApp = RunningApp.new(launch_item, display)
	running_app.launch_item = launch_item
	running_app.pid = pid
	running_app.display = display
	return running_app


# Returns the parent app if the focused app is a child of a currently running app.
func _get_app_from_running_pid_groups(pid: int) -> RunningApp:
	var pids_with_ogui_id := PackedInt64Array()
	for app in _running:
		if pid in app.get_child_pids(pids_with_ogui_id):
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
