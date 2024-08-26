extends Control

var platform := load("res://core/global/platform.tres") as Platform
var gamescope := load("res://core/systems/gamescope/gamescope.tres") as GamescopeInstance
var library_manager := load("res://core/global/library_manager.tres") as LibraryManager
var settings_manager := load("res://core/global/settings_manager.tres") as SettingsManager
var input_plumber := load("res://core/systems/input/input_plumber.tres") as InputPlumberInstance

var state_machine := (
	preload("res://assets/state/state_machines/global_state_machine.tres") as StateMachine
)
var menu_state_machine := preload("res://assets/state/state_machines/menu_state_machine.tres") as StateMachine
var popup_state_machine := preload("res://assets/state/state_machines/popup_state_machine.tres") as StateMachine
var menu_state := preload("res://assets/state/states/menu.tres") as State
var popup_state := preload("res://assets/state/states/popup.tres") as State
var first_boot_state := preload("res://assets/state/states/first_boot_menu.tres") as State
var home_state := preload("res://assets/state/states/home.tres") as State
var in_game_state := preload("res://assets/state/states/in_game.tres") as State
var osk_state := preload("res://assets/state/states/osk.tres") as State
var power_state := preload("res://assets/state/states/power_menu.tres") as State

var PID: int = OS.get_process_id()
var _xwayland_primary := gamescope.get_xwayland(gamescope.XWAYLAND_TYPE_PRIMARY)
var _xwayland_ogui := gamescope.get_xwayland(gamescope.XWAYLAND_TYPE_OGUI)
var overlay_window_id := 0

@onready var panel := $%Panel as Panel
@onready var ui_container := $%MenuContent as MarginContainer
@onready var boot_video := $%BootVideoPlayer as VideoStreamPlayer
@onready var fade_transition := $%FadeTransitionPlayer as AnimationPlayer
@onready var fade_texture := $%FadeTexture as TextureRect
@onready var power_timer := $%PowerTimer as Timer
@onready var settings_menu := $%SettingsMenu as Control

var logger = Log.get_logger("Main", Log.LEVEL.INFO)

func _init() -> void:
	# Discover the window id of OpenGamepadUI
	if _xwayland_ogui:
		var ogui_windows := _xwayland_ogui.get_windows_for_pid(PID)
		if not ogui_windows.is_empty():
			overlay_window_id = ogui_windows[0]
	
	# Tell gamescope that we're an overlay
	if overlay_window_id <= 0:
		logger.error("Unable to detect Window ID. Overlay is not going to work!")
	logger.debug("Found primary window id: {0}".format([overlay_window_id]))
	_setup(overlay_window_id)


# Lets us run as an overlay in gamescope
func _setup(window_id: int) -> void:
	if window_id <= 0:
		logger.error("Unable to configure gamescope atoms")
		return
	# Pretend to be Steam
	# Gamescope is hard-coded to look for appId 769
	if _xwayland_primary.set_main_app(window_id) != OK:
		logger.error("Unable to set STEAM_GAME atom!")
	# Sets ourselves to the input focus
	if _xwayland_primary.set_input_focus(window_id, 1) != OK:
		logger.error("Unable to set STEAM_INPUT_FOCUS atom!")


# Called when the node enters the scene tree for the first time.
# gamescope --xwayland-count 2 -- build/opengamepad-ui.x86_64
func _ready() -> void:
	# Set bg to transparent
	get_tree().get_root().transparent_bg = true
	fade_texture.visible = true
	boot_video.finished.connect(_on_boot_video_player_finished)

	# Configure the locale
	var locale := settings_manager.get_value("general", "locale", "en_US") as String
	TranslationServer.set_locale(locale)

	# Load any platform-specific logic
	platform.load(get_tree().get_root())

	# Set the FPS limit
	Engine.max_fps = settings_manager.get_value("general", "max_fps", 60) as int

	# Always push the menu state if we end up with an empty stack.
	var on_states_emptied := func():
		state_machine.push_state.call_deferred(menu_state)
	state_machine.emptied.connect(on_states_emptied)

	# Whenever the menu state is refreshed, refresh the menu state machine to
	# re-grab focus.
	var on_menu_refreshed := func():
		menu_state_machine.refresh()
	menu_state.refreshed.connect(on_menu_refreshed)

	# Whenever the menu state is entered, refresh the menu state machine to
	# re-grab focus
	var on_menu_state_entered := func(_from: State):
		menu_state_machine.refresh()
	menu_state.state_entered.connect(on_menu_state_entered)
	var on_menu_state_removed := func():
		menu_state_machine.clear_states()
	menu_state.state_removed.connect(on_menu_state_removed)
	var on_menu_states_empty := func():
		state_machine.remove_state(menu_state)
	menu_state_machine.emptied.connect(on_menu_states_empty)

	# Whenever an popup state is pushed, update the global state
	var on_popup_state_changed := func(_from: State, to: State):
		if to:
			state_machine.push_state(popup_state)
		else:
			state_machine.remove_state(popup_state)
	popup_state_machine.state_changed.connect(on_popup_state_changed)

	# Show/hide the overlay when we enter/exit the in-game state
	in_game_state.state_entered.connect(_on_game_state_entered)
	in_game_state.state_exited.connect(_on_game_state_exited)
	in_game_state.state_removed.connect(_on_game_state_removed)

	get_viewport().gui_focus_changed.connect(_on_focus_changed)
	library_manager.reload_library()

	# Set the initial intercept mode
	input_plumber.set_intercept_mode(InputPlumberInstance.INTERCEPT_MODE_ALL)
	#var on_device_changed := func(device: CompositeDevice):
	#	var intercept_mode := input_plumber.intercept_mode
	#	logger.debug("Setting intercept mode to: " + str(intercept_mode))
	#	device.intercept_mode = intercept_mode
	## TODO: Do we still need this..?
	#input_plumber.composite_device_changed.connect(on_device_changed)

	# Set the theme if one was set
	var theme_path := settings_manager.get_value("general", "theme", "res://assets/themes/card_ui-dracula.tres") as String
	logger.debug("Setting theme to: " + theme_path)
	var loaded_theme = load(theme_path)
	if loaded_theme != null:
		@warning_ignore("unsafe_call_argument")
		set_theme(loaded_theme)
	else:
		logger.debug("Unable to load theme")


func _on_focus_changed(control: Control) -> void:
	if control != null:
		logger.debug("Focus changed to: " + control.get_parent().name + " | " + control.name)


## Invoked when the in-game state was entered
func _on_game_state_entered(_from: State) -> void:
	# Pass all gamepad input to the game
	input_plumber.set_intercept_mode(InputPlumberInstance.INTERCEPT_MODE_PASS)

	# Turn off gamescope blur effect
	_set_blur(GamescopeXWayland.BLUR_MODE_OFF)

	# Set gamescope input focus to off so the user can interact with the game
	if _xwayland_ogui and _xwayland_ogui.set_input_focus(overlay_window_id, 0) != OK:
		logger.error("Unable to set STEAM_INPUT_FOCUS atom!")

	# Ensure panel is invisible
	panel.visible = false
	for child in ui_container.get_children():
		if not child is Control:
			continue
		(child as Control).visible = false

	# Clear all menu states
	menu_state_machine.clear_states()


## Invoked when the in-game state is exited
func _on_game_state_exited(to: State) -> void:
	# Intercept all gamepad input when not in-game
	input_plumber.set_intercept_mode(InputPlumberInstance.INTERCEPT_MODE_ALL)

	# Revert back to the default gamepad profile
	#gamepad_manager.set_gamepads_profile(null)

	# Set gamescope input focus to on so the user can interact with the UI
	if to == popup_state:
		var current_popup := popup_state_machine.current_state()
		if current_popup == osk_state:
			return

	if _xwayland_primary:
		if _xwayland_primary.set_input_focus(overlay_window_id, 1) != OK:
			logger.error("Unable to set STEAM_INPUT_FOCUS atom!")

	# If the in-game state still exists in the stack, set the blur state.
	if state_machine.has_state(in_game_state):
		panel.visible = false
		# Only blur if the focused GFX app is set
		if _xwayland_primary:
			var should_blur := settings_manager.get_value("display", "enable_overlay_blur", true) as bool
			if should_blur and _xwayland_primary.get_focused_app_gfx() != gamescope.OVERLAY_GAME_ID:
				_set_blur(GamescopeXWayland.BLUR_MODE_ALWAYS)

	else:
		_on_game_state_removed()

	# Un-hide all UI elements
	for child in ui_container.get_children():
		if not child is Control:
			continue
		(child as Control).visible = true


## Invoked when the in-game state is removed
func _on_game_state_removed() -> void:
	# Turn off gamescope blur
	_set_blur(GamescopeXWayland.BLUR_MODE_OFF)

	# Un-hide the background panel
	panel.visible = true

	# Reset the state stack if no menu state exists
	if not state_machine.has_state(menu_state):
		state_machine.set_state([menu_state])
	if not menu_state_machine.has_state(home_state):
		menu_state_machine.set_state([home_state])


# Sets the blur mode in gamescope
func _set_blur(mode: int) -> void:
	# Sometimes setting this may fail when Steam closes. Retry several times.
	for try in range(10):
		if _xwayland_primary:
			_xwayland_primary.set_blur_mode(mode)
		var current := _xwayland_primary.get_blur_mode()
		if mode == current:
			break
		logger.warn("Retrying in " + str(try) + "ms")
		OS.delay_msec(try)


## Invoked when the boot video finishes playing
func _on_boot_video_player_finished() -> void:
	fade_transition.play("fade")
	boot_video.visible = false

	# Set the initial global state
	state_machine.push_state(menu_state)

	# If this is the first boot, enter the first-boot menu state. Otherwise,
	# go to the home state.
	if settings_manager.get_value("general", "first_boot", true):
		menu_state_machine.push_state(first_boot_state)
	else:
		# Initialize the state machine with its initial state
		menu_state_machine.push_state(home_state)


## Called when any unhandled input reaches the main node
func _input(event: InputEvent) -> void:
	if not event.is_action("ogui_power"):
		return

	# Handle power events
	if event.is_action_pressed("ogui_power"):
		var open_power_menu := func():
			logger.info("Power menu requested")
			popup_state_machine.push_state(power_state)
		power_timer.timeout.connect(open_power_menu, CONNECT_ONE_SHOT)
		power_timer.start()
		return

	# Handle suspend events
	if not power_timer.is_stopped():
		logger.info("Received suspend signal")
		for connection in power_timer.timeout.get_connections():
			power_timer.timeout.disconnect(connection["callable"] as Callable)
		power_timer.stop()
		var output: Array = []
		if OS.execute("systemctl", ["suspend"], output) != OK:
			logger.warn("Failed to suspend: '" + output[0] + "'")


# Removes specified child elements from the given Node.
func _remove_children(remove_list: PackedStringArray, parent: Node) -> void:
	var child_count := parent.get_child_count()
	var to_remove_list: Array[Node]

	for child_idx in child_count:
		var child := parent.get_child(child_idx)
		logger.trace("Checking if " + child.name + " in remove list...")
		if child.name in remove_list:
			logger.trace(child.name + " queued for removal!")
			to_remove_list.append(child)
			continue

		logger.trace(child.name + " is not a node we are looking for.")
		var grandchild_count := child.get_child_count()
		if grandchild_count > 0:
			logger.trace("Checking " + child.name + "'s children...")
			_remove_children(remove_list, child)

	for child in to_remove_list:
		logger.trace("Removing " + child.name)
		child.queue_free()
