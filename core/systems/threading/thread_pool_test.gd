extends Test

var thread_pool := ThreadPool.new()


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	thread_pool.start()
	print("Thread pool started")
	var sleep1 := func():
		OS.delay_msec(5000)
		print("sleep1 done")
		return "sleep1"
	var sleep2 := func():
		OS.delay_msec(10000)
		print("sleep2 done")
		return "sleep2"
		
	thread_pool.exec(sleep1)
	thread_pool.exec(sleep2)


func _exit_tree() -> void:
	thread_pool.stop()
