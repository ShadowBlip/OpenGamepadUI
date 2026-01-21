# ThreadPool

**Inherits:** [Resource](https://docs.godotengine.org/en/stable/classes/class_resource.html)

Resource that allows executing methods in a thread pool
## Description

By default, the thread pool will create a thread for each detected core on the running machine. Each thread sleeps until a task is queued when [method exec](https://docs.godotengine.org/en/stable/classes/class_method exec.html) is called. When a task is queued, a thread will wake up and start working on the task until it is completed.
## Properties

| Type | Name | Default |
| ---- | ---- | ------- |
| [String](https://docs.godotengine.org/en/stable/classes/class_string.html) | [name](./#name) | "ThreadPool" |
| [int](https://docs.godotengine.org/en/stable/classes/class_int.html) | [size](./#size) | <unknown> |
| [bool](https://docs.godotengine.org/en/stable/classes/class_bool.html) | [running](./#running) | false |
| [Thread[]](https://docs.godotengine.org/en/stable/classes/class_thread.html) | [threads](./#threads) | [] |
| [Semaphore](https://docs.godotengine.org/en/stable/classes/class_semaphore.html) | [semaphore](./#semaphore) | <unknown> |
| [Mutex](https://docs.godotengine.org/en/stable/classes/class_mutex.html) | [mutex](./#mutex) | <unknown> |
| [ThreadPool.Task[]](../ThreadPool.Task) | [queue](./#queue) | [] |
| [CustomLogger](../CustomLogger) | [logger](./#logger) | <unknown> |

## Methods

| Returns | Signature |
| ------- | --------- |
| void | [start](./#start)() |
| void | [stop](./#stop)() |
| [bool](https://docs.godotengine.org/en/stable/classes/class_bool.html) | [is_running](./#is_running)() |
| [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html) | [exec](./#exec)(method: [Callable](https://docs.godotengine.org/en/stable/classes/class_callable.html), name: [String](https://docs.godotengine.org/en/stable/classes/class_string.html) = "") |


------------------

## Property Descriptions

### `name`


[String](https://docs.godotengine.org/en/stable/classes/class_string.html) name = <span style="color: red;">"ThreadPool"</span>


Name of the thread pool
### `size`


[int](https://docs.godotengine.org/en/stable/classes/class_int.html) size


Number of threads to create in the thread pool
### `running`


[bool](https://docs.godotengine.org/en/stable/classes/class_bool.html) running = <span style="color: red;">false</span>


!!! note
    There is currently no description for this property. Please help us by contributing one!

### `threads`


[Thread[]](https://docs.godotengine.org/en/stable/classes/class_thread.html) threads = <span style="color: red;">[]</span>


!!! note
    There is currently no description for this property. Please help us by contributing one!

### `semaphore`


[Semaphore](https://docs.godotengine.org/en/stable/classes/class_semaphore.html) semaphore


!!! note
    There is currently no description for this property. Please help us by contributing one!

### `mutex`


[Mutex](https://docs.godotengine.org/en/stable/classes/class_mutex.html) mutex


!!! note
    There is currently no description for this property. Please help us by contributing one!

### `queue`


[ThreadPool.Task[]](../ThreadPool.Task) queue = <span style="color: red;">[]</span>


!!! note
    There is currently no description for this property. Please help us by contributing one!

### `logger`


[CustomLogger](../CustomLogger) logger


!!! note
    There is currently no description for this property. Please help us by contributing one!




------------------

## Method Descriptions

### `start()`


void **start**()


Starts the threads for the thread pool
### `stop()`


void **stop**()


Stops the thread pool
### `is_running()`


[bool](https://docs.godotengine.org/en/stable/classes/class_bool.html) **is_running**()


Returns whether or not the thread pool is running
### `exec()`


[Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html) **exec**(method: [Callable](https://docs.godotengine.org/en/stable/classes/class_callable.html), name: [String](https://docs.godotengine.org/en/stable/classes/class_string.html) = "")


Calls the given method from the thread pool. Internally, this queues the given method and awaits it to be called during the process loop. You should await this method if your method returns something. E.g. [code](https://docs.godotengine.org/en/stable/classes/class_code.html)var result = await thread_pool.exec(myfund.bind("myarg"))[/code](https://docs.godotengine.org/en/stable/classes/class_/code.html)
