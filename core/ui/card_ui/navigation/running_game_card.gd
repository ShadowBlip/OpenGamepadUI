@tool
extends Container

signal pressed
signal button_up
signal button_down
signal toggled(pressed: bool)
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

@export_category("Animation")
@export var highlight_speed := 0.1

@export_category("AudioSteamPlayer")
@export_file("*.ogg") var focus_audio = "res://assets/audio/interface/glitch_004.ogg"
@export_file("*.ogg") var select_audio = "res://assets/audio/interface/select_002.ogg"


@onready var separator := $%HSeparator
@onready var content_container := $%ContentContainer
@onready var game_logo := $%GameLogo
@onready var game_label := $%GameLabel
@onready var resume_button := $%ResumeButton
@onready var exit_button := $%ExitButton
@onready var highlight := $%HighlightTexture 
@onready var inside_panel := $%InsidePanel
@onready var focus_group := $%FocusGroup as FocusGroup

var tween: Tween
var highlight_tween: Tween
var running_app: RunningApp
var focus_audio_stream = load(focus_audio)
var select_audio_stream = load(select_audio)
var window_buttons := {}
var logger := Log.get_logger("RunningGameCard", Log.LEVEL.INFO)


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	focus_entered.connect(_on_focus)
	focus_exited.connect(_on_unfocus)
	pressed.connect(_on_pressed)
	
	# Connect sub-buttons
	var on_resume_game := func():
		state_machine.set_state([in_game_state])
	resume_button.pressed.connect(on_resume_game)
	var on_exit_game := func():
		# TODO: Handle this better
		launch_manager.stop(running_app)
		state_machine.pop_state()
	exit_button.pressed.connect(on_exit_game)


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
	_highlight()
	
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
	
	_unhighlight()


func _highlight() -> void:
	if highlight_tween:
		highlight_tween.kill()
	highlight_tween = get_tree().create_tween()
	highlight_tween.tween_property(highlight, "visible", true, 0)
	highlight_tween.tween_property(highlight, "modulate", Color(1, 1, 1, 0), 0)
	highlight_tween.tween_property(highlight, "modulate", Color(1, 1, 1, 1), highlight_speed)
	_play_sound(focus_audio_stream)
	
	
func _unhighlight() -> void:
	if highlight_tween:
		highlight_tween.kill()
	highlight_tween = get_tree().create_tween()
	highlight_tween.tween_property(highlight, "modulate", Color(1, 1, 1, 1), 0)
	highlight_tween.tween_property(highlight, "modulate", Color(1, 1, 1, 0), highlight_speed)
	highlight_tween.tween_property(highlight, "visible", false, 0)


func _on_pressed() -> void:
	is_toggled = !is_toggled
	if is_toggled:
		_grow()
	else:
		_shrink()
	
	toggled.emit(is_toggled)


func _grow() -> void:
	if tween:
		tween.kill()
	tween = get_tree().create_tween()
	tween.tween_property(self, "custom_minimum_size", Vector2(0, size.y + content_container.size.y), 0.2)
	tween.tween_property(inside_panel, "visible", true, 0)
	tween.tween_property(content_container, "visible", true, 0)
	tween.tween_property(separator, "visible", true, 0)
	tween.tween_property(inside_panel, "modulate", Color(1, 1, 1, 1), 0.1)
	tween.tween_property(content_container, "modulate", Color(1, 1, 1, 1), 0.2)
	
	# After growing finishes, grab focus on the child focus group
	var on_grown := func():
		if not focus_group:
			logger.warn("No focus group to grab!")
			return
		focus_group.grab_focus()
		
	tween.tween_callback(on_grown)
	
	
func _shrink() -> void:
	if tween:
		tween.kill()
	tween = get_tree().create_tween()
	tween.tween_property(content_container, "modulate", Color(1, 1, 1, 0), 0.2)
	tween.tween_property(inside_panel, "modulate", Color(1, 1, 1, 0), 0.1)
	tween.tween_property(separator, "visible", false, 0)
	tween.tween_property(inside_panel, "visible", false, 0)
	tween.tween_property(content_container, "visible", false, 0)
	tween.tween_property(self, "custom_minimum_size", Vector2(0, 0), 0.2)
	tween.tween_callback(grab_focus)


func _play_sound(stream: AudioStream) -> void:
	var audio_player: AudioStreamPlayer = $AudioStreamPlayer
	audio_player.stream = stream
	audio_player.play()


func _gui_input(event: InputEvent) -> void:
	if event.is_action("ui_accept"):
		if event.is_pressed():
			button_down.emit()
			pressed.emit()
		else:
			button_up.emit()
