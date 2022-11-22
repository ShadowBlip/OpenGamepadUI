extends Node
class_name LaunchManager

signal app_launched(pid: int)
signal app_killed(pid: int)

@export_node_path(StateManager) var state_manager = NodePath("../StateManager")

var PID: int = OS.get_process_id()
var running: PackedInt64Array = []
var target_display: int = -1

@onready var state_mgr = get_node(state_manager)
@onready var overlay_display = Gamescope.discover_xwayland_display(PID)
@onready var overlay_window_id = Gamescope.get_window_id(PID, overlay_display)

func _ready() -> void:
	_set_overylay(overlay_window_id)
	target_display = _get_target_display(overlay_display)

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
	running.append(pid)
	state_mgr.push_state(StateManager.State.IN_GAME)
	return pid

# Stops the game with the given PID
func stop(pid: int) -> void:
	OS.kill(pid)
	var i = running.find(pid)
	if i >= 0:
		running.remove_at(i)

# Returns the target xwayland display to launch on
func _get_target_display(exclude_display: int) -> int:
	# Get all gamescope xwayland displays
	var all_displays = Gamescope.discover_all_xwayland_displays(exclude_display)
	print_debug("Found xwayland displays: {0}".format([all_displays]))
	# Return the xwayland display that doesn't match our excluded display
	for display in all_displays:
		if display == exclude_display:
			continue
		return display
	# If we can't find any other displays, use the one given
	return exclude_display

# Lets us run as an overlay in gamescope
func _set_overylay(window_id: String) -> void:
	# Pretend to be Steam
	Gamescope.set_xprop(window_id, "STEAM_OVERLAY", "32c", "1")
	# Gamescope is hard-coded to look for appId 769
	Gamescope.set_xprop(window_id, "STEAM_GAME", "32c", "769")
	# Sets ourselves to the input focus
	Gamescope.set_xprop(window_id, "STEAM_INPUT_FOCUS", "32c", "1")
