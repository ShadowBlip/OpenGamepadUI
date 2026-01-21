# Reaper

**Inherits:** [RefCounted](https://docs.godotengine.org/en/stable/classes/class_refcounted.html)


## Methods

| Returns | Signature |
| ------- | --------- |
| [int](https://docs.godotengine.org/en/stable/classes/class_int.html) | [create_process](./#create_process)(cmd: [String](https://docs.godotengine.org/en/stable/classes/class_string.html), args: [PackedStringArray](https://docs.godotengine.org/en/stable/classes/class_packedstringarray.html), app_id: [int](https://docs.godotengine.org/en/stable/classes/class_int.html) = -1) |
| [String](https://docs.godotengine.org/en/stable/classes/class_string.html) | [get_reaper_command](./#get_reaper_command)() |
| void | [reap](./#reap)(pid: [int](https://docs.godotengine.org/en/stable/classes/class_int.html), sig: [int](https://docs.godotengine.org/en/stable/classes/class_int.html) = 15) |
| [Array](https://docs.godotengine.org/en/stable/classes/class_array.html) | [get_children_with_pgid](./#get_children_with_pgid)(pid: [int](https://docs.godotengine.org/en/stable/classes/class_int.html), pgid: [int](https://docs.godotengine.org/en/stable/classes/class_int.html)) |
| [int](https://docs.godotengine.org/en/stable/classes/class_int.html) | [get_parent_pid](./#get_parent_pid)(pid: [int](https://docs.godotengine.org/en/stable/classes/class_int.html)) |
| [int](https://docs.godotengine.org/en/stable/classes/class_int.html) | [get_pid_group](./#get_pid_group)(pid: [int](https://docs.godotengine.org/en/stable/classes/class_int.html)) |
| [String](https://docs.godotengine.org/en/stable/classes/class_string.html) | [get_pid_state](./#get_pid_state)(pid: [int](https://docs.godotengine.org/en/stable/classes/class_int.html)) |
| [int](https://docs.godotengine.org/en/stable/classes/class_int.html) | [get_pid_property_int](./#get_pid_property_int)(pid: [int](https://docs.godotengine.org/en/stable/classes/class_int.html), key: [String](https://docs.godotengine.org/en/stable/classes/class_string.html)) |
| [Dictionary](https://docs.godotengine.org/en/stable/classes/class_dictionary.html) | [get_pid_status](./#get_pid_status)(pid: [int](https://docs.godotengine.org/en/stable/classes/class_int.html)) |
| [Dictionary[String, String]](https://docs.godotengine.org/en/stable/classes/class_dictionary.html) | [get_pid_environment](./#get_pid_environment)(pid: [int](https://docs.godotengine.org/en/stable/classes/class_int.html)) |
| [PackedInt64Array](https://docs.godotengine.org/en/stable/classes/class_packedint64array.html) | [get_pids](./#get_pids)() |
| [Array](https://docs.godotengine.org/en/stable/classes/class_array.html) | [pstree](./#pstree)(pid: [int](https://docs.godotengine.org/en/stable/classes/class_int.html)) |
| [bool](https://docs.godotengine.org/en/stable/classes/class_bool.html) | [is_gamescope_pid](./#is_gamescope_pid)(pid: [int](https://docs.godotengine.org/en/stable/classes/class_int.html)) |
| [Array](https://docs.godotengine.org/en/stable/classes/class_array.html) | [to_int_array](./#to_int_array)(arr: [Array](https://docs.godotengine.org/en/stable/classes/class_array.html)) |


------------------

## Method Descriptions

### `create_process()`


[int](https://docs.godotengine.org/en/stable/classes/class_int.html) **create_process**(cmd: [String](https://docs.godotengine.org/en/stable/classes/class_string.html), args: [PackedStringArray](https://docs.godotengine.org/en/stable/classes/class_packedstringarray.html), app_id: [int](https://docs.godotengine.org/en/stable/classes/class_int.html) = -1)


Spawn a process with PR_SET_CHILD_SUBREAPER set so child processes will reparent themselves to OpenGamepadUI. Returns the PID of the spawned process.
### `get_reaper_command()`


[String](https://docs.godotengine.org/en/stable/classes/class_string.html) **get_reaper_command**()


Discovers the 'reaper' binary to execute commands with PR_SET_CHILD_SUBREAPER.
### `reap()`


void **reap**(pid: [int](https://docs.godotengine.org/en/stable/classes/class_int.html), sig: [int](https://docs.godotengine.org/en/stable/classes/class_int.html) = 15)


!!! note
    There is currently no description for this method. Please help us by contributing one!

### `get_children_with_pgid()`


[Array](https://docs.godotengine.org/en/stable/classes/class_array.html) **get_children_with_pgid**(pid: [int](https://docs.godotengine.org/en/stable/classes/class_int.html), pgid: [int](https://docs.godotengine.org/en/stable/classes/class_int.html))


!!! note
    There is currently no description for this method. Please help us by contributing one!

### `get_parent_pid()`


[int](https://docs.godotengine.org/en/stable/classes/class_int.html) **get_parent_pid**(pid: [int](https://docs.godotengine.org/en/stable/classes/class_int.html))


!!! note
    There is currently no description for this method. Please help us by contributing one!

### `get_pid_group()`


[int](https://docs.godotengine.org/en/stable/classes/class_int.html) **get_pid_group**(pid: [int](https://docs.godotengine.org/en/stable/classes/class_int.html))


!!! note
    There is currently no description for this method. Please help us by contributing one!

### `get_pid_state()`


[String](https://docs.godotengine.org/en/stable/classes/class_string.html) **get_pid_state**(pid: [int](https://docs.godotengine.org/en/stable/classes/class_int.html))


!!! note
    There is currently no description for this method. Please help us by contributing one!

### `get_pid_property_int()`


[int](https://docs.godotengine.org/en/stable/classes/class_int.html) **get_pid_property_int**(pid: [int](https://docs.godotengine.org/en/stable/classes/class_int.html), key: [String](https://docs.godotengine.org/en/stable/classes/class_string.html))


!!! note
    There is currently no description for this method. Please help us by contributing one!

### `get_pid_status()`


[Dictionary](https://docs.godotengine.org/en/stable/classes/class_dictionary.html) **get_pid_status**(pid: [int](https://docs.godotengine.org/en/stable/classes/class_int.html))


!!! note
    There is currently no description for this method. Please help us by contributing one!

### `get_pid_environment()`


[Dictionary[String, String]](https://docs.godotengine.org/en/stable/classes/class_dictionary.html) **get_pid_environment**(pid: [int](https://docs.godotengine.org/en/stable/classes/class_int.html))


Returns the parsed environment for the given PID. Returns an empty dictionary if the PID is not found or we do not have permission to read the environment.
### `get_pids()`


[PackedInt64Array](https://docs.godotengine.org/en/stable/classes/class_packedint64array.html) **get_pids**()


Returns a list of all currently running processes
### `pstree()`


[Array](https://docs.godotengine.org/en/stable/classes/class_array.html) **pstree**(pid: [int](https://docs.godotengine.org/en/stable/classes/class_int.html))


!!! note
    There is currently no description for this method. Please help us by contributing one!

### `is_gamescope_pid()`


[bool](https://docs.godotengine.org/en/stable/classes/class_bool.html) **is_gamescope_pid**(pid: [int](https://docs.godotengine.org/en/stable/classes/class_int.html))


!!! note
    There is currently no description for this method. Please help us by contributing one!

### `to_int_array()`


[Array](https://docs.godotengine.org/en/stable/classes/class_array.html) **to_int_array**(arr: [Array](https://docs.godotengine.org/en/stable/classes/class_array.html))


!!! note
    There is currently no description for this method. Please help us by contributing one!

