extends Control

var platform := preload("res://core/global/platform.tres") as Platform
var gamescope := load("res://core/systems/gamescope/gamescope.tres") as GamescopeInstance
var input_plumber := load("res://core/systems/input/input_plumber.tres") as InputPlumberInstance
var boxart_manager := preload("res://core/global/boxart_manager.tres") as BoxArtManager
var settings_manager := preload("res://core/global/settings_manager.tres") as SettingsManager
var launch_manager := preload("res://core/global/launch_manager.tres") as LaunchManager
var library_manager := preload("res://core/global/library_manager.tres") as LibraryManager

var state_machine := preload("res://assets/state/state_machines/global_state_machine.tres") as StateMachine
var menu_state_machine := preload("res://assets/state/state_machines/menu_state_machine.tres") as StateMachine
var popup_state_machine := preload("res://assets/state/state_machines/popup_state_machine.tres") as StateMachine
var menu_state := preload("res://assets/state/states/menu.tres") as State
var popup_state := preload("res://assets/state/states/popup.tres") as State
var home_state := preload("res://assets/state/states/home.tres") as State
var in_game_state := preload("res://assets/state/states/in_game.tres") as State
var osk_state := preload("res://assets/state/states/osk.tres") as State
var default_banner := preload("res://assets/images/starfield.svg") as Texture2D

var PID: int = OS.get_process_id()
var _tween: Tween
var _xwayland_primary := gamescope.get_xwayland(gamescope.XWAYLAND_TYPE_PRIMARY)
var _xwayland_ogui := gamescope.get_xwayland(gamescope.XWAYLAND_TYPE_OGUI)
var _xwayland_game := gamescope.get_xwayland(gamescope.XWAYLAND_TYPE_GAME)
var overlay_window_id := 0
var logger := Log.get_logger("Home", Log.LEVEL.INFO)

@onready var home_menu := %Home
@onready var banner := %BannerTexture as TextureRect
@onready var panel := %Panel as Panel
@onready var ui_container := $%MenuContent as Control


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

	if overlay_window_id <= 0:
		logger.error("Unable to configure gamescope atoms")
		return
	# Pretend to be Steam
	# Gamescope is hard-coded to look for appId 769
	if _xwayland_primary.set_main_app(overlay_window_id) != OK:
		logger.error("Unable to set STEAM_GAME atom!")
	# Sets ourselves to the input focus
	if _xwayland_primary.set_input_focus(overlay_window_id, 1) != OK:
		logger.error("Unable to set STEAM_INPUT_FOCUS atom!")

	# As of Gamescope v3.16.3+, the baselayer atom needs to be set at the start
	_xwayland_primary.baselayer_window = 0
	_xwayland_primary.baselayer_apps = PackedInt64Array([GamescopeInstance.EXTRA_UNKNOWN_GAME_ID, GamescopeInstance.OVERLAY_GAME_ID])

	# Override reserved app ids for any newly created windows
	# Listen for window created/destroyed events
	var on_window_created := func(window_id: int):
		logger.debug("Window created:", window_id)
		var try := 0
		while try < 10:
			if _xwayland_game.has_app_id(window_id):
				break
			try += 1
			await get_tree().create_timer(0.2).timeout # wait a beat
		var app_id := _xwayland_game.get_app_id(window_id)
		if app_id == GamescopeInstance.OVERLAY_GAME_ID:
			# Find the current running app and use that app id
			var running := launch_manager.get_running()
			running.reverse()
			for app in running:
				_xwayland_game.set_app_id(window_id, app.app_id)
				return
			logger.warn("Unable to find a running app to tie Steam to")
			_xwayland_game.set_app_id(window_id, 7769)
	_xwayland_game.window_created.connect(on_window_created)


func _ready() -> void:
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

	# Initialize the state machine with its initial state
	menu_state_machine.push_state(home_state)

	# Listen for changes to the selected game tile on the home menu to update the
	# banner texture
	var game_carousel := home_menu.get_node("%CarouselContainer") as CarouselContainer
	game_carousel.child_selected.connect(_on_tile_selected)

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
	library_manager.reload_library()

	# Enable InputPlumber management of all supported input devices
	input_plumber.manage_all_devices = true

	# Setup inputplumber to receive guide presses.
	input_plumber.set_intercept_mode(InputPlumberInstance.INTERCEPT_MODE_ALL)
	input_plumber.set_intercept_activation(PackedStringArray(["Gamepad:Button:Guide"]), "Gamepad:Button:Guide")

	# Set the theme if one was set
	var theme_path := settings_manager.get_value("general", "theme", "res://assets/themes/card_ui-darksoul.tres") as String
	logger.debug("Setting theme to: " + theme_path)
	var loaded_theme = load(theme_path)
	if loaded_theme != null:
		@warning_ignore("unsafe_call_argument")
		set_theme(loaded_theme)
	else:
		logger.debug("Unable to load theme")


# Set the background based on selected game
func _on_tile_selected(node: Node) -> void:
	if not node is GameTile:
		return
	var tile := node as GameTile
	var texture: Texture2D
	if tile.is_library_tile:
		texture = default_banner
	elif tile.library_item:
		texture = await boxart_manager.get_boxart(tile.library_item, BoxArtProvider.LAYOUT.BANNER)

	if not texture:
		texture = default_banner

	if _tween:
		_tween.kill()
	_tween = create_tween()
	banner.modulate = Color(1, 1, 1, 0)
	banner.texture = texture
	_tween.tween_property(banner, "modulate", Color(1, 1, 1, 0.5), 1.2)


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
	banner.visible = false
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
			var should_blur := settings_manager.get_value("display", "enable_overlay_blur", false) as bool
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
	if not _xwayland_primary:
		return
	# Sometimes setting this may fail when Steam closes. Retry several times.
	for try in range(10):
		if _xwayland_primary:
			_xwayland_primary.set_blur_mode(mode)
		var current := _xwayland_primary.get_blur_mode()
		if mode == current:
			break
		logger.warn("Retrying in " + str(try) + "ms")
		OS.delay_msec(try)
