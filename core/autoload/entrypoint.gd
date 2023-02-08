extends Node


const main := preload("res://main.tscn")

var qam_state = load("res://assets/state/states/quick_access_menu.tres")

var display : String
var qam_window_id : int
var pid : int
var steam_window_id : int


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var args := OS.get_cmdline_args()
	if "--qam-only" in args or "--only-qam" in args:
		get_tree().get_root().transparent_bg = true
		get_tree().change_scene_to_file("res://core/ui/menu/qam/quick_access_menu.tscn")
		
		display = OS.get_environment("DISPLAY")
		pid = OS.get_process_id()
		qam_window_id = Gamescope.get_window_id(display, pid)
		
		# Find Steam in the display tree
		var root_win_id := Gamescope.get_root_window_id(display)
		var all_windows := Gamescope.get_all_windows(display, root_win_id)
		for window in all_windows:
			if window == qam_window_id:
				continue
			if Gamescope.has_xprop(display, window, "STEAM_OVERLAY"):
				steam_window_id = window
				break
		
		qam_state.state_entered.connect(_on_qam_open)
		qam_state.state_exited.connect(_on_qam_closed)


func _on_qam_open(_from: State) -> void:
	Gamescope.set_overlay(display, qam_window_id, 1)
	Gamescope.set_app_id(display, qam_window_id, 769)
	Gamescope.set_overlay(display, steam_window_id, 0)
	Gamescope.set_app_id(display, steam_window_id, 7420)


func _on_qam_closed(_to: State) -> void:
	Gamescope.set_overlay(display, qam_window_id, 0)
	Gamescope.set_app_id(display, qam_window_id, 7420)
	Gamescope.set_overlay(display, steam_window_id, 1)
	Gamescope.set_app_id(display, steam_window_id, 769)
	
