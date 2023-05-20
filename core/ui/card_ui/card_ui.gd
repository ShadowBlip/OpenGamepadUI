extends Control

const Platform := preload("res://core/global/platform.tres")
const Gamescope := preload("res://core/global/gamescope.tres")
const LibraryManager := preload("res://core/global/library_manager.tres")
const SettingsManager := preload("res://core/global/settings_manager.tres")

var PID: int = OS.get_process_id()
var overlay_window_id = Gamescope.get_window_id(PID, Gamescope.XWAYLAND.OGUI)
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
	boot_video.finished.connect(_on_boot_video_player_finished)
	
	# Load any platform-specific logic
	Platform.load(get_tree().get_root())

	# If this is the first boot, enter the first-boot menu state. Otherwise,
	# go to the home state.
	if SettingsManager.get_value("general", "first_boot", true):
		state_machine.push_state(first_boot_state)
	else:
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
	panel.visible = false
	_set_blur(Gamescope.BLUR_MODE.OFF)
	for child in ui_container.get_children():
		child.visible = false


func _on_game_state_exited(to: State) -> void:
	if state_machine.has_state(in_game_state):
		panel.visible = false
		if to != osk_state:
			_set_blur(Gamescope.BLUR_MODE.ALWAYS)
	else:
		_on_game_state_removed()
	for child in ui_container.get_children():
		child.visible = true


func _on_game_state_removed() -> void:
	_set_blur(Gamescope.BLUR_MODE.OFF)
	panel.visible = true
	if not state_machine.has_state(home_state):
		state_machine.set_state([home_state])


# Sets the blur mode in gamescope
func _set_blur(mode: Gamescope.BLUR_MODE) -> void:
	# Sometimes setting this may fail when Steam closes. Retry several times.
	for try in range(10):
		if Gamescope.set_blur_mode(mode) != OK:
			logger.warn("Unable to set blur mode atom!")
		var current := Gamescope.get_blur_mode()
		if mode == current:
			break
		logger.warn("Retrying in " + str(try) + "ms")
		OS.delay_msec(try)


func _on_boot_video_player_finished() -> void:
	fade_transition.play("fade")
	boot_video.visible = false


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
