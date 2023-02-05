extends Control
class_name Main

var DISPLAY: String = OS.get_environment("DISPLAY")
var PID: int = OS.get_process_id()
var overlay_display = DISPLAY
var overlay_window_id = Gamescope.get_window_id(DISPLAY, PID)
var state_machine := preload("res://assets/state/state_machines/global_state_machine.tres") as StateMachine
var home_state := preload("res://assets/state/states/home.tres") as State
var osk_state := preload("res://assets/state/states/osk.tres") as State
var in_game_state := preload("res://assets/state/states/in_game.tres") as State
var logger = Log.get_logger("Main", Log.LEVEL.DEBUG)

@onready var ui_container := $UIContainer
@onready var osk := $OnScreenKeyboard as OnScreenKeyboard
@onready var fade_transition := $%FadeTransitionPlayer
@onready var fade_texture := $FadeTexture

func _init() -> void:
	# Tell gamescope that we're an overlay
	if overlay_window_id < 0:
		logger.error("Unable to detect Window ID. Overlay is not going to work!")
	logger.debug("Found primary X display: " + DISPLAY)
	logger.debug("Found primary window id: {0}".format([overlay_window_id]))
	_setup(overlay_window_id)


func _on_focus_changed(control:Control) -> void:
	if control != null:
		logger.debug("Focus changed to: " + control.get_parent().name + " | " + control.name)


# Lets us run as an overlay in gamescope
func _setup(window_id: int) -> void:
	if window_id < 0:
		logger.error("Unable to configure gamescope atoms")
		return
	# Pretend to be Steam
	# Gamescope is hard-coded to look for appId 769
	if Gamescope.set_main_app(DISPLAY, window_id) != OK:
		logger.error("Unable to set STEAM_GAME atom!")
	# Sets ourselves to the input focus
	if Gamescope.set_input_focus(DISPLAY, window_id, 1) != OK:
		logger.error("Unable to set STEAM_INPUT_FOCUS atom!")
	# Set some WM_HINTS
	if Xlib.set_wm_hints(DISPLAY, window_id) != OK:
		logger.error("Unable to set WM_HINTS!")


# Called when the node enters the scene tree for the first time.
# gamescope --xwayland-count 2 -- build/opengamepad-ui.x86_64
func _ready() -> void:
	# Set bg to transparent
	logger.debug("ID: {0}".format([Gamescope.get_window_id(DISPLAY, PID)]))
	get_tree().get_root().transparent_bg = true
	fade_texture.visible = true
	
	# Initialize the state machine with its initial state
	state_machine.push_state(home_state)
	state_machine.state_changed.connect(_on_state_changed)
	
	# Show/hide the overlay when we enter/exit the in-game state
	in_game_state.state_entered.connect(_on_game_state_entered)
	in_game_state.state_exited.connect(_on_game_state_exited)
	in_game_state.state_removed.connect(_on_game_state_removed)
	
	# Configure the OSK with the state machine
	var on_osk_opened := func():
		state_machine.push_state(osk_state)
	osk.keyboard_opened.connect(on_osk_opened)
	var on_osk_closed := func():
		state_machine.remove_state(osk_state)
	
	# Wire all search bars to the on-screen keyboard
	for b in get_tree().get_nodes_in_group("search_bar"):
		var search_bar := b as SearchBar
		var on_keyboard_requested := func():
			var context := KeyboardContext.new()
			context.type = KeyboardContext.TYPE.GODOT
			context.target = search_bar
			context.close_on_submit = true
			osk.open(context)
		search_bar.keyboard_requested.connect(on_keyboard_requested)

	get_viewport().gui_focus_changed.connect(_on_focus_changed)

# Always push the home state if we end up with an empty stack.
func _on_state_changed(from: State, to: State) -> void:
	if state_machine.stack_length() == 0:
		state_machine.push_state.call_deferred(home_state)


func _on_game_state_entered(_from: State) -> void:
	Gamescope.set_blur_mode(DISPLAY, Gamescope.BLUR_MODE.OFF)
	_set_overlay(false)
	for child in ui_container.get_children():
		child.visible = false


func _on_game_state_exited(_to: State) -> void:
	if state_machine.has_state(in_game_state):
		Gamescope.set_blur_mode(DISPLAY, Gamescope.BLUR_MODE.ALWAYS)
		_set_overlay(true)
	else:
		_on_game_state_removed()
	for child in ui_container.get_children():
		child.visible = true


func _on_game_state_removed() -> void:
	Gamescope.set_blur_mode(DISPLAY, Gamescope.BLUR_MODE.OFF)
	_set_overlay(false)


# Set overlay will set the Gamescope atom to indicate that we should be drawn
# over a running game or not.
func _set_overlay(enable: bool) -> void:
	var overlay_enabled = 0
	if enable:
		overlay_enabled = 1
	Gamescope.set_overlay(DISPLAY, overlay_window_id, overlay_enabled)


func _on_boot_video_player_finished() -> void:
	fade_transition.play("fade")

