extends Resource
class_name RunningApp

signal app_killed

var launch_item: LibraryLaunchItem
var pid: int
var display: String
var logger := Log.get_logger("RunningApp")


func _init(item: LibraryLaunchItem, process_id: int, dsp: String) -> void:
	launch_item = item
	pid = process_id
	display = dsp


func get_window_id() -> int:
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
		logger.info("{0} is not running, but lives on in {1}".format([pid, ",".join(candidates)]))
		return true

	return false
