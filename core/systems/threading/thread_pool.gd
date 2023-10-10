extends Resource
class_name ThreadPool

## Resource that allows executing methods in a thread pool
##
## By default, the thread pool will create a thread for each detected core
## on the running machine. Each thread sleeps until a task is queued when
## [method exec] is called. When a task is queued, a thread will wake up and
## start working on the task until it is completed.

signal exec_completed(task: Task)

## Name of the thread pool
@export var name := "ThreadPool"
## Number of threads to create in the thread pool
@export var size := OS.get_processor_count()

var running := false
var threads: Array[Thread] = []
var semaphore := Semaphore.new()
var mutex := Mutex.new()
var queue: Array[Task] = []
var logger := Log.get_logger("ThreadPool", Log.LEVEL.INFO)


## A queued task to run in the thread pool
class Task extends RefCounted:
	var method: Callable
	var ret: Variant


func _notification(what: int):
	if what == NOTIFICATION_PREDELETE:
		for thread in threads:
			semaphore.post()
			thread.wait_to_finish()


## Starts the threads for the thread pool
func start() -> void:
	# Don't start if run from the editor (during doc generation)
	if Engine.is_editor_hint():
		logger.info("Not starting. Ran from editor.")
		return
	if is_running():
		return
	for i in range(size):
		var thread := Thread.new()
		thread.start(_process.bind(i))
		threads.append(thread)
	mutex.lock()
	running = true
	mutex.unlock()


## Stops the thread pool
func stop() -> void:
	if is_running():
		return
	mutex.lock()
	running = false
	mutex.unlock()
	for thread in threads:
		semaphore.post()
		thread.wait_to_finish()


## Returns whether or not the thread pool is running
func is_running() -> bool:
	mutex.lock()
	var run := running
	mutex.unlock()
	return run


## Calls the given method from the thread pool. Internally, this queues the given 
## method and awaits it to be called during the process loop. You should await 
## this method if your method returns something. 
## E.g. [code]var result = await thread_pool.exec(myfund.bind("myarg"))[/code]
func exec(method: Callable) -> Variant:
	if size == 0:
		return method.call()
	var task := Task.new()
	task.method = method
	mutex.lock()
	queue.append(task)
	mutex.unlock()
	semaphore.post()
	var out: Task
	while out != task:
		out = await exec_completed
	return out.ret


## Each thread in the pool waits for tasks and executes methods from the queue
func _process(id: int) -> void:
	logger.info("Started thread: " + str(id))
	# TODO: Fix unsafe thread operations
	Thread.set_thread_safety_checks_enabled(false)
	while true:
		semaphore.wait()
		mutex.lock()
		var should_exit := not running
		mutex.unlock()

		if should_exit:
			break

		mutex.lock()
		var task := queue.pop_front() as Task
		mutex.unlock()
		
		logger.debug("Processing task in thread " + str(id))
		_async_call(task)


func _async_call(task: Task) -> void:
	var ret = await task.method.call()
	task.ret = ret
	emit_signal.call_deferred("exec_completed", task)
