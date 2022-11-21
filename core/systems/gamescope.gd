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

# Returns the xwayland number that we're running in
static func discover_xwayland_display(pid: int) -> int:
	var display: int = -1
	for i in range(0, max_xwaylands):
		if get_window_id(pid, i) != "":
			display = i
			break
	
	if display < 0:
		push_error("Unable to detect running xwayland display! We won't be able to launch games!")
		#assert(false)
		
	return display

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
