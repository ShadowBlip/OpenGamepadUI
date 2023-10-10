extends GutTest

var shared_thread := SharedThread.new()


func before_all() -> void:
	shared_thread.start()


func after_all() -> void:
	shared_thread.stop()


func test_exec() -> void:
	var result = await shared_thread.exec(long_method.bind(1))
	assert_eq(result, 2, "should have returned a result")


func long_method(one: int) -> int:
	OS.delay_msec(100)
	return one + 1
