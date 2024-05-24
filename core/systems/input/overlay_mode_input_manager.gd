@icon("res://assets/icons/navigation.svg")
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
var input_plumber := load("res://core/systems/input/input_plumber.tres") as InputPlumber

## State machine to use to switch menu states in response to input events.
var state_machine := (
	preload("res://assets/state/state_machines/global_state_machine.tres") as StateMachine
)
var in_game_menu_state := preload("res://assets/state/states/in_game_menu.tres") as State
var main_menu_state := preload("res://assets/state/states/main_menu.tres") as State
var quick_bar_state := preload("res://assets/state/states/quick_bar_menu.tres") as State
var base_state = preload("res://assets/state/states/in_game.tres") as State

var handle_back: bool = false

## Will show logger events with the prefix InputManager(Overlay Mode)
var logger := Log.get_logger("InputManager(Overlay Mode)", Log.LEVEL.INFO)


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	add_to_group("InputManager")
	input_plumber.composite_device_added.connect(_watch_dbus_device)

	for device in input_plumber.composite_devices:
		_watch_dbus_device(device)

	state_machine.state_changed.connect(_on_state_changed)


# Only process back input when not on the base state
func _on_state_changed(_from: State, to: State) -> void:
	if to == base_state:
		handle_back = false
		return
	handle_back = true


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
	var dbus_path := event.get_meta("dbus_path", "") as String

	# Handle guide button inputs
	if event.is_action("ogui_guide"):
		_guide_input(event)
		get_viewport().set_input_as_handled()
		return

	# Steam QAM open events
	if event.is_action("ogui_qam"):
		_qam_input(event)
		get_viewport().set_input_as_handled()
		return

	# Quick Bar open events
	if event.is_action("ogui_osk"):
		_osk_input(event)
		get_viewport().set_input_as_handled()
		return

	# Steam OSK open events
	if event.is_action("ogui_qb"):
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
		if event.is_action_released("ogui_north"):
			action_release(dbus_path, "ogui_osk")
			get_viewport().set_input_as_handled()
			return
		# Quick Bar
		if event.is_action_released("ogui_east"):
			action_release(dbus_path, "ogui_qb")
			get_viewport().set_input_as_handled()
			return
		# Steam QAM
		if event.is_action_released("ogui_south"):
			action_release(dbus_path, "ogui_qam")
			get_viewport().set_input_as_handled()
			return

	# Handle inputs when the guide button is being held
	if Input.is_action_pressed("ogui_guide"):
		
		if event.is_pressed():
			logger.debug("Additional action while guide wad pressed.")
			# Steam OSK
			if event.is_action_pressed("ogui_north"):
				action_press(dbus_path, "ogui_guide_action")
				action_press(dbus_path, "ogui_osk")
			# Quick Bar
			if event.is_action_pressed("ogui_east"):
				action_press(dbus_path, "ogui_guide_action")
				action_press(dbus_path, "ogui_qb")
			# Steam QAM
			if event.is_action_pressed("ogui_south"):
				action_press(dbus_path, "ogui_guide_action")
				action_press(dbus_path, "ogui_qam")
		elif event.is_released():
			# Steam OSK
			if event.is_action_released("ogui_north"):
				action_release(dbus_path, "ogui_osk")
				get_viewport().set_input_as_handled()
				return
			# Quick Bar
			if event.is_action_released("ogui_east"):
				action_release(dbus_path, "ogui_qb")
				get_viewport().set_input_as_handled()
				return
			# Steam QAM
			if event.is_action_released("ogui_south"):
				action_release(dbus_path, "ogui_qam")
				get_viewport().set_input_as_handled()
				return
		# Prevent ALL input from propagating if guide is held!
		get_viewport().set_input_as_handled()
		return

	# Handle accept in the UI while it is open.
	if event.is_action_pressed("ogui_south"):
		logger.debug("South pressed on its own.")
		action_press(dbus_path, "ui_accept")
		get_viewport().set_input_as_handled()
		return

	elif event.is_action_released("ogui_south"):
		logger.debug("South released on its own.")
		action_release(dbus_path, "ui_accept")
		get_viewport().set_input_as_handled()
		return

	# Handle back in the UI while it is open.
	if event.is_action_pressed("ogui_east"):
		logger.debug("East pressed on its own.")
		action_press(dbus_path, "ui_back")
		get_viewport().set_input_as_handled()
		return

	elif event.is_action_released("ogui_east"):
		logger.debug("East released on its own.")
		action_release(dbus_path, "ui_back")
		get_viewport().set_input_as_handled()
		return

	# Only proceed if this is a back event.
	if not event.is_action("ogui_back"):
		return

	# If we're on the base state, don't pop the state.
	if not handle_back:
		return

	# Only handle back on the down event
	if not event.is_pressed():
		return

	# Pop the state off the state stack and prevent the event from propagating
	state_machine.pop_state()
	get_viewport().set_input_as_handled()


## Handle guide button events and determine whether this is a guide action
## (e.g. guide + A to open the Quick Bar), or if it's just a normal guide button press.
func _guide_input(event: InputEvent) -> void:
	var dbus_path := event.get_meta("dbus_path", "") as String
	# Only act on release events
	if event.is_pressed():
		logger.debug("Guide pressed. Waiting for additional events.")
		return

	# If a guide action combo was pressed and we released the guide button,
	# end the guide action and do nothing else.
	if Input.is_action_pressed("ogui_guide_action"):
		logger.debug("Guide released. Additional events used guide action, ignoring.")
		action_release(dbus_path, "ogui_guide_action")
		return

	# Emit the main menu action if this was not a guide action
	logger.debug("Guide released. Additional events did not use guide action. Sending Guide.")
	input_plumber.set_intercept_mode(InputPlumber.INTERCEPT_MODE.PASS)
	_return_chord(["Gamepad:Button:Guide"])
	_close_quickbar()


## Handle quick bar menu events to open the quick bar menu
func _quick_bar_input(event: InputEvent) -> void:
	logger.debug("Trigger Quick Bar")

	# Only act on press events
	if not event.is_pressed():
		logger.debug("Event is up event, ignore.")
		return

	var state := state_machine.current_state()
	logger.debug("Current State: " +str(state))
	if state == quick_bar_state:
		logger.debug("Close Quick Bar")
		state_machine.pop_state()
	elif state in [main_menu_state, in_game_menu_state]:
		logger.debug("Replace state with Quick Bar")
		state_machine.replace_state(quick_bar_state)
	else:
		logger.debug("Push Quick Bar")
		state_machine.push_state(quick_bar_state)


## Handle OSK events for bringing up the on-screen keyboard
func _osk_input(event: InputEvent) -> void:
	logger.debug("Trigger Steam OSK")
	if not event.is_pressed():
		return
	input_plumber.set_intercept_mode(InputPlumber.INTERCEPT_MODE.PASS)
	_return_chord(["Gamepad:Button:Guide", "Gamepad:Button:East"])
	_close_quickbar()


## Handle QAM events for bringing up the steam QAM
func _qam_input(event: InputEvent) -> void:
	logger.debug("Trigger Steam QAM")
	if not event.is_pressed():
		return
	input_plumber.set_intercept_mode(InputPlumber.INTERCEPT_MODE.PASS)
	_return_chord(["Gamepad:Button:Guide", "Gamepad:Button:South"])
	_close_quickbar()


func _return_chord(actions: PackedStringArray) -> void:
	# TODO: Figure out a way to get the device who sent the event through
	# Input.parse_input_event so we don't do this terrible loop. This is awful.
	logger.debug("Return events to InputPlumber: " + str(actions))
	for device in input_plumber.composite_devices:
		device.intercept_mode = 0
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


func _watch_dbus_device(device: InputPlumber.CompositeDevice) -> void:
		for target in device.dbus_targets:
			logger.debug("Adding watch for " + device.name + " " + target.name)
			logger.debug(str(target.get_instance_id()))
			logger.debug(str(target.get_rid()))
			target.input_event.connect(_on_dbus_input_event.bind(device.dbus_path))


func _on_dbus_input_event(event: String, value: float, dbus_path: String) -> void:
	var pressed := value == 1.0
	logger.debug("Handling dbus input event: " + event + " pressed: " + str(pressed))
	var action = event
	match event:
		"ui_accept":
			action = "ogui_south"
		"ui_back":
			action = "ogui_east"
		"ui_guide":
			action = "ogui_guide"
		"ui_action":
			action = "ogui_west"
		"ui_context":
			action = "ogui_north"
		"ui_quick":
			action = "ogui_qam"
		"ui_quick2":
			action = "ogui_qb"
		"ui_osk":
			action = "ogui_osk"
		"ui_r1":
			action = "ogui_tab_right"
		"ui_l1":
			action = "ogui_tab_left"

	if pressed:
		action_press(dbus_path, action)
	else:
		action_release(dbus_path, action)


func _close_quickbar() -> void:
	var state := state_machine.current_state()
	logger.debug("Current State: " +str(state))
	while state != base_state:
		state_machine.pop_state()
		state = state_machine.current_state()
