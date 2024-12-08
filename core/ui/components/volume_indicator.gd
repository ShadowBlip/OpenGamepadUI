extends Control

var audio_manager := load("res://core/global/audio_manager.tres") as AudioManager
var PID: int = OS.get_process_id()
var gamescope := load("res://core/systems/gamescope/gamescope.tres") as GamescopeInstance
var overlay_window_id: int

@onready var timer := $%Timer as Timer
@onready var level_indicator := $%LevelIndicator


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var xwayland := gamescope.get_xwayland(gamescope.XWAYLAND_TYPE_OGUI)
	if xwayland:
		var window_ids := xwayland.get_windows_for_pid(PID)
		if not window_ids.is_empty():
			overlay_window_id = window_ids[0]
	audio_manager.volume_changed.connect(_on_volume_changed)
	timer.timeout.connect(_on_timeout)
	visible = false


func _on_volume_changed(value: float) -> void:
	visible = true
	level_indicator.value = value * 100
	timer.start()
	var xwayland := gamescope.get_xwayland(gamescope.XWAYLAND_TYPE_OGUI)
	if xwayland:
		xwayland.set_notification(overlay_window_id, 1)


func _on_timeout() -> void:
	visible = false
	var xwayland := gamescope.get_xwayland(gamescope.XWAYLAND_TYPE_OGUI)
	if xwayland:
		xwayland.set_notification(overlay_window_id, 0)
