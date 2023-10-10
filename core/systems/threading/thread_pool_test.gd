extends GutTest

var thread_pool := ThreadPool.new()


func before_all() -> void:
	thread_pool.start()


func after_all() -> void:
	thread_pool.stop()


func test_exec() -> void:
	var sleep1 := func():
		OS.delay_msec(100)
		return "sleep1"
	var sleep2 := func():
		OS.delay_msec(50)
		return "sleep2"
		
	var result1 := await thread_pool.exec(sleep1) as String
	var result2 := await thread_pool.exec(sleep2) as String
	assert_eq(result1, "sleep1")
	assert_eq(result2, "sleep2")
