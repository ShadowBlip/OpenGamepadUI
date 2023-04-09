@tool
extends Control

signal button_up
signal button_down
signal pressed

@onready var animation_player := $%AnimationPlayer
@onready var texture := $%TextureRect
@onready var audio_player: AudioStreamPlayer = $%AudioStreamPlayer
@export_file("*.ogg") var focus_audio = "res://assets/audio/interface/glitch_004.ogg"
@export_file("*.ogg") var select_audio = "res://assets/audio/interface/select_002.ogg"

var _focus_audio_stream = load(focus_audio)
var _select_audio_stream = load(select_audio)


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pressed.connect(_play_sound.bind(_select_audio_stream))
	focus_entered.connect(_play_sound.bind(_focus_audio_stream))
	focus_entered.connect(_on_focus)
	focus_exited.connect(_on_unfocus)
	texture.mouse_entered.connect(_on_focus)
	texture.mouse_exited.connect(_on_unfocus)
	texture.position = Vector2.ZERO
	animation_player.play("RESET")
	
	# Set shader parameters
	texture.material.set_shader_parameter("corder_radius", 80)
	
	var parent := get_parent()
	if parent and parent is Container:
		parent.queue_sort()


func _on_focus() -> void:
	animation_player.play("focus_entered")


func _on_unfocus() -> void:
	animation_player.play("focus_exited")


func _play_sound(stream: AudioStream) -> void:
	audio_player.stream = stream
	audio_player.play()


func _gui_input(event: InputEvent) -> void:
	if event.is_action("ui_accept"):
		if event.is_pressed():
			button_down.emit()
			pressed.emit()
		else:
			button_up.emit()
