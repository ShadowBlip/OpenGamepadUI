extends Resource
class_name Gamescope

## Interact with Gamescope windows and properties
##
## The Gamescope class is responsible for interacting with Gamescope, usually
## via the means of setting gamescope-specific window properties. It can be
## used to discover Gamescope displays, list windows and their children, and set
## gamescope-specific window atoms to switch windows, set blur, limit FPS, etc.
## [br][br]
## For example, to limit the FPS, you can do the following:
##     [codeblock]
##     Gamescope.set_fps_limit(display, 30)
##     [/codeblock]
## [br][br]
## Most of the core functionality of this class is provided by the [Xlib]
## module, which is a GDExtension that exposes Xlib methods to Godot.

## Gamescope Blur modes
enum BLUR_MODE {
	OFF = 0,  ## Turns off blur of running games
	COND = 1,  ## Conditionally blurs running games
	ALWAYS = 2,  ## Turns blurring of running games on
}

## Specifies which Gamescope xwayland server to perform an operation on.
enum XWAYLAND {
	PRIMARY,  ## Primary Gamescope xwayland instance
	OGUI,  ## Xwayland instance that OpenGamepadUI is running on
	GAME,  ## Xwayland instance where games run
}

@export var log_level := Log.LEVEL.DEBUG
var xwayland_primary: Xlib
var xwayland_ogui: Xlib
var xwayland_game: Xlib
var xwaylands: Array[Xlib] = []
var logger := Log.get_logger("Gamescope", log_level)


# Connects to all gamescope xwayland instances
func _init() -> void:
	# Connect to the xwayland instance that OGUI is running on
	var ogui_display := OS.get_environment("DISPLAY")
	xwayland_ogui = Xlib.new()
	if xwayland_ogui.open(ogui_display) != OK:
		logger.error("Failed to open OGUI X server: " + ogui_display)
		return
	if _is_gamescope_xwayland(xwayland_ogui):
		logger.debug("OpenGamepadUI is running in Gamescope")
		xwayland_game = xwayland_ogui
	if _is_gamescope_xwayland_primary(xwayland_ogui):
		logger.debug("OpenGamepadUI is running on the primary Gamescope xwayland")
		xwayland_primary = xwayland_ogui
	xwaylands.push_front(xwayland_ogui)

	# Discover all other xwayland displays
	var displays := discover_gamescope_displays()
	for display in displays:
		if _has_xwayland(display):
			logger.debug("Already discovered xwayland: " + display)
			continue
		var xwayland := Xlib.new()
		if xwayland.open(display) != OK:
			logger.debug("Failed to open X server: " + display)
			continue
		if _is_gamescope_xwayland_primary(xwayland):
			logger.debug("Display " + display + " is the primary gamescope instance")
			xwayland_primary = xwayland
		xwaylands.append(xwayland)

	# If we haven't discovered any gamescope displays, set everything to use
	# the OGUI xwayland instance
	if not xwayland_primary:
		logger.warn("OpenGamepadUI is not running in Gamescope. Unexpected behavior expected.")
		xwayland_primary = xwayland_ogui
	if not xwayland_game:
		xwayland_game = xwayland_ogui


## Returns all gamescope xwayland names (E.g. [":0", ":1"])
# TODO: This seems brittle. Is there any other way we can discover Gamescope displays?
func discover_gamescope_displays() -> PackedStringArray:
	logger.debug("Discovering xwaylands!")

	# X11 displays have a corresponding socket in /tmp/.X11-unix
	# The sockets are named like: X0, X1, X2, etc.
	var dir := DirAccess.open("/tmp/.X11-unix")
	var sockets := dir.get_files()

	# Loop through each socket file and derrive the display number.
	var display_names: PackedInt32Array = []
	for socket in sockets:
		var suffix := (socket as String).trim_prefix("X")
		if not suffix.is_valid_int():
			logger.warn("Skipping X11 socket with a weird name: " + socket)
			continue
		display_names.append(suffix.to_int())

	# Check to see if the root window of these displays has gamescope-specific properties
	var gamescope_displays := PackedStringArray()
	for display_num in display_names:
		var display := ":{0}".format([display_num])
		var xwayland := Xlib.new()
		if xwayland.open(display) != OK:
			logger.debug("Failed to open X server: " + display)
			continue
		if _is_gamescope_xwayland(xwayland):
			gamescope_displays.append(display)
			logger.debug("Disovered X server display: " + display)
		xwayland.close()
	return gamescope_displays


## Returns the name of the given xwayland display (e.g. ":1")
func get_display_name(display: XWAYLAND) -> String:
	var xwayland := _get_xwayland(display)
	if not xwayland:
		return ""
	return xwayland.get_name()


## Returns true if the given X property exists on the given window.
func has_xprop(window_id: int, key: String, display: XWAYLAND) -> bool:
	var xwayland := _get_xwayland(display)
	if not xwayland:
		return false
	return xwayland.has_xprop(window_id, key)


## Returns a list of X properties on the given window
func list_xprops(window_id: int, display: XWAYLAND) -> PackedStringArray:
	var xwayland := _get_xwayland(display)
	if not xwayland:
		return []
	return xwayland.list_xprops(window_id)


## Returns the name of the given window.
func get_window_name(window_id: int, display: XWAYLAND = XWAYLAND.GAME) -> String:
	var xwayland := _get_xwayland(display)
	if not xwayland:
		return ""
	return xwayland.get_window_name(window_id)


## Returns the PID of the given window. Returns -1 if no PID was found.
func get_window_pid(window_id: int, display: XWAYLAND) -> int:
	var xwayland := _get_xwayland(display)
	if not xwayland:
		return -1
	return xwayland.get_window_pid(window_id)


## Returns the xwayland window ID for the given process. Returns -1 if no
## window was found.
func get_window_id(pid: int, display: XWAYLAND) -> int:
	var display_name := get_display_name(display)
	logger.debug("Getting Window ID for {0} on display {1}".format([pid, display_name]))
	var xwayland := _get_xwayland(display)
	if not xwayland:
		return -1
	var root_id := xwayland.get_root_window_id()
	print("Goot root id: ", root_id)
	var all_windows := get_all_windows(root_id, display)
	print("Got all windows: ", all_windows)
	for window_id in all_windows:
		var window_pid := xwayland.get_window_pid(window_id)
		print("Got pid: ", window_pid)
		if pid == window_pid:
			return window_id
		window_pid = xwayland.get_xprop(window_id, "_NET_WM_PID")
		if pid == window_pid:
			return window_id

	return -1


## Returns the child window ids of the given window
func get_window_children(window_id: int, display: XWAYLAND) -> PackedInt32Array:
	var xwayland := _get_xwayland(display)
	if not xwayland:
		return PackedInt32Array()
	var children := xwayland.get_window_children(window_id)
	if len(children) == 0:
		return PackedInt32Array()
	return children


## Recursively returns all child windows of the given window id
func get_all_windows(window_id: int, display: XWAYLAND) -> PackedInt32Array:
	var xwayland := _get_xwayland(display)
	if not xwayland:
		return PackedInt32Array()
	var children := xwayland.get_window_children(window_id)
	if len(children) == 0:
		return PackedInt32Array([])

	var leaves := PackedInt32Array()
	for child in children:
		leaves.append(child)
		leaves.append_array(get_all_windows(display, child))

	return leaves


## Returns true if the window with the given window ID exists
func is_focusable_app(window_id: int, display: XWAYLAND = XWAYLAND.PRIMARY) -> bool:
	var focusable := get_focusable_apps(display)
	if window_id in focusable:
		return true
	return false


## Returns the root window ID of the given display
func get_root_window_id(display: XWAYLAND) -> int:
	var xwayland := _get_xwayland(display)
	if not xwayland:
		return -1
	return xwayland.get_root_window_id()


## Returns a list of focusable app window ids
func get_focusable_apps(display: XWAYLAND = XWAYLAND.PRIMARY) -> PackedInt32Array:
	var xwayland := _get_xwayland(display)
	if not xwayland:
		return PackedInt32Array()
	var root_id := xwayland.get_root_window_id()
	return _get_xprop_array(xwayland, root_id, "GAMESCOPE_FOCUSABLE_APPS")


## Returns a list of focusable window ids
func get_focusable_windows(display: XWAYLAND = XWAYLAND.PRIMARY) -> PackedInt32Array:
	var xwayland := _get_xwayland(display)
	if not xwayland:
		return PackedInt32Array()
	var root_id := xwayland.get_root_window_id()
	return _get_xprop_array(xwayland, root_id, "GAMESCOPE_FOCUSABLE_WINDOWS")


## Returns a list of focusable window names
func get_focusable_window_names(display: XWAYLAND = XWAYLAND.PRIMARY) -> PackedStringArray:
	var focusable := get_focusable_windows(display)
	var results := PackedStringArray()
	for window_id in focusable:
		var name := get_window_name(window_id, display)
		results.append(name)
	return results


## Return the currently focused window id.
func get_focused_window(display: XWAYLAND = XWAYLAND.PRIMARY) -> int:
	var xwayland := _get_xwayland(display)
	if not xwayland:
		return -1
	var root_id := xwayland.get_root_window_id()
	var results := _get_xprop_array(xwayland, root_id, "GAMESCOPE_FOCUSED_WINDOW")
	if results.size() == 0:
		return 0
	return results[0]


## Sets the given window as the main launcher app.
## Gamescope is hard-coded to look for appId 769
func set_main_app(window_id: int, display: XWAYLAND = XWAYLAND.OGUI) -> int:
	var xwayland := _get_xwayland(display)
	if not xwayland:
		return -1
	return _set_xprop(xwayland, window_id, "STEAM_GAME", 769)


## Set the given window as the primary overlay input focus
func set_input_focus(window_id: int, value: int, display: XWAYLAND = XWAYLAND.OGUI) -> int:
	var xwayland := _get_xwayland(display)
	if not xwayland:
		return -1
	return _set_xprop(xwayland, window_id, "STEAM_INPUT_FOCUS", value)


## Set the given window as an overlay
func set_overlay(window_id: int, value: int, display: XWAYLAND = XWAYLAND.OGUI) -> int:
	var xwayland := _get_xwayland(display)
	if not xwayland:
		return -1
	return _set_xprop(xwayland, window_id, "STEAM_OVERLAY", value)


## Set the given window as an external overlay
func set_external_overlay(window_id: int, value: int, display: XWAYLAND = XWAYLAND.OGUI) -> int:
	var xwayland := _get_xwayland(display)
	if not xwayland:
		return -1
	return _set_xprop(xwayland, window_id, "GAMESCOPE_EXTERNAL_OVERLAY", value)


## Returns the currently set app ID on the given window
func get_app_id(window_id: int, display: XWAYLAND = XWAYLAND.GAME) -> int:
	var xwayland := _get_xwayland(display)
	if not xwayland:
		return -1
	return _get_xprop(xwayland, window_id, "STEAM_GAME")


## Sets the app ID on the given window
func set_app_id(window_id: int, app_id: int, display: XWAYLAND = XWAYLAND.GAME) -> int:
	var xwayland := _get_xwayland(display)
	if not xwayland:
		return -1
	return _set_xprop(xwayland, window_id, "STEAM_GAME", app_id)


## Sets the Gamescope FPS limit
func set_fps_limit(fps: int = 60, display: XWAYLAND = XWAYLAND.PRIMARY) -> int:
	logger.debug("Setting FPS to: {0}".format([fps]))
	var xwayland := _get_xwayland(display)
	if not xwayland:
		return -1
	var root_id := xwayland.get_root_window_id()
	return _set_xprop(xwayland, root_id, "GAMESCOPE_FPS_LIMIT", fps)


## Returns the Gamescope FPS limit
func get_fps_limit(display: XWAYLAND = XWAYLAND.PRIMARY) -> int:
	var xwayland := _get_xwayland(display)
	if not xwayland:
		return -1
	var root_id := xwayland.get_root_window_id()
	return _get_xprop(xwayland, root_id, "GAMESCOPE_FPS_LIMIT")


## Sets the Gamescope blur mode
func set_blur_mode(mode: BLUR_MODE = BLUR_MODE.OFF, display: XWAYLAND = XWAYLAND.PRIMARY) -> int:
	logger.debug("Setting blur mode to: {0}".format([mode]))
	var xwayland := _get_xwayland(display)
	if not xwayland:
		return -1
	var root_id := xwayland.get_root_window_id()
	return _set_xprop(xwayland, root_id, "GAMESCOPE_BLUR_MODE", mode)


## Sets the Gamescope blur radius when blur is active
func set_blur_radius(radius: int, display: XWAYLAND = XWAYLAND.PRIMARY) -> int:
	logger.debug("Setting blur radius to: {0}".format([radius]))
	var xwayland := _get_xwayland(display)
	if not xwayland:
		return -1
	var root_id := xwayland.get_root_window_id()
	return _set_xprop(xwayland, root_id, "GAMESCOPE_BLUR_RADIUS", radius)


## Configures Gamescope to allow tearing or not
func set_allow_tearing(allow: bool, display: XWAYLAND = XWAYLAND.PRIMARY) -> int:
	logger.debug("Setting tearing to: {0}".format([allow]))
	var xwayland := _get_xwayland(display)
	if not xwayland:
		return -1
	var value := 0
	if allow:
		value = 1
	var root_id := xwayland.get_root_window_id()
	return _set_xprop(xwayland, root_id, "GAMESCOPE_ALLOW_TEARING", value)


## Focuses the given window
func set_baselayer_window(window_id: int, display: XWAYLAND = XWAYLAND.PRIMARY) -> int:
	var xwayland := _get_xwayland(display)
	if not xwayland:
		return -1
	var root_id := xwayland.get_root_window_id()
	return _set_xprop(xwayland, root_id, "GAMESCOPECTRL_BASELAYER_WINDOW", window_id)


## Removes the baselayer property to un-focus windows
func remove_baselayer_window(display: XWAYLAND = XWAYLAND.PRIMARY) -> int:
	var xwayland := _get_xwayland(display)
	if not xwayland:
		return -1
	var root_id := xwayland.get_root_window_id()
	return _remove_xprop(xwayland, root_id, "GAMESCOPECTRL_BASELAYER_WINDOW")


# Returns the display type for the given display name
func get_display_type(name: String) -> XWAYLAND:
	if xwayland_primary.get_name() == name:
		return XWAYLAND.PRIMARY
	if xwayland_ogui.get_name() == name:
		return XWAYLAND.OGUI
	return XWAYLAND.GAME


# Returns the xwayland instance for the given display type
func _get_xwayland(display: XWAYLAND) -> Xlib:
	if xwaylands.size() == 0:
		return null
	if display == XWAYLAND.PRIMARY:
		return xwayland_primary
	if display == XWAYLAND.OGUI:
		return xwayland_ogui
	return xwayland_game


## Returns true if Gamescope is tracking the given display
func _has_xwayland(display: String) -> bool:
	for xwayland in xwaylands:
		if xwayland.get_name() == display:
			return true
	return false


## Returns true if the given xwayland instance is the primary gamescope instance
func _is_gamescope_xwayland_primary(xwayland: Xlib) -> bool:
	var root_id := xwayland.get_root_window_id()
	if xwayland.has_xprop(root_id, "GAMESCOPE_FOCUSED_WINDOW"):
		return true
	return false


## Returns true if the given xwayland instance is a gamescope instance
func _is_gamescope_xwayland(xwayland: Xlib) -> bool:
	var root_id := xwayland.get_root_window_id()
	if xwayland.has_xprop(root_id, "GAMESCOPE_CURSOR_VISIBLE_FEEDBACK"):
		return true
	return false


## Sets the given X property on the given window.
## Example:
##     [codeblock]
##     Gamescope._set_xprop(":0", 1234, "STEAM_INPUT", 1)
##     [/codeblock]
func _set_xprop(xwayland: Xlib, window_id: int, key: String, value: int) -> int:
	logger.debug("Setting window {0} key {1} to {2}".format([window_id, key, value]))
	return xwayland.set_xprop(window_id, key, value)


## Returns the value of the given X property for the given window. Returns
## [member Xlib.ERR_XPROP_NOT_FOUND] if property doesn't exist.
func _get_xprop(xwayland: Xlib, window_id: int, key: String) -> int:
	return xwayland.get_xprop(window_id, key)


## Removes the given X property for the given window.
func _remove_xprop(xwayland: Xlib, window_id: int, key: String) -> int:
	return xwayland.remove_xprop(window_id, key)


## Returns an array of values for the given X property for the given window.
## Returns an empty array if property was not found.
func _get_xprop_array(xwayland: Xlib, window_id: int, key: String) -> PackedInt32Array:
	return xwayland.get_xprop_array(window_id, key)
