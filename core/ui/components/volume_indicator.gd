extends Control

var AudioManager := load("res://core/global/audio_manager.tres") as AudioManager

@onready var timer := $%Timer as Timer
@onready var level_indicator := $%LevelIndicator as LevelIndicator


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	print("READY")
	AudioManager.volume_changed.connect(_on_volume_changed)
	timer.timeout.connect(_on_timeout)
	visible = false
	print("SET VISIBLE TO FALSE")


func _on_volume_changed(value: float) -> void:
	visible = true
	print("Setting volume to: ", value)
	level_indicator.value = value * 100
	timer.start()


func _on_timeout() -> void:
	visible = false
