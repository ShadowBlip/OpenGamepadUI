extends Node
class_name LaunchManager

signal app_launched(pid: int)
signal app_stopped(pid: int)

var running: PackedInt64Array = []
var target_display: int = -1

@onready var main: Main = get_node("..")
@onready var state_manager: StateManager = get_node("../StateManager")
@onready var overlay_display = main.overlay_display


func _ready() -> void:
	# Get the target xwayland display to launch on
	target_display = _get_target_display(overlay_display)
	
	# Set a timer that will update our state based on if anything is running.
	var running_timer = Timer.new()
	running_timer.timeout.connect(_check_running)
	running_timer.wait_time = 1
	add_child(running_timer)
	running_timer.start()
	

# Launches the given command on the target xwayland display. Returns a PID
# of the launched process.
func launch(cmd: String, args: PackedStringArray) -> int:
	# Discover the target display to launch on.
	if target_display < 0:
		target_display = _get_target_display(overlay_display)
	var display = target_display
	
	# Build the launch command to run
	var command = "DISPLAY=:{0} {1} {2}".format([display, cmd, " ".join(args)])
	print_debug("Launching game with command: {0}".format([command]))
	var pid = OS.create_process("sh", ["-c", command])
	print_debug("Launched with PID: {0}".format([pid]))
	
	# Add the running app to our list and change to the IN_GAME state
	_add_running(pid)
	state_manager.push_state(StateManager.State.IN_GAME)
	return pid


# Stops the game with the given PID
func stop(pid: int) -> void:
	OS.kill(pid)
	_remove_running(pid)


# Adds the given PID to our list of running apps
func _add_running(pid: int):
	running.append(pid)
	app_launched.emit(pid)


# Removes the given PID from our list of running apps
func _remove_running(pid: int):
	var i = running.find(pid)
	if i < 0:
		return
	print_debug("Cleaning up pid {0}".format([pid]))
	running.remove_at(i)
	
	# TODO: Better way to do this?
	state_manager.set_state([StateManager.State.HOME])
	
	app_stopped.emit(pid)


# Returns the target xwayland display to launch on
func _get_target_display(exclude_display: int) -> int:
	# Get all gamescope xwayland displays
	var all_displays = Gamescope.discover_all_xwayland_displays(exclude_display)
	print_debug("Found xwayland displays: " + ",".join(all_displays))
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
		if state_manager.has_state(StateManager.State.IN_GAME):
			state_manager.remove_state(StateManager.State.IN_GAME)
		return
	
	# Check all running apps
	var to_remove = []
	for pid in running:
		# If our app is still running, great!
		if OS.is_process_running(pid):
			continue
		
		# If it's not running, make sure we remove it from our list
		to_remove.push_back(pid)
		
	# Remove any non-running apps
	for pid in to_remove:
		_remove_running(pid)
		
	# Change away from IN_GAME state if nothing is running
	if state_manager.current_state() == StateManager.State.IN_GAME and len(running) == 0:
		state_manager.pop_state()
