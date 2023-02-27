extends Control


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var thread_group := ThreadGroup.new()
	thread_group.start()
	var result = await thread_group.exec(long_method.bind(1))
	print("Got result: ", result)
	assert(result == 2)


func long_method(one: int) -> int:
	OS.delay_msec(10000)
	print("Done!")
	return one + 1
