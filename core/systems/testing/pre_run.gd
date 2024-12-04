extends GutHookScript

var PID: int
var gamescope: GamescopeInstance
var window_id: int


func run() -> void:
	PID = OS.get_process_id()
	gamescope = load("res://core/systems/gamescope/gamescope.tres") as GamescopeInstance
	var xwayland := gamescope.get_xwayland(gamescope.XWAYLAND_TYPE_OGUI)
	if not xwayland:
		return
	var window_ids := xwayland.get_windows_for_pid(PID)
	if not window_ids.is_empty():
		window_id = window_ids[0]
	if window_id < 0:
		return

	gamescope.set_main_app(window_id)
	gamescope.set_input_focus(window_id, 1)
