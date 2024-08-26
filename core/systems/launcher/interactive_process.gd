extends Resource
class_name InteractiveProcess

## Class for starting an interacting with a process through a psuedo terminal
##
## Starts an interactive session

var pty: Pty
var cmd: String
var args: PackedStringArray = []
var pid: int
var logger := Log.get_logger("InteractiveProcess", Log.LEVEL.INFO)


func _init(command: String, cmd_args: PackedStringArray = []) -> void:
	cmd = command
	args = cmd_args


## Start the interactive process
# TODO: Fixme
func start() -> int:
	return OK


## Send the given input to the running process
func send(input: String) -> void:
	if not pty:
		return
	logger.debug("Writing input: " + input)
	if pty.write(input.to_utf8_buffer()) < 0:
		logger.debug("Unable to write to PTY")


## Read from the stdout of the running process
#TODO: Fixme
func read(chunk_size: int = 1024) -> String:
	if not pty:
		logger.debug("Unable to read from closed PTY")
		return ""

	# Keep reading from the process until the buffer is empty
	var output := ""

	return output


## Stop the given process
func stop() -> void:
	logger.debug("Stopping pid: " + str(pid))
	OS.kill(pid)
	pty = null


## Returns whether or not the interactive process is still running
func is_running() -> bool:
	return OS.is_process_running(pid)


# TODO: Fixme
func output_to_log_file(log_file: FileAccess, chunk_size: int = 1024) -> int:
	if not log_file:
		logger.warn("Unable to log output. Log file has not been opened.")
		return ERR_FILE_CANT_OPEN
	# Keep reading from the process until the buffer is empty
	if not pty:
		logger.warn("Unable to read from closed PTY")
		return ERR_DOES_NOT_EXIST

	# Keep reading from the process until the buffer is empty

	log_file.flush()
	return OK
