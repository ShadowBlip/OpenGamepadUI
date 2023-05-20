extends Control

var AudioManager := load("res://core/global/audio_manager.tres") as AudioManager

@onready var timer := $%Timer as Timer
@onready var level_indicator := $%LevelIndicator


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	AudioManager.volume_changed.connect(_on_volume_changed)
	timer.timeout.connect(_on_timeout)
	visible = false


func _on_volume_changed(value: float) -> void:
	visible = true
	level_indicator.value = value * 100
	timer.start()


func _on_timeout() -> void:
	visible = false
