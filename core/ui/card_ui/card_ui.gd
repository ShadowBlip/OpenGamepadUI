extends Control

var PID: int = OS.get_process_id()
var platform := load("res://core/global/platform.tres") as Platform
var gamescope := load("res://core/global/gamescope.tres") as Gamescope
var library_manager := load("res://core/global/library_manager.tres") as LibraryManager
var settings_manager := load("res://core/global/settings_manager.tres") as SettingsManager
var gamepad_manager := load("res://core/systems/input/gamepad_manager.tres") as GamepadManager

var overlay_window_id = gamescope.get_window_id(PID, gamescope.XWAYLAND.OGUI)
var state_machine := (
	preload("res://assets/state/state_machines/global_state_machine.tres") as StateMachine
)
var first_boot_state := preload("res://assets/state/states/first_boot_menu.tres") as State
var home_state := preload("res://assets/state/states/home.tres") as State
var in_game_state := preload("res://assets/state/states/in_game.tres") as State
var osk_state := preload("res://assets/state/states/osk.tres") as State
var power_state := load("res://assets/state/states/power_menu.tres") as State
var logger = Log.get_logger("Main", Log.LEVEL.INFO)

@onready var panel := $%Panel
@onready var ui_container := $%MenuContent
@onready var boot_video := $%BootVideoPlayer
@onready var fade_transition := $%FadeTransitionPlayer
@onready var fade_texture := $%FadeTexture
@onready var power_timer := $%PowerTimer


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
	if gamescope.set_main_app(window_id) != OK:
		logger.error("Unable to set STEAM_GAME atom!")
	# Sets ourselves to the input focus
	if gamescope.set_input_focus(window_id, 1) != OK:
		logger.error("Unable to set STEAM_INPUT_FOCUS atom!")


# Called when the node enters the scene tree for the first time.
# gamescope --xwayland-count 2 -- build/opengamepad-ui.x86_64
func _ready() -> void:
	# Set bg to transparent
	get_tree().get_root().transparent_bg = true
	fade_texture.visible = true
	boot_video.finished.connect(_on_boot_video_player_finished)
	
	# Load any platform-specific logic
	platform.load(get_tree().get_root())
	
	# Set the theme if one was set
	var theme_path := settings_manager.get_value("general", "theme", "") as String
	if theme_path == "":
		logger.debug("No theme set. Using default theme.")
	if theme_path != "":
		logger.debug("Setting theme to: " + theme_path)
		var loaded_theme = load(theme_path)
		if loaded_theme != null:
			theme = loaded_theme
		else:
			logger.debug("Unable to load theme")
	
	# Set the FPS limit
	Engine.max_fps = settings_manager.get_value("general", "max_fps", 60) as int
	
	# Listen for global state changes
	state_machine.state_changed.connect(_on_state_changed)
	
	# Show/hide the overlay when we enter/exit the in-game state
	in_game_state.state_entered.connect(_on_game_state_entered)
	in_game_state.state_exited.connect(_on_game_state_exited)
	in_game_state.state_removed.connect(_on_game_state_removed)

	get_viewport().gui_focus_changed.connect(_on_focus_changed)
	library_manager.reload_library()


func _on_focus_changed(control: Control) -> void:
	if control != null:
		logger.debug("Focus changed to: " + control.get_parent().name + " | " + control.name)


# Always push the home state if we end up with an empty stack.
func _on_state_changed(_from: State, _to: State) -> void:
	if state_machine.stack_length() == 0:
		state_machine.push_state.call_deferred(home_state)


## Invoked when the in-game state was entered
func _on_game_state_entered(_from: State) -> void:
	# Pass all gamepad input to the game
	gamepad_manager.set_intercept(ManagedGamepad.INTERCEPT_MODE.PASS)

	# Turn off gamescope blur effect
	_set_blur(gamescope.BLUR_MODE.OFF)
	
	# Set gamescope input focus to off so the user can interact with the game
	if gamescope.set_input_focus(overlay_window_id, 0) != OK:
		logger.error("Unable to set STEAM_INPUT_FOCUS atom!")
	
	# Ensure panel is invisible
	panel.visible = false
	for child in ui_container.get_children():
		child.visible = false


## Invoked when the in-game state is exited
func _on_game_state_exited(to: State) -> void:
	# Intercept all gamepad input when not in-game
	gamepad_manager.set_intercept(ManagedGamepad.INTERCEPT_MODE.ALL)
	
	# Revert back to the default gamepad profile
	gamepad_manager.set_gamepads_profile(null)
	
	# Set gamescope input focus to on so the user can interact with the UI
	if gamescope.set_input_focus(overlay_window_id, 1) != OK:
		logger.error("Unable to set STEAM_INPUT_FOCUS atom!")
	
	# If the in-game state still exists in the stack, set the blur state.
	if state_machine.has_state(in_game_state):
		panel.visible = false
		if to != osk_state:
			_set_blur(gamescope.BLUR_MODE.ALWAYS)
	else:
		_on_game_state_removed()
	
	# Un-hide all UI elements
	for child in ui_container.get_children():
		child.visible = true


## Invoked when the in-game state is removed
func _on_game_state_removed() -> void:
	# Turn off gamescope blur
	_set_blur(gamescope.BLUR_MODE.OFF)
	
	# Un-hide the background panel
	panel.visible = true
	
	# Reset the state stack if no home state exists
	if not state_machine.has_state(home_state):
		state_machine.set_state([home_state])


# Sets the blur mode in gamescope
func _set_blur(mode: Gamescope.BLUR_MODE) -> void:
	# Sometimes setting this may fail when Steam closes. Retry several times.
	for try in range(10):
		if gamescope.set_blur_mode(mode) != OK:
			logger.warn("Unable to set blur mode atom!")
		var current := gamescope.get_blur_mode()
		if mode == current:
			break
		logger.warn("Retrying in " + str(try) + "ms")
		OS.delay_msec(try)


## Invoked when the boot video finishes playing
func _on_boot_video_player_finished() -> void:
	fade_transition.play("fade")
	boot_video.visible = false

	# If this is the first boot, enter the first-boot menu state. Otherwise,
	# go to the home state.
	if settings_manager.get_value("general", "first_boot", true):
		state_machine.push_state(first_boot_state)
	else:
		# Initialize the state machine with its initial state
		state_machine.push_state(home_state)


## Called when any unhandled input reaches the main node
func _input(event: InputEvent) -> void:
	if not event.is_action("ogui_power"):
		return

	# Handle power events
	if event.is_action_pressed("ogui_power"):
		var open_power_menu := func():
			logger.info("Power menu requested")
			state_machine.push_state(power_state)
		power_timer.timeout.connect(open_power_menu, CONNECT_ONE_SHOT)
		power_timer.start()
		return

	# Handle suspend events
	if not power_timer.is_stopped():
		logger.info("Received suspend signal")
		for connection in power_timer.timeout.get_connections():
			power_timer.timeout.disconnect(connection["callable"])
		power_timer.stop()
		var output: Array = []
		if OS.execute("systemctl", ["suspend"], output) != OK:
			logger.warn("Failed to suspend: '" + output[0] + "'")
