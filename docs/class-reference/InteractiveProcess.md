# InteractiveProcess

**Inherits:** [Resource](https://docs.godotengine.org/en/stable/classes/class_resource.html)

Class for starting an interacting with a process through a psuedo terminal
## Description

Starts an interactive session
## Properties

| Type | Name | Default |
| ---- | ---- | ------- |
| [Pty](../Pty) | [pty](./#pty) |  |
| [String](https://docs.godotengine.org/en/stable/classes/class_string.html) | [cmd](./#cmd) |  |
| [PackedStringArray](https://docs.godotengine.org/en/stable/classes/class_packedstringarray.html) | [args](./#args) | [] |
| [int](https://docs.godotengine.org/en/stable/classes/class_int.html) | [pid](./#pid) |  |
| [Platform](../Platform) | [platform](./#platform) | <unknown> |
| [ResourceRegistry](../ResourceRegistry) | [registry](./#registry) | <unknown> |
| [Mutex](https://docs.godotengine.org/en/stable/classes/class_mutex.html) | [lines_mutex](./#lines_mutex) | <unknown> |
| [PackedStringArray](https://docs.godotengine.org/en/stable/classes/class_packedstringarray.html) | [lines_buffer](./#lines_buffer) | PackedStringArray() |
| [CustomLogger](../CustomLogger) | [logger](./#logger) | <unknown> |

## Methods

| Returns | Signature |
| ------- | --------- |
| [int](https://docs.godotengine.org/en/stable/classes/class_int.html) | [start](./#start)() |
| void | [send](./#send)(input: [String](https://docs.godotengine.org/en/stable/classes/class_string.html)) |
| [String](https://docs.godotengine.org/en/stable/classes/class_string.html) | [read](./#read)(_chunk_size: [int](https://docs.godotengine.org/en/stable/classes/class_int.html) = 1024) |
| void | [stop](./#stop)() |
| [bool](https://docs.godotengine.org/en/stable/classes/class_bool.html) | [is_running](./#is_running)() |
| [int](https://docs.godotengine.org/en/stable/classes/class_int.html) | [output_to_log_file](./#output_to_log_file)(log_file: [FileAccess](https://docs.godotengine.org/en/stable/classes/class_fileaccess.html), _chunk_size: [int](https://docs.godotengine.org/en/stable/classes/class_int.html) = 1024) |


------------------

## Property Descriptions

### `pty`


[Pty](../Pty) pty


!!! note
    There is currently no description for this property. Please help us by contributing one!

### `cmd`


[String](https://docs.godotengine.org/en/stable/classes/class_string.html) cmd


!!! note
    There is currently no description for this property. Please help us by contributing one!

### `args`


[PackedStringArray](https://docs.godotengine.org/en/stable/classes/class_packedstringarray.html) args = <span style="color: red;">[]</span>


!!! note
    There is currently no description for this property. Please help us by contributing one!

### `pid`


[int](https://docs.godotengine.org/en/stable/classes/class_int.html) pid


!!! note
    There is currently no description for this property. Please help us by contributing one!

### `platform`


[Platform](../Platform) platform


!!! note
    There is currently no description for this property. Please help us by contributing one!

### `registry`


[ResourceRegistry](../ResourceRegistry) registry


!!! note
    There is currently no description for this property. Please help us by contributing one!

### `lines_mutex`


[Mutex](https://docs.godotengine.org/en/stable/classes/class_mutex.html) lines_mutex


!!! note
    There is currently no description for this property. Please help us by contributing one!

### `lines_buffer`


[PackedStringArray](https://docs.godotengine.org/en/stable/classes/class_packedstringarray.html) lines_buffer = <span style="color: red;">PackedStringArray()</span>


!!! note
    There is currently no description for this property. Please help us by contributing one!

### `logger`


[CustomLogger](../CustomLogger) logger


!!! note
    There is currently no description for this property. Please help us by contributing one!




------------------

## Method Descriptions

### `start()`


[int](https://docs.godotengine.org/en/stable/classes/class_int.html) **start**()


Start the interactive process
### `send()`


void **send**(input: [String](https://docs.godotengine.org/en/stable/classes/class_string.html))


Send the given input to the running process
### `read()`


[String](https://docs.godotengine.org/en/stable/classes/class_string.html) **read**(_chunk_size: [int](https://docs.godotengine.org/en/stable/classes/class_int.html) = 1024)


Read from the stdout of the running process
### `stop()`


void **stop**()


Stop the given process
### `is_running()`


[bool](https://docs.godotengine.org/en/stable/classes/class_bool.html) **is_running**()


Returns whether or not the interactive process is still running
### `output_to_log_file()`


[int](https://docs.godotengine.org/en/stable/classes/class_int.html) **output_to_log_file**(log_file: [FileAccess](https://docs.godotengine.org/en/stable/classes/class_fileaccess.html), _chunk_size: [int](https://docs.godotengine.org/en/stable/classes/class_int.html) = 1024)


!!! note
    There is currently no description for this method. Please help us by contributing one!

