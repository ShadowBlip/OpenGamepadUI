extends Resource
class_name RunningApp

## Defines a running application
##
## RunningApp contains details and methods around running applications

const Gamescope := preload("res://core/global/gamescope.tres")

## Emitted when the given app has been killed
signal app_killed
## Emitted when the window id of the given app has changed
signal window_id_changed
## Emitted when the app id of the given app has changed
signal app_id_changed

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
## The currently detected window ID of the application
var window_id: int:
	set(v):
		window_id = v
		window_id_changed.emit()
## The current app ID of the application
var app_id: int:
	set(v):
		app_id = v
		app_id_changed.emit()
## Whether or not the running app has created at least one valid window
var created_window := false
## The number of windows that have been disovered from this app
var num_created_windows := 0
var logger := Log.get_logger("RunningApp", Log.LEVEL.DEBUG)


func _init(item: LibraryLaunchItem, process_id: int, dsp: String) -> void:
	launch_item = item
	pid = process_id
	display = dsp


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
	logger.debug(app_name + " found window IDs: " + str(window_ids))

	return window_ids


## Returns true if the app's PID is running or any decendents with the same
## process group.
func is_running() -> bool:
	# If the app is still running, great!
	if OS.is_process_running(pid):
		return true

	# If it's not running, let's check to make sure it's REALLY not running
	# and hasn't re-parented itself
	var children := get_child_pids()
	if children.size() > 0:
		var pids := Array(children)
		logger.debug("{0} is not running, but lives on in {1}".format([pid, ",".join(pids)]))
		return true

	return false


## Return a list of child PIDs. When launching apps with [Reaper], PR_SET_CHILD_SUBREAPER
## is set to prevent processes from re-parenting themselves to other processes.
func get_child_pids() -> PackedInt32Array:
	if launch_item != null:
		logger._name = "RunningApp-" + launch_item.name
	var pids := PackedInt32Array()

	# Get all child processes
	var child_pids := Reaper.pstree(pid)
	pids.append_array(pids)

	# Get all PIDs that share the running app's process ID group
	var gamescope_pid := Reaper.get_parent_pid(OS.get_process_id())
	var pids_in_group := Reaper.get_children_with_pgid(gamescope_pid, pid)
	
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
	return Reaper.pstree(pid)


## Return true if the currently running app is focused
func is_focused() -> bool:
	var focused_window := Gamescope.get_focused_window()
	if window_id == focused_window:
		return true
	return false


## Kill the running app
func kill(sig: Reaper.SIG = Reaper.SIG.TERM) -> void:
	Reaper.reap(pid, sig)


## Iterates through all windows related to the app and sets the app ID property
## so they will appear as focusable windows to Gamescope
func ensure_app_id() -> void:
	# If this is a Steam app, there's no need to set the app ID; Steam will do
	# it for us.
	if is_steam_app():
		return
	
	# Get all windows associated with the running app
	var possible_windows := get_all_window_ids()
	
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

	# Track that a window has been successfully detected at least once.
	if not created_window:
		created_window = true
	num_created_windows += 1
		
	return false


## Tries to discover the window ID of the running app
func discover_window_id() -> int:
	# If there's a window directly associated with the PID, return that
	var win_id := get_window_id_from_pid()
	if win_id > 0:
		logger.debug("Found window ID for {0} from PID: {1}".format([launch_item.name, window_id]))
		return win_id

	# Get all windows associated with the running app
	var possible_windows := get_all_window_ids()
	
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
