extends Object
class_name Gamescope

const max_xwaylands: int = 10

# Sets the given X property on the given window.
# The format can be 8, 16, or 32 bits, followed by 's' for a c string, 'c' for
# a cardinal, or 'i' for an integer.
# Example: 32c
static func set_xprop(window_id: String, key: String, format: String, value: String) -> int:
	print_debug("Setting window {0} key {1} to {2}".format([window_id, key, value]))
	return OS.execute("xprop", ["-id", window_id, "-f", key, format, "-set", key, value])

# Returns true if the given x property exists on the given window.
static func has_xprop(display: int, window_id: String, key: String) -> bool:
	var target_arg = "-id {0}".format([window_id])
	if window_id == "root":
		target_arg = "-root"
	var output = []
	var cmd = ["-c", "DISPLAY=:{0} timeout 0.5 xprop {1} {2}".format([display, target_arg, key])]
	var code = OS.execute("sh", cmd, output)
	if code != 0:
		return false
	for line in output:
		if line.contains(key) and not line.contains("no such atom"):
			return true
	return false

# Returns the xwayland number that we're running in
static func discover_xwayland_display(pid: int) -> int:
	var display: int = -1
	for i in range(0, max_xwaylands):
		if get_window_id(pid, i) != "":
			display = i
			break
	
	if display < 0:
		push_error("Unable to detect running xwayland display! We won't be able to launch games!")
		
	return display

# Returns all gamescope displays
# TODO: This seems brittle. Is there any other way we can discover Gamescope displays?
static func discover_all_xwayland_displays(start: int = 0) -> Array:
	var displays = []
	for i in range(start, max_xwaylands):
		if has_xprop(i, "root", "GAMESCOPE_CURSOR_VISIBLE_FEEDBACK"):
			displays.push_back(i)
	return displays

# Returns the xwayland window ID for the given process
static func get_window_id(pid: int, display: int) -> String:
	print_debug("Getting Window ID for {0} on display {1}".format([pid, display]))
	var output = []
	var cmd = ["-c", "DISPLAY=:{0} xdotool search --pid {1}".format([display, pid])]
	if OS.execute("sh", cmd, output) != 0:
		return ""
	var window_id: String
	for line in output:
		if line == "":
			continue
		window_id = line.trim_suffix("\n")
	print_debug("Found Window ID: ", window_id)
	return window_id
