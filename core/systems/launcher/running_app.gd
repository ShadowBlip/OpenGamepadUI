extends Resource
class_name RunningApp

## Defines a running application
##
## RunningApp contains details and methods around running applications

const Gamescope := preload("res://core/global/gamescope.tres")


## Emitted when all child processes of the app are no longer running
signal app_killed
## Emitted when the given app is gracefully stopped
signal app_stopped
## Emitted when the window id of the given app has changed
signal window_id_changed
## Emitted whenever the windows change for the app
signal window_ids_changed(from: PackedInt32Array, to: PackedInt32Array)
## Emitted when the app id of the given app has changed
signal app_id_changed
## Emitted when the app's state has changed
signal state_changed(from: STATE, to: STATE)
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


## Updates the running app and fires signals
func update() -> void:
	# Update all windows related to the app's PID
	window_ids = get_all_window_ids()

	# Ensure that all windows related to the app have an app ID set
	_ensure_app_id()

	# Ensure that the running app has a corresponding window ID
	var has_valid_window := false
	if needs_window_id():
		logger.debug("App needs a valid window id")
		var id := _discover_window_id()
		if id > 0 and window_id != id:
			logger.debug("Setting window ID " + str(id) + " for " + launch_item.name)
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
	logger.debug(launch_item.name + " current state: " + state_str[state])

	# TODO: Check all windows for STEAM_GAME prop
	# If this was launched by Steam, try and detect if the game closed 
	# so we can kill Steam gracefully
	if is_steam_app() and state == STATE.MISSING_WINDOW and is_ogui_managed:
		logger.debug(launch_item.name + " is a Steam game and has no valid window ID. It may have closed.")
		# Don't try closing Steam immediately. Wait a few more ticks before attempting
		# to close Steam.
		if steam_close_tries < 4:
			steam_close_tries += 1
			return
		var steam_pid := find_steam()
		if steam_pid > 0:
			logger.info("Trying to stop steam with pid: " + str(steam_pid))
			OS.execute("kill", ["-15", str(steam_pid)])



## Attempt to discover the window ID from the PID of the given application
func get_window_id_from_pid() -> int:
	var display_type := Gamescope.get_display_type(display)
	return Gamescope.get_window_id(pid, display_type)


## Attempt to discover all window IDs from the PID of the given application and
## the PIDs of all processes in the same process group.
func get_all_window_ids() -> PackedInt32Array:
	var app_name := launch_item.name
	var display_type := Gamescope.get_display_type(display)
	var window_ids := PackedInt32Array()
	var pids := get_child_pids()
	pids.append(pid)
	logger.debug(app_name + " found related PIDs: " + str(pids))

	for process_id in pids:
		var windows := Gamescope.get_window_ids(process_id, display_type)
		for window in windows:
			if window < 0:
				continue
			if window in window_ids:
				continue
			window_ids.append(window)
	logger.debug(app_name + " found related window IDs: " + str(window_ids))

	return window_ids


## Returns true if the app's PID is running or any decendents with the same
## process group.
func is_running() -> bool:
	# If the app is still running, great!
	if OS.is_process_running(pid):
		return true

	# If that failed, check if reaper can get the status.
	logger.debug("Reaper pid State: " + Reaper.get_pid_state(pid))
	if Reaper.get_pid_state(pid) in ["R (running)", "S (sleeping)"]:
		return true

	logger.debug("Original process not running. Checking child PID's...")
	# If it's not running, let's check to make sure it's REALLY not running
	# and hasn't re-parented itself
	var children := get_child_pids()
	if children.size() > 0:
		var pids := Array(children)
		logger.debug("{0} is not running, but lives on in {1}".format([pid, ",".join(pids)]))
		return true
	logger.debug("Process " + str(pid) + " has died and no child PID's could be found.")
	return false


## Return a list of child PIDs. When launching apps with [Reaper], PR_SET_CHILD_SUBREAPER
## is set to prevent processes from re-parenting themselves to other processes.
func get_child_pids() -> PackedInt32Array:
	var pids := PackedInt32Array()

	# Get all child processes
	var child_pids := Reaper.pstree(pid)
	pids.append_array(pids)

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
	return window_id > 0


## Return true if the currently running app is focused
func is_focused() -> bool:
	if not can_focus():
		return false
	var focused_window := Gamescope.get_focused_window()
	return window_id == focused_window or focused_window in window_ids


## Focuses to the app's window
func grab_focus() -> void:
	if not can_focus():
		return
	Gamescope.set_baselayer_window(window_id)
	focused = true


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

	# Get all windows associated with the running app
	var possible_windows := window_ids.duplicate()

	# Try setting the app ID on each possible Window. If they are valid windows,
	# gamescope will make these windows available as focusable windows.
	var app_name := launch_item.name
	for window in possible_windows:
		var display_type := Gamescope.get_display_type(display)
		if Gamescope.has_app_id(window, display_type):
			continue
		Gamescope.set_app_id(window, window, display_type)


## Returns whether or not the window id of the running app needs to be discovered
func needs_window_id() -> bool:
	if window_id <= 0:
		logger.debug(launch_item.name + " has a bad window ID: " + str(window_id))
		return true
	var focusable_windows := Gamescope.get_focusable_windows()
	if not window_id in focusable_windows:
		logger.debug(str(window_id) + " is not in the list of focusable windows")
		return true

	# Check if the current window ID exists in the list of open windows
	var root_window := Gamescope.get_root_window_id(Gamescope.XWAYLAND.GAME)
	var all_windows := Gamescope.get_all_windows(root_window, Gamescope.XWAYLAND.GAME)
	if not window_id in all_windows:
		logger.debug(str(window_id) + " is not in the list of all windows")
		return true

	# If this is a Steam app, the only acceptable window will have its STEAM_GAME
	# property set.
	if is_steam_app():
		var display_type := Gamescope.get_display_type(display)
		var steam_app_id := get_meta("steam_app_id") as int
		if not Gamescope.has_app_id(window_id, display_type):
			logger.debug(str(window_id) + " does not have an app ID already set by Steam")
			return true
		if Gamescope.get_app_id(window_id) != steam_app_id:
			logger.debug(str(window_id) + " has an app ID but it does not match " + str(steam_app_id))
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
		logger.debug("Found window ID for {0} from PID: {1}".format([launch_item.name, window_id]))
		return win_id

	# Get all windows associated with the running app
	var possible_windows := window_ids.duplicate()
	
	# Look for the app window in the list of focusable windows
	var focusable := Gamescope.get_focusable_windows()
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
			logger.debug("Found steam PID: " + str(child_pid))
			return child_pid

	return -1
