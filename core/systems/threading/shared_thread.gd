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
var tid := -1
var running := false
var nodes: Array[NodeThread] = []
var process_funcs: Array[Callable] = []
var scheduled_funcs: Array[ScheduledTask] = []
var one_shots: Array[Callable] = []
var last_time: int
var logger := Log.get_logger("SharedThread", Log.LEVEL.INFO)

## Name of the thread group
@export var name := "SharedThread"
## Target rate to run at in ticks per second
@export var target_tick_rate := 60
## Priority (niceness) of the thread
@export var niceness := 0


func _init() -> void:
	watchdog.add_thread(self)


func _notification(what: int):
	if what == NOTIFICATION_PREDELETE:
		stop()


## Starts the thread for the thread group
func start() -> void:
	# Don't start if run from the editor (during doc generation)
	if Engine.is_editor_hint():
		logger.info("Not starting. Ran from editor.")
		return
	if running:
		return
	running = true
	thread = Thread.new()
	thread.start(_run)
	logger.info("Shared thread started: " + name)


## Stops the thread for the thread group
func stop() -> void:
	if not running:
		return
	mutex.lock()
	running = false
	mutex.unlock()
	thread.wait_to_finish()
	logger.info("Shared thread stopped: " + name)


## Set the given thread niceness to the given value.
## Note: in order to set negative nice value, this must be run:
## setcap 'cap_sys_nice=eip' <opengamepadui binary>
func set_priority(value: int) -> int:
	# If this was called from another thread, schedule it to run on the thread
	mutex.lock()
	var thread_id := tid
	mutex.unlock()
	if LinuxThread.get_tid() != thread_id:
		logger.debug("Set thread priority was called from another thread")
		return await exec(set_priority.bind(value))
	
	# Set the thread priority if this function was called from the SharedThread
	var err := LinuxThread.set_thread_priority(value)
	if err == OK:
		niceness = value
		logger.info("Set thread niceness on {0} ({1}) to: {2}".format([name, thread_id, value]))
	
	return err


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


## Calls the given method from the thread after 'wait_time_ms' has passed.
func scheduled_exec(method: Callable, wait_time_ms: int) -> void:
	var task := ScheduledTask.new()
	task.method = method
	task.wait_time_ms = wait_time_ms
	task.start_time = Time.get_ticks_msec()
	mutex.lock()
	scheduled_funcs.append(task)
	mutex.unlock()


## Cancels a given Sheduled Task before it is executed.
func cancel_scheduled_exec(task: ScheduledTask) -> void:
	mutex.lock()
	var all_sched_funcs := scheduled_funcs.duplicate()
	mutex.unlock()
	if task not in all_sched_funcs:
		logger.warn("Scheduled Task " + task.method.get_method() + " canceled but not found in scheduled functions."  )
		return
	mutex.lock()
	scheduled_funcs.erase(task)
	mutex.unlock()


## Finds all SheduledTask's who's method matches the given method.
func find_scheduled_exec(method: Callable) -> Array[ScheduledTask]:
	mutex.lock()
	var all_sched_funcs := scheduled_funcs.duplicate()
	mutex.unlock()
	var matching_tasks: Array[ScheduledTask] = []
	for task in all_sched_funcs:
		if task.method == method:
			matching_tasks.append(task)
	return matching_tasks


## Adds the given method to the thread process loop. This method will be called
## every thread tick.
func add_process(method: Callable) -> void:
	mutex.lock()
	process_funcs.append(method)
	mutex.unlock()


## Removes the given method from the thread process loop.
func remove_process(method: Callable) -> void:
	if method not in process_funcs:
		logger.warn("Method " + method.get_method() + " canceled but not found in processing functions."  )
		return
	mutex.lock()
	process_funcs.erase(method)
	mutex.unlock()


func _run() -> void:
	# Update the thread ID
	mutex.lock()
	tid = LinuxThread.get_tid()
	mutex.unlock()
	logger.info("Started thread with thread ID: " + str(LinuxThread.get_tid()))
	
	# If the nice value isn't default, reassign the thread priority
	if niceness != 0:
		if await set_priority(niceness) != OK:
			logger.warn("Unable to set niceness on thread: " + name)
	
	# TODO: Fix unsafe thread operations
	Thread.set_thread_safety_checks_enabled(false)
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
	var process_nodes := nodes.duplicate() as Array[NodeThread]
	var process_methods := one_shots.duplicate() as Array[Callable]
	var process_scheduled := scheduled_funcs.duplicate() as Array[ScheduledTask]
	var process_loops := process_funcs.duplicate() as Array[Callable]
	mutex.unlock()

	# Process any thread process methods
	for process in process_loops:
		if not is_instance_valid(process.get_object()):
			continue
		process.call(delta)

	# Process nodes with _thread_process
	for node in process_nodes:
		if not is_instance_valid(node):
			continue
		node._thread_process(delta)
	
	# Call any one-shot thread methods
	for method in process_methods:
		if not is_instance_valid(method.get_object()):
			continue
		_async_call(method)
		mutex.lock()
		one_shots.erase(method)
		mutex.unlock()
	
	# Call any scheduled methods
	for task in process_scheduled:
		var current_time := Time.get_ticks_msec()
		if current_time - task.start_time < task.wait_time_ms:
			continue
		var method := task.method as Callable
		if not is_instance_valid(method.get_object()):
			continue
		method.call()
		mutex.lock()
		scheduled_funcs.erase(task)
		mutex.unlock()


func _async_call(method: Callable) -> void:
	var ret = await method.call()
	emit_signal.call_deferred("exec_completed", method, ret)


## Returns the target frame time in microseconds of the SharedThread
func get_target_frame_time() -> int:
	return int((1.0 / target_tick_rate) * 1000000.0)


## Container for holding a scheduled task to run in a thread
class ScheduledTask:
	var start_time: int
	var wait_time_ms: int
	var method: Callable
