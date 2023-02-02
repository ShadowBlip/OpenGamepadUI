@icon("res://assets/icons/navigation.svg")
extends Node

# Intercept mode defines how we intercept gamepad events
enum INTERCEPT_MODE {
	NONE,
	PASS,  # Pass all inputs to the virtual device
	ALL,  # Intercept all inputs and send nothing to the virtual device
}

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
var input_exited_mut := Mutex.new()
var input_intercept := INTERCEPT_MODE.NONE
var input_intercept_mut := Mutex.new()
var input_thread := Thread.new()
var gamepad_map := {}
var gamepad_info := {}
var virt_gamepad_map := {}
var phys_to_virt_map := {}

@onready var launch_manager: LaunchManager = get_node("../LaunchManager")


func _ready() -> void:
	in_game_state.state_entered.connect(_on_game_state_entered)
	in_game_state.state_exited.connect(_on_game_state_exited)
	in_game_state.state_removed.connect(_on_game_state_removed)

	# Discover any gamepads and grab exclusive access to them. Create a
	# duplicate virtual gamepad for each physical one.
	var gamepads := discover_gamepads()
	for path in gamepads:
		# Skip any virtual devices we've already created.
		if path in phys_to_virt_map:
			logger.debug("Gamepad appears to be virtual: " + path)
			continue

		# Open the gamepad and create a virtual gamepad assoiated with it
		logger.debug("Opening gamepad device: " + path)
		var device := InputDevice.new()
		if device.open(path) != OK:
			logger.warn("Unable to open gamepad: " + path)
			continue

		# Query information about the device
		var info := {}
		info["ABS_Y_MAX"] = device.get_abs_max(InputDeviceEvent.ABS_Y)
		info["ABS_Y_MIN"] = device.get_abs_min(InputDeviceEvent.ABS_Y)
		info["ABS_X_MAX"] = device.get_abs_max(InputDeviceEvent.ABS_X)
		info["ABS_X_MIN"] = device.get_abs_min(InputDeviceEvent.ABS_X)

		# Create a virtual gamepad from this physical one
		var virt_gamepad := device.duplicate()
		var devnode := virt_gamepad.get_devnode()

		# Map the device, its info, and its child virtual device
		gamepad_map[path] = device
		gamepad_info[path] = info
		phys_to_virt_map[path] = devnode
		virt_gamepad_map[path] = virt_gamepad
		device.grab(true)
		logger.debug("Discovered gamepad at: " + path)
		logger.debug("  Gamepad properties: " + str(info))

	# Create a thread to process gamepad inputs separately
	logger.debug("Starting gamepad input thread")
	input_thread.start(_start_process_input)


# Sets the gamepad intercept mode
func _set_intercept(mode: INTERCEPT_MODE) -> void:
	input_intercept_mut.lock()
	input_intercept = mode
	input_intercept_mut.unlock()


# Runs evdev input processing in its own thread
func _start_process_input():
	var exited := false
	while not exited:
		input_exited_mut.lock()
		exited = input_exited
		input_exited_mut.unlock()
		_process_input()


# Processes all raw gamepad input
func _process_input() -> void:
	var mode := input_intercept
	for path in gamepad_map.keys():
		var gamepad := gamepad_map[path] as InputDevice
		var virt_gamepad := virt_gamepad_map[path] as VirtualInputDevice
		if not gamepad.is_open():
			continue
		var events := gamepad.get_events()
		for event in events:
			_process_event(path, virt_gamepad, event, mode)


# Processes a single input event
func _process_event(
	path: String, dev: VirtualInputDevice, event: InputDeviceEvent, mode: INTERCEPT_MODE
) -> void:
	if mode == INTERCEPT_MODE.NONE:
		dev.write_event(event.get_type(), event.get_code(), event.get_value())
		return
	if mode == INTERCEPT_MODE.PASS:
		dev.write_event(event.get_type(), event.get_code(), event.get_value())
		return
	match event.get_code():
		InputDeviceEvent.BTN_SOUTH:
			_send_input("ogui_south", event.value == 1, 1)
			_send_input("ui_accept", event.value == 1, 1)
		InputDeviceEvent.BTN_NORTH:
			_send_input("ogui_north", event.value == 1, 1)
		InputDeviceEvent.BTN_WEST:
			_send_input("ogui_west", event.value == 1, 1)
			_send_input("ui_select", event.value == 1, 1)
		InputDeviceEvent.BTN_EAST:
			_send_input("ogui_east", event.value == 1, 1)
		InputDeviceEvent.BTN_MODE:
			_send_input("ogui_guide", event.value == 1, 1)
		InputDeviceEvent.BTN_TRIGGER_HAPPY1:
			_send_input("ui_left", event.value == 1, 1)
		InputDeviceEvent.BTN_TRIGGER_HAPPY2:
			_send_input("ui_right", event.value == 1, 1)
		InputDeviceEvent.BTN_TRIGGER_HAPPY3:
			_send_input("ui_up", event.value == 1, 1)
		InputDeviceEvent.BTN_TRIGGER_HAPPY4:
			_send_input("ui_down", event.value == 1, 1)
		InputDeviceEvent.ABS_Y:
			var info := gamepad_info[path] as Dictionary
			if event.value > 0:
				var maximum := info["ABS_Y_MAX"] as int
				var value := event.value / float(maximum)
				if value == 0:
					return
				_send_joy_input(JOY_AXIS_LEFT_Y, value)
			if event.value <= 0:
				var minimum := info["ABS_Y_MIN"] as int
				var value := event.value / float(minimum)
				if value == 0:
					return
				_send_joy_input(JOY_AXIS_LEFT_Y, -value)
		InputDeviceEvent.ABS_X:
			var info := gamepad_info[path] as Dictionary
			if event.value > 0:
				var maximum := info["ABS_X_MAX"] as int
				var value := event.value / float(maximum)
				if value == 0:
					return
				_send_joy_input(JOY_AXIS_LEFT_X, value)
			if event.value <= 0:
				var minimum := info["ABS_X_MIN"] as int
				var value := event.value / float(minimum)
				if value == 0:
					return
				_send_joy_input(JOY_AXIS_LEFT_X, -value)


func discover_gamepads() -> PackedStringArray:
	var gamepads := PackedStringArray()
	var input_path := "/dev/input"
	var files := DirAccess.get_files_at(input_path)
	for file in files:
		var path := "/".join([input_path, file])
		var dev := InputDevice.new()
		if dev.open(path) != OK:
			logger.debug("Unable to open event device: " + path)
			continue
		if dev.has_event_code(InputDeviceEvent.EV_KEY, InputDeviceEvent.BTN_MODE):
			gamepads.append(path)
	return gamepads


func _on_game_state_entered(_from: State) -> void:
	set_focus(false)
	logger.debug("Ungrabbing gamepad interception")
	_set_intercept(INTERCEPT_MODE.PASS)


func _on_game_state_exited(_to: State) -> void:
	_on_game_state_removed()


func _on_game_state_removed() -> void:
	set_focus(true)

	# If no game is running now, don't intercept gamepad inputs
	if not state_machine.has_state(in_game_state):
		logger.debug("Ungrabbing gamepad interception")
		_set_intercept(INTERCEPT_MODE.PASS)
		return
	logger.debug("Grabbing gamepad interception")
	_set_intercept(INTERCEPT_MODE.ALL)


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


# https://docs.godotengine.org/en/latest/tutorials/inputs/inputevent.html#how-does-it-work
func _input(event: InputEvent) -> void:
	# Handle guide button inputs
	if event.is_action("ogui_guide"):
		_guide_input(event)
		get_viewport().set_input_as_handled()
		return

	# QAM Events
	if event.is_action("ogui_qam"):
		_qam_input(event)
		get_viewport().set_input_as_handled()
		return

	# OSK Events
	if event.is_action("ogui_osk"):
		_osk_input(event)
		get_viewport().set_input_as_handled()
		return

	# Main menu events
	if event.is_action("ogui_menu"):
		_main_menu_input(event)
		get_viewport().set_input_as_handled()
		return

	# Handle guide action release events
	if event.is_action_released("ogui_guide_action"):
		if event.is_action_released("ogui_north"):
			_action_release("ogui_osk")
			get_viewport().set_input_as_handled()
			return
		if event.is_action_released("ogui_south"):
			_action_release("ogui_qam")
			get_viewport().set_input_as_handled()
			return

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
		get_viewport().set_input_as_handled()


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

	if state_machine.stack_length() > 2:
		state_machine.pop_state()
		state = state_machine.current_state()

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


func _exit_tree() -> void:
	input_exited_mut.lock()
	input_exited = true
	input_exited_mut.unlock()
	input_thread.wait_to_finish()
