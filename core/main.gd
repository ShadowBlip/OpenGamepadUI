extends Control
class_name Main

const Gamescope := preload("res://core/global/gamescope.tres")
const LibraryManager := preload("res://core/global/library_manager.tres")

var PID: int = OS.get_process_id()
var overlay_window_id = Gamescope.get_window_id(PID, Gamescope.XWAYLAND.OGUI)
var state_machine := (
	preload("res://assets/state/state_machines/global_state_machine.tres") as StateMachine
)
var home_state := preload("res://assets/state/states/home.tres") as State
var in_game_state := preload("res://assets/state/states/in_game.tres") as State
var logger = Log.get_logger("Main", Log.LEVEL.DEBUG)

@onready var ui_container := $UIContainer
@onready var fade_transition := $%FadeTransitionPlayer
@onready var fade_texture := $FadeTexture


func _init() -> void:
	# Tell gamescope that we're an overlay
	if overlay_window_id < 0:
		logger.error("Unable to detect Window ID. Overlay is not going to work!")
	logger.debug("Found primary window id: {0}".format([overlay_window_id]))
	_setup(overlay_window_id)


# Lets us run as an overlay in gamescope
func _setup(window_id: int) -> void:
	if window_id < 0:
		logger.error("Unable to configure gamescope atoms")
		return
	# Pretend to be Steam
	# Gamescope is hard-coded to look for appId 769
	if Gamescope.set_main_app(window_id) != OK:
		logger.error("Unable to set STEAM_GAME atom!")
	# Sets ourselves to the input focus
	if Gamescope.set_input_focus(window_id, 1) != OK:
		logger.error("Unable to set STEAM_INPUT_FOCUS atom!")


# Called when the node enters the scene tree for the first time.
# gamescope --xwayland-count 2 -- build/opengamepad-ui.x86_64
func _ready() -> void:
	# Set bg to transparent
	get_tree().get_root().transparent_bg = true
	fade_texture.visible = true

	# Initialize the state machine with its initial state
	state_machine.push_state(home_state)
	state_machine.state_changed.connect(_on_state_changed)

	# Show/hide the overlay when we enter/exit the in-game state
	in_game_state.state_entered.connect(_on_game_state_entered)
	in_game_state.state_exited.connect(_on_game_state_exited)
	in_game_state.state_removed.connect(_on_game_state_removed)

	get_viewport().gui_focus_changed.connect(_on_focus_changed)
	LibraryManager.reload_library()


func _on_focus_changed(control: Control) -> void:
	if control != null:
		logger.debug("Focus changed to: " + control.get_parent().name + " | " + control.name)


# Always push the home state if we end up with an empty stack.
func _on_state_changed(_from: State, _to: State) -> void:
	if state_machine.stack_length() == 0:
		state_machine.push_state.call_deferred(home_state)


func _on_game_state_entered(_from: State) -> void:
	Gamescope.set_blur_mode(Gamescope.BLUR_MODE.OFF)
	_set_overlay(false)
	for child in ui_container.get_children():
		child.visible = false


func _on_game_state_exited(_to: State) -> void:
	if state_machine.has_state(in_game_state):
		Gamescope.set_blur_mode(Gamescope.BLUR_MODE.ALWAYS)
		_set_overlay(true)
	else:
		_on_game_state_removed()
	for child in ui_container.get_children():
		child.visible = true


func _on_game_state_removed() -> void:
	Gamescope.set_blur_mode(Gamescope.BLUR_MODE.OFF)
	_set_overlay(false)


# Set overlay will set the Gamescope atom to indicate that we should be drawn
# over a running game or not.
func _set_overlay(enable: bool) -> void:
	var overlay_enabled = 0
	if enable:
		overlay_enabled = 1
	Gamescope.set_overlay(overlay_window_id, overlay_enabled)


func _on_boot_video_player_finished() -> void:
	fade_transition.play("fade")
