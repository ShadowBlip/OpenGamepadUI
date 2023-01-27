extends Resource
class_name RunningApp

signal app_killed
signal window_id_changed
signal app_id_changed

var launch_item: LibraryLaunchItem
var pid: int
var display: String
var window_id: int:
	set(v):
		window_id = v
		window_id_changed.emit()
var app_id: int:
	set(v):
		app_id = v
		app_id_changed.emit()
var logger := Log.get_logger("RunningApp", Log.LEVEL.INFO)


func _init(item: LibraryLaunchItem, process_id: int, dsp: String) -> void:
	launch_item = item
	pid = process_id
	display = dsp


func get_window_id_from_pid() -> int:
	return Gamescope.get_window_id(display, pid)


func is_running() -> bool:
	# If the app is still running, great!
	if OS.is_process_running(pid):
		return true
		
	if launch_item != null:
		logger._name = "RunningApp-" + launch_item.name
	
	# If it's not running, let's check to make sure it's REALLY not running
	# and hasn't re-parented itself
	var gamescope_pid: int = Reaper.get_parent_pid(OS.get_process_id())
	if not Reaper.is_gamescope_pid(gamescope_pid):
		logger.warn("OpenGamepadUI wasn't launched with gamescope! Unexpected behavior expected.")
	
	# Try checking to see if there are any other processes running with our
	# app's process group
	var candidates = Reaper.get_children_with_pgid(gamescope_pid, pid)
	if len(candidates) > 0:
		logger.debug("{0} is not running, but lives on in {1}".format([pid, ",".join(candidates)]))
		return true

	return false
