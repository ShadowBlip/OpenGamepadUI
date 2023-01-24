@icon("res://assets/icons/upload.svg")
extends Node

signal app_launched(app: RunningApp)
signal app_stopped(app: RunningApp)
signal recent_apps_changed()

var state_machine := preload("res://assets/state/state_machines/global_state_machine.tres") as StateMachine
var in_game_state := preload("res://assets/state/states/in_game.tres") as State
var in_game_menu_state := preload("res://assets/state/states/in_game_menu.tres") as State

var target_display: String = OS.get_environment("DISPLAY")
var _current_app: RunningApp
var _running: Array[RunningApp] = []
var _apps_by_pid: Dictionary = {}
var _apps_by_name: Dictionary = {}
var _all_apps_by_name: Dictionary = {}
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
func launch(app: LibraryLaunchItem) -> RunningApp:
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

	# Create a running app instance
	if not app.name in _all_apps_by_name:
		_all_apps_by_name[app.name] = RunningApp.new(app, pid, display)
	var running_app := _all_apps_by_name[app.name] as RunningApp
	running_app.launch_item = app
	running_app.pid = pid
	running_app.display = display

	# Add the running app to our list and change to the IN_GAME state
	_add_running(running_app)
	state_machine.set_state([in_game_state])
	_update_recent_apps(app)
	return running_app


# Stops the game and all its children with the given PID
func stop(app: RunningApp) -> void:
	Reaper.reap(app.pid)
	_remove_running(app)


# Returns a list of apps that have been launched recently
func get_recent_apps() -> Array:
	if not "recent" in _persist_data:
		return []
	return _persist_data["recent"]


# Returns a list of currently running apps
func get_running() -> Array[RunningApp]:
	return _running


# Returns the currently running app
func get_current_app() -> RunningApp:
	return _current_app


# Returns whether the given app is running
func is_running(name: String) -> bool:
	if name in _apps_by_name:
		return true
	return false


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
func _add_running(app: RunningApp):
	_apps_by_pid[app.pid] = app
	_apps_by_name[app.launch_item.name] = app
	_running.append(app)
	_current_app = app
	app_launched.emit(app)


# Removes the given PID from our list of running apps
func _remove_running(app: RunningApp):
	logger.info("Cleaning up pid {0}".format([app.pid]))
	if app == _current_app:
		_current_app = null
	_running.erase(app)
	_apps_by_name.erase(app.launch_item.name)
	_apps_by_pid.erase(app.pid)
	
	# If no more apps are running, clear the in-game state
	if len(_running) == 0:
		state_machine.remove_state(in_game_state)
		state_machine.remove_state(in_game_menu_state)
	
	app_stopped.emit(app)
	app.app_killed.emit()


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
	if len(_running) == 0:
		return
	
	# Check all running apps
	var to_remove := []
	for app in _running:
		# If our app is still running, great!
		if app.is_running():
			continue
		
		# If it's not running, make sure we remove it from our list
		to_remove.push_back(app)
		
	# Remove any non-running apps
	for app in to_remove:
		_remove_running(app)
