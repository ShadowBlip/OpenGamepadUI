# Platform

**Inherits:** [Resource](https://docs.godotengine.org/en/stable/classes/class_resource.html)

Platform specific methods
## Description

Used to perform platform-specific functions
## Properties

| Type | Name | Default |
| ---- | ---- | ------- |
| [HardwareManager](../HardwareManager) | [hardware_manager](./#hardware_manager) | <unknown> |
| [Platform.OSInfo](../Platform.OSInfo) | [os_info](./#os_info) | _detect_os() |
| [OSPlatform](../OSPlatform) | [os](./#os) |  |
| [PlatformProvider](../PlatformProvider) | [platform](./#platform) |  |
| [CustomLogger](../CustomLogger) | [logger](./#logger) | <unknown> |
| [bool](https://docs.godotengine.org/en/stable/classes/class_bool.html) | [loaded](./#loaded) |  |

## Methods

| Returns | Signature |
| ------- | --------- |
| void | [load](./#load)(root: [Window](https://docs.godotengine.org/en/stable/classes/class_window.html)) |
| [int[]](https://docs.godotengine.org/en/stable/classes/class_int.html) | [get_platform_flags](./#get_platform_flags)() |


------------------

## Property Descriptions

### `hardware_manager`


[HardwareManager](../HardwareManager) hardware_manager


!!! note
    There is currently no description for this property. Please help us by contributing one!

### `os_info`


[Platform.OSInfo](../Platform.OSInfo) os_info = <span style="color: red;">_detect_os()</span>


Detected Operating System information
### `os`


[OSPlatform](../OSPlatform) os


The OS platform provider detected
### `platform`


[PlatformProvider](../PlatformProvider) platform


The hardware platform provider detected
### `logger`


[CustomLogger](../CustomLogger) logger


!!! note
    There is currently no description for this property. Please help us by contributing one!

### `loaded`


[bool](https://docs.godotengine.org/en/stable/classes/class_bool.html) loaded


!!! note
    There is currently no description for this property. Please help us by contributing one!




------------------

## Method Descriptions

### `load()`


void **load**(root: [Window](https://docs.godotengine.org/en/stable/classes/class_window.html))


Loads the detected platforms. This should be called once when OpenGamepadUI first starts. It takes the root window to give platform providers the opportinity to modify the scene tree.
### `get_platform_flags()`


[int[]](https://docs.godotengine.org/en/stable/classes/class_int.html) **get_platform_flags**()


Returns all detected platform flags
