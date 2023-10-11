extends GutTest

var shared_thread := SharedThread.new()


func before_all() -> void:
	shared_thread.start()


# NOTE: We need to cleanly stop all threads to prevent crashing
func after_all() -> void:
	var input_thread := load("res://core/systems/threading/input_thread.tres") as SharedThread
	var io_thread := load("res://core/systems/threading/io_thread.tres") as SharedThread
	var system_thread := load("res://core/systems/threading/system_thread.tres") as SharedThread
	var utility_thread := load("res://core/systems/threading/utility_thread.tres") as SharedThread
	var thread_pool := load("res://core/systems/threading/thread_pool.tres") as ThreadPool
	var watchdog_thread := load("res://core/systems/threading/watchdog_thread.tres") as WatchdogThread
	shared_thread.stop()
	input_thread.stop()
	system_thread.stop()
	utility_thread.stop()
	thread_pool.stop()
	watchdog_thread.stop()


func test_exec() -> void:
	var result = await shared_thread.exec(long_method.bind(1))
	assert_eq(result, 2, "should have returned a result")


func long_method(one: int) -> int:
	OS.delay_msec(100)
	return one + 1
