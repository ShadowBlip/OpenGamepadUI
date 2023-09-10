extends RefCounted
class_name Command

## Execute an OS command in a thread
##
## The [Command] class allows you to asyncronously execute a command in a thread
## that does not block the main thread. Optionally a [SharedThread] can be
## passed if you do not wish for the command to execute in the [ThreadPool].[br]
## Example:
## [codeblock]
## var cmd := Command.new("cat", ["/etc/issue"])
## if cmd.execute() != OK:
##     print("Command failed with exit code: ", cmd.code)
## 
## print(cmd.stdout)
## [/codeblock]

## The [ThreadPool] to execute the command in
var thread_pool := load("res://core/systems/threading/thread_pool.tres") as ThreadPool
## Optional [SharedThread] to execute the command in
var shared_thread: SharedThread
## Path to the command to execute
var cmd: String
## Array of arguments to pass to the command
var args := PackedStringArray()
## The command output after execution
var stdout: String
## The exit code of the command after execution
var code := 0


func _init(command: String = "", arguments: PackedStringArray = [], thread: SharedThread = null) -> void:
	cmd = command
	args = arguments
	if thread:
		shared_thread = thread


## Execute the command in a thread and return the command's exit code.
func execute() -> int:
	var ret: int
	if shared_thread:
		ret = await _shared_thread_exec()
	else:
		ret = await _thread_pool_exec()
	
	return ret


func _shared_thread_exec() -> int:
	shared_thread.start()
	
	var output := []
	var ret := await shared_thread.exec(OS.execute.bind(cmd, args, output)) as int
	code = ret
	stdout = output[0]
	
	return ret


func _thread_pool_exec() -> int:
	thread_pool.start()
	
	var output := []
	var ret := await thread_pool.exec(OS.execute.bind(cmd, args, output)) as int
	code = ret
	stdout = output[0]
	
	return ret


func _to_string() -> String:
	return "Command<{0} {1}>".format([cmd, " ".join(args)])
