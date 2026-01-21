# CPU

**Inherits:** [Resource](https://docs.godotengine.org/en/stable/classes/class_resource.html)

Read and manage the system CPU
## Properties

| Type | Name | Default |
| ---- | ---- | ------- |
| [int](https://docs.godotengine.org/en/stable/classes/class_int.html) | [core_count](./#core_count) | get_total_core_count() |
| [String](https://docs.godotengine.org/en/stable/classes/class_string.html) | [vendor](./#vendor) |  |
| [String](https://docs.godotengine.org/en/stable/classes/class_string.html) | [model](./#model) |  |
| [CustomLogger](../CustomLogger) | [logger](./#logger) | <unknown> |

## Methods

| Returns | Signature |
| ------- | --------- |
| [int](https://docs.godotengine.org/en/stable/classes/class_int.html) | [get_enabled_core_count](./#get_enabled_core_count)() |
| [CPUCore](../CPUCore) | [get_core](./#get_core)(num: [int](https://docs.godotengine.org/en/stable/classes/class_int.html)) |
| [CPUCore[]](../CPUCore) | [get_cores](./#get_cores)() |
| [int](https://docs.godotengine.org/en/stable/classes/class_int.html) | [get_total_core_count](./#get_total_core_count)() |
| [int](https://docs.godotengine.org/en/stable/classes/class_int.html) | [get_online_core_count](./#get_online_core_count)() |


------------------

## Property Descriptions

### `core_count`


[int](https://docs.godotengine.org/en/stable/classes/class_int.html) core_count = <span style="color: red;">get_total_core_count()</span>


!!! note
    There is currently no description for this property. Please help us by contributing one!

### `vendor`


[String](https://docs.godotengine.org/en/stable/classes/class_string.html) vendor


!!! note
    There is currently no description for this property. Please help us by contributing one!

### `model`


[String](https://docs.godotengine.org/en/stable/classes/class_string.html) model


!!! note
    There is currently no description for this property. Please help us by contributing one!

### `logger`


[CustomLogger](../CustomLogger) logger


!!! note
    There is currently no description for this property. Please help us by contributing one!




------------------

## Method Descriptions

### `get_enabled_core_count()`


[int](https://docs.godotengine.org/en/stable/classes/class_int.html) **get_enabled_core_count**()


Returns the count of number of enabled CPU cores
### `get_core()`


[CPUCore](../CPUCore) **get_core**(num: [int](https://docs.godotengine.org/en/stable/classes/class_int.html))


Returns an instance of the given CPU core
### `get_cores()`


[CPUCore[]](../CPUCore) **get_cores**()


Returns an array of all CPU cores
### `get_total_core_count()`


[int](https://docs.godotengine.org/en/stable/classes/class_int.html) **get_total_core_count**()


Returns the total number of detected CPU cores
### `get_online_core_count()`


[int](https://docs.godotengine.org/en/stable/classes/class_int.html) **get_online_core_count**()


Returns the total number of CPU cores that are online
