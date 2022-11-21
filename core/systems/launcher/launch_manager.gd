extends Node
class_name LaunchManager

signal app_launched(pid: int)
signal app_killed(pid: int)

var PID: int = OS.get_process_id()
var running: PackedInt64Array = []
@onready var xwayland_display = Gamescope.discover_xwayland_display(PID)
@onready var overlay_window_id = Gamescope.get_window_id(PID, xwayland_display)

func _ready() -> void:
	_set_overylay(overlay_window_id)

# Launches the given command on the given xwayland display. Returns a PID
# of the launched process.
func launch(cmd: String, args: PackedStringArray, display: int = xwayland_display + 1) -> int:
	var command = "DISPLAY=:{0} {1} {2}".format([display, cmd, " ".join(args)])
	print_debug("Launching game with command: {0}".format([command]))
	var pid = OS.create_process("sh", ["-c", command])
	print_debug("Launched with PID: {0}".format([pid]))
	running.append(pid)
	return pid

# Stops the game with the given PID
func stop(pid: int) -> void:
	OS.kill(pid)
	var i = running.find(pid)
	if i >= 0:
		running.remove_at(i)

# Lets us run as an overlay in gamescope
func _set_overylay(window_id: String) -> void:
	# Pretend to be Steam
	Gamescope.set_xprop(window_id, "STEAM_OVERLAY", "32c", "1")
	# Gamescope is hard-coded to look for appId 769
	Gamescope.set_xprop(window_id, "STEAM_GAME", "32c", "769")
	# Sets ourselves to the input focus
	Gamescope.set_xprop(window_id, "STEAM_INPUT_FOCUS", "32c", "1")
