extends RefCounted
class_name CommandSync

## Execute a blocking OS command
##
## The [CommandSync] class allows you to syncronously execute a command that
## will block the executing thread.

## Path to the command to execute
var cmd: String
## Array of arguments to pass to the command
var args := PackedStringArray()
## The command output after execution
var stdout: String
## The exit code of the command after execution
var code := 0


func _init(command: String = "", arguments: PackedStringArray = []) -> void:
	cmd = command
	args = arguments


## Execute the command in a thread and return the command's exit code.
func execute() -> int:
	var output := []
	var ret := OS.execute(cmd, args, output)
	code = ret
	stdout = output[0]
	
	return ret


func _to_string() -> String:
	return "CommandSync<{0} {1}>".format([cmd, " ".join(args)])
