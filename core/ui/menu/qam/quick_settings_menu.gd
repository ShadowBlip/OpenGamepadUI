extends Control

const AudioManager := preload("res://core/global/audio_manager.tres")

@onready var output_volume := $%VolumeSlider


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var current_volume := AudioManager.get_current_volume()
	output_volume.value = current_volume * 100
	output_volume.value_changed.connect(_on_output_volume_slider_changed)
	AudioManager.volume_changed.connect(_on_output_volume_changed)


func _on_output_volume_changed(value: float) -> void:
	output_volume.value = value * 100


func _on_output_volume_slider_changed(value: float) -> void:
	var percent := value * 0.01
	AudioManager.set_volume(percent)
