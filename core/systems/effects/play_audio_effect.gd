@tool
extends Effect
class_name PlayAudioEffect

@export_category("AudioSteamPlayer")
@export_file("*.ogg") var audio = "res://assets/audio/interface/glitch_004.ogg"

var audio_stream = load(audio)


# Fires when the given signal is emitted
func _on_signal():
	_play_sound(audio_stream)


func _play_sound(stream: AudioStream) -> void:
	var audio_player: AudioStreamPlayer = $AudioStreamPlayer
	audio_player.stream = stream
	audio_player.play()
