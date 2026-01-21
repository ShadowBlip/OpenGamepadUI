# SharedThread

**Inherits:** [Resource](https://docs.godotengine.org/en/stable/classes/class_resource.html)

Resource that allows nodes to run in a separate thread
## Description

NodeThreads can belong to a SharedThread which will run their _thread_process method in the given thread
## Properties

| Type | Name | Default |
| ---- | ---- | ------- |
| [Thread](https://docs.godotengine.org/en/stable/classes/class_thread.html) | [thread](./#thread) |  |
| [Mutex](https://docs.godotengine.org/en/stable/classes/class_mutex.html) | [mutex](./#mutex) | <unknown> |
| [int](https://docs.godotengine.org/en/stable/classes/class_int.html) | [tid](./#tid) | -1 |
| [bool](https://docs.godotengine.org/en/stable/classes/class_bool.html) | [running](./#running) | false |
| [SharedThread.ExecutingTask](../SharedThread.ExecutingTask) | [executing_task](./#executing_task) |  |
| [NodeThread[]](../NodeThread) | [nodes](./#nodes) | [] |
| [Callable[]](https://docs.godotengine.org/en/stable/classes/class_callable.html) | [process_funcs](./#process_funcs) | [] |
| [SharedThread.ScheduledTask[]](../SharedThread.ScheduledTask) | [scheduled_funcs](./#scheduled_funcs) | [] |
| [Callable[]](https://docs.godotengine.org/en/stable/classes/class_callable.html) | [one_shots](./#one_shots) | [] |
| [int](https://docs.godotengine.org/en/stable/classes/class_int.html) | [last_time](./#last_time) |  |
| [int](https://docs.godotengine.org/en/stable/classes/class_int.html) | [task_id_count](./#task_id_count) | 0 |
| [CustomLogger](../CustomLogger) | [logger](./#logger) | <unknown> |
| [String](https://docs.godotengine.org/en/stable/classes/class_string.html) | [name](./#name) | "SharedThread" |
| [int](https://docs.godotengine.org/en/stable/classes/class_int.html) | [target_tick_rate](./#target_tick_rate) | 60 |
| [int](https://docs.godotengine.org/en/stable/classes/class_int.html) | [niceness](./#niceness) | 0 |
| [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html) | [watchdog_enabled](./#watchdog_enabled) | true |

## Methods

| Returns | Signature |
| ------- | --------- |
| void | [start](./#start)() |
| void | [stop](./#stop)() |
| [int](https://docs.godotengine.org/en/stable/classes/class_int.html) | [set_priority](./#set_priority)(value: [int](https://docs.godotengine.org/en/stable/classes/class_int.html)) |
| void | [add_node](./#add_node)(node: [NodeThread](../NodeThread)) |
| void | [remove_node](./#remove_node)(node: [NodeThread](../NodeThread), stop_on_empty: [bool](https://docs.godotengine.org/en/stable/classes/class_bool.html) = true) |
| [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html) | [exec](./#exec)(method: [Callable](https://docs.godotengine.org/en/stable/classes/class_callable.html)) |
| [int](https://docs.godotengine.org/en/stable/classes/class_int.html) | [scheduled_exec](./#scheduled_exec)(method: [Callable](https://docs.godotengine.org/en/stable/classes/class_callable.html), wait_time_ms: [int](https://docs.godotengine.org/en/stable/classes/class_int.html), task_type: [int](https://docs.godotengine.org/en/stable/classes/class_int.html) = 0) |
| void | [cancel_scheduled_exec](./#cancel_scheduled_exec)(task_id: [int](https://docs.godotengine.org/en/stable/classes/class_int.html)) |
| void | [add_process](./#add_process)(method: [Callable](https://docs.godotengine.org/en/stable/classes/class_callable.html)) |
| void | [remove_process](./#remove_process)(method: [Callable](https://docs.godotengine.org/en/stable/classes/class_callable.html)) |
| [SharedThread.ExecutingTask](../SharedThread.ExecutingTask) | [get_executing_task](./#get_executing_task)() |
| [int](https://docs.godotengine.org/en/stable/classes/class_int.html) | [get_target_frame_time](./#get_target_frame_time)() |


------------------

## Property Descriptions

### `thread`


[Thread](https://docs.godotengine.org/en/stable/classes/class_thread.html) thread


!!! note
    There is currently no description for this property. Please help us by contributing one!

### `mutex`


[Mutex](https://docs.godotengine.org/en/stable/classes/class_mutex.html) mutex


!!! note
    There is currently no description for this property. Please help us by contributing one!

### `tid`


[int](https://docs.godotengine.org/en/stable/classes/class_int.html) tid = <span style="color: red;">-1</span>


!!! note
    There is currently no description for this property. Please help us by contributing one!

### `running`


[bool](https://docs.godotengine.org/en/stable/classes/class_bool.html) running = <span style="color: red;">false</span>


!!! note
    There is currently no description for this property. Please help us by contributing one!

### `executing_task`


[SharedThread.ExecutingTask](../SharedThread.ExecutingTask) executing_task


!!! note
    There is currently no description for this property. Please help us by contributing one!

### `nodes`


[NodeThread[]](../NodeThread) nodes = <span style="color: red;">[]</span>


!!! note
    There is currently no description for this property. Please help us by contributing one!

### `process_funcs`


[Callable[]](https://docs.godotengine.org/en/stable/classes/class_callable.html) process_funcs = <span style="color: red;">[]</span>


!!! note
    There is currently no description for this property. Please help us by contributing one!

### `scheduled_funcs`


[SharedThread.ScheduledTask[]](../SharedThread.ScheduledTask) scheduled_funcs = <span style="color: red;">[]</span>


!!! note
    There is currently no description for this property. Please help us by contributing one!

### `one_shots`


[Callable[]](https://docs.godotengine.org/en/stable/classes/class_callable.html) one_shots = <span style="color: red;">[]</span>


!!! note
    There is currently no description for this property. Please help us by contributing one!

### `last_time`


[int](https://docs.godotengine.org/en/stable/classes/class_int.html) last_time


!!! note
    There is currently no description for this property. Please help us by contributing one!

### `task_id_count`


[int](https://docs.godotengine.org/en/stable/classes/class_int.html) task_id_count = <span style="color: red;">0</span>


!!! note
    There is currently no description for this property. Please help us by contributing one!

### `logger`


[CustomLogger](../CustomLogger) logger


!!! note
    There is currently no description for this property. Please help us by contributing one!

### `name`


[String](https://docs.godotengine.org/en/stable/classes/class_string.html) name = <span style="color: red;">"SharedThread"</span>


Name of the thread group
### `target_tick_rate`


[int](https://docs.godotengine.org/en/stable/classes/class_int.html) target_tick_rate = <span style="color: red;">60</span>


Target rate to run at in ticks per second
### `niceness`


[int](https://docs.godotengine.org/en/stable/classes/class_int.html) niceness = <span style="color: red;">0</span>


Priority (niceness) of the thread
### `watchdog_enabled`


[Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html) watchdog_enabled = <span style="color: red;">true</span>


If watchdog should be enabled on this thread



------------------

## Method Descriptions

### `start()`


void **start**()


Starts the thread for the thread group
### `stop()`


void **stop**()


Stops the thread for the thread group
### `set_priority()`


[int](https://docs.godotengine.org/en/stable/classes/class_int.html) **set_priority**(value: [int](https://docs.godotengine.org/en/stable/classes/class_int.html))


Set the given thread niceness to the given value. Note: in order to set negative nice value, this must be run: setcap 'cap_sys_nice=eip' <opengamepadui binary>
### `add_node()`


void **add_node**(node: [NodeThread](../NodeThread))


Add the given [NodeThread](../NodeThread) to the list of nodes to process. This should happen automatically by the [NodeThread](../NodeThread)
### `remove_node()`


void **remove_node**(node: [NodeThread](../NodeThread), stop_on_empty: [bool](https://docs.godotengine.org/en/stable/classes/class_bool.html) = true)


Remove the given [NodeThread](../NodeThread) from the list of nodes to process. This should happen automatically when the [NodeThread](../NodeThread) exits the scene tree.
### `exec()`


[Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html) **exec**(method: [Callable](https://docs.godotengine.org/en/stable/classes/class_callable.html))


Calls the given method from the thread. Internally, this queues the given method and awaits it to be called during the process loop. You should await this method if your method returns something. E.g. [code](https://docs.godotengine.org/en/stable/classes/class_code.html)var result = await thread_group.exec(myfund.bind("myarg"))[/code](https://docs.godotengine.org/en/stable/classes/class_/code.html)
### `scheduled_exec()`


[int](https://docs.godotengine.org/en/stable/classes/class_int.html) **scheduled_exec**(method: [Callable](https://docs.godotengine.org/en/stable/classes/class_callable.html), wait_time_ms: [int](https://docs.godotengine.org/en/stable/classes/class_int.html), task_type: [int](https://docs.godotengine.org/en/stable/classes/class_int.html) = 0)


Calls the given method from the thread after 'wait_time_ms' has passed. By default, this method will execute as a "oneshot" task. Optionally, the "task_type" parameter can be set to "RECURRING" if this task should run every 'wait_time_ms'.
### `cancel_scheduled_exec()`


void **cancel_scheduled_exec**(task_id: [int](https://docs.godotengine.org/en/stable/classes/class_int.html))


Cancels a given Sheduled Task
### `add_process()`


void **add_process**(method: [Callable](https://docs.godotengine.org/en/stable/classes/class_callable.html))


Adds the given method to the thread process loop. This method will be called every thread tick.
### `remove_process()`


void **remove_process**(method: [Callable](https://docs.godotengine.org/en/stable/classes/class_callable.html))


Removes the given method from the thread process loop.
### `get_executing_task()`


[SharedThread.ExecutingTask](../SharedThread.ExecutingTask) **get_executing_task**()


Returns the currently executing task
### `get_target_frame_time()`


[int](https://docs.godotengine.org/en/stable/classes/class_int.html) **get_target_frame_time**()


Returns the target frame time in microseconds of the SharedThread
