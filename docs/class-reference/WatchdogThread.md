# WatchdogThread

**Inherits:** [Resource](https://docs.godotengine.org/en/stable/classes/class_resource.html)


## Properties

| Type | Name | Default |
| ---- | ---- | ------- |
| [String](https://docs.godotengine.org/en/stable/classes/class_string.html) | [name](./#name) | "WatchdogThread" |
| [int](https://docs.godotengine.org/en/stable/classes/class_int.html) | [target_tick_rate](./#target_tick_rate) | 1 |
| [int](https://docs.godotengine.org/en/stable/classes/class_int.html) | [warn_after_num_missed_frames](./#warn_after_num_missed_frames) | 20 |
| [Thread](https://docs.godotengine.org/en/stable/classes/class_thread.html) | [thread](./#thread) | <unknown> |
| [SharedThread[]](../SharedThread) | [threads_to_watch](./#threads_to_watch) | [] |
| [bool](https://docs.godotengine.org/en/stable/classes/class_bool.html) | [running](./#running) | true |
| [Mutex](https://docs.godotengine.org/en/stable/classes/class_mutex.html) | [mutex](./#mutex) | <unknown> |
| [CustomLogger](../CustomLogger) | [logger](./#logger) | <unknown> |

## Methods

| Returns | Signature |
| ------- | --------- |
| void | [add_thread](./#add_thread)(thread: [SharedThread](../SharedThread)) |
| void | [stop](./#stop)() |
| [int](https://docs.godotengine.org/en/stable/classes/class_int.html) | [get_target_frame_time](./#get_target_frame_time)(tick_rate: [int](https://docs.godotengine.org/en/stable/classes/class_int.html)) |


------------------

## Property Descriptions

### `name`


[String](https://docs.godotengine.org/en/stable/classes/class_string.html) name = <span style="color: red;">"WatchdogThread"</span>


Name of the watchdog thread
### `target_tick_rate`


[int](https://docs.godotengine.org/en/stable/classes/class_int.html) target_tick_rate = <span style="color: red;">1</span>


Target rate to run at in ticks per second
### `warn_after_num_missed_frames`


[int](https://docs.godotengine.org/en/stable/classes/class_int.html) warn_after_num_missed_frames = <span style="color: red;">20</span>


Number of missed frame times before logging a warning that a thread might be blocked
### `thread`


[Thread](https://docs.godotengine.org/en/stable/classes/class_thread.html) thread


!!! note
    There is currently no description for this property. Please help us by contributing one!

### `threads_to_watch`


[SharedThread[]](../SharedThread) threads_to_watch = <span style="color: red;">[]</span>


!!! note
    There is currently no description for this property. Please help us by contributing one!

### `running`


[bool](https://docs.godotengine.org/en/stable/classes/class_bool.html) running = <span style="color: red;">true</span>


!!! note
    There is currently no description for this property. Please help us by contributing one!

### `mutex`


[Mutex](https://docs.godotengine.org/en/stable/classes/class_mutex.html) mutex


!!! note
    There is currently no description for this property. Please help us by contributing one!

### `logger`


[CustomLogger](../CustomLogger) logger


!!! note
    There is currently no description for this property. Please help us by contributing one!




------------------

## Method Descriptions

### `add_thread()`


void **add_thread**(thread: [SharedThread](../SharedThread))


Add the given shared thread
### `stop()`


void **stop**()


Stops the thread
### `get_target_frame_time()`


[int](https://docs.godotengine.org/en/stable/classes/class_int.html) **get_target_frame_time**(tick_rate: [int](https://docs.godotengine.org/en/stable/classes/class_int.html))


Returns the target frame time in microseconds of the WatchdogThread
