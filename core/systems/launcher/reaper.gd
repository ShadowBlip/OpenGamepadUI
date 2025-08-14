extends RefCounted
class_name Reaper

enum SIG {
	KILL = 9,
	TERM = 15,
	CONT = 18,
	STOP = 19,
}


## Spawn a process with PR_SET_CHILD_SUBREAPER set so child processes will
## reparent themselves to OpenGamepadUI. Returns the PID of the spawned process.
static func create_process(cmd: String, args: PackedStringArray, app_id: int = -1) -> int:
	var logger := Log.get_logger("Reaper")
	logger.debug("Got command to execute:", cmd, args)
	var reaper_cmd := get_reaper_command()
	logger.debug("Got reaper command:", reaper_cmd)
	if reaper_cmd.is_empty():
		logger.warn("'reaper' binary not found, launching without reaper")
		logger.info("Executing OS command:", cmd, args)
		return OS.create_process(cmd, args)

	# Build the arguments for reaper.
	var reaper_args := PackedStringArray()
	if app_id >= 0:
		reaper_args.append("SteamLaunch")
		reaper_args.append("AppId={0}".format([app_id]))
	reaper_args.append("--")
	reaper_args.append(cmd)
	reaper_args.append_array(args)
	logger.info("Executing REAPER command:", reaper_cmd, reaper_args)
	return OS.create_process(reaper_cmd, reaper_args)

## Discovers the 'reaper' binary to execute commands with PR_SET_CHILD_SUBREAPER.
static func get_reaper_command() -> String:
	var logger := Log.get_logger("Reaper")
	var home := OS.get_environment("HOME")
	var search_paths := [
		"./extensions/target/release",
		"/usr/share/opengamepadui",
		"{0}/.local/share/opengamepadui".format([home]),
		"/run/current-system/sw/share/opengamepadui"
	]
	
	for path in search_paths:
		logger.debug("Checking for reaper in path:", path)
		# Check if the path exists, its the responsible thing to do.
		if not DirAccess.dir_exists_absolute(path):
			logger.debug("Path does not exists!")
			continue
		logger.debug("Path does exists!")
		var directory := DirAccess.open(path)
		if not directory:
			logger.warn("Failed to open path:", path)
			continue
		if directory.file_exists("reaper"):
			var reaper_path := "{0}/reaper".format([path])
			return reaper_path
	
	return ""


# Kills the given PID and all its descendants
static func reap(pid: int, sig: SIG = SIG.TERM) -> void:
	var pids: Array = pstree(pid)
	pids.push_front(pid)
	var sig_arg := "-{0}".format([str(sig)])
	
	# Kill all children in the process tree from the leaves inward
	pids.reverse()
	var logger := Log.get_logger("Reaper")
	for p in pids:
		# Don't kill the actual reaper PID
		if p == pid:
			logger.debug("Skipping killing reaper pid:", pid)
			continue
		
		# Kill PGID
		var cmd := "kill"
		var args: Array[String] = [sig_arg, "--", "-{0}".format([p])]
		logger.info(cmd + " " + " ".join(args))
		Command.create(cmd, args).execute()
		
		# Kill PIDs
		args = [sig_arg, "--", "{0}".format([p])]
		logger.info(cmd + " " + " ".join(args))
		Command.create(cmd, args).execute()

	var verb := "Reaped"
	if sig == SIG.STOP:
		verb = "Suspended"
	if sig == SIG.CONT:
		verb = "Resumed"
	logger.info(verb + " pids: " + ",".join(pids))


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
		return "D (dead)"
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
		logger.debug("Unable to check status for pid: {0}".format([pid]))
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


## Returns the parsed environment for the given PID. Returns an empty dictionary
## if the PID is not found or we do not have permission to read the environment.
static func get_pid_environment(pid: int) -> Dictionary[String, String]:
	var env: Dictionary[String, String] = {}

	# Open the environment file for the given process
	var env_path := "/".join(["/proc", str(pid), "environ"])
	var env_file := FileAccess.open(env_path, FileAccess.READ)
	if not env_file:
		return env

	# Read from the environment until no data is left
	var env_data := PackedByteArray()
	while not env_file.eof_reached():
		env_data.append_array(env_file.get_buffer(8128))

	# The environment data is a null-terminated list of strings. Loop
	# over the bytes to find slices between the null bytes and decode each
	# found slice as a string.
	var current_position := 0
	while true:
		var next_position := env_data.find(0, current_position)
		if next_position < 0:
			break
		var entry := env_data.slice(current_position, next_position)
		var string := entry.get_string_from_utf8()
		var key_value := string.split("=", true, 1)
		if key_value.size() > 1:
			env[key_value[0]] = key_value[1]
		current_position = next_position + 1
	
	return env


## Returns a list of all currently running processes
static func get_pids() -> PackedInt64Array:
	var pids := PackedInt64Array()
	for proc in DirAccess.get_directories_at("/proc"):
		if not (proc as String).is_valid_int():
			continue
		var process_id := proc.to_int()
		pids.push_back(process_id)
	return pids


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
		logger.debug("No name was found in pid status!")
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
