extends Control

var audio_manager := load("res://core/global/audio_manager.tres") as AudioManager
var PID: int = OS.get_process_id()
var gamescope := load("res://core/global/gamescope.tres") as Gamescope
var overlay_window_id := gamescope.get_window_id(PID, gamescope.XWAYLAND.OGUI)

@onready var timer := $%Timer as Timer
@onready var level_indicator := $%LevelIndicator


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	audio_manager.volume_changed.connect(_on_volume_changed)
	timer.timeout.connect(_on_timeout)
	visible = false


func _on_volume_changed(value: float) -> void:
	visible = true
	level_indicator.value = value * 100
	timer.start()
	gamescope.set_notification(overlay_window_id, 1)


func _on_timeout() -> void:
	visible = false
	gamescope.set_notification(overlay_window_id, 0)
