extends Control

var Gamescope := load("res://core/global/gamescope.tres") as Gamescope
var AudioManager := load("res://core/global/audio_manager.tres") as AudioManager
var state_machine := load("res://assets/state/state_machines/global_state_machine.tres") as StateMachine
var in_game_state := load("res://assets/state/states/in_game.tres") as State
var PID: int = OS.get_process_id()

@onready var timer := $%Timer as Timer
@onready var level_indicator := $%LevelIndicator


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	AudioManager.volume_changed.connect(_on_volume_changed)
	timer.timeout.connect(_on_timeout)
	visible = false


func _on_volume_changed(value: float) -> void:
	# Check to see if OGUI is set as an overlay
	var ogui_window_id = Gamescope.get_window_id(PID, Gamescope.XWAYLAND.OGUI)
	var is_overlay := Gamescope.get_overlay(ogui_window_id)
	if is_overlay == 0:
		Gamescope.set_overlay(ogui_window_id, 1)
		
	visible = true
	level_indicator.value = value * 100
	timer.start()


func _on_timeout() -> void:
	visible = false
	if state_machine.current_state() == in_game_state:
		var ogui_window_id = Gamescope.get_window_id(PID, Gamescope.XWAYLAND.OGUI)
		Gamescope.set_overlay(ogui_window_id, 0)
