@tool
extends TextureButton

enum LAYOUT_MODE {
	LANDSCAPE,
	PORTRAIT,
}

const LAYOUTS: Dictionary = {
	LAYOUT_MODE.LANDSCAPE: Vector2(460, 215),  # Original: 460 x 215
	LAYOUT_MODE.PORTRAIT: Vector2(143, 215),  # Original: 600 x 900
}

@export var text: String = "Empty"
@export_file("*.ogg") var focus_audio = "res://assets/audio/interface/glitch_004.ogg"
@export_file("*.ogg") var select_audio = "res://assets/audio/interface/select_002.ogg"
@export var layout: LAYOUT_MODE = LAYOUT_MODE.LANDSCAPE
@export var layout_scale: float = 1
var library_item: LibraryItem
var _focus_audio_stream = load(focus_audio)
var _select_audio_stream = load(select_audio)

@onready var _label: Label = $Label
@onready var _panel: Panel = $Label/Panel
@onready var _panel_alpha: int = _panel.modulate.a8


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_set_layout(LAYOUTS[layout])
	_label.text = text
	_highlight(false)

	# Connect to focus events
	focus_entered.connect(_play_sound.bind(_focus_audio_stream))
	focus_entered.connect(_highlight.bind(true))
	mouse_entered.connect(_highlight.bind(true))
	focus_exited.connect(_highlight.bind(false))
	mouse_exited.connect(_highlight.bind(false))
	pressed.connect(_play_sound.bind(_select_audio_stream))


# Transforms our poster when we are highlighted or not
func _highlight(focused: bool) -> void:
	if focused:
		var focused_alpha = _panel_alpha * 1.5
		_panel.modulate.a8 = focused_alpha
		self_modulate.r = 1.15
		self_modulate.g = 1.15
		self_modulate.b = 1.15
		material.set_shader_parameter("on", true)
		return

	_panel.modulate.a8 = _panel_alpha
	self_modulate.r = 0.85
	self_modulate.g = 0.85
	self_modulate.b = 0.85
	material.set_shader_parameter("on", false)


func _play_sound(stream: AudioStream) -> void:
	var audio_player: AudioStreamPlayer = $AudioStreamPlayer
	audio_player.stream = stream
	audio_player.play()


func _set_layout(dimensions: Vector2) -> void:
	custom_minimum_size.x = dimensions.x * layout_scale
	custom_minimum_size.y = dimensions.y * layout_scale
