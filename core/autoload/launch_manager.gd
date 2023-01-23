@icon("res://assets/icons/upload.svg")
extends Node

signal app_launched(app: LibraryLaunchItem, pid: int)
signal app_stopped(app: LibraryLaunchItem, pid: int)
signal recent_apps_changed()

var state_machine := preload("res://assets/state/state_machines/global_state_machine.tres") as StateMachine
var in_game_state := preload("res://assets/state/states/in_game.tres") as State
var apps_running: Dictionary = {}
var running: PackedInt64Array = []
var target_display: String = OS.get_environment("DISPLAY")
var _data_dir: String = ProjectSettings.get_setting("OpenGamepadUI/data/directory")
var _persist_path: String = "/".join([_data_dir, "launcher.json"])
var _persist_data: Dictionary = {"version": 1}
var logger := Log.get_logger("LaunchManager")

@onready var overlay_display = OS.get_environment("DISPLAY")


func _init() -> void:
	_load_persist_data()


func _ready() -> void:
	# Get the target xwayland display to launch on
	target_display = _get_target_display(overlay_display)
	
	# Set a timer that will update our state based on if anything is running.
	var running_timer = Timer.new()
	running_timer.timeout.connect(_check_running)
	running_timer.wait_time = 1
	add_child(running_timer)
	running_timer.start()


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
	var persist_json: String = JSON.stringify(_persist_data)
	file.store_string(JSON.stringify(_persist_data))
	file.flush()


# Launches the given command on the target xwayland display. Returns a PID
# of the launched process.
func launch(app: LibraryLaunchItem) -> int:
	var cmd: String = app.command
	var args: PackedStringArray = app.args
	
	# Discover the target display to launch on.
	target_display = _get_target_display(overlay_display)
	var display = target_display
	
	# Build the launch command to run
	var command = "DISPLAY={0} {1} {2}".format([display, cmd, " ".join(args)])
	logger.info("Launching game with command: {0}".format([command]))
	var pid = OS.create_process("sh", ["-c", command])
	logger.info("Launched with PID: {0}".format([pid]))
	
	# Add the running app to our list and change to the IN_GAME state
	_add_running(app, pid)
	state_machine.set_state([in_game_state])
	_update_recent_apps(app)
	return pid


# Stops the game and all its children with the given PID
func stop(pid: int) -> void:
	Reaper.reap(pid)
	_remove_running(pid)


# Returns a list of apps that have been launched recently
func get_recent_apps() -> Array:
	if not "recent" in _persist_data:
		return []
	return _persist_data["recent"]


# Updates our list of recently launched apps
func _update_recent_apps(app: LibraryLaunchItem) -> void:
	if not "recent" in _persist_data:
		_persist_data["recent"] = []
	var recent: Array = _persist_data["recent"]
	recent.erase(app.name)
	recent.push_front(app.name)
	# TODO: Make this configurable instead of hard coding at 10
	if len(recent) > 10:
		recent.pop_back()
	_persist_data["recent"] = recent
	_save_persist_data()
	recent_apps_changed.emit()


# Adds the given PID to our list of running apps
func _add_running(app: LibraryLaunchItem, pid: int):
	apps_running[pid] = app
	running.append(pid)
	app_launched.emit(app, pid)


# Removes the given PID from our list of running apps
func _remove_running(pid: int):
	var i = running.find(pid)
	if i < 0:
		return
	logger.info("Cleaning up pid {0}".format([pid]))
	var app: LibraryLaunchItem = apps_running[pid]
	apps_running.erase(pid)
	running.remove_at(i)
	
	# If no more apps are running, clear the in-game state
	if len(running) == 0:
		state_machine.remove_state(in_game_state)
	
	app_stopped.emit(app, pid)


# Returns the target xwayland display to launch on
func _get_target_display(exclude_display: String) -> String:
	# Get all gamescope xwayland displays
	var all_displays := Gamescope.discover_gamescope_displays()
	logger.info("Found xwayland displays: " + ",".join(all_displays))
	# Return the xwayland display that doesn't match our excluded display
	for display in all_displays:
		if display == exclude_display:
			continue
		return display
	# If we can't find any other displays, use the one given
	return exclude_display


# Checks for running apps and updates our state accordingly
func _check_running():
	if len(running) == 0:
		return
	
	# Check all running apps
	var to_remove = []
	for pid in running:
		# If our app is still running, great!
		if OS.is_process_running(pid):
			continue
		
		# If it's not running, let's check to make sure it's REALLY not running
		# and hasn't re-parented itself
		var gamescope_pid: int = Reaper.get_parent_pid(OS.get_process_id())
		if not Reaper.is_gamescope_pid(gamescope_pid):
			logger.warn("OpenGamepadUI wasn't launched with gamescope! Unexpected behavior expected.")
		
		# Try checking to see if there are any other processes running with our
		# app's process group
		var candidates = Reaper.get_children_with_pgid(gamescope_pid, pid)
		if len(candidates) > 0:
			logger.info("{0} is not running, but lives on in {1}".format([pid, ",".join(candidates)]))
			continue
		
		# If it's not running, make sure we remove it from our list
		to_remove.push_back(pid)
		
	# Remove any non-running apps
	for pid in to_remove:
		_remove_running(pid)
