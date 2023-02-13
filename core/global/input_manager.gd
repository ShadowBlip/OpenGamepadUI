@icon("res://assets/icons/navigation.svg")
extends Resource
class_name InputManager

var launch_manager := load("res://core/global/launch_manager.tres") as LaunchManager
var state_machine := (
	preload("res://assets/state/state_machines/global_state_machine.tres") as StateMachine
)
var in_game_menu_state := preload("res://assets/state/states/in_game_menu.tres") as State
var in_game_state := preload("res://assets/state/states/in_game.tres") as State
var main_menu_state := preload("res://assets/state/states/main_menu.tres") as State
var qam_state := preload("res://assets/state/states/quick_access_menu.tres") as State
var PID: int = OS.get_process_id()
var display = OS.get_environment("DISPLAY")
var overlay_window_id = Gamescope.get_window_id(display, PID)
var logger := Log.get_logger("InputManager", Log.LEVEL.DEBUG)
var guide_action := false

var input_exited := false
var input_thread := Thread.new()
var managed_gamepads := {}  # {"/dev/input/event1": <ManagedGamepad>}
var virtual_gamepads := []  # ["/dev/input/event2"]
var gamepad_mutex := Mutex.new()


func _init() -> void:
	in_game_state.state_entered.connect(_on_game_state_entered)
	in_game_state.state_exited.connect(_on_game_state_exited)
	in_game_state.state_removed.connect(_on_game_state_removed)

	# Discover any gamepads and grab exclusive access to them. Create a
	# duplicate virtual gamepad for each physical one.
	_on_gamepad_change(0, false)

	# Create a thread to process gamepad inputs separately
	logger.debug("Starting gamepad input thread")
	input_thread.start(_start_process_input)
	Input.joy_connection_changed.connect(_on_gamepad_change)


# Returns a list of gamepad devices that are being exclusively managed.
func get_managed_gamepads() -> Array:
	return managed_gamepads.keys()


# Sets the gamepad intercept mode
func _set_intercept(mode: ManagedGamepad.INTERCEPT_MODE) -> void:
	logger.debug("Setting gamepad intercept mode: " + str(mode))
	gamepad_mutex.lock()
	for gamepad in managed_gamepads.values():
		gamepad.mode = mode
	gamepad_mutex.unlock()


# Runs evdev input processing in its own thread. We use mutexes to safely
# access variables from the main thread
func _start_process_input():
	var exited := false
	while not exited:
		OS.delay_usec(1)  # Throttle to execute every 1us, to save CPU
		gamepad_mutex.lock()
		exited = input_exited
		_process_input()
		gamepad_mutex.unlock()


# Processes all raw gamepad input
func _process_input() -> void:
	for gamepad in managed_gamepads.values():
		gamepad.process_input()


# Triggers whenever we detect any gamepad connect/disconnect events
func _on_gamepad_change(_device: int, _connected: bool) -> void:
	logger.info("Gamepad was changed")
	# Lock the gamepad mappings so we can alter them.
	gamepad_mutex.lock()

	# Discover any new gamepads
	var discovered_paths := discover_gamepads()

	# Remove all gamepads that no longer exist
	for gamepad in managed_gamepads.values():
		if gamepad.phys_path in discovered_paths:
			continue
		logger.debug("Gamepad no longer exists: " + gamepad.phys_path)
		gamepad.virt_device.close()
		managed_gamepads.erase(gamepad.phys_path)
		virtual_gamepads.erase(gamepad.virt_path)

	# Add any newly found gamepads
	for path in discovered_paths:
		if path in managed_gamepads:
			logger.debug("Gamepad is already being managed: " + path)
			continue
		if path in virtual_gamepads:
			logger.debug("Gamepad appears to be virtual: " + path)
			continue

		var gamepad := ManagedGamepad.new()
		if gamepad.open(path) != OK:
			logger.warn("Unable to create managed gamepad for: " + path)
			continue
		managed_gamepads[path] = gamepad
		virtual_gamepads.append(gamepad.virt_path)
		logger.debug("Discovered gamepad at: " + gamepad.phys_path)
		logger.debug("Created virtual gamepad at: " + gamepad.virt_path)
	logger.debug("Finished configuring gamepads")
	gamepad_mutex.unlock()


func _on_game_state_entered(_from: State) -> void:
	set_focus(false)
	logger.debug("Ungrabbing gamepad interception")
	_set_intercept(ManagedGamepad.INTERCEPT_MODE.PASS)


func _on_game_state_exited(_to: State) -> void:
	_on_game_state_removed()


func _on_game_state_removed() -> void:
	set_focus(true)

	# If no game is running now, don't intercept gamepad inputs
	if not state_machine.has_state(in_game_state):
		logger.debug("Ungrabbing gamepad interception")
		_set_intercept(ManagedGamepad.INTERCEPT_MODE.PASS)
		return
	logger.debug("Grabbing gamepad interception")
	_set_intercept(ManagedGamepad.INTERCEPT_MODE.ALL)


# Set focus will use Gamescope to focus OpenGamepadUI
func set_focus(focused: bool) -> void:
	# Sets ourselves to the input focus
	var window_id = overlay_window_id
	if focused:
		logger.debug("Focusing overlay")
		Gamescope.set_input_focus(display, window_id, 1)
		return
	logger.debug("Un-focusing overlay")
	Gamescope.set_input_focus(display, window_id, 0)


# Returns an array of device paths
func discover_gamepads() -> PackedStringArray:
	var paths := PackedStringArray()
	var input_path := "/dev/input"
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
	return paths


# Returns whether or not get_viewport().set_input_as_handled() should be called
# https://docs.godotengine.org/en/latest/tutorials/inputs/inputevent.html#how-does-it-work
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
	elif state in [qam_state]:  #osk_state:
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
	elif state in [main_menu_state, in_game_menu_state]:  #, osk_state:
		state_machine.replace_state(qam_state)
	else:
		state_machine.push_state(qam_state)


func _osk_input(_event: InputEvent) -> void:
	pass


func _action_release(action: String, strength: float = 1.0) -> void:
	_send_input(action, false, strength)


func _action_press(action: String, strength: float = 1.0) -> void:
	_send_input(action, true, strength)


# Sends an input action to the event queue
func _send_input(action: String, pressed: bool, strength: float = 1.0) -> void:
	var input_action := InputEventAction.new()
	input_action.action = action
	input_action.pressed = pressed
	input_action.strength = strength
	Input.parse_input_event(input_action)


# Sends joy motion input to the event queue
func _send_joy_input(axis: int, value: float) -> void:
	var joy_action := InputEventJoypadMotion.new()
	joy_action.axis = axis
	joy_action.axis_value = value
	Input.parse_input_event(joy_action)


func exit() -> void:
	gamepad_mutex.lock()
	input_exited = true
	gamepad_mutex.unlock()
	input_thread.wait_to_finish()
	Input.joy_connection_changed.disconnect(_on_gamepad_change)
	for gamepad in managed_gamepads.values():
		logger.debug("Cleaning up gamepad: " + gamepad.phys_path)
		gamepad.phys_device.grab(false)
		gamepad.virt_device.close()
		gamepad.phys_device.close()
