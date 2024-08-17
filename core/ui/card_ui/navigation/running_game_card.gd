@tool
extends Container

signal pressed
signal button_up
signal button_down
signal toggled(pressed: bool)
signal toggled_on
signal toggled_off
signal finished_growing
signal finished_shrinking

const Gamescope := preload("res://core/global/gamescope.tres")

var launch_manager := load("res://core/global/launch_manager.tres") as LaunchManager
var boxart_manager := load("res://core/global/boxart_manager.tres") as BoxArtManager
var library_manager := load("res://core/global/library_manager.tres") as LibraryManager
var state_machine := load("res://assets/state/state_machines/global_state_machine.tres") as StateMachine
var in_game_state := load("res://assets/state/states/in_game.tres") as State
var button_scene := load("res://core/ui/components/card_button.tscn") as PackedScene

@export_category("Card")
@export var is_toggled := false

@onready var content_container := $%ContentContainer
@onready var game_logo := $%GameLogo
@onready var game_label := $%GameLabel
@onready var resume_button := $%ResumeButton as CardButton
@onready var suspend_button := $%SuspendButton as CardButton
@onready var exit_button := $%ExitButton as CardButton
@onready var highlight_rect := $%HighlightTextureRect
@onready var focus_group := $%FocusGroup as FocusGroup

var tween: Tween
var running_app: RunningApp
var window_buttons := {}
var logger := Log.get_logger("RunningGameCard", Log.LEVEL.INFO)


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if Engine.is_editor_hint():
		return

	focus_entered.connect(_on_focus)
	focus_exited.connect(_on_unfocus)
	pressed.connect(_on_pressed)
	theme_changed.connect(_on_theme_changed)

	# Find the parent theme and update if required
	var effective_theme := ThemeUtils.get_effective_theme(self)
	if effective_theme:
		_on_theme_changed()

	# Auto-close when visibility is lost
	var on_visibility_changed := func():
		var grower := get_node("GrowerEffect") as GrowerEffect
		grower.shrink()
		is_toggled = false
	hidden.connect(on_visibility_changed)

	# Connect sub-buttons
	var on_resume_game := func():
		state_machine.set_state([in_game_state])
	resume_button.pressed.connect(on_resume_game)
	var on_exit_game := func():
		# TODO: Handle this better
		launch_manager.stop(running_app)
		state_machine.pop_state()
	exit_button.pressed.connect(on_exit_game)
	var on_suspend := func():
		running_app.suspend(not running_app.is_suspended)
		if running_app.is_suspended:
			suspend_button.text = "Continue"
		else:
			suspend_button.text = "Suspend"
	suspend_button.pressed.connect(on_suspend)


func _on_theme_changed() -> void:
	# Configure the highlight texture from the theme
	var highlight_texture := get_theme_icon("highlight", "ExpandableCard")
	if highlight_texture:
		highlight_rect.texture = highlight_texture


# Sets the running app for this card
func set_running_app(app: RunningApp):
	if not app:
		return
	running_app = app
	var item := library_manager.get_app_by_name(app.launch_item.name)
	game_logo.visible = false
	game_label.visible = false
	var logo := await boxart_manager.get_boxart(item, BoxArtProvider.LAYOUT.LOGO) as Texture2D
	if logo != null:
		game_logo.texture = logo
		game_logo.visible = true
	else:
		game_label.visible = true
		game_label.text = item.name
	
	# Connect to app signals to allow switching between app windows
	var on_windows_changed := func(_from: PackedInt32Array, to: PackedInt32Array):
		var focusable_windows := Gamescope.get_focusable_windows()
		# Add a button to switch to a given window
		for window_id in to:
			# A button already exists for this window
			if window_id in window_buttons:
				continue
			if not window_id in focusable_windows:
				continue
			var window_name := app.get_window_title(window_id)
			if window_name == "":
				continue
			var button := button_scene.instantiate() as CardButton
			button.text = window_name
			button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			window_buttons[window_id] = button
			content_container.add_child(button)
			content_container.move_child(button, 1)
			
			# Switch app window when the button is pressed
			var on_pressed := func():
				app.switch_window(window_id)
			button.button_up.connect(on_pressed)
		
		# Remove buttons for windows that don't exist anymore
		for window_id in window_buttons.keys():
			if window_id in to:
				continue
			var button := window_buttons[window_id] as Control
			button.queue_free()
			window_buttons.erase(window_id)

	app.window_ids_changed.connect(on_windows_changed)


func _on_focus() -> void:
	# If the card gets focused, and its already expanded, that means we've
	# the user has focused outside the card, and we should shrink to hide the
	# content
	if is_toggled:
		_on_pressed()


func _on_unfocus() -> void:
	# If a child focus group is focused, don't do anything. That means that
	if not focus_group:
		logger.warn("No focus group defined!")
		return

	# a child node is focused and we want the card to remain "selected"
	if focus_group.is_in_focus_stack():
		return


func _on_pressed() -> void:
	is_toggled = !is_toggled
	if is_toggled:
		toggled_on.emit()
	else:
		toggled_off.emit()
	
	toggled.emit(is_toggled)


func _gui_input(event: InputEvent) -> void:
	if event.is_action("ui_accept"):
		if event.is_pressed():
			button_down.emit()
			pressed.emit()
		else:
			button_up.emit()
