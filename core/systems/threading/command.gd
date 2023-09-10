extends RefCounted
class_name Command

## Convienience class for executing OS commands in a thread

var thread_pool := load("res://core/systems/threading/thread_pool.tres") as ThreadPool
var cmd: String
var args := PackedStringArray()
var stdout: String
var code := 0


func _init(command: String = "", arguments: PackedStringArray = []) -> void:
	cmd = command
	args = arguments


func execute() -> int:
	thread_pool.start()
	
	var output := []
	var ret := await thread_pool.exec(OS.execute.bind(cmd, args, output)) as int
	code = ret
	stdout = output[0]
	
	return ret


func _to_string() -> String:
	return "Command<{0} {1}>".format([cmd, " ".join(args)])
