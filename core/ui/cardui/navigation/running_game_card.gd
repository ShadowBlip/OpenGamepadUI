@tool
extends Container

signal pressed
signal button_up
signal button_down
signal toggled(pressed: bool)

var launch_manager := load("res://core/global/launch_manager.tres") as LaunchManager
var boxart_manager := load("res://core/global/boxart_manager.tres") as BoxArtManager
var library_manager := load("res://core/global/library_manager.tres") as LibraryManager
var state_machine := load("res://assets/state/state_machines/global_state_machine.tres") as StateMachine
var in_game_state := load("res://assets/state/states/in_game.tres") as State

@export var is_toggled := false

@onready var separator := $%HSeparator
@onready var content_container := $%ContentContainer
@onready var margin_container := $%MarginContainer
@onready var game_logo := $%GameLogo
@onready var game_label := $%GameLabel
@onready var resume_button := $%ResumeButton
@onready var exit_button := $%ExitButton

var tween: Tween
var running_app: RunningApp


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	#focus_entered.connect(_play_sound.bind(_focus_audio_stream))
	focus_entered.connect(_on_focus)
	focus_exited.connect(_on_unfocus)
	pressed.connect(_on_pressed)
	
	# Connect sub-buttons
	var on_resume_game := func():
		state_machine.set_state([in_game_state])
	resume_button.pressed.connect(on_resume_game)
	var on_exit_game := func():
		# TODO: Handle this better
		launch_manager.stop(launch_manager.get_current_app())
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
	if logo:
		game_logo.texture = logo
		game_logo.visible = true
	else:
		game_label.visible = true
		game_label.text = item.name


func _on_focus() -> void:
	var style := get("theme_override_styles/panel") as StyleBoxFlat
	style.border_width_left = 4
	style.border_width_bottom = 4
	style.border_width_top = 4
	style.border_width_right = 4


func _on_unfocus() -> void:
	for child in content_container.get_children():
		if not child is Control:
			continue
		if child.has_focus():
			return
	
	var style := get("theme_override_styles/panel") as StyleBoxFlat
	style.border_width_left = 0
	style.border_width_bottom = 0
	style.border_width_top = 0
	style.border_width_right = 0
	#if is_toggled:
	#	_on_pressed()


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
#	var focus_node: Control
#	for child in content_container.get_children():
#		if not child is Control:
#			continue
#		focus_node = child
#		break
#	var on_grown := func():
#		if not focus_node:
#			return
#		focus_node.grab_focus.call_deferred()
	tween.tween_property(self, "custom_minimum_size", Vector2(0, size.y + content_container.size.y), 0.2)
	tween.tween_property(content_container, "visible", true, 0)
	tween.tween_property(separator, "visible", true, 0)
	tween.tween_property(content_container, "modulate", Color(1, 1, 1, 1), 0.2)
	#tween.tween_callback(on_grown)
	
	
func _shrink() -> void:
	if tween:
		tween.kill()
	tween = get_tree().create_tween()
	tween.tween_property(content_container, "modulate", Color(1, 1, 1, 0), 0.2)
	tween.tween_property(separator, "visible", false, 0)
	tween.tween_property(content_container, "visible", false, 0)
	tween.tween_property(self, "custom_minimum_size", Vector2(0, 0), 0.2)
	tween.tween_callback(grab_focus)


func _gui_input(event: InputEvent) -> void:
	if event.is_action("ui_accept"):
		if event.is_pressed():
			button_down.emit()
			pressed.emit()
		else:
			button_up.emit()
