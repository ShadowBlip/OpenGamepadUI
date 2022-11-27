@tool
extends TextureButton

enum LAYOUT_MODE {
	LANDSCAPE,
	PORTRAIT,
}

const LAYOUTS: Dictionary = {
	LAYOUT_MODE.LANDSCAPE: Vector2(460, 215),
	LAYOUT_MODE.PORTRAIT: Vector2(600, 900) / 3,
}

@export var text: String = "Empty"
@export_file("*.ogg") var focus_audio = "res://assets/audio/interface/glitch_004.ogg"
@export_file("*.ogg") var select_audio = "res://assets/audio/interface/select_002.ogg"
@export var layout: LAYOUT_MODE = LAYOUT_MODE.LANDSCAPE
var focus_audio_stream = load(focus_audio)
var select_audio_stream = load(select_audio)

@onready var label: Label = $Label
@onready var panel: Panel = $Panel
@onready var panel_alpha: int = panel.modulate.a8

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_set_layout(LAYOUTS[layout])
	label.text = text
	
	# Connect to focus events
	focus_entered.connect(_play_sound.bind(focus_audio_stream))
	focus_entered.connect(_highlight.bind(true))
	focus_exited.connect(_highlight.bind(false))
	pressed.connect(_play_sound.bind(select_audio_stream))


# Transforms our poster when we are highlighted or not
func _highlight(focused: bool) -> void:
	if focused:
		var focused_alpha = panel_alpha/3
		panel.modulate.a8 = focused_alpha
		return
	
	panel.modulate.a8 = panel_alpha


func _play_sound(stream: AudioStream) -> void:
	var audio_player: AudioStreamPlayer = $AudioStreamPlayer
	audio_player.stream = stream
	audio_player.play()


func _set_layout(dimensions: Vector2) -> void:
	custom_minimum_size.x = dimensions.x
	custom_minimum_size.y = dimensions.y
