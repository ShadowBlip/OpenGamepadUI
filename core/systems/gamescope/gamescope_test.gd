extends Node2D

var gamescope := load("res://core/systems/gamescope/gamescope.tres") as GamescopeInstance

var PID := OS.get_process_id()

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	print(gamescope.get_xwaylands())
	var xwayland := gamescope.get_xwayland(gamescope.XWAYLAND_TYPE_OGUI)
	if not xwayland:
		print("XWayland not found")
		return

	var ogui_window_ids := xwayland.get_windows_for_pid(PID)
	if ogui_window_ids.is_empty():
		print("Unable to find window id for OGUI")
		return
	var ogui_window_id := ogui_window_ids[0]
	xwayland.set_main_app(ogui_window_id)
	print("Found window ids for OGUI: ", ogui_window_ids)
