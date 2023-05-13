@icon("res://assets/icons/navigation.svg")
extends Resource
class_name InputManager

## Manages global input and virtual controllers
##
## The InputManager class is responsible for handling global input that should
## happen everywhere in the application. The input manager discovers gamepads
## and interepts their input so OpenGamepadUI can control what inputs should get
## passed on to the game and what only OpenGamepadUI should process. This works
## by grabbing exclusive access to the physical gamepads and creating a virtual
## gamepad that games can see.[br][br]
##
## This class should be loaded and managed by a single node in the scene tree.
## It requires to be initialized and passed input events:
##     [codeblock]
##     const InputManager := preload("res://core/global/input_manager.tres")
##
##     func _ready() -> void:
##         InputManager.init()
##
##     func _input(event: InputEvent) -> void:
##     	   if not InputManager.input(event):
##     	       return
##     	   get_viewport().set_input_as_handled()
##
##     func _exit_tree() -> void:
##     	   InputManager.exit()
##     [/codeblock]

const Gamescope := preload("res://core/global/gamescope.tres")
const osk := preload("res://core/global/keyboard_instance.tres")
const Platform := preload("res://core/global/platform.tres")
const input_thread := preload("res://core/systems/threading/input_thread.tres")
const input_default_path := "/dev/input"
const input_hidden_path := "/dev/input/.hidden"

var state_machine := (
	preload("res://assets/state/state_machines/global_state_machine.tres") as StateMachine
)
var in_game_menu_state := preload("res://assets/state/states/in_game_menu.tres") as State
var in_game_state := preload("res://assets/state/states/in_game.tres") as State
var main_menu_state := preload("res://assets/state/states/main_menu.tres") as State
var qam_state := preload("res://assets/state/states/quick_access_menu.tres") as State
var osk_state := preload("res://assets/state/states/osk.tres") as State
var PID: int = OS.get_process_id()
var overlay_window_id = Gamescope.get_window_id(PID, Gamescope.XWAYLAND.OGUI)
var logger := Log.get_logger("InputManager", Log.LEVEL.INFO)
var guide_action := false

var handheld_gamepad: HandheldGamepad
var managed_gamepads := {}  # {"/dev/input/event1": <ManagedGamepad>}
var orphaned_gamepads := {} # {"event1" : <ManagedGamepad>}
var virtual_gamepads := []  # ["/dev/input/event2"]
var gamepad_mutex := Mutex.new()


## Initializes the input manager and starts the gamepad interecpt thread. A
## node should initialize the InputManager resource and call [method input]
## in their _input() method to process input events.
func init() -> void:
	in_game_state.state_entered.connect(_on_game_state_entered)
	in_game_state.state_exited.connect(_on_game_state_exited)
	in_game_state.state_removed.connect(_on_game_state_removed)

	# If we crashed, unhide any device events taht were orphaned
	_restore_all_hidden()

	# If running on a platform with a built-in gamepad, get the device
	# to process input on it.
	handheld_gamepad = Platform.get_handheld_gamepad()

	# Discover any gamepads and grab exclusive access to them. Create a
	# duplicate virtual gamepad for each physical one.
	_on_gamepad_change(0, false)

	# Create a thread to process gamepad inputs separately
	logger.debug("Starting gamepad input thread")
	input_thread.add_process(_process_input)
	input_thread.start()
	Input.joy_connection_changed.connect(_on_gamepad_change)


## Returns a list of gamepad devices that are being exclusively managed.
func get_managed_gamepads() -> Array:
	return managed_gamepads.keys()


## Sets the given gamepad profile on the given managed gamepad.
func set_gamepad_profile(device: String, profile: GamepadProfile) -> void:
	gamepad_mutex.lock()
	if not device in managed_gamepads:
		logger.warn("Unable to set profile on non-managed device: " + device)
		gamepad_mutex.unlock()
		return
	var gamepad := managed_gamepads[device] as ManagedGamepad
	gamepad.set_profile(profile)
	gamepad_mutex.unlock()


## Sets the gamepad intercept mode
func _set_intercept(mode: ManagedGamepad.INTERCEPT_MODE) -> void:
	logger.debug("Setting gamepad intercept mode: " + str(mode))
	gamepad_mutex.lock()
	for gamepad in managed_gamepads.values():
		gamepad.mode = mode
	gamepad_mutex.unlock()


## Runs evdev input processing in its own thread. We use mutexes to safely
## access variables from the main thread
func _process_input(_delta: float) -> void:
	# If there is a handheld gamepad, process its inputs
	if handheld_gamepad:
		handheld_gamepad.process_input()

	# Process the input for all currently managed gamepads
	gamepad_mutex.lock()
	var gamepads := managed_gamepads.values()
	gamepad_mutex.unlock()
	for gamepad in gamepads:
		gamepad.process_input()


## Triggers whenever we detect any gamepad connect/disconnect events
func _on_gamepad_change(device: int, connected: bool) -> void:
	logger.info("Gamepad was changed: " + Input.get_joy_name(device) + " connected: " + str(connected))
	
	logger.debug("START Managed gamepads: " + str(managed_gamepads))
	logger.debug("START Orphan gamepads: " + str(orphaned_gamepads))
	
	# Discover any new gamepads
	var discovered_paths := discover_gamepads()

	# Remove all gamepads that no longer exist
	var hidden_devices := PackedStringArray()
	if DirAccess.dir_exists_absolute(input_hidden_path):
		hidden_devices = DirAccess.get_files_at(input_hidden_path)
	for gamepad in managed_gamepads.values():
		if _get_event_from_phys(gamepad.phys_path) in hidden_devices:
			continue
		if gamepad.phys_path in discovered_paths:
			continue

		logger.debug("Gamepad disconnected: " + gamepad.phys_path)
		# Lock the gamepad mappings so we can alter them.
		var event_name := _get_event_from_phys(gamepad.phys_path)
		orphaned_gamepads[event_name] = gamepad
		gamepad_mutex.lock()
		managed_gamepads.erase(gamepad.phys_path)
		gamepad_mutex.unlock()
		restore_event_device(gamepad.phys_path)
		return

	# Add any newly found gamepads
	for path in discovered_paths:
		logger.debug("Considering gamepad: " + path)
		# Reject managed and virtual devices
		if path in virtual_gamepads:
			logger.debug("Virtual gamepad is already being managed: " + path)
			continue
		if path in managed_gamepads:
			logger.debug("Gamepad is already being managed: " + path)
			continue
		
		# Reconfigure disconnected gamepads
		var event_name := _get_event_from_phys(path)
		if orphaned_gamepads.has(event_name):
			var gamepad: ManagedGamepad = orphaned_gamepads[event_name]
			
			# Hide the device from other processes
			var hidden_path := hide_event_device(path)
			if hidden_path == "":
				logger.warn("Unable to hide gamepad: " + path)
				logger.warn("Opening the raw gamepad instead")
				# Try to open the non-hidden device instead
				hidden_path = path
			
			# Reopen the physical gamepad
			if gamepad.reopen(hidden_path) != OK:
				logger.error("Unable to reopen managed gamepad for: " + hidden_path)
				continue
			gamepad_mutex.lock()
			managed_gamepads[hidden_path] = gamepad
			gamepad_mutex.unlock()
			orphaned_gamepads.erase(event_name)
			logger.debug("Reconnected gamepad at: " + gamepad.phys_path)
			continue

		# Open the device from its new path to check if it is a gamepad
		# that we need to manage or if it's one of our own virtual devices.
		var input_device := InputDevice.new()
		if input_device.open(path) != OK:
			logger.error("Unable to create managed gamepad for: " + path)
			continue
		
		# See if we've identified the gamepad defined by the device platform.
		# Specifically, OpenSD creates a virtual device that we DO want to manage
		var is_handheld_gamepad := false
		if handheld_gamepad:
			is_handheld_gamepad = handheld_gamepad.is_found_gamepad(input_device)
		if input_device.get_phys() == "" and not is_handheld_gamepad:
			logger.debug("Device appears to be virtual, skipping " + path)
			continue
			
		# Hide the device from other processes
		var hidden_path := hide_event_device(path)
		if hidden_path == "":
			logger.warn("Unable to hide gamepad: " + path)
			logger.warn("Opening the raw gamepad instead")
			# Try to open the non-hidden device instead
			hidden_path = path

		# Create a new managed gamepad with physical/virtual gamepad pair
		var gamepad := ManagedGamepad.new()
		if gamepad.open(hidden_path) != OK:
			logger.error("Unable to create managed gamepad for: " + hidden_path)
			restore_event_device(hidden_path)
			continue
		
		# Give the gamepad xwayland access and add it to our mapping of managed
		# gamepads
		gamepad.xwayland = Gamescope.get_xwayland(Gamescope.XWAYLAND.GAME)
		gamepad_mutex.lock()
		virtual_gamepads.append(gamepad.virt_path)
		managed_gamepads[hidden_path] = gamepad
		gamepad_mutex.unlock()
		logger.debug("Discovered gamepad at: " + gamepad.phys_path)
		logger.debug("Created virtual gamepad at: " + gamepad.virt_path)

		# Check if we're using a known handheld and link this device to the
		# handheld gamepad so we can send events to the correct virtual controller.
		if is_handheld_gamepad:
			logger.debug("Assigning managed gamepad to handheld gamepad")
			handheld_gamepad.set_gamepad_device(gamepad)

	# If we're using a handheld, open the device.
	if handheld_gamepad and not handheld_gamepad.is_open():
		if handheld_gamepad.open() != OK:
			logger.error("Unable to open handheld keyboard device.")
		hide_event_device(handheld_gamepad.kb_event_path)
	logger.debug("Finished configuring detected controllers")
	gamepad_mutex.lock()
	logger.debug("Managed gamepads: " + str(managed_gamepads))
	logger.debug("Orphan gamepads: " + str(orphaned_gamepads))
	gamepad_mutex.unlock()


func _on_game_state_entered(_from: State) -> void:
	set_focus(false)
	logger.debug("Ungrabbing gamepad interception")
	_set_intercept(ManagedGamepad.INTERCEPT_MODE.PASS)


func _on_game_state_exited(_to: State) -> void:
	_on_game_state_removed()


func _on_game_state_removed() -> void:
	set_focus(true)
	_set_intercept(ManagedGamepad.INTERCEPT_MODE.ALL)

	# If no game is running now, don't mess with gamepad profiles
	if state_machine.has_state(in_game_state):
		return

	# Clear any gamepad profiles when no games are running
	logger.debug("Resetting gamepad profiles")
	for gamepad in get_managed_gamepads():
		set_gamepad_profile(gamepad, null)


## Set focus will use Gamescope to focus OpenGamepadUI
func set_focus(focused: bool) -> void:
	# Sets ourselves to the input focus
	var window_id = overlay_window_id
	if focused:
		logger.debug("Focusing overlay")
		Gamescope.set_input_focus(window_id, 1)
		return
	logger.debug("Un-focusing overlay")
	Gamescope.set_input_focus(window_id, 0)


## Returns an array of device paths
func discover_gamepads() -> PackedStringArray:
	var input_path := "/dev/input"
	var paths := PackedStringArray()
	
	if handheld_gamepad:
		logger.info("Handheld gamepad was defined by platform provider")
	
	var files := DirAccess.get_files_at(input_path)
	for file in files:
		if not file.begins_with("event"):
			continue
		var path := "/".join([input_path, file])
		var dev := InputDevice.new()
		if dev.open(path) != OK:
			logger.debug("Unable to open event device: " + path)
			continue
		if dev.has_event_code(InputDeviceEvent.EV_KEY, InputDeviceEvent.BTN_MODE):
			paths.append(path)
			continue
		if not handheld_gamepad:
			continue

		if handheld_gamepad.is_found_kb(dev):
			logger.info("Discovered handheld gamepad keyboard device: " + path)
			handheld_gamepad.set_kb_event_path(path)

	return paths


## Returns whether or not get_viewport().set_input_as_handled() should be called
## https://docs.godotengine.org/en/latest/tutorials/inputs/inputevent.html#how-does-it-work
func input(event: InputEvent) -> bool:
	# Handle guide button inputs
	if event.is_action("ogui_guide"):
		_guide_input(event)
		return true

	# QAM Events
	if event.is_action("ogui_qam"):
		_qam_input(event)
		return true

	# OSK Events
	if event.is_action("ogui_osk"):
		_osk_input(event)
		return true

	# Main menu events
	if event.is_action("ogui_menu"):
		_main_menu_input(event)
		return true

	# Handle guide action release events
	if event.is_action_released("ogui_guide_action"):
		if event.is_action_released("ogui_north"):
			_action_release("ogui_osk")
			return true
		if event.is_action_released("ogui_south"):
			_action_release("ogui_qam")
			return true

	# Handle inputs when the guide button is being held
	if Input.is_action_pressed("ogui_guide"):
		# OSK
		if event.is_action_pressed("ogui_north"):
			_action_press("ogui_osk")
			_action_press("ogui_guide_action")
		# QAM
		if event.is_action_pressed("ogui_south"):
			_action_press("ogui_qam")
			_action_press("ogui_guide_action")

		# Prevent ALL input from propagating if guide is held!
		return true

	return false


func _guide_input(event: InputEvent) -> void:
	# Only act on release events
	if event.is_pressed():
		return

	# If a guide action combo was pressed and we released the guide button,
	# end the guide action and do nothing else.
	if Input.is_action_pressed("ogui_guide_action"):
		_action_release("ogui_guide_action")
		return

	# Emit the main menu action if this was not a guide action
	_action_press("ogui_menu")
	_action_release("ogui_menu")


func _main_menu_input(event: InputEvent) -> void:
	# Only act on release events
	if event.is_pressed():
		return

	# Open the main menu
	var state := state_machine.current_state()
	var menu_state := main_menu_state

	# Handle cases where a game is running
	if state_machine.has_state(in_game_state):
		menu_state = in_game_menu_state

	if state == menu_state:
		state_machine.pop_state()
	elif state in [qam_state, osk_state]:
		state_machine.replace_state(menu_state)
	else:
		state_machine.push_state(menu_state)


func _qam_input(event: InputEvent) -> void:
	# Only act on press events
	if not event.is_pressed():
		return

	var state := state_machine.current_state()
	if state == qam_state:
		state_machine.pop_state()
	elif state in [main_menu_state, in_game_menu_state, osk_state]:
		state_machine.replace_state(qam_state)
	else:
		state_machine.push_state(qam_state)


func _osk_input(event: InputEvent) -> void:
	# Only act on press events
	if not event.is_pressed():
		return

	var context := KeyboardContext.new()
	context.type = KeyboardContext.TYPE.X11
	osk.open(context)

	var state := state_machine.current_state()
	if state == osk_state:
		state_machine.pop_state()
	elif state in [main_menu_state, in_game_menu_state, qam_state]:
		state_machine.replace_state(osk_state)
	else:
		state_machine.push_state(osk_state)


func _action_release(action: String, strength: float = 1.0) -> void:
	_send_input(action, false, strength)


func _action_press(action: String, strength: float = 1.0) -> void:
	_send_input(action, true, strength)


## Sends an input action to the event queue
func _send_input(action: String, pressed: bool, strength: float = 1.0) -> void:
	var input_action := InputEventAction.new()
	input_action.action = action
	input_action.pressed = pressed
	input_action.strength = strength
	Input.parse_input_event(input_action)


## Sends joy motion input to the event queue
func _send_joy_input(axis: int, value: float) -> void:
	var joy_action := InputEventJoypadMotion.new()
	joy_action.axis = axis
	joy_action.axis_value = value
	Input.parse_input_event(joy_action)


func exit() -> void:
	input_thread.stop()
	Input.joy_connection_changed.disconnect(_on_gamepad_change)
	for gamepad in managed_gamepads.values():
		logger.debug("Cleaning up gamepad: " + gamepad.phys_path)
		gamepad.phys_device.grab(false)
		gamepad.virt_device.close()
		gamepad.phys_device.close()
		restore_event_device(gamepad.phys_path)
	if handheld_gamepad and handheld_gamepad.is_open():
		handheld_gamepad.kb_device.grab(false)
		handheld_gamepad.kb_device.close()
		restore_event_device(handheld_gamepad.kb_phys_path)


func hide_event_device(phys_path: String) -> String:
	logger.debug("Hiding " + phys_path)
	return _manage_event_path("hide", _get_event_from_phys(phys_path))


func restore_event_device(phys_path: String) -> String:
	logger.debug("Restoring " + phys_path)
	return _manage_event_path("restore", _get_event_from_phys(phys_path))


# Returns the path that the device was moved to
func _manage_event_path(action: String, event_name: String) -> String:
	var command := "/usr/share/opengamepadui/scripts/manage_input"
	var args := [action, event_name]
	var output = []
	logger.debug("Start _manage_event_path with command : " + command + " " + "  ".join(args))
	var exit_code := OS.execute(command, args, output)
	logger.debug("Output: " + str(output))
	logger.debug("Exit code: " +str(exit_code))
	if exit_code != OK:
		return ""
	if action == "hide":
		return "/".join([input_hidden_path, event_name])
	return "/".join([input_default_path, event_name])


func _get_event_from_phys(phys_path: String)  -> String:
	logger.debug("_get_event_from_phys: " + phys_path)
	var event := phys_path.split("/")[-1] as String
	logger.debug("found event: " + event)
	return event 


func _restore_all_hidden() -> void:
	logger.info("Restoring hidden UInput devices.")
	if not DirAccess.dir_exists_absolute(input_hidden_path):
		logger.debug("No hidden devices found")
		return

	var files := DirAccess.get_files_at(input_hidden_path)
	if files.size() == 0:
		logger.debug("Found no hidden files at " + input_hidden_path + ". Nothing to do.")
		return

	for file_name in files:
		if not file_name.begins_with("event"):
			continue
		logger.debug("Found hidden file: " + file_name)
		restore_event_device(file_name)

	logger.info("Restore hidden UInput devices completed.")
