extends Resource
class_name SharedThread

## Resource that allows nodes to run in a separate thread
##
## NodeThreads can belong to a SharedThread which will run their _thread_process
## method in the given thread

signal exec_completed(method: Callable, ret: Variant)

const watchdog := preload("res://core/systems/threading/watchdog_thread.tres")

var thread: Thread
var mutex := Mutex.new()
var running := false
var nodes: Array[NodeThread] = []
var process_funcs: Array[Callable] = []
var one_shots: Array[Callable] = []
var last_time: int
var logger := Log.get_logger("SharedThread", Log.LEVEL.DEBUG)

## Name of the thread group
@export var name := "SharedThread"
## Target rate to run at in ticks per second
@export var target_tick_rate := 60


func _init() -> void:
	watchdog.add_thread(self)


func _notification(what: int):
	if what == NOTIFICATION_PREDELETE:
		stop()
		

## Starts the thread for the thread group
func start() -> void:
	if running:
		return
	running = true
	thread = Thread.new()
	thread.start(_run)
	logger.info("Thread group started: " + name)


## Stops the thread for the thread group
func stop() -> void:
	if not running:
		return
	mutex.lock()
	running = false
	mutex.unlock()
	thread.wait_to_finish()
	logger.info("Thread group stopped: " + name)


## Add the given [NodeThread] to the list of nodes to process. This should
## happen automatically by the [NodeThread]
func add_node(node: NodeThread) -> void:
	mutex.lock()
	nodes.append(node)
	mutex.unlock()
	logger.debug("Added node: " + str(node))


## Remove the given [NodeThread] from the list of nodes to process. This should
## happen automatically when the [NodeThread] exits the scene tree.
func remove_node(node: NodeThread, stop_on_empty: bool = true) -> void:
	mutex.lock()
	nodes.erase(node)
	mutex.unlock()
	logger.debug("Removed node: " + str(node))
	if stop_on_empty and nodes.size() == 0:
		stop()


## Calls the given method from the thread. Internally, this queues the given 
## method and awaits it to be called during the process loop. You should await 
## this method if your method returns something. 
## E.g. [code]var result = await thread_group.exec(myfund.bind("myarg"))[/code]
func exec(method: Callable) -> Variant:
	mutex.lock()
	one_shots.append(method)
	mutex.unlock()
	var out: Array = [null]
	while out[0] != method:
		out = await exec_completed
	return out[1]


## Adds the given method to the thread process loop. This method will be called
## every thread tick.
func add_process(method: Callable) -> void:
	mutex.lock()
	process_funcs.append(method)
	mutex.unlock()


## Removes the given method from the thread process loop.
func remove_process(method: Callable) -> void:
	mutex.lock()
	process_funcs.erase(method)
	mutex.unlock()


func _run() -> void:
	var exited := false
	var current_tick_rate = target_tick_rate
	var target_frame_time_us := get_target_frame_time()
	last_time = Time.get_ticks_usec()
	while not exited:
		# If the tick rate has changed, update it.
		if target_tick_rate != current_tick_rate:
			current_tick_rate = target_tick_rate
			target_frame_time_us = get_target_frame_time()

		# Start timing how long this frame takes
		var start_time := Time.get_ticks_usec()

		# Calculate the delta between frames
		var last_delta_us := start_time - last_time
		last_time = start_time
		var delta := last_delta_us / 1000000.0

		# Process everything in the thread group
		exited = not running
		await _process(delta)

		# Calculate how long this frame took
		var end_time := Time.get_ticks_usec()
		var delta_us := end_time - start_time  # Time in microseconds since last input frame

		# If the last frame took less time than our target frame
		# rate, sleep for the difference.
		var sleep_time_us := target_frame_time_us - delta_us
		if delta_us < target_frame_time_us:
			OS.delay_usec(sleep_time_us)  # Throttle to save CPU
		else:
			var msg := (
				"{0} missed target frame time {1}us. Got: {2}us"
				.format([name, target_frame_time_us, delta_us])
			)
			logger.debug(msg)


func _process(delta: float) -> void:
	# Only lock our mutex fetching data, not during processing
	mutex.lock()
	var process_nodes := nodes.duplicate()
	var process_methods := one_shots.duplicate()
	var process_loops := process_funcs.duplicate()
	mutex.unlock()

	# Process any thread process methods
	for process in process_loops:
		process.call(delta)

	# Process nodes with _thread_process
	for node in process_nodes:
		node._thread_process(delta)
	
	# Call any one-shot thread methods
	var to_remove := []
	for method in process_methods:
		_async_call(method)
		to_remove.append(method)
	
	# Lock when mutating our list
	mutex.lock()
	for method in to_remove:
		one_shots.erase(method)
	mutex.unlock()


func _async_call(method: Callable) -> void:
	var ret = await method.call()
	emit_signal.call_deferred("exec_completed", method, ret)


## Returns the target frame time in microseconds of the SharedThread
func get_target_frame_time() -> int:
	return int((1.0 / target_tick_rate) * 1000000.0)
