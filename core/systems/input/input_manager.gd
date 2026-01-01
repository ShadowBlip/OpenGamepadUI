@icon("res://assets/editor-icons/material-symbols-joystick.svg")
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
var osk := load("res://core/global/keyboard_instance.tres") as KeyboardInstance

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
var in_game_menu_state := preload("res://assets/state/states/in_game_menu.tres") as State
var main_menu_state := preload("res://assets/state/states/main_menu.tres") as State
var quick_bar_state := preload("res://assets/state/states/quick_bar_menu.tres") as State
var osk_state := preload("res://assets/state/states/osk.tres") as State
var popup_state := preload("res://assets/state/states/popup.tres") as State

## Map of pressed actions to prevent double inputs
var actions_pressed := {}

## Number of currently pressed touches
var current_touches := 0

## Will show logger events with the prefix InputManager
var logger := Log.get_logger("InputManager", Log.LEVEL.INFO)

const PROFILES_DIR := "user://data/gamepad/profiles"


func _init() -> void:
	# Ensure the default global profile exists in the user directory.
	var default_global_profile := get_default_global_profile_path()
	var default_profile := _get_default_profile_path()
	if FileAccess.file_exists(default_global_profile):
		return

	var file := FileAccess.open(default_profile, FileAccess.READ)
	var content := file.get_as_text()
	file.close()
	if DirAccess.make_dir_recursive_absolute(PROFILES_DIR) != OK:
		logger.error("Failed to create gamepad profiles directory")
	var new_file := FileAccess.open(default_global_profile, FileAccess.WRITE)
	new_file.store_string(content)
	new_file.close()


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	input_plumber.composite_device_added.connect(_watch_dbus_device)
	input_plumber.started.connect(_init_inputplumber)
	_init_inputplumber()


func _init_inputplumber() -> void:
	for device in input_plumber.get_composite_devices():
		_watch_dbus_device(device)


func _get_default_profile_path() -> String:
	return "res://assets/gamepad/profiles/default.json"


func get_default_global_profile_path() -> String:
	return "user://data/gamepad/profiles/global_default.json"


## Returns true if the given event is an InputPlumber event
static func is_inputplumber_event(event: InputEvent) -> bool:
	return event.has_meta("dbus_path")


## Returns true if the given action is currently pressed. If InputPlumber is
## not running, then Godot's Input system will be used to check if the action
## is pressed. Otherwise, the input manager will track the state of the action.
func is_action_pressed(action: String) -> bool:
	if not input_plumber.is_running():
		return Input.is_action_pressed(action)
	if not action in self.actions_pressed:
		return false
	return self.actions_pressed[action]


## Queue a release event for the given action
func action_release(dbus_path: String, action: String, strength: float = 1.0) -> void:
	_send_input(dbus_path, action, false, strength)


## Queue a pressed event for the given action
func action_press(dbus_path: String, action: String, strength: float = 1.0) -> void:
	_send_input(dbus_path, action, true, strength)


## Sends an input action to the event queue
func _send_input(dbus_path: String, action: String, pressed: bool, strength: float = 1.0) -> void:
	var input_action := InputEventAction.new()
	input_action.action = action
	input_action.pressed = pressed
	input_action.strength = strength
	input_action.set_meta("dbus_path", dbus_path)
	self.actions_pressed[action] = pressed
	logger.debug("Send input: " + str(input_action))
	Input.parse_input_event(input_action)


## Process all window input. Window input is processed before all _input and
## _gui_input node methods.
## @tutorial https://docs.godotengine.org/en/latest/tutorials/inputs/inputevent.html#how-does-it-work
func _input(event: InputEvent) -> void:
	logger.debug("Got input event to handle: " + str(event))

	# Keep track of the current number of touch inputs
	if event is InputEventScreenTouch:
		if event.is_pressed():
			self.current_touches += 1
		else:
			self.current_touches -= 1

	# Don't process Godot events if InputPlumber is running
	if input_plumber.is_running() and not is_inputplumber_event(event):
		if event is InputEventJoypadButton or event is InputEventJoypadMotion:
			logger.debug("Skipping Godot event while InputPlumber is running:", event)
			get_viewport().set_input_as_handled()
			return

	var dbus_path := event.get_meta("dbus_path", "") as String

	# Consume double inputs for controllers with DPads that have TRIGGER_HAPPY events
	if not input_plumber.is_running():
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

	# If no focus exists and a direction is pressed, try to find a new focus
	if event.is_action("ui_left") or event.is_action("ui_right") or event.is_action("ui_up") or event.is_action("ui_down"):
		if not get_viewport().gui_get_focus_owner():
			logger.debug("Focus lost. Finding something to focus.")
			var new_focus := _find_focus()
			if new_focus:
				logger.debug("Found something to focus:", new_focus)
				new_focus.grab_focus.call_deferred()
				return

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
	if is_action_pressed("ogui_guide"):
		# Prevent ALL input from propagating if guide is held!
		get_viewport().set_input_as_handled()
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
		return

	if event.is_action_pressed("ogui_south"):
		logger.debug("South pressed on its own.")
		action_press(dbus_path, "ui_accept")
	elif event.is_action_released("ogui_south"):
		logger.debug("South released on its own.")
		action_release(dbus_path, "ui_accept")

	if event.is_action_pressed("ogui_north"):
		logger.debug("North pressed on its own.")
		action_press(dbus_path, "ogui_search")
	elif event.is_action_released("ogui_north"):
		logger.debug("North released on its own.")
		action_release(dbus_path, "ogui_search")


## Find a node to grab focus on if no focus exists
func _find_focus() -> Node:
	var main := get_tree().get_first_node_in_group("main")
	if not main:
		logger.debug("Unable to find main node to find focus. Is there a node in the 'main' node group?")
		return null

	return FocusGroup.find_focusable([main])


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
	if is_action_pressed("ogui_guide_action"):
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
	var state := popup_state_machine.current_state()

	if state == main_menu_state:
		popup_state_machine.pop_state()
	elif state in [quick_bar_state, osk_state]:
		popup_state_machine.replace_state(main_menu_state)
	else:
		popup_state_machine.push_state(main_menu_state)


## Handle quick bar menu events to open the quick bar menu
func _on_quick_bar_open(event: InputEvent) -> void:
	# Only act on press events
	if not event.is_pressed():
		return

	var state := popup_state_machine.current_state()
	if state == quick_bar_state:
		popup_state_machine.pop_state()
	elif state in [main_menu_state, in_game_menu_state, osk_state]:
		popup_state_machine.replace_state(quick_bar_state)
	else:
		popup_state_machine.push_state(quick_bar_state)


## Handle OSK events for bringing up the on-screen keyboard
func _osk_input(event: InputEvent) -> void:
	# Only act on press events
	if not event.is_pressed():
		return

	var state := popup_state_machine.current_state()
	if state == osk_state:
		osk.close()
		popup_state_machine.pop_state()
		return

	if state in [main_menu_state, in_game_menu_state, quick_bar_state]:
		popup_state_machine.replace_state(osk_state)
	else:
		popup_state_machine.push_state(osk_state)
	state_machine.push_state(popup_state)

	var context := KeyboardContext.new()
	context.type = KeyboardContext.TYPE.X11
	osk.open(context)


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
	logger.debug("Handling dbus input event from '" + dbus_path + "': " + event + " pressed: " + str(pressed))

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
		"ui_r2":
			action = "ogui_right_trigger"
		"ui_l1":
			action = "ogui_tab_left"
		"ui_l2":
			action = "ogui_left_trigger"

	if pressed:
		action_press(dbus_path, action)
	else:
		action_release(dbus_path, action)
