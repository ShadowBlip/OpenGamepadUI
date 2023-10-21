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

signal blur_mode_updated(from: int, to: int)
signal display_is_external_updated(from: int, to: int)
signal focused_window_updated(from: int, to: int)
signal focusable_windows_updated(from: PackedInt32Array, to: PackedInt32Array)
signal focused_app_updated(from: int, to: int)
signal focused_app_gfx_updated(from: int, to: int)
signal focusable_apps_updated(from: PackedInt32Array, to: PackedInt32Array)

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

## Gamescope is hard-coded to look for STEAM_GAME=769 to determine if it is the
## overlay app.
const OVERLAY_GAME_ID := 769

@export var log_level := Log.LEVEL.INFO
## The primary xwayland is the primary Gamescope xwayland session that contains
## Gamescope properties on the root window.
var xwayland_primary: Xlib
## The OGUI xwayland is the xwayland instance that OGUI is running under.
var xwayland_ogui: Xlib
## The Game xwayland is the xwayland instance that games are launched under.
var xwayland_game: Xlib
## Array of all discovered xwayland instances
var xwaylands: Array[Xlib] = []
var logger := Log.get_logger("Gamescope", log_level)

# Gamescope properties
## Blur mode (read-only)
var blur_mode: int:
	set(v):
		var prev_value := blur_mode
		blur_mode = v
		if prev_value != v:
			blur_mode_updated.emit(prev_value, v)
var baselayer_window: int
var input_counter: int
var display_is_external: int
var vrr_enabled: int
var vrr_feedback: int
var vrr_capable: int
var keyboard_focus_display: PackedInt32Array
var mouse_focus_display: PackedInt32Array
var focus_display: PackedInt32Array
var focused_window: int:
	set(v):
		var prev_value := focused_window
		focused_window = v
		if prev_value != v:
			focused_window_updated.emit(prev_value, v)
var focused_app_gfx: int:
	set(v):
		var prev_value := focused_app_gfx
		focused_app_gfx = v
		if prev_value != v:
			focused_app_gfx_updated.emit(prev_value, v)
var focused_app: int:
	set(v):
		var prev_value := focused_app
		focused_app = v
		if prev_value != v:
			focused_app_updated.emit(prev_value, v)
var focusable_windows: PackedInt32Array:
	set(v):
		var prev_value := focusable_windows
		focusable_windows = v
		if prev_value != v:
			focusable_windows_updated.emit(prev_value, v)
var focusable_apps: PackedInt32Array:
	set(v):
		var prev_value := focusable_apps
		focusable_apps = v
		if prev_value != v:
			focusable_apps_updated.emit(prev_value, v)
var cursor_visible_feedback: int


# Connects to all gamescope xwayland instances
func _init() -> void:
	# Don't initialize if run from the editor (during doc generation)
	if Engine.is_editor_hint():
		logger.info("Not initializing. Ran from editor.")
		return
	
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
		if xwayland_primary != xwayland:
			xwayland_game = xwayland
		xwaylands.append(xwayland)

	# If we haven't discovered any gamescope displays, set everything to use
	# the OGUI xwayland instance
	if not xwayland_primary:
		logger.warn("OpenGamepadUI is not running in Gamescope. Unexpected behavior expected.")
		xwayland_primary = xwayland_ogui
	if not xwayland_game:
		xwayland_game = xwayland_ogui

	logger.debug("Primary xwayland is " + xwayland_primary.get_name())
	logger.debug("OGUI xwayland is " + xwayland_ogui.get_name())
	logger.debug("Game xwayland is " + xwayland_game.get_name())


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
			logger.debug("Discovered X server display: " + display)
		xwayland.close()
	return gamescope_displays


## Updates the Gamescope state. Should be called in a loop to keep the Gamescope
## state up-to-date.
func update() -> void:
	blur_mode = get_blur_mode()
	focused_window = get_focused_window()
	focused_app = get_focused_app()
	focused_app_gfx = get_focused_app_gfx()
	focusable_windows = get_focusable_windows()
	focusable_apps = get_focusable_apps()
	baselayer_window = get_baselayer_window()
	if not baselayer_window in get_focusable_windows():
		baselayer_window = -1
		remove_baselayer_window()


## Returns the name of the given xwayland display (e.g. ":1")
func get_display_name(display: XWAYLAND) -> String:
	var xwayland := get_xwayland(display)
	if not xwayland:
		return ""
	return xwayland.get_name()


## Returns true if the given X property exists on the given window.
func has_xprop(window_id: int, key: String, display: XWAYLAND) -> bool:
	var xwayland := get_xwayland(display)
	if not xwayland:
		return false
	return xwayland.has_xprop(window_id, key)


## Returns a list of X properties on the given window
func list_xprops(window_id: int, display: XWAYLAND) -> PackedStringArray:
	var xwayland := get_xwayland(display)
	if not xwayland:
		return []
	return xwayland.list_xprops(window_id)


## Returns the name of the given window.
func get_window_name(window_id: int, display: XWAYLAND = XWAYLAND.GAME) -> String:
	var xwayland := get_xwayland(display)
	if not xwayland:
		return ""
	return xwayland.get_window_name(window_id)


## Returns the PID of the given window. Returns -1 if no PID was found.
func get_window_pid(window_id: int, display: XWAYLAND) -> int:
	var xwayland := get_xwayland(display)
	if not xwayland:
		return -1
	return xwayland.get_window_pid(window_id)


## Returns the xwayland window ID for the given process. Returns -1 if no
## window was found.
func get_window_id(pid: int, display: XWAYLAND) -> int:
	var display_name := get_display_name(display)
	logger.debug("Getting Window ID for {0} on display {1}".format([pid, display_name]))
	var xwayland := get_xwayland(display)
	if not xwayland:
		return -1
	var root_id := xwayland.get_root_window_id()
	var all_windows := get_all_windows(root_id, display)
	for window_id in all_windows:
		var window_pid := xwayland.get_window_pid(window_id)
		if pid == window_pid:
			return window_id
		window_pid = xwayland.get_xprop(window_id, "_NET_WM_PID")
		if pid == window_pid:
			return window_id

	return -1


## Returns the xwayland window ID(s) for the given process using multiple methods
## to try and discover.
func get_window_ids(pid: int, display: XWAYLAND) -> PackedInt32Array:
	var window_ids := PackedInt32Array()
	var display_name := get_display_name(display)
	logger.debug("Getting Window ID for {0} on display {1}".format([pid, display_name]))
	var xwayland := get_xwayland(display)
	if not xwayland:
		return window_ids
	var root_id := xwayland.get_root_window_id()
	var all_windows := get_all_windows(root_id, display)
	for window_id in all_windows:
		var window_pid := xwayland.get_window_pid(window_id)
		if pid == window_pid and not window_id in window_ids:
			window_ids.append(window_id)
		var net_window_pid := xwayland.get_xprop(window_id, "_NET_WM_PID")
		if pid == net_window_pid and not net_window_pid in window_ids:
			window_ids.append(net_window_pid)

	return window_ids


## Returns the child window ids of the given window
func get_window_children(window_id: int, display: XWAYLAND) -> PackedInt32Array:
	var xwayland := get_xwayland(display)
	if not xwayland:
		return PackedInt32Array()
	var children := xwayland.get_window_children(window_id)
	if len(children) == 0:
		return PackedInt32Array()
	return children


## Recursively returns all child windows of the given window id
func get_all_windows(window_id: int, display: XWAYLAND) -> PackedInt32Array:
	var xwayland := get_xwayland(display)
	if not xwayland:
		return PackedInt32Array()
	var children := xwayland.get_window_children(window_id)
	if len(children) == 0:
		return PackedInt32Array([])

	var leaves := PackedInt32Array()
	for child in children:
		leaves.append(child)
		leaves.append_array(get_all_windows(child, display))

	return leaves


## Returns true if the window with the given window ID exists
func is_focusable_app(window_id: int, display: XWAYLAND = XWAYLAND.PRIMARY) -> bool:
	var focusable := get_focusable_apps(display)
	if window_id in focusable:
		return true
	return false


## Returns the root window ID of the given display
func get_root_window_id(display: XWAYLAND) -> int:
	var xwayland := get_xwayland(display)
	if not xwayland:
		return -1
	return xwayland.get_root_window_id()


## Returns a list of focusable app window ids
func get_focusable_apps(display: XWAYLAND = XWAYLAND.PRIMARY) -> PackedInt32Array:
	var xwayland := get_xwayland(display)
	if not xwayland:
		return PackedInt32Array()
	var root_id := xwayland.get_root_window_id()
	return _get_xprop_array(xwayland, root_id, "GAMESCOPE_FOCUSABLE_APPS")


## Returns a list of focusable window ids
func get_focusable_windows(display: XWAYLAND = XWAYLAND.PRIMARY) -> PackedInt32Array:
	var xwayland := get_xwayland(display)
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
	var xwayland := get_xwayland(display)
	if not xwayland:
		return -1
	var root_id := xwayland.get_root_window_id()
	var results := _get_xprop_array(xwayland, root_id, "GAMESCOPE_FOCUSED_WINDOW")
	if results.size() == 0:
		return 0
	return results[0]


## Return the currently focused app id.
func get_focused_app(display: XWAYLAND = XWAYLAND.PRIMARY) -> int:
	var xwayland := get_xwayland(display)
	if not xwayland:
		return -1
	var root_id := xwayland.get_root_window_id()
	var results := _get_xprop_array(xwayland, root_id, "GAMESCOPE_FOCUSED_APP")
	if results.size() == 0:
		return 0
	return results[0]


## Return the currently focused gfx app id.
func get_focused_app_gfx(display: XWAYLAND = XWAYLAND.PRIMARY) -> int:
	var xwayland := get_xwayland(display)
	if not xwayland:
		return -1
	var root_id := xwayland.get_root_window_id()
	var results := _get_xprop_array(xwayland, root_id, "GAMESCOPE_FOCUSED_APP_GFX")
	if results.size() == 0:
		return 0
	return results[0]


## Sets the given window as the main launcher app.
## Gamescope is hard-coded to look for appId 769
func set_main_app(window_id: int, display: XWAYLAND = XWAYLAND.OGUI) -> int:
	var xwayland := get_xwayland(display)
	if not xwayland:
		return -1
	return _set_xprop(xwayland, window_id, "STEAM_GAME", OVERLAY_GAME_ID)


## Set the given window as the primary overlay input focus. This should be set to
## "1" whenever the overlay wants to intercept input from a game.
func set_input_focus(window_id: int, value: int, display: XWAYLAND = XWAYLAND.OGUI) -> int:
	var xwayland := get_xwayland(display)
	if not xwayland:
		return -1
	return _set_xprop(xwayland, window_id, "STEAM_INPUT_FOCUS", value)


## Returns whether or not the overlay window is currently focused
func is_overlay_focused(display: XWAYLAND = XWAYLAND.OGUI) -> bool:
	return get_focused_app(display) == OVERLAY_GAME_ID


## Get the overlay status for the given window
func get_overlay(window_id: int, display: XWAYLAND = XWAYLAND.OGUI) -> int:
	var xwayland := get_xwayland(display)
	if not xwayland:
		return -1
	return _get_xprop(xwayland, window_id, "STEAM_OVERLAY")


## Set the given window as an overlay
func set_overlay(window_id: int, value: int, display: XWAYLAND = XWAYLAND.OGUI) -> int:
	var xwayland := get_xwayland(display)
	if not xwayland:
		return -1
	return _set_xprop(xwayland, window_id, "STEAM_OVERLAY", value)


## Set the given window as a notification. This should be set to "1" when some
## UI wants to be shown but not intercept input.
func set_notification(window_id: int, value: int, display: XWAYLAND = XWAYLAND.OGUI) -> int:
	var xwayland := get_xwayland(display)
	if not xwayland:
		return -1
	return _set_xprop(xwayland, window_id, "STEAM_NOTIFICATION", value)


## Set the given window as an external overlay
func set_external_overlay(window_id: int, value: int, display: XWAYLAND = XWAYLAND.OGUI) -> int:
	var xwayland := get_xwayland(display)
	if not xwayland:
		return -1
	return _set_xprop(xwayland, window_id, "GAMESCOPE_EXTERNAL_OVERLAY", value)


## Returns the currently set app ID on the given window
func get_app_id(window_id: int, display: XWAYLAND = XWAYLAND.GAME) -> int:
	var xwayland := get_xwayland(display)
	if not xwayland:
		return -1
	return _get_xprop(xwayland, window_id, "STEAM_GAME")


## Sets the app ID on the given window
func set_app_id(window_id: int, app_id: int, display: XWAYLAND = XWAYLAND.GAME) -> int:
	var xwayland := get_xwayland(display)
	if not xwayland:
		return -1
	return _set_xprop(xwayland, window_id, "STEAM_GAME", app_id)


## Returns whether or not the given window has an app ID set
func has_app_id(window_id: int, display: XWAYLAND = XWAYLAND.GAME) -> bool:
	return has_xprop(window_id, "STEAM_GAME", display)


## Sets the Gamescope FPS limit
func set_fps_limit(fps: int = 60, display: XWAYLAND = XWAYLAND.PRIMARY) -> int:
	logger.debug("Setting FPS to: {0}".format([fps]))
	var xwayland := get_xwayland(display)
	if not xwayland:
		return -1
	var root_id := xwayland.get_root_window_id()
	return _set_xprop(xwayland, root_id, "GAMESCOPE_FPS_LIMIT", fps)


## Returns the Gamescope FPS limit
func get_fps_limit(display: XWAYLAND = XWAYLAND.PRIMARY) -> int:
	var xwayland := get_xwayland(display)
	if not xwayland:
		return -1
	var root_id := xwayland.get_root_window_id()
	return _get_xprop(xwayland, root_id, "GAMESCOPE_FPS_LIMIT")


## Returns the current Gamescope blur mode
func get_blur_mode(display: XWAYLAND = XWAYLAND.PRIMARY) -> int:
	var xwayland := get_xwayland(display)
	if not xwayland:
		return -1
	var root_id := xwayland.get_root_window_id()
	return _get_xprop(xwayland, root_id, "GAMESCOPE_BLUR_MODE")


## Sets the Gamescope blur mode
func set_blur_mode(mode: BLUR_MODE = BLUR_MODE.OFF, display: XWAYLAND = XWAYLAND.PRIMARY) -> int:
	logger.debug("Setting blur mode to: {0}".format([mode]))
	var xwayland := get_xwayland(display)
	if not xwayland:
		return -1
	var root_id := xwayland.get_root_window_id()
	var err := _set_xprop(xwayland, root_id, "GAMESCOPE_BLUR_MODE", mode)
	blur_mode = mode
	return err


## Sets the Gamescope blur radius when blur is active
func set_blur_radius(radius: int, display: XWAYLAND = XWAYLAND.PRIMARY) -> int:
	logger.debug("Setting blur radius to: {0}".format([radius]))
	var xwayland := get_xwayland(display)
	if not xwayland:
		return -1
	var root_id := xwayland.get_root_window_id()
	return _set_xprop(xwayland, root_id, "GAMESCOPE_BLUR_RADIUS", radius)


## Configures Gamescope to allow tearing or not
func set_allow_tearing(allow: bool, display: XWAYLAND = XWAYLAND.PRIMARY) -> int:
	logger.debug("Setting tearing to: {0}".format([allow]))
	var xwayland := get_xwayland(display)
	if not xwayland:
		return -1
	var value := 1 if allow else 0
	var root_id := xwayland.get_root_window_id()
	return _set_xprop(xwayland, root_id, "GAMESCOPE_ALLOW_TEARING", value)


## Returns the currently set manual focus
func get_baselayer_window(display: XWAYLAND = XWAYLAND.PRIMARY) -> int:
	var xwayland := get_xwayland(display)
	if not xwayland:
		return -1
	var root_id := xwayland.get_root_window_id()
	return _get_xprop(xwayland, root_id, "GAMESCOPECTRL_BASELAYER_WINDOW")


## Focuses the given window
func set_baselayer_window(window_id: int, display: XWAYLAND = XWAYLAND.PRIMARY) -> int:
	var xwayland := get_xwayland(display)
	if not xwayland:
		return -1
	var root_id := xwayland.get_root_window_id()
	return _set_xprop(xwayland, root_id, "GAMESCOPECTRL_BASELAYER_WINDOW", window_id)


## Removes the baselayer property to un-focus windows
func remove_baselayer_window(display: XWAYLAND = XWAYLAND.PRIMARY) -> int:
	var xwayland := get_xwayland(display)
	if not xwayland:
		return -1
	var root_id := xwayland.get_root_window_id()
	return _remove_xprop(xwayland, root_id, "GAMESCOPECTRL_BASELAYER_WINDOW")


## Request a screenshot from gamescope
func request_screenshot(display: XWAYLAND = XWAYLAND.PRIMARY) -> int:
	var xwayland := get_xwayland(display)
	if not xwayland:
		return -1
	var root_id := xwayland.get_root_window_id()
	return _set_xprop(xwayland, root_id, "GAMESCOPECTRL_REQUEST_SCREENSHOT", 1)


## Sets the xwayland mode resolution on the given xwayland display 
## number (default: XWAYLAND.GAME).
func set_resolution(resolution: Vector2i, allow_super: bool = false, display: XWAYLAND = XWAYLAND.GAME) -> int:
	var xwayland := get_xwayland(XWAYLAND.PRIMARY)
	if not xwayland:
		return -1
	
	var target_display := get_display_number(display)
	var root_id := xwayland.get_root_window_id()
	var allow_super_value := 1 if allow_super else 0
	var args := PackedInt32Array([target_display, resolution.x, resolution.y, allow_super_value])
	return _set_xprop_array(xwayland, root_id, "GAMESCOPE_XWAYLAND_MODE_CONTROL", args)


func set_rotation(rotation_index: int, display: XWAYLAND = XWAYLAND.PRIMARY) -> int:
	var xwayland := get_xwayland(XWAYLAND.PRIMARY)
	if not xwayland:
		return -1
	
	var target_display := get_display_number(display)
	var root_id := xwayland.get_root_window_id()
	var args := PackedInt32Array([rotation_index])
	return _set_xprop_array(xwayland, root_id, "GAMESCOPE_ROTATE_CONTROL", args)


func set_connector(connector_id: int, display: XWAYLAND = XWAYLAND.PRIMARY) -> int:
	var xwayland := get_xwayland(XWAYLAND.PRIMARY)
	if not xwayland:
		return -1
	
	var target_display := get_display_number(display)
	var root_id := xwayland.get_root_window_id()
	var args := PackedInt32Array([connector_id])
	print(args)
	return _set_xprop_array(xwayland, root_id, "GAMESCOPE_CONNECTOR_CONTROL", args)


## Returns the currently set gamescope saturation
# Based on vibrantDeck by Scrumplex
func get_saturation(display: XWAYLAND = XWAYLAND.PRIMARY) -> float:
	var xwayland := get_xwayland(display)
	if not xwayland:
		return -1
	var root_id := xwayland.get_root_window_id()
	
	var matrix := _get_xprop_array(xwayland, root_id, "GAMESCOPE_COLOR_MATRIX")
	if matrix.size() < 2:
		return -1
	
	# [1065353216, 0, 0, 0, 1065353216, 0, 0, 0, 1065353216]
	var matrix_arr: Array[int] = Array(matrix)
	# Convert the array of longs to floats
	# [1.0, 0, 0, 0, 1.0, 0, 0, 0, 1.0]
	var coeffs := matrix_arr.map(_long_to_float)
	var saturation := snappedf(coeffs[0] - coeffs[1], 0.01)
	
	return saturation


## Set the gamescope saturation
# Based on vibrantDeck by Scrumplex
func set_saturation(saturation: float, display: XWAYLAND = XWAYLAND.PRIMARY) -> int:
	saturation = maxf(saturation, 0.0)
	saturation = minf(saturation, 4.0)
	logger.debug("Setting saturation to: " + str(saturation))

	# Generate color transformation matrix
	var coeffs := _saturation_to_coeffs(saturation)
	
	# Represent floats as integars (long)
	var long_coeffs := coeffs.map(_float_to_long)
	
	# Get the xwayland to set the property on
	var xwayland := get_xwayland(display)
	if not xwayland:
		return -1
	var root_id := xwayland.get_root_window_id()
	
	logger.debug("Setting color matrix coeffs: " + str(long_coeffs))
	return _set_xprop_array(xwayland, root_id, "GAMESCOPE_COLOR_MATRIX", long_coeffs)


func _saturation_to_coeffs(saturation: float) -> Array[float]:
	var coeff := (1.0 - saturation) / 3.0
	
	var coeffs: Array[float] = []
	coeffs.resize(9)
	coeffs.fill(coeff)
	coeffs[0] += saturation
	coeffs[4] += saturation
	coeffs[8] += saturation
	
	return coeffs


func _float_to_long(x: float) -> int:
	var bytes := PackedByteArray()
	bytes.resize(4)
	bytes.encode_float(0, x)
	return bytes.decode_u32(0)


func _long_to_float(x: int) -> float:
	var bytes := PackedByteArray()
	bytes.resize(4)
	bytes.encode_u32(0, x)
	return bytes.decode_float(0)


## Returns the display type for the given display name
func get_display_type(name: String) -> XWAYLAND:
	if xwayland_primary.get_name() == name:
		return XWAYLAND.PRIMARY
	if xwayland_ogui.get_name() == name:
		return XWAYLAND.OGUI
	return XWAYLAND.GAME


## Returns the name of the given xwayland display
func get_display_number(display: XWAYLAND) -> int:
	var name := get_display_name(display)
	var clean_name := name.replace(":", "")
	if clean_name.is_valid_int():
		return clean_name.to_int()
	logger.error("Unable to determine display number from name: " + name)
	return 0


## Returns the xwayland instance for the given display type
func get_xwayland(display: XWAYLAND) -> Xlib:
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
	var msg_args := [window_id, key, value, xwayland.get_name()]
	logger.debug("Setting window {0} key {1} to {2} on display {3}".format(msg_args))
	return xwayland.set_xprop(window_id, key, value)


## Sets the given X property with the given array of values
func _set_xprop_array(xwayland: Xlib, window_id: int, key: String, values: PackedInt32Array) -> int:
	var msg_args := [window_id, key, str(values), xwayland.get_name()]
	logger.debug("Setting window {0} key {1} to {2} on display {3}".format(msg_args))
	# TODO: Fix set_xprop_array and use that instead of xprop
	var values_str_arr := []
	for value in values:
		values_str_arr.append(str(value))
	var values_str := ",".join(values_str_arr)
	var cmd := "env"
	var args := ["DISPLAY="+xwayland.get_name(), "xprop", "-id", str(window_id), "-f", key, "32c", "-set", key, values_str]
	return OS.execute(cmd, args)


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
