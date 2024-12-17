@icon("res://assets/editor-icons/material-symbols-joystick.svg")
extends Node
class_name OverlayInputManager

## Manages global input while ion overlay mode
##
## The OverlayInputManager class is responsible for handling global input while
## the quick bar or configuration menu are open while permitting underlay
## process chords to function, such as the Steam Quick Access Menu chord.[br][br]
##
## To include this functionality, add this as a node to the root node in the
## scene tree.

## The audio manager to use to adjust the audio when audio input events happen.
var audio_manager := load("res://core/global/audio_manager.tres") as AudioManager
## InputPlumber receives and sends DBus input events.
var input_plumber := load("res://core/systems/input/input_plumber.tres") as InputPlumberInstance
## LaunchManager provides context on the currently running app so we can switch profiles
var launch_manager := load("res://core/global/launch_manager.tres") as LaunchManager
## The Global State Machine
var state_machine := load("res://assets/state/state_machines/global_state_machine.tres") as StateMachine
## State machine to use to switch menu states in response to input events.
var popup_state_machine := (
	preload("res://assets/state/state_machines/popup_state_machine.tres") as StateMachine
)
var menu_state_machine := preload("res://assets/state/state_machines/menu_state_machine.tres") as StateMachine
var in_game_menu_state := preload("res://assets/state/states/in_game_menu.tres") as State
var main_menu_state := preload("res://assets/state/states/main_menu.tres") as State
var quick_bar_state := preload("res://assets/state/states/quick_bar_menu.tres") as State
var base_state = preload("res://assets/state/states/in_game.tres") as State

var actions_pressed := {}

## Will show logger events with the prefix InputManager(Overlay Mode)
var logger := Log.get_logger("InputManager(Overlay Mode)", Log.LEVEL.INFO)


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	add_to_group("InputManager")
	input_plumber.composite_device_added.connect(_watch_dbus_device)
	input_plumber.started.connect(_init_inputplumber)
	_init_inputplumber()


func _init_inputplumber() -> void:
	for device in input_plumber.get_composite_devices():
		_watch_dbus_device(device)


## Queue a release event for the given action
func action_release(dbus_path: String, action: String, strength: float = 1.0) -> void:
	Input.action_release(action)
	_send_input(dbus_path, action, false, strength)


## Queue a pressed event for the given action
func action_press(dbus_path: String, action: String, strength: float = 1.0) -> void:
	Input.action_press(action)
	_send_input(dbus_path, action, true, strength)


## Sends an input action to the event queue
func _send_input(dbus_path: String, action: String, pressed: bool, strength: float = 1.0) -> void:
	var input_action := InputEventAction.new()
	input_action.action = action
	input_action.pressed = pressed
	input_action.strength = strength
	input_action.set_meta("dbus_path", dbus_path)
	logger.debug("Send input: " + str(input_action))
	Input.parse_input_event(input_action)


## Process all unhandled input, possibly preventing the input from propagating further.
## https://docs.godotengine.org/en/latest/tutorials/inputs/inputevent.html#how-does-it-work
func _input(event: InputEvent) -> void:
	logger.debug("Got input event to handle: " + str(event))
	# Don't process Godot events if InputPlumber is running
	if input_plumber.is_running() and not InputManager.is_inputplumber_event(event):
		if event is InputEventJoypadButton or event is InputEventJoypadMotion:
			logger.debug("Skipping Godot event while InputPlumber is running:", event)
			get_viewport().set_input_as_handled()
			return

	var dbus_path := event.get_meta("dbus_path", "") as String
	
	# Don't process Godot events if InputPlumber is running
	if input_plumber.is_running() and not InputManager.is_inputplumber_event(event):
		logger.trace("Skipping Godot event while InputPlumber is running:", event)
		return

	# Consume double inputs for controllers with DPads that have TRIGGER_HAPPY events
	const possible_doubles := ["ui_left", "ui_right", "ui_up", "ui_down"]
	for action in possible_doubles:
		if not event.is_action(action):
			continue
		var value := event.is_pressed()
		var old_value := false
		if action in actions_pressed:
			old_value = actions_pressed[action]
		if old_value == value:
			get_viewport().set_input_as_handled()
			return
		actions_pressed[action] = value

	# Handle guide button inputs
	if event.is_action("ogui_guide_ov"):
		_guide_input(event)
		get_viewport().set_input_as_handled()
		return

	# Steam chord events
	if _send_steam_chord(event):
		get_viewport().set_input_as_handled()
		return

	# Quick Bar open events
	if event.is_action("ogui_qb_ov"):
		_quick_bar_input(event)
		get_viewport().set_input_as_handled()
		return

	# Handle audio events
	if event.is_action("ogui_volume_down") or event.is_action("ogui_volume_up") or event.is_action("ogui_volume_mute"):
		_audio_input(event)
		return

	# Handle guide action release events
	if event.is_action_released("ogui_guide_action"):
		logger.debug("Additional action as guide is released.")
		# Steam OSK
		if event.is_action_released("ogui_north_ov"):
			action_release(dbus_path, "ogui_osk_ov")
			get_viewport().set_input_as_handled()
			return

		# Steam QAM
		if event.is_action_released("ogui_south_ov"):
			action_release(dbus_path, "ogui_qam_ov")
			get_viewport().set_input_as_handled()
			return

		# Steam Video Capture
		if event.is_action_released("ogui_west_ov"):
			action_release(dbus_path, "ogui_vc_ov")
			get_viewport().set_input_as_handled()
			return

		# Steam Screenshot
		if event.is_action_released("ogui_rb_ov"):
			action_release(dbus_path, "ogui_sc_ov")
			get_viewport().set_input_as_handled()
			return

		# Quick Bar
		if event.is_action_released("ogui_east_ov"):
			action_release(dbus_path, "ogui_qb_ov")
			get_viewport().set_input_as_handled()
			return

	# Handle inputs when the guide button is being held
	if Input.is_action_pressed("ogui_guide_ov"):
		# Prevent ALL input from propagating if guide is held!
		get_viewport().set_input_as_handled()

		if event.is_pressed():
			logger.debug("Additional action while guide wad pressed.")
			# Steam OSK
			if event.is_action_pressed("ogui_north_ov"):
				action_press(dbus_path, "ogui_guide_action")
				action_press(dbus_path, "ogui_osk_ov")

			# Steam QAM
			if event.is_action_pressed("ogui_south_ov"):
				action_press(dbus_path, "ogui_guide_action")
				action_press(dbus_path, "ogui_qam_ov")

			# Steam Video Capture
			if event.is_action_pressed("ogui_west_ov"):
				action_press(dbus_path, "ogui_guide_action")
				action_press(dbus_path, "ogui_vc_ov")

			# Steam Screenshot
			if event.is_action_pressed("ogui_rb_ov"):
				action_press(dbus_path, "ogui_guide_action")
				action_press(dbus_path, "ogui_sc_ov")

			# Quick Bar
			if event.is_action_pressed("ogui_east_ov"):
				action_press(dbus_path, "ogui_guide_action")
				action_press(dbus_path, "ogui_qb_ov")

		elif event.is_released():
			# Steam OSK
			if event.is_action_released("ogui_north_ov"):
				action_release(dbus_path, "ogui_osk_ov")

			# Steam QAM
			if event.is_action_released("ogui_south_ov"):
				action_release(dbus_path, "ogui_qam_ov")

			# Steam Video Capture
			if event.is_action_released("ogui_west_ov"):
				action_release(dbus_path, "ogui_vc_ov")

			# Steam Screenshot
			if event.is_action_pressed("ogui_rb_ov"):
				action_release(dbus_path, "ogui_sc_ov")

			# Quick Bar
			if event.is_action_released("ogui_east_ov"):
				action_release(dbus_path, "ogui_qb_ov")

		return

	# Handle events in the UI while it is open.
	if event.is_action_pressed("ogui_south_ov"):
		logger.debug("South pressed on its own.")
		action_press(dbus_path, "ui_accept")
		get_viewport().set_input_as_handled()

	elif event.is_action_released("ogui_south_ov"):
		logger.debug("South released on its own.")
		action_release(dbus_path, "ui_accept")
		get_viewport().set_input_as_handled()

	if event.is_action_pressed("ogui_east_ov"):
		logger.debug("East pressed on its own.")
		action_press(dbus_path, "ogui_east")
		get_viewport().set_input_as_handled()

	elif event.is_action_released("ogui_east_ov"):
		logger.debug("East released on its own.")
		action_release(dbus_path, "ogui_east")
		get_viewport().set_input_as_handled()

	if event.is_action_pressed("ogui_rb_ov"):
		logger.debug("East pressed on its own.")
		action_press(dbus_path, "ogui_tab_right")
		get_viewport().set_input_as_handled()

	elif event.is_action_released("ogui_rb_ov"):
		logger.debug("East released on its own.")
		action_release(dbus_path, "ogui_tab_right")
		get_viewport().set_input_as_handled()

	if event.is_action_pressed("ogui_lb_ov"):
		logger.debug("East pressed on its own.")
		action_press(dbus_path, "ogui_tab_left")
		get_viewport().set_input_as_handled()

	elif event.is_action_released("ogui_lb_ov"):
		logger.debug("East released on its own.")
		action_release(dbus_path, "ogui_tab_left")
		get_viewport().set_input_as_handled()


## Handle guide button events and determine whether this is a guide action
## (e.g. guide + A to open the Quick Bar), or if it's just a normal guide button press.
func _guide_input(event: InputEvent) -> void:
	var dbus_path := event.get_meta("dbus_path", "") as String
	# Only act on release events
	if event.is_pressed():
		logger.debug("Guide pressed. Waiting for additional events.")
		# Set the gamepad profile to the global default so we can capture button events.
		# This ensures that we use the global profile and not the game's input profile for
		# processing guide button combos and navigating the menu.
		launch_manager.set_gamepad_profile("")
		return

	# If a guide action combo was pressed and we released the guide button,
	# end the guide action and do nothing else.
	if Input.is_action_pressed("ogui_guide_action"):
		logger.debug("Guide released. Additional events used guide action, ignoring.")
		action_release(dbus_path, "ogui_guide_action")
		return

	# Emit the main menu action if this was not a guide action
	logger.debug("Guide released. Additional events did not use guide action. Sending Guide.")
	_close_focused_window()
	_return_chord(["Gamepad:Button:Guide"])


## Handle quick bar menu events to open the quick bar menu
func _quick_bar_input(event: InputEvent) -> void:
	# Only act on press events
	if not event.is_pressed():
		return

	var state := popup_state_machine.current_state()
	if state == quick_bar_state:
		popup_state_machine.pop_state()
	elif state in [main_menu_state, in_game_menu_state]:
		popup_state_machine.replace_state(quick_bar_state)
	else:
		popup_state_machine.push_state(quick_bar_state)


## Handle Steam chord events. Returns true if this was a Steam chord.
func _send_steam_chord(event: InputEvent) -> bool:
	var chord: PackedStringArray = ["Gamepad:Button:Guide"]
	# Block up events from doing weird things. InputPlumber will handle up events.
	if not event.is_pressed():
		return false

	# Steam Quick Bar
	if event.is_action_pressed("ogui_qam_ov"):
		logger.debug("Trigger Steam QAM")
		chord.append("Gamepad:Button:South")

	# Steam On-Screen Keyboard
	elif event.is_action_pressed("ogui_osk_ov"):
			logger.debug("Trigger Steam OSK")
			chord.append("Gamepad:Button:North")

	# Steam Video-Capture
	elif event.is_action_pressed("ogui_vc_ov"):
			logger.debug("Trigger Steam VC")
			chord.append("Gamepad:Button:West")

	# Steam Screenshot
	elif event.is_action_pressed("ogui_sc_ov"):
			logger.debug("Trigger Steam Screenshot")
			chord.append("Gamepad:Button:RightBumper")

	# Not a steam chord
	else:
		return false

	_close_focused_window()
	_return_chord(chord)
	return true


func _return_chord(actions: PackedStringArray) -> void:
	# TODO: Figure out a way to get the device who sent the event through
	# Input.parse_input_event so we don't do this terrible loop. This is awful.
	logger.debug("Return events to InputPlumber: " + str(actions))
	for device in input_plumber.get_composite_devices():
		device.intercept_mode = InputPlumberInstance.INTERCEPT_MODE_PASS
		device.send_button_chord(actions)


func _audio_input(event: InputEvent) -> void:
	# Only act on press events
	if not event.is_pressed():
		return

	if event.is_action("ogui_volume_mute"):
		logger.debug("Mute!")
		audio_manager.call_deferred("toggle_mute")
		get_viewport().set_input_as_handled()
		return
	if event.is_action("ogui_volume_down"):
		logger.debug("Volume Down!")
		audio_manager.call_deferred("set_volume", -0.06, audio_manager.VOLUME.RELATIVE)
		get_viewport().set_input_as_handled()
		return
	if event.is_action("ogui_volume_up"):
		logger.debug("Volume Up!")
		audio_manager.call_deferred("set_volume", 0.06, audio_manager.VOLUME.RELATIVE)
		get_viewport().set_input_as_handled()
		return


func _watch_dbus_device(device: CompositeDevice) -> void:
		for target in device.dbus_devices:
			if target.input_event.is_connected(_on_dbus_input_event.bind(device.dbus_path)):
				continue
			logger.debug("Adding watch for " + device.name + " " + target.dbus_path)
			logger.debug(str(target.get_instance_id()))
			logger.debug(str(target.get_rid()))
			target.input_event.connect(_on_dbus_input_event.bind(device.dbus_path))


func _on_dbus_input_event(event: String, value: float, dbus_path: String) -> void:
	var pressed := value == 1.0
	logger.debug("Handling dbus input event from" + dbus_path + ": " + event + " pressed: " + str(pressed))

	var action := event
	match event:
		"ui_accept":
			action = "ogui_south_ov"
		"ui_back":
			action = "ogui_east_ov"
		"ui_guide":
			action = "ogui_guide_ov"
		"ui_action":
			action = "ogui_west_ov"
		"ui_context":
			action = "ogui_north_ov"
		"ui_quick":
			action = "ogui_qam_ov"
		"ui_quick2":
			action = "ogui_qb_ov"
		"ui_osk":
			action = "ogui_osk_ov"
		"ui_r1":
			action = "ogui_rb_ov"
		"ui_l1":
			action = "ogui_lb_ov"

	if pressed:
		action_press(dbus_path, action)
	else:
		action_release(dbus_path, action)


# Closes all windows until we return to the base_state
func _close_focused_window() -> void:
	popup_state_machine.clear_states()
	menu_state_machine.clear_states()
