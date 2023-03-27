extends Test


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var thread_group := SharedThread.new()
	thread_group.start()
	var result = await thread_group.exec(long_method.bind(1))
	logger.info("Got result: " + str(result))
	assert_true(result == 3)


func long_method(one: int) -> int:
	OS.delay_msec(10000)
	logger.info("Done!")
	return one + 1
