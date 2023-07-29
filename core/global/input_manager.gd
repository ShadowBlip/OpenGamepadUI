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

var audio_manager := load("res://core/global/audio_manager.tres") as AudioManager

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


## Returns whether or not get_viewport().set_input_as_handled() should be called
## https://docs.godotengine.org/en/latest/tutorials/inputs/inputevent.html#how-does-it-work
func input(event: InputEvent) -> bool:
	logger.debug("Too much data: " + str(event))
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

	# Audio events
	if event.is_action("ogui_volume_down") or event.is_action("ogui_volume_up") or event.is_action("ogui_volume_mute"):
		_audio_input(event)
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
	logger.debug("Send input: " + str(input_action))
	Input.parse_input_event(input_action)

