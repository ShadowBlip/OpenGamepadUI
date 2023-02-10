extends Resource
class_name InteractiveProcess

# Create a stdin pipe
# Read from the stdin pipe to keep it open
# Spawn the process like: foo.sh < /tmp/stdin

var cmd: String
var args: PackedStringArray = []
var pid: int
var stdout: PipeAccess
var stdin: PipeAccess
var stdin_hold: PipeAccess
var _pipe_dir: String
var _stdout_path: String
var _stdin_path: String
var logger := Log.get_logger("InteractiveProcess", Log.LEVEL.DEBUG)


func _init(command: String, cmd_args: PackedStringArray = []) -> void:
	cmd = command
	args = cmd_args


func start() -> int:
	# Create a temporary directory to store our named pipes
	var out := []
	if OS.execute("mktemp", ["-d"], out) != OK:
		logger.debug("Unable to create temporary directory for stdin/out")
		return ERR_CANT_CREATE
	if out.size() == 0:
		logger.debug("No output from mktemp")
		return ERR_CANT_CREATE
	_pipe_dir = (out[0] as String).strip_edges()
	logger.debug("Created temporary directory: " + _pipe_dir)
	if not DirAccess.dir_exists_absolute(_pipe_dir):
		logger.debug("Pipe directory does not exist: " + _pipe_dir)
		return ERR_CANT_CREATE

	# Set up our paths to stdin/stdout
	_stdin_path = "/".join([_pipe_dir, "stdin"])
	_stdout_path = "/".join([_pipe_dir, "stdout"])
	logger.debug("Using stdin/stdout: {0} {1}".format([_stdin_path, _stdout_path]))

	# Create named pipes for stdin and stdout
	if OS.execute("mkfifo", [_stdin_path]) != OK:
		logger.debug("Unable to create stdin pipe")
		return ERR_CANT_CREATE
	if OS.execute("mkfifo", [_stdout_path]) != OK:
		logger.debug("Unable to create stdout pipe")
		return ERR_CANT_CREATE
	logger.debug("Created stdin and stdout named pipes")

	# Spawn the process and attach its stdin and stdout to the named pipes
	# E.g. ./foo.sh < /tmp/stdin 1> /tmp/stdout
	var command: PackedStringArray = [cmd]
	command.append_array(args)
	command.append_array(["<", _stdin_path, "1>", _stdout_path])
	logger.debug("Executing command: " + " ".join(command))
	pid = OS.create_process("bash", ["-c", " ".join(command)])
	if pid < 0:
		logger.debug("Unable to spawn process")
		return ERR_CANT_CREATE
	logger.debug("Spawned process with PID: " + str(pid))

	# Open the stdout file descriptor
	stdout = PipeAccess.open(_stdout_path, PipeAccess.READ)
	if not stdout.is_open():
		logger.debug("Unable to open stdout pipe")
		return ERR_CANT_OPEN

	# Pipe readers will receive an EOF once there are no writers left.
	# So keep the stdin open until we're ready to stop interacting.
	stdin_hold = PipeAccess.open(_stdin_path, PipeAccess.WRITE)
	if not stdout.is_open():
		logger.debug("Unable to open stdin pipe")
		return ERR_CANT_OPEN
	logger.debug("Created stdin watcher")

	return OK


# Send the given input to the running process
func send(input: String) -> void:
	logger.debug("Writing input: " + input)
	if not stdout or not stdout.is_open() or _stdin_path == "":
		logger.debug("No stdin/stdout are defined")
		return
	stdin = PipeAccess.open(_stdin_path, PipeAccess.WRITE)
	if not stdin or not stdin.is_open():
		logger.debug("Unable to open stdin")
		return
	stdin.write(input)
	stdin.close()
	stdin = null


func read() -> String:
	if not stdout or not stdout.is_open() or _stdin_path == "":
		logger.debug("No stdin/stdout are defined")
		return ""
	return stdout.get_line()


# Stop the given process
func stop() -> void:
	OS.kill(pid)
	if stdin and stdin.is_open():
		stdin.close()
	if stdout and stdout.is_open():
		stdout.close()
	if stdin_hold and stdin_hold.is_open():
		stdin_hold.close()
