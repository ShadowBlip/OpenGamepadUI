extends Resource
class_name InteractiveProcess

## Class for starting an interacting with a process through a psuedo terminal
##
## Starts an interactive session

var pty: PTY
var cmd: String
var args: PackedStringArray = []
var pid: int
var logger := Log.get_logger("InteractiveProcess", Log.LEVEL.DEBUG)


func _init(command: String, cmd_args: PackedStringArray = []) -> void:
	cmd = command
	args = cmd_args


## Start the interactive process
func start() -> int:
	pty = PTY.new()
	if pty.open() != OK:
		pty = null
		return ERR_CANT_CREATE

	pid = pty.create_process(cmd, args)
	if pid < 0:
		pty = null
		return ERR_CANT_FORK

	return OK


## Send the given input to the running process
func send(input: String) -> void:
	if not pty:
		return
	logger.debug("Writing input: " + input)
	if pty.write(input.to_utf8_buffer()) < 0:
		logger.debug("Unable to write to PTY")


## Read from the stdout of the running process
func read(chunk_size: int = 1024) -> String:
	if not pty:
		logger.debug("Unable to read from closed PTY")
		return ""

	# Keep reading from the process until the buffer is empty
	var output := ""
	var buffer := pty.read(chunk_size)
	while buffer.size() != 0:
		output += buffer.get_string_from_utf8()
		buffer = pty.read(chunk_size)

	return output


## Stop the given process
func stop() -> void:
	logger.debug("Stopping pid: " + str(pid))
	OS.kill(pid)
	pty = null
