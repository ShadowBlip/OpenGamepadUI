extends GutHookScript

var PID: int = OS.get_process_id()
var gamescope := load("res://core/global/gamescope.tres") as Gamescope
var window_id = gamescope.get_window_id(PID, gamescope.XWAYLAND.OGUI)


func run() -> void:
	if window_id < 0:
		return

	gamescope.set_main_app(window_id)
	gamescope.set_input_focus(window_id, 1)
