# DRMCardPort

**Inherits:** [Resource](https://docs.godotengine.org/en/stable/classes/class_resource.html)

GPU connector port state
## Description

Represents the data contained in /sys/class/drm/cardX-YYYY and includes an update function that can be called to update the state of the connector port.
## Properties

| Type | Name | Default |
| ---- | ---- | ------- |
| [Mutex](https://docs.godotengine.org/en/stable/classes/class_mutex.html) | [mutex](./#mutex) | <unknown> |
| [String](https://docs.godotengine.org/en/stable/classes/class_string.html) | [name](./#name) |  |
| [String](https://docs.godotengine.org/en/stable/classes/class_string.html) | [path](./#path) |  |
| [int](https://docs.godotengine.org/en/stable/classes/class_int.html) | [connector_id](./#connector_id) | -1 |
| [bool](https://docs.godotengine.org/en/stable/classes/class_bool.html) | [enabled](./#enabled) | false |
| [PackedStringArray](https://docs.godotengine.org/en/stable/classes/class_packedstringarray.html) | [modes](./#modes) | PackedStringArray() |
| [String](https://docs.godotengine.org/en/stable/classes/class_string.html) | [status](./#status) |  |
| [bool](https://docs.godotengine.org/en/stable/classes/class_bool.html) | [dpms](./#dpms) |  |

## Methods

| Returns | Signature |
| ------- | --------- |
| void | [update](./#update)() |
| [int](https://docs.godotengine.org/en/stable/classes/class_int.html) | [get_connector_id](./#get_connector_id)() |
| [bool](https://docs.godotengine.org/en/stable/classes/class_bool.html) | [get_enabled](./#get_enabled)() |
| [PackedStringArray](https://docs.godotengine.org/en/stable/classes/class_packedstringarray.html) | [get_modes](./#get_modes)() |
| [String](https://docs.godotengine.org/en/stable/classes/class_string.html) | [get_status](./#get_status)() |
| [bool](https://docs.godotengine.org/en/stable/classes/class_bool.html) | [get_dpms](./#get_dpms)() |


------------------

## Property Descriptions

### `mutex`


[Mutex](https://docs.godotengine.org/en/stable/classes/class_mutex.html) mutex


Mutex used for thread safety
### `name`


[String](https://docs.godotengine.org/en/stable/classes/class_string.html) name


Name of the port. E.g. HDMI-A-1
### `path`


[String](https://docs.godotengine.org/en/stable/classes/class_string.html) path


Full path to the port. E.g. /sys/class/drm/card1-HDMI-A-1
### `connector_id`


[int](https://docs.godotengine.org/en/stable/classes/class_int.html) connector_id = <span style="color: red;">-1</span>


The connector id. E.g. /sys/class/drm/card1-HDMI-A-1/connector_id
### `enabled`


[bool](https://docs.godotengine.org/en/stable/classes/class_bool.html) enabled = <span style="color: red;">false</span>


Whether or not the port is enabled
### `modes`


[PackedStringArray](https://docs.godotengine.org/en/stable/classes/class_packedstringarray.html) modes = <span style="color: red;">PackedStringArray()</span>


An array of valid modes (E.g. ["1024x768", "1920x1080"](https://docs.godotengine.org/en/stable/classes/class_"1024x768", "1920x1080".html))
### `status`


[String](https://docs.godotengine.org/en/stable/classes/class_string.html) status


Status of the port (e.g. "connected")
### `dpms`


[bool](https://docs.godotengine.org/en/stable/classes/class_bool.html) dpms


Display power management signaling



------------------

## Method Descriptions

### `update()`


void **update**()


Updates the properties of the port
### `get_connector_id()`


[int](https://docs.godotengine.org/en/stable/classes/class_int.html) **get_connector_id**()


!!! note
    There is currently no description for this method. Please help us by contributing one!

### `get_enabled()`


[bool](https://docs.godotengine.org/en/stable/classes/class_bool.html) **get_enabled**()


!!! note
    There is currently no description for this method. Please help us by contributing one!

### `get_modes()`


[PackedStringArray](https://docs.godotengine.org/en/stable/classes/class_packedstringarray.html) **get_modes**()


!!! note
    There is currently no description for this method. Please help us by contributing one!

### `get_status()`


[String](https://docs.godotengine.org/en/stable/classes/class_string.html) **get_status**()


!!! note
    There is currently no description for this method. Please help us by contributing one!

### `get_dpms()`


[bool](https://docs.godotengine.org/en/stable/classes/class_bool.html) **get_dpms**()


!!! note
    There is currently no description for this method. Please help us by contributing one!

