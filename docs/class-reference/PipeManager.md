# PipeManager

**Inherits:** [Node](https://docs.godotengine.org/en/stable/classes/class_node.html)

Class for managing control messages sent through a named pipe
## Description

The [PipeManager](../PipeManager) creates a named pipe in `/run/user/<uid>/opengamepadui` that can be used as a communication mechanism to send OpenGamepadUI commands from another process. This is mostly done to handle custom `ogui://` URIs which can be used to react in different ways.
## Properties

| Type | Name | Default |
| ---- | ---- | ------- |
| [LaunchManager](../LaunchManager) | [launch_manager](./#launch_manager) | <unknown> |
| [LibraryManager](../LibraryManager) | [library_manager](./#library_manager) | <unknown> |
| [SettingsManager](../SettingsManager) | [settings_manager](./#settings_manager) | <unknown> |
| [FifoReader](../FifoReader) | [pipe](./#pipe) |  |
| [String](https://docs.godotengine.org/en/stable/classes/class_string.html) | [pipe_path](./#pipe_path) |  |
| [CustomLogger](../CustomLogger) | [logger](./#logger) | <unknown> |

## Methods

| Returns | Signature |
| ------- | --------- |
| [String](https://docs.godotengine.org/en/stable/classes/class_string.html) | [get_pipe_path](./#get_pipe_path)() |
| [String](https://docs.godotengine.org/en/stable/classes/class_string.html) | [get_run_path](./#get_run_path)() |
| [int](https://docs.godotengine.org/en/stable/classes/class_int.html) | [get_uid](./#get_uid)() |


------------------

## Property Descriptions

### `launch_manager`


[LaunchManager](../LaunchManager) launch_manager


!!! note
    There is currently no description for this property. Please help us by contributing one!

### `library_manager`


[LibraryManager](../LibraryManager) library_manager


!!! note
    There is currently no description for this property. Please help us by contributing one!

### `settings_manager`


[SettingsManager](../SettingsManager) settings_manager


!!! note
    There is currently no description for this property. Please help us by contributing one!

### `pipe`


[FifoReader](../FifoReader) pipe


!!! note
    There is currently no description for this property. Please help us by contributing one!

### `pipe_path`


[String](https://docs.godotengine.org/en/stable/classes/class_string.html) pipe_path


!!! note
    There is currently no description for this property. Please help us by contributing one!

### `logger`


[CustomLogger](../CustomLogger) logger


!!! note
    There is currently no description for this property. Please help us by contributing one!




------------------

## Method Descriptions

### `get_pipe_path()`


[String](https://docs.godotengine.org/en/stable/classes/class_string.html) **get_pipe_path**()


Returns the path to the named pipe (e.g. /run/user/1000/opengamepadui/opengamepadui-0)
### `get_run_path()`


[String](https://docs.godotengine.org/en/stable/classes/class_string.html) **get_run_path**()


Returns the run path for the current user (e.g. /run/user/1000/opengamepadui)
### `get_uid()`


[int](https://docs.godotengine.org/en/stable/classes/class_int.html) **get_uid**()


Returns the current user id (e.g. 1000)
