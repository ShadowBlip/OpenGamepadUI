@tool
@icon("res://assets/editor-icons/icon.svg")
extends Control
class_name CardIconButton

signal pressed
signal button_up
signal player_button_up(metaname: String, dbus_path: String)
signal button_down
signal player_button_down(metaname: String, dbus_path: String)

@export_category("Image")
@export var texture: Texture2D:
	set(v):
		texture = v
		if icon:
			icon.texture = v

@export_category("Animation")
@export var highlight_speed := 0.1

@export_category("AudioSteamPlayer")
@export_file("*.ogg") var focus_audio = "res://assets/audio/interface/glitch_004.ogg"
@export_file("*.ogg") var select_audio = "res://assets/audio/interface/select_002.ogg"

var tween: Tween
var focus_audio_stream = load(focus_audio)
var select_audio_stream = load(select_audio)

@onready var icon := $%Icon as TextureRect
@onready var highlight := $%HighlightTexture as TextureRect


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Configure the icon
	icon.texture = texture
	
	# Connect signals
	pressed.connect(_play_sound.bind(select_audio_stream))
	focus_entered.connect(_on_focus)
	focus_exited.connect(_on_unfocus)
	mouse_entered.connect(_on_focus)
	mouse_exited.connect(_on_unfocus)
	theme_changed.connect(_on_theme_changed)


func _on_theme_changed() -> void:
	# Configure the highlight texture from the theme
	var highlight_texture := get_theme_icon("highlight", "CardIconButton")
	if highlight_texture:
		highlight.texture = highlight_texture


func _on_focus() -> void:
	if tween:
		tween.kill()
	tween = get_tree().create_tween()
	tween.tween_property(highlight, "visible", true, 0)
	tween.tween_property(highlight, "modulate", Color(1, 1, 1, 0), 0)
	tween.tween_property(highlight, "modulate", Color(1, 1, 1, 1), highlight_speed)
	_play_sound(focus_audio_stream)


func _on_unfocus() -> void:
	if tween:
		tween.kill()
	tween = get_tree().create_tween()
	tween.tween_property(highlight, "modulate", Color(1, 1, 1, 1), 0)
	tween.tween_property(highlight, "modulate", Color(1, 1, 1, 0), highlight_speed)
	tween.tween_property(highlight, "visible", false, 0)
	

func _play_sound(stream: AudioStream) -> void:
	var audio_player: AudioStreamPlayer = $AudioStreamPlayer
	audio_player.stream = stream
	audio_player.play()


func _gui_input(event: InputEvent) -> void:
	var dbus_path := event.get_meta("dbus_path", "") as String
	if event is InputEventMouseButton:
		if event.is_pressed():
			button_down.emit()
			pressed.emit()
		else:
			button_up.emit()
	if not event.is_action("ui_accept"):
		return
	if event.is_pressed():
		button_down.emit()
		player_button_down.emit("dbus_path", dbus_path)
		pressed.emit()
	else:
		button_up.emit()
		player_button_up.emit("dbus_path", dbus_path)
