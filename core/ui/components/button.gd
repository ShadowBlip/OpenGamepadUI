extends Button

@export_file("*.ogg") var focus_audio = "res://assets/audio/interface/536764__egomassive__toss.ogg"
@export_file("*.ogg") var select_audio = "res://assets/audio/interface/96127__bmaczero__contact1.ogg"
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

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
