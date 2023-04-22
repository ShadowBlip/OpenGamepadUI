@tool
extends Control

signal button_up
signal button_down
signal pressed

@onready var texture := $%TextureRect
@onready var shadow := $%Shadow
@onready var audio_player: AudioStreamPlayer = $%AudioStreamPlayer
@export_file("*.ogg") var focus_audio = "res://assets/audio/interface/glitch_004.ogg"
@export_file("*.ogg") var select_audio = "res://assets/audio/interface/select_002.ogg"

var tween: Tween
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
	
	# Set shader parameters
	var texture_size := texture.texture.get_size() as Vector2
	var radius := texture_size.x / 7.5
	texture.material.set_shader_parameter("corner_radius", radius)
	
	var parent := get_parent()
	if parent and parent is Container:
		parent.queue_sort()


## Sets the texture on the given card and sets the shader params
func set_texture(new_texture: Texture2D) -> void:
	var texture_rect := get_node("TextureRect")
	var texture_size := new_texture.get_size()
	texture_rect.texture = new_texture

	# Update the corner radius based on the image size
	var radius := texture_size.x / 7.5
	texture_rect.material.set_shader_parameter("corner_radius", radius)
	print("Size: ", texture_size)
	print("Setting to radius: ", radius)


func _on_focus() -> void:
	if tween:
		tween.kill()
	tween = get_tree().create_tween()
	tween.tween_property(texture, "scale", Vector2(1.01, 1.01), 0.2)
	tween.parallel().tween_property(texture, "position", Vector2(0, -40), 0.2)
	tween.parallel().tween_property(shadow, "theme_override_styles/panel:shadow_size", 20, 0.2)


func _on_unfocus() -> void:
	if tween:
		tween.kill()
	tween = get_tree().create_tween()
	tween.tween_property(texture, "scale", Vector2(1, 1), 0.2)
	tween.parallel().tween_property(texture, "position", Vector2(0, 0), 0.2)
	tween.parallel().tween_property(shadow, "theme_override_styles/panel:shadow_size", 10, 0.2)


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
