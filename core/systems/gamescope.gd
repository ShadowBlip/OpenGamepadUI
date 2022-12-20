# Manages Gamescope specific functionality
# TODO: Instead of relying on xprop/wininfo, we should use native X11 methods
# though the DisplayServer through an extension.
# https://docs.godotengine.org/en/latest/classes/class_displayserver.html
extends Object
class_name Gamescope

const max_xwaylands: int = 10


# Sets the given X property on the given window.
# Example:
#  Gamescope.set_xprop(":0", 1234, "STEAM_INPUT", 1)
static func set_xprop(display: String, window_id: int, key: String, value: int) -> int:
	var logger := Log.get_logger("Gamescope")
	logger.debug("Setting window {0} key {1} to {2}".format([window_id, key, value]))
	return Xlib.set_xprop(display, window_id, key, value)


# Returns the value of the given X property for the given window. Returns
# Xlib.ERR_XPROP_NOT_FOUND if property doesn't exist.
static func get_xprop(display: String, window_id: int, key: String) -> int:
	return Xlib.get_xprop(display, window_id, key)


# Returns true if the given X property exists on the given window.
static func has_xprop(display: String, window_id: int, key: String) -> bool:
	return Xlib.has_xprop(display, window_id, key)


# Returns all gamescope displays
# TODO: This seems brittle. Is there any other way we can discover Gamescope displays?
static func discover_gamescope_displays() -> PackedStringArray:
	var logger := Log.get_logger("Gamescope")
	logger.info("Discovering xwaylands!")

	# X11 displays have a corresponding socket in /tmp/.X11-unix
	# The sockets are named like: X0, X1, X2, etc.
	var dir := DirAccess.open("/tmp/.X11-unix")
	var sockets := dir.get_files()
	
	# Loop through each socket file and derrive the display number.
	var displays: PackedInt32Array = []
	for socket in sockets:
		var suffix := (socket as String).trim_prefix("X")
		if not suffix.is_valid_int():
			logger.warn("Skipping X11 socket with a weird name: " + socket)
			continue
		displays.append(suffix.to_int())
	
	# Check to see if the root window of these displays has gamescope-specific properties
	var gamescope_displays := PackedStringArray()
	for display_num in displays:
		var display := ":{0}".format([display_num])
		var root_id := Xlib.get_root_window_id(display)
		if has_xprop(display, root_id, "GAMESCOPE_CURSOR_VISIBLE_FEEDBACK"):
			gamescope_displays.append(display)
	return gamescope_displays


# Returns the xwayland window ID for the given process. Returns -1 if no
# window was found.
static func get_window_id(display: String, pid: int) -> int:
	var logger := Log.get_logger("Gamescope")
	logger.debug("Getting Window ID for {0} on display {1}".format([pid, display]))
	var root_id := Xlib.get_root_window_id(display)
	var all_windows := get_all_windows(display, root_id)
	for window_id in all_windows:
		var window_pid := Xlib.get_xprop(display, window_id, "_NET_WM_PID")
		if pid == window_pid:
			return window_id
	return -1


# Recursively returns all child windows of the given window id
static func get_all_windows(display: String, window_id: int) -> PackedInt32Array:
	var children := Xlib.get_window_children(display, window_id)
	if len(children) == 0:
		return PackedInt32Array([window_id])
	
	var leaves := PackedInt32Array()
	for child in children:
		leaves.append_array(get_all_windows(display, child))
		
	return leaves
