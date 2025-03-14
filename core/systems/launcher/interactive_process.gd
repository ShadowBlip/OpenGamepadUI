@icon("res://assets/editor-icons/devicon-plain--bash.svg")
extends Resource
class_name InteractiveProcess

# DEPRECATED: Use the [Pty] node instead

## Class for starting an interacting with a process through a psuedo terminal
##
## Starts an interactive session

var pty: Pty
var cmd: String
var args: PackedStringArray = []
var pid: int
var platform := load("res://core/global/platform.tres") as Platform
var registry := load("res://core/systems/resource/resource_registry.tres") as ResourceRegistry
var lines_mutex := Mutex.new()
var lines_buffer := PackedStringArray()
var logger := Log.get_logger("InteractiveProcess", Log.LEVEL.INFO)


func _init(command: String, cmd_args: PackedStringArray = []) -> void:
	# Check to see if this OS requires running the command through a binary
	# compatibility tool.
	if platform and platform.os:
		var compatibility_cmd := platform.os.get_binary_compatibility_cmd(command, cmd_args)
		if not compatibility_cmd.is_empty():
			logger.debug("Using binary compatibility tool")
			self.cmd = compatibility_cmd.pop_front()
			self.args = PackedStringArray(compatibility_cmd)
			return

	self.cmd = command
	self.args = cmd_args


## Start the interactive process
func start() -> int:
	# Create a new PTY instance and start the process
	self.pty = Pty.new()
	self.pty.exec(self.cmd, self.args)
	self.pty.line_written.connect(_on_line_written)
	
	# The new [Pty] is a node, so it must be added to the scene tree
	self.registry.add_child(self.pty)
	
	return OK


func _on_line_written(line: String):
	logger.trace("PTY:", line)
	self.lines_mutex.lock()
	self.lines_buffer.append(line)
	self.lines_mutex.unlock()


## Send the given input to the running process
func send(input: String) -> void:
	if not pty:
		return
	#if pty.write_line(input) < 0:
	if pty.write(input.to_utf8_buffer()) < 0:
		logger.debug("Unable to write to PTY")


## Read from the stdout of the running process
func read(_chunk_size: int = 1024) -> String:
	if not pty:
		logger.debug("Unable to read from closed PTY")
		return ""

	# Keep reading from the process until the buffer is empty
	self.lines_mutex.lock()
	var output := "\n".join(self.lines_buffer)
	self.lines_buffer = PackedStringArray()
	self.lines_mutex.unlock()

	return output


## Stop the given process
func stop() -> void:
	logger.debug("Stopping pid: " + str(self.pid))
	self.pty.kill()
	self.registry.remove_child(self.pty)
	self.pty = null


## Returns whether or not the interactive process is still running
func is_running() -> bool:
	if not pty:
		return false
	return pty.running


# TODO: Fixme
func output_to_log_file(log_file: FileAccess, _chunk_size: int = 1024) -> int:
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
