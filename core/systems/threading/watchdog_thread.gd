extends Resource
class_name WatchdogThread

## Name of the watchdog thread
@export var name := "WatchdogThread"
## Target rate to run at in ticks per second
@export var target_tick_rate := 1
## Number of missed frame times before logging a warning that a thread might be blocked
@export var warn_after_num_missed_frames := 20

var thread := Thread.new()
var threads_to_watch: Array[SharedThread] = []
var running := true
var mutex := Mutex.new()
var logger := Log.get_logger(name)


func _init() -> void:
	thread.start(_run)
	logger.info("Watchdog thread started")


func _notification(what: int):
	if what == NOTIFICATION_PREDELETE:
		stop()


## Add the given shared thread
func add_thread(thread: SharedThread) -> void:
	mutex.lock()
	threads_to_watch.append(thread)
	mutex.unlock()


## Stops the thread
func stop() -> void:
	if not running:
		return
	mutex.lock()
	running = false
	mutex.unlock()
	thread.wait_to_finish()
	logger.info("Thread stopped: " + name)


func _run() -> void:
	# TODO: Fix unsafe thread operations
	Thread.set_thread_safety_checks_enabled(false)
	var exited := false
	var current_tick_rate = target_tick_rate
	var target_frame_time_us := get_target_frame_time(target_tick_rate)
	var last_time := Time.get_ticks_usec()
	while not exited:
		# If the tick rate has changed, update it.
		if target_tick_rate != current_tick_rate:
			current_tick_rate = target_tick_rate
			target_frame_time_us = get_target_frame_time(target_tick_rate)

		# Start timing how long this frame takes
		var start_time := Time.get_ticks_usec()

		# Calculate the delta between frames
		var last_delta_us := start_time - last_time
		last_time = start_time

		# Process everything in the thread group
		exited = not running
		await _process()

		# Calculate how long this frame took
		var end_time := Time.get_ticks_usec()
		var delta_us := end_time - start_time  # Time in microseconds since last input frame

		# If the last frame took less time than our target frame
		# rate, sleep for the difference.
		var sleep_time_us := target_frame_time_us - delta_us
		if delta_us < target_frame_time_us:
			OS.delay_usec(sleep_time_us)  # Throttle to save CPU


func _process() -> void:
	for thread in threads_to_watch:
		if not thread.running:
			continue
		_check_frame_time(thread)


## Checks whether or not the given thread has significantly missed its frame time
func _check_frame_time(thread: SharedThread) -> void:
	# Find how long it's been since this thread has last executed its loop
	var current_time := Time.get_ticks_usec()
	var thread_last_time := thread.last_time as int
	var time_since_us := current_time - thread_last_time
	
	# Compare how long its been with the target tick rate for the thread
	var target_time_us := get_target_frame_time(thread.target_tick_rate)
	if time_since_us > (target_time_us * warn_after_num_missed_frames):
		var time_since := time_since_us / 1000000.0
		logger.warn("Thread '" + thread.name + "' has been blocked for {0} seconds".format([time_since]))


## Returns the target frame time in microseconds of the WatchdogThread
func get_target_frame_time(tick_rate: int) -> int:
	return int((1.0 / tick_rate) * 1000000.0)
