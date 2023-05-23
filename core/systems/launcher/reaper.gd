extends Object
class_name Reaper

enum SIG {
	KILL = 9,
	TERM = 15,
}


## Spawn a process with PR_SET_CHILD_SUBREAPER set so child processes will
## reparent themselves to OpenGamepadUI. Returns the PID of the spawned process.
static func create_process(cmd: String, args: PackedStringArray) -> int:
	#return Subreaper.create_process(cmd, args)
	return OS.create_process(cmd, args)


# Kills the given PID and all its descendants
static func reap(pid: int, sig: SIG = SIG.TERM) -> void:
	var pids: Array = pstree(pid)
	pids.push_front(pid)
	var sig_arg := "-{0}".format([str(sig)])
	
	# Kill all children in the process tree from the leaves inward
	pids.reverse()
	for p in pids:
		OS.execute("kill", [sig_arg, "--", "-{0}".format([p])])
		#OS.kill(p)
	var logger := Log.get_logger("Reaper")
	logger.info("Reaped pids: " + ",".join(pids))


# Returns an array of child PIDs that are in the given process group
static func get_children_with_pgid(pid: int, pgid: int) -> Array:
	var with_group: Array = []
	var descendants: Array = pstree(pid)
	for c in descendants:
		var child: int = c
		var child_pgid: int = get_pid_group(child)
		if child_pgid == pgid:
			with_group.push_back(child)
	
	return with_group


# Returns the parent PID of the given PID
static func get_parent_pid(pid: int) -> int:
	return get_pid_property_int(pid, "PPid")
	

# Returns the PID group the given PID belongs to
static func get_pid_group(pid: int) -> int:
	return get_pid_property_int(pid, "NSpgid")


# Returns the PID state the given PID is in
static func get_pid_state(pid: int) -> String:
	var status: Dictionary = get_pid_status(pid)
	if not "State" in status:
		var logger := Log.get_logger("Reaper")
		logger.warn("Unable to check state of PID " + str(pid))
		return ""
	return status["State"]


# Returns the given PID property as an integar
static func get_pid_property_int(pid: int, key: String) -> int:
	var status: Dictionary = get_pid_status(pid)
	if not key in status:
		return -1
	if not status[key].is_valid_int():
		var logger := Log.get_logger("Reaper")
		logger.error("{0} was not a valid integar!".format([key]))
		logger.error(status)
		return -1
	return int(status[key])


# Returns the parsed status of the given PID.
# Example:
#   {
#     "Name": "opengamepad-ui.",
#     "PPid": "17821",           # Parent PID
#     "NSpgid": "17787",         # PID Group
#     ...
#   }
static func get_pid_status(pid: int) -> Dictionary:
	var status_path: String = "/".join(["/proc", str(pid), "status"])
	var status_file: FileAccess = FileAccess.open(status_path, FileAccess.READ)
	if not status_file:
		var logger := Log.get_logger("Reaper")
		logger.error("Unable to check status for pid: {0}".format([pid]))
		return {}
	
	# Parse the status output
	var status: Dictionary
	var output: String = status_file.get_buffer(1000000).get_string_from_ascii()
	for l in output.split("\n"):
		var line: String = l
		if not line.contains(":"):
			continue
		var columns: PackedStringArray = line.split(":")
		var key: String = columns[0]
		var value: String = columns[1].strip_edges()
		# Split the value by tab character
		var values = value.split("\t")
		# TODO: Don't just get the first value in a multi-value property
		if len(values) > 0:
			value = values[0]
		status[key] = value
	
	return status


# Recursively finds all descendant processes and returns it as an array of PIDs
static func pstree(pid: int) -> Array:
	var logger := Log.get_logger("Reaper")
	var proc_path: String = "/proc/{0}".format([pid])
	var task_path: String = "{0}/task".format([proc_path])
	
	var descendants: Array = []
	
	# Loop through each task for the pid and get its children
	var tasks: DirAccess = DirAccess.open(task_path)
	if not tasks:
		logger.debug("Unable to open proc directory: " + task_path)
		return []
	tasks.list_dir_begin()
	var task: String = tasks.get_next()
	while task != "":
		# Read the children of the task
		var children_path: String = "/".join([task_path, task, "children"])
		var children: FileAccess = FileAccess.open(children_path, FileAccess.READ)
		if not children:
			logger.debug("Unable to open children: " + children_path)
			task = tasks.get_next()
			continue
		
		var data: PackedByteArray = children.get_buffer(1000000)
		var child_pids: Array = data.get_string_from_ascii().split(" ")
		descendants.append_array(to_int_array(child_pids))
		task = tasks.get_next()

	if len(descendants) == 0:
		return descendants

	var grandchildren: Array = []
	for child_pid in descendants:
		grandchildren.append_array(pstree(child_pid))
	
	descendants.append_array(grandchildren)
	return descendants


# Checks the given pid to see if its name is "gamescope-wl"
static func is_gamescope_pid(pid: int) -> bool:
	var status: Dictionary = get_pid_status(pid)
	if not "Name" in status:
		var logger := Log.get_logger("Reaper")
		logger.error("No name was found in pid status!")
		return false
	if status["Name"] == "gamescope-wl":
		return true
	return false


# Converts the given string array to an int array
static func to_int_array(arr: Array) -> Array:
	var int_array: Array = []
	for item in arr:
		if item.is_valid_int():
			int_array.push_back(int(item))
	return int_array
