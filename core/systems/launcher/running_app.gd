extends Resource
class_name RunningApp

## Defines a running application
##
## RunningApp contains details and methods around running applications

var gamescope := load("res://core/systems/gamescope/gamescope.tres") as GamescopeInstance


## Emitted when all child processes of the app are no longer running
signal app_killed
## Emitted when the given app is gracefully stopped
signal app_stopped
## Emitted when the app type is detected
signal app_type_detected
## Emitted when the window id of the given app has changed
signal window_id_changed
## Emitted whenever the windows change for the app
signal window_ids_changed(from: PackedInt32Array, to: PackedInt32Array)
## Emitted when the app id of the given app has changed
signal app_id_changed
## Emitted when the app's state has changed
signal state_changed(from: STATE, to: STATE)
## Emitted when an app is suspended
signal suspended(enabled: bool)
## Emitted when the app is focused
signal focus_entered
## Emitted when the app is unfocused
signal focus_exited

## Possible states the running app can be in
enum STATE {
	STARTED, ## App was just started
	RUNNING, ## App is running and has an app_id and window_id
	MISSING_WINDOW, ## App was running, but now its window cannot be discovered
	STOPPING, ## App is being killed gracefully
	STOPPED, ## App is no longer running
}

enum APP_TYPE {
	UNKNOWN,
	X11,
	WAYLAND,
}

## The LibraryLaunchItem associated with the running application
var launch_item: LibraryLaunchItem
## The PID of the launched application
var pid: int
## The xwayland display that the application is running on (e.g. ":1")
var display: String
## The raw command that was used to launch the application
var command: PackedStringArray
## Environment variables that were set with the launched application
var environment: Dictionary
## The state of the running app
var state: STATE = STATE.STARTED:
	set(v):
		var old_state := state
		state = v
		if old_state != state:
			state_changed.emit(old_state, state)
## Whether or not the running app is suspended
var is_suspended := false:
	set(v):
		var old_value := is_suspended
		is_suspended = v
		if old_value != is_suspended:
			suspended.emit(is_suspended)
## Time in milliseconds when the app started
var start_time := Time.get_ticks_msec()
## The currently detected window ID of the application
var window_id: int:
	set(v):
		window_id = v
		window_id_changed.emit()
## A list of all detected window IDs related to the application
var window_ids: PackedInt32Array = PackedInt32Array():
	set(v):
		var old_windows := window_ids
		window_ids = v
		if old_windows != window_ids:
			window_ids_changed.emit(old_windows, window_ids)
## The current app ID of the application
var app_id: int:
	set(v):
		app_id = v
		app_id_changed.emit()
## The type of app
var app_type: APP_TYPE = APP_TYPE.UNKNOWN
## Whether or not the app is currently focused
var focused: bool = false:
	set(v):
		var old_focus := focused
		focused = v
		if old_focus == focused:
			return
		if focused:
			focus_entered.emit()
			return
		focus_exited.emit()
## Whether or not the running app has created at least one valid window
var created_window := false
## The number of windows that have been discovered from this app
var num_created_windows := 0
## Number of times this app has failed its "is_running" check
var not_running_count := 0
## When a steam-launched app has no window, count a few tries before trying
## to close Steam
var steam_close_tries := 0
## Flag for if OGUI should manage this app. Set to false if app is launched
## outside OGUI and we just want to track it.
var is_ogui_managed: bool = true
var logger := Log.get_logger("RunningApp", Log.LEVEL.INFO)


func _init(item: LibraryLaunchItem, process_id: int, dsp: String) -> void:
	launch_item = item
	pid = process_id
	display = dsp


## Run the given command and return it as a [RunningApp]
static func spawn(app: LibraryLaunchItem, env: Dictionary, cmd: String, args: PackedStringArray) -> RunningApp:
	# Generate an app id for the running application based on its name
	var app_id := app.get_app_id()

	# Launch the application process
	var pid := Reaper.create_process(cmd, args, app_id)
	var display := env["DISPLAY"] as String
	var command := PackedStringArray([cmd])
	command.append_array(args)

	# Create a running app instance
	var running_app := RunningApp.new(app, pid, display)
	running_app.command = command
	running_app.environment = env
	running_app.app_id = app_id

	return running_app


# TODO: Only call this on window creation/deletion
## Updates the running app and fires signals
func update() -> void:
	match self.app_type:
		APP_TYPE.UNKNOWN:
			self.app_type = discover_app_type()
			if self.app_type != APP_TYPE.UNKNOWN:
				app_type_detected.emit()
				self.update()
		APP_TYPE.X11:
			update_xwayland_app()
		APP_TYPE.WAYLAND:
			update_wayland_app()


func discover_app_type() -> APP_TYPE:
	# Update all the windows
	self.window_ids = get_all_window_ids()

	# Check to see if running app's app_id exists in focusable_apps
	var xwayland_primary := gamescope.get_xwayland(gamescope.XWAYLAND_TYPE_PRIMARY)
	var focused_app := xwayland_primary.focused_app
	var focusable_apps := xwayland_primary.focusable_apps
	if (self.app_id == focused_app or self.app_id in focusable_apps) and self.window_ids.is_empty():
		logger.debug("Discovered app type: Wayland")
		return APP_TYPE.WAYLAND
	
	if self.app_id in focusable_apps and not self.window_ids.is_empty():
		logger.debug("Discovered app type: X11")
		return APP_TYPE.X11
	
	return APP_TYPE.UNKNOWN


func update_wayland_app() -> void:
	# Check if the app, or any of its children, are still running
	var running := is_running()
	if not running:
		self.not_running_count += 1

	# Update the running app's state
	if not_running_count > 3:
		state = STATE.STOPPED
		app_killed.emit()
	elif state == STATE.STARTED:
		state = STATE.RUNNING
		#grab_focus() # How can we grab wayland window focus?

	# Update the focus state of the app
	focused = is_focused()

	var state_str := {
		STATE.STARTED: "started", 
		STATE.RUNNING: "running", 
		STATE.MISSING_WINDOW: "no window",
		STATE.STOPPING: "stopping", 
		STATE.STOPPED: "stopped"
	}
	logger.trace(launch_item.name + " current state: " + state_str[state])

	# If this was launched by Steam, try and detect if the game closed 
	# so we can kill Steam gracefully
	if is_steam_app() and state == STATE.STOPPED and is_ogui_managed:
		logger.trace(launch_item.name + " is a Steam game and has no valid window ID. It may have closed.")
		# Don't try closing Steam immediately. Wait a few more ticks before attempting
		# to close Steam.
		if steam_close_tries < 4:
			steam_close_tries += 1
			return
		var steam_pid := find_steam()
		if steam_pid > 0:
			logger.info("Trying to stop steam with pid: " + str(steam_pid))
			OS.execute("kill", ["-15", str(steam_pid)])


func update_xwayland_app() -> void:
	# Update all windows related to the app's PID
	self.window_ids = get_all_window_ids()

	# Ensure that all windows related to the app have an app ID set
	_ensure_app_id()

	# Ensure that the running app has a corresponding window ID
	var has_valid_window := false
	if needs_window_id():
		logger.trace("App needs a valid window id")
		var id := _discover_window_id()
		if id > 0 and window_id != id:
			logger.trace("Setting window ID " + str(id) + " for " + launch_item.name)
			window_id = id
	else:
		has_valid_window = true

	# Update the focus state of the app
	focused = is_focused()

	# Check if the app, or any of its children, are still running
	var running := is_running()
	if not running:
		not_running_count += 1

	# Update the running app's state
	if not_running_count > 3:
		state = STATE.STOPPED
		app_killed.emit()
	elif state == STATE.STARTED and has_valid_window:
		state = STATE.RUNNING
		grab_focus()
	elif state == STATE.RUNNING and not has_valid_window:
		state = STATE.MISSING_WINDOW

	var state_str := {
		STATE.STARTED: "started", 
		STATE.RUNNING: "running", 
		STATE.MISSING_WINDOW: "no window",
		STATE.STOPPING: "stopping", 
		STATE.STOPPED: "stopped"
	}
	logger.trace(launch_item.name + " current state: " + state_str[state])

	# TODO: Check all windows for STEAM_GAME prop
	# If this was launched by Steam, try and detect if the game closed 
	# so we can kill Steam gracefully
	if is_steam_app() and state == STATE.MISSING_WINDOW and is_ogui_managed:
		logger.trace(launch_item.name + " is a Steam game and has no valid window ID. It may have closed.")
		# Don't try closing Steam immediately. Wait a few more ticks before attempting
		# to close Steam.
		if steam_close_tries < 4:
			steam_close_tries += 1
			return
		var steam_pid := find_steam()
		if steam_pid > 0:
			logger.info("Trying to stop steam with pid: " + str(steam_pid))
			OS.execute("kill", ["-15", str(steam_pid)])


## Pauses/Resumes the running app by running 'kill -STOP' or 'kill -CONT'
func suspend(enable: bool) -> void:
	if enable:
		Reaper.reap(pid, Reaper.SIG.STOP)
	else:
		Reaper.reap(pid, Reaper.SIG.CONT)
	is_suspended = enable


## Returns the window title of the given window. If the window ID does not belong to this app,
## it will return an empty string.
func get_window_title(win_id: int) -> String:
	if not win_id in window_ids:
		return ""
	var xwayland := gamescope.get_xwayland_by_name(display)
	if not xwayland:
		return ""
	return xwayland.get_window_name(win_id)


## Attempt to discover the window ID from the PID of the given application
func get_window_id_from_pid() -> int:
	var xwayland := gamescope.get_xwayland_by_name(display)
	if not xwayland:
		return -1
	var windows := xwayland.get_windows_for_pid(pid)
	if windows.is_empty():
		return -1
	return windows[0]


## Attempt to discover all window IDs from the PID of the given application and
## the PIDs of all processes in the same process group.
func get_all_window_ids() -> PackedInt32Array:
	var app_name := launch_item.name
	var window_ids := PackedInt32Array()
	var pids := get_child_pids()
	var xwayland := gamescope.get_xwayland_by_name(display)
	pids.append(pid)
	logger.trace(app_name + " found related PIDs: " + str(pids))

	# Loop through all windows and check if the window belongs to one of our
	# processes
	var all_windows := xwayland.get_all_windows(xwayland.root_window_id)
	for window_id in all_windows:
		var window_pids := xwayland.get_pids_for_window(window_id)
		for window_pid in window_pids:
			if window_pid in pids:
				#logger.trace("Found window for pid", window_pid, ":", window_id)
				window_ids.append(window_id)

	logger.trace(app_name + " found related window IDs: " + str(window_ids))

	return window_ids


## Returns true if the app's PID is running or any decendents with the same
## process group.
func is_running() -> bool:
	return OS.is_process_running(pid)


## Return a list of child PIDs. When launching apps with [Reaper], PR_SET_CHILD_SUBREAPER
## is set to prevent processes from re-parenting themselves to other processes.
func get_child_pids() -> PackedInt32Array:
	var pids := PackedInt32Array()

	# Get all child processes
	var child_pids := Reaper.pstree(pid)
	pids.append_array(child_pids)

	# Get all PIDs that share the running app's process ID group
	var pids_in_group := []
	for proc in DirAccess.get_directories_at("/proc"):
		if not (proc as String).is_valid_int():
			continue
		var process_id := proc.to_int()
		if process_id in pids_in_group or process_id in pids:
			continue
		var pgid := Reaper.get_pid_group(process_id)
		if pgid == pid:
			pids_in_group.append(process_id)

	# Get all the children of THOSE pids as well
	for process_id in pids_in_group:
		var subchildren := Reaper.pstree(process_id)
		if not process_id in pids:
			pids.append(process_id)
		for subpid in subchildren:
			if subpid in pids:
				continue
			pids.append(subpid)

	# Recursively return all child PIDs of the process
	return pids


## Returns whether or not the app can be switched to/focused
func can_focus() -> bool:
	return self.app_id > 0


## Return true if the currently running app is focused
func is_focused() -> bool:
	if not can_focus():
		return false
	var xwayland_primary := gamescope.get_xwayland(gamescope.XWAYLAND_TYPE_PRIMARY)
	if not xwayland_primary:
		return false
	var focused_app := xwayland_primary.focused_app
	return self.app_id == focused_app


## Focuses to the app's window
func grab_focus() -> void:
	if not can_focus():
		return
	var xwayland_primary := gamescope.get_xwayland(gamescope.XWAYLAND_TYPE_PRIMARY)
	if not xwayland_primary:
		return
	xwayland_primary.baselayer_app = self.app_id
	focused = true


## Switches the app window to the given window ID. Returns an error if unable
## to switch to the window
func switch_window(win_id: int, focus: bool = true) -> int:
	# Error if the window does not belong to the running app
	# TODO: Look into how window switching can work with Wayland windows
	if not win_id in window_ids:
		return ERR_DOES_NOT_EXIST

	# Get the primary XWayland instance
	var xwayland_primary := gamescope.get_xwayland(gamescope.XWAYLAND_TYPE_PRIMARY)
	if not xwayland_primary:
		return ERR_UNAVAILABLE

	# Check if this app is a focusable window.
	if not win_id in xwayland_primary.focusable_windows:
		return ERR_UNAVAILABLE
	
	# Update the window ID and optionally grab focus
	window_id = win_id
	if focus:
		grab_focus()
		xwayland_primary.baselayer_window = win_id
	return OK


## Kill the running app
func kill(sig: Reaper.SIG = Reaper.SIG.TERM) -> void:
	state = STATE.STOPPING
	app_stopped.emit()
	Reaper.reap(pid, sig)


## Iterates through all windows related to the app and sets the app ID property
## so they will appear as focusable windows to Gamescope
func _ensure_app_id() -> void:
	# If this is a Steam app, there's no need to set the app ID; Steam will do
	# it for us.
	if is_steam_app() or not is_ogui_managed:
		return

	# Get the xwayland instance this app is running on
	var xwayland := gamescope.get_xwayland_by_name(display)
	if not xwayland:
		return

	# Get all windows associated with the running app
	var possible_windows := window_ids.duplicate()

	# Try setting the app ID on each possible Window. If they are valid windows,
	# gamescope will make these windows available as focusable windows.
	for window in possible_windows:
		if xwayland.has_app_id(window):
			continue
		xwayland.set_app_id(window, self.app_id)


## Returns whether or not the window id of the running app needs to be discovered
func needs_window_id() -> bool:
	var xwayland_primary := gamescope.get_xwayland(gamescope.XWAYLAND_TYPE_PRIMARY)
	if not xwayland_primary:
		return false

	if window_id <= 0:
		logger.trace(launch_item.name + " has a bad window ID: " + str(window_id))
		return true
	var focusable_windows := xwayland_primary.focusable_windows
	if not window_id in focusable_windows:
		logger.trace(str(window_id) + " is not in the list of focusable windows")
		return true

	var xwayland := gamescope.get_xwayland_by_name(display)
	if not xwayland:
		return false

	# Check if the current window ID exists in the list of open windows
	var root_window := xwayland.root_window_id
	var all_windows := xwayland.get_all_windows(root_window)
	if not window_id in all_windows:
		logger.trace(str(window_id) + " is not in the list of all windows")
		return true

	# If this is a Steam app, the only acceptable window will have its STEAM_GAME
	# property set.
	if is_steam_app():
		var steam_app_id := get_meta("steam_app_id") as int
		if not xwayland.has_app_id(window_id):
			logger.trace(str(window_id) + " does not have an app ID already set by Steam")
			return true
		if xwayland.get_app_id(window_id) != steam_app_id:
			logger.trace(str(window_id) + " has an app ID but it does not match " + str(steam_app_id))
			return true

	# Track that a window has been successfully detected at least once.
	if not created_window:
		created_window = true
	num_created_windows += 1

	return false


## Tries to discover the window ID of the running app
func _discover_window_id() -> int:
	# If there's a window directly associated with the PID, return that
	var win_id := get_window_id_from_pid()
	if win_id > 0:
		logger.trace("Found window ID for {0} from PID: {1}".format([launch_item.name, window_id]))
		return win_id

	# Get all windows associated with the running app
	var possible_windows := window_ids.duplicate()

	# Get the primary XWayland instance
	var xwayland_primary := gamescope.get_xwayland(gamescope.XWAYLAND_TYPE_PRIMARY)
	if not xwayland_primary:
		return -1

	# Look for the app window in the list of focusable windows
	var focusable := xwayland_primary.focusable_windows
	for window in possible_windows:
		if window in focusable:
			return window

	return -1


## Returns true if the running app was launched through Steam
func is_steam_app() -> bool:
	if has_meta("is_steam_app"):
		return get_meta("is_steam_app")
	var args := launch_item.args
	for arg in args:
		if arg.contains("steam://rungameid/"):
			set_meta("is_steam_app", true)
			var steam_app_id := arg.split("/")[-1]
			if steam_app_id.is_valid_int():
				set_meta("steam_app_id", steam_app_id.to_int())
			return true
	set_meta("is_steam_app", false)
	return false


## Finds the steam process so it can be killed when a game closes
func find_steam() -> int:
	var child_pids := get_child_pids()
	for child_pid in child_pids:
		var pid_info := Reaper.get_pid_status(child_pid)
		if not "Name" in pid_info:
			continue
		var process_name := pid_info["Name"] as String
		if process_name == "steam":
			logger.trace("Found steam PID: " + str(child_pid))
			return child_pid

	return -1


func _to_string() -> String:
	if not self.launch_item:
		return "<RunningApp.Unknown>"
	return "<RunningApp.{0}#{1}>".format([self.launch_item.name, self.app_id])
