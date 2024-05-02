@icon("res://assets/icons/navigation.svg")
extends Node
class_name InputManager

## Manages global input
##
## The InputManager class is responsible for handling global input that should
## happen everywhere in the application, regardless of the current menu. Examples
## include opening up the main or quick bar menus.[br][br]
##
## To include this functionality, add this as a node to the root node in the
## scene tree.

## Reference to the on-screen keyboard instance to open when the OSK action is
## pressed.
const osk := preload("res://core/global/keyboard_instance.tres")

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
var osk_state := preload("res://assets/state/states/osk.tres") as State

## Will show logger events with the prefix InputManager
var logger := Log.get_logger("InputManager", Log.LEVEL.INFO)


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	add_to_group("InputManager")
	input_plumber.composite_device_added.connect(_watch_dbus_device)

	for device in input_plumber.composite_devices:
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
	var dbus_path := event.get_meta("dbus_path", "") as String

	# Handle guide button inputs
	if event.is_action("ogui_guide"):
		_guide_input(event)
		get_viewport().set_input_as_handled()
		return

	# Quick Bar Open Events
	if event.is_action("ogui_qb"):
		logger.debug("Quick bar action pressed")
		_on_quick_bar_open(event)
		get_viewport().set_input_as_handled()
		return

	# OSK Events
	if event.is_action("ogui_osk"):
		logger.debug("OSK action pressed")
		_osk_input(event)
		get_viewport().set_input_as_handled()
		return

	# Main menu events
	if event.is_action("ogui_menu"):
		logger.debug("Menu action pressed")
		_main_menu_input(event)
		get_viewport().set_input_as_handled()
		return

	# Audio events
	if event.is_action("ogui_volume_down") or event.is_action("ogui_volume_up") or event.is_action("ogui_volume_mute"):
		logger.debug("Volume key pressed")
		_audio_input(event)
		get_viewport().set_input_as_handled()
		return

	# Handle guide action release events
	if event.is_action_released("ogui_guide_action"):
		if event.is_action_released("ogui_north"):
			action_release(dbus_path, "ogui_osk")
			get_viewport().set_input_as_handled()
			return
		if event.is_action_released("ogui_south"):
			action_release(dbus_path, "ogui_qb")
			get_viewport().set_input_as_handled()
			return

	# Handle inputs when the guide button is being held
	if Input.is_action_pressed("ogui_guide"):
		logger.debug("Additional action while guide wad pressed.")
		# OSK
		if event.is_action_pressed("ogui_north"):
			logger.debug("North. Trigger OSK")
			action_press(dbus_path, "ogui_osk")
			action_press(dbus_path, "ogui_guide_action")
		# Quick Bar
		if event.is_action_pressed("ogui_south"):
			logger.debug("Trigger QB")
			action_press(dbus_path, "ogui_qb")
			action_press(dbus_path, "ogui_guide_action")

		# Prevent ALL input from propagating if guide is held!
		get_viewport().set_input_as_handled()
		return

	if event.is_action_pressed("ogui_south"):
		logger.debug("South pressed on its own.")
		action_press(dbus_path, "ui_accept")
	elif event.is_action_released("ogui_south"):
		logger.debug("South released on its own.")
		action_release(dbus_path, "ui_accept")


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
	logger.debug("Guide released. Additional events did not use guide action. Opening menu.")
	action_press(dbus_path, "ogui_menu")
	action_release(dbus_path, "ogui_menu")


## Handle main menu events to open the main menu
func _main_menu_input(event: InputEvent) -> void:
	# Only act on release events
	if event.is_pressed():
		return

	# Open the main menu
	var state := state_machine.current_state()
	var menu_state := main_menu_state

	if state == menu_state:
		state_machine.pop_state()
	elif state in [quick_bar_state, osk_state]:
		state_machine.replace_state(menu_state)
	else:
		state_machine.push_state(menu_state)


## Handle quick bar menu events to open the quick bar menu
func _on_quick_bar_open(event: InputEvent) -> void:
	# Only act on press events
	if not event.is_pressed():
		return

	var state := state_machine.current_state()
	if state == quick_bar_state:
		state_machine.pop_state()
	elif state in [main_menu_state, in_game_menu_state, osk_state]:
		state_machine.replace_state(quick_bar_state)
	else:
		state_machine.push_state(quick_bar_state)


## Handle OSK events for bringing up the on-screen keyboard
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
	elif state in [main_menu_state, in_game_menu_state, quick_bar_state]:
		state_machine.replace_state(osk_state)
	else:
		state_machine.push_state(osk_state)


## Handle audio input events such as mute, volume up, and volume down
func _audio_input(event: InputEvent) -> void:
	# Only act on press events
	if not event.is_pressed():
		return
	
	if event.is_action("ogui_volume_mute"):
		logger.debug("Mute!")
		audio_manager.call_deferred("toggle_mute")
		return
	if event.is_action("ogui_volume_down"):
		logger.debug("Volume Down!")
		audio_manager.call_deferred("set_volume", -0.06, audio_manager.VOLUME.RELATIVE)
		return
	if event.is_action("ogui_volume_up"):
		logger.debug("Volume Up!")
		audio_manager.call_deferred("set_volume", 0.06, audio_manager.VOLUME.RELATIVE)
		return


func _watch_dbus_device(device: InputPlumber.CompositeDevice) -> void:
		for target in device.dbus_targets:
			logger.debug("Adding watch for " + device.name + " " + target.name)
			logger.debug(str(target.get_instance_id()))
			logger.debug(str(target.get_rid()))
			target.input_event.connect(_on_dbus_input_event.bind(device.dbus_path))


func _on_dbus_input_event(event: String, value: float, dbus_path: String) -> void:
	var pressed := value == 1.0
	logger.debug("Handling dbus input event from" + dbus_path + ": " + event + " pressed: " + str(pressed))

	var action := event
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
			action = "ogui_qb"
		"ui_quick2":
			action = "ogui_qb"
		"ui_osk":
			action = "ogui_osk"
		"ui_r1":
			action = "ogui_tab_right"
		"ui_l1":
			action = "ogui_tab_left"

	var input_action := InputEventAction.new()
	input_action.action = action
	input_action.pressed = pressed
	input_action.strength = value

	if pressed:
		action_press(dbus_path, action)
	else:
		action_release(dbus_path, action)
