extends TextureButton

const LAYOUT_LANDSCAPE: Vector2 = Vector2(460, 215)
const LAYOUT_PORTRAIT: Vector2 = Vector2(600, 900)

@export_file("*.ogg") var focus_audio = "res://assets/audio/interface/glitch_004.ogg"
@export_file("*.ogg") var select_audio = "res://assets/audio/interface/select_002.ogg"
var focus_audio_stream = load(focus_audio)
var select_audio_stream = load(select_audio)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	focus_entered.connect(_play_sound.bind(focus_audio_stream))
	pressed.connect(_play_sound.bind(select_audio_stream))


func _play_sound(stream: AudioStream) -> void:
	var audio_player: AudioStreamPlayer = $AudioStreamPlayer
	audio_player.stream = stream
	audio_player.play()


func set_layout(dimensions: Vector2) -> void:
	custom_minimum_size.x = dimensions.x
	custom_minimum_size.y = dimensions.y
