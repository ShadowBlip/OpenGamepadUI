# DRMCardInfo

**Inherits:** [Resource](https://docs.godotengine.org/en/stable/classes/class_resource.html)

GPU card state
## Description

Represents the data contained in /sys/class/drm/cardX
## Properties

| Type | Name | Default |
| ---- | ---- | ------- |
| [String](https://docs.godotengine.org/en/stable/classes/class_string.html) | [name](./#name) |  |
| [String](https://docs.godotengine.org/en/stable/classes/class_string.html) | [vendor](./#vendor) |  |
| [String](https://docs.godotengine.org/en/stable/classes/class_string.html) | [vendor_id](./#vendor_id) |  |
| [String](https://docs.godotengine.org/en/stable/classes/class_string.html) | [device](./#device) |  |
| [String](https://docs.godotengine.org/en/stable/classes/class_string.html) | [device_id](./#device_id) |  |
| [String](https://docs.godotengine.org/en/stable/classes/class_string.html) | [device_type](./#device_type) |  |
| [String](https://docs.godotengine.org/en/stable/classes/class_string.html) | [subdevice](./#subdevice) |  |
| [String](https://docs.godotengine.org/en/stable/classes/class_string.html) | [subdevice_id](./#subdevice_id) |  |
| [String](https://docs.godotengine.org/en/stable/classes/class_string.html) | [subvendor_id](./#subvendor_id) |  |
| [String](https://docs.godotengine.org/en/stable/classes/class_string.html) | [revision_id](./#revision_id) |  |

## Methods

| Returns | Signature |
| ------- | --------- |
| [DRMCardPort](../DRMCardPort) | [get_port](./#get_port)(port_dir: [String](https://docs.godotengine.org/en/stable/classes/class_string.html)) |
| [DRMCardPort[]](../DRMCardPort) | [get_ports](./#get_ports)() |
| [Vector2](https://docs.godotengine.org/en/stable/classes/class_vector2.html) | [get_clock_limits](./#get_clock_limits)() |
| [Vector2](https://docs.godotengine.org/en/stable/classes/class_vector2.html) | [get_clock_values](./#get_clock_values)() |


------------------

## Property Descriptions

### `name`


[String](https://docs.godotengine.org/en/stable/classes/class_string.html) name


!!! note
    There is currently no description for this property. Please help us by contributing one!

### `vendor`


[String](https://docs.godotengine.org/en/stable/classes/class_string.html) vendor


!!! note
    There is currently no description for this property. Please help us by contributing one!

### `vendor_id`


[String](https://docs.godotengine.org/en/stable/classes/class_string.html) vendor_id


!!! note
    There is currently no description for this property. Please help us by contributing one!

### `device`


[String](https://docs.godotengine.org/en/stable/classes/class_string.html) device


!!! note
    There is currently no description for this property. Please help us by contributing one!

### `device_id`


[String](https://docs.godotengine.org/en/stable/classes/class_string.html) device_id


!!! note
    There is currently no description for this property. Please help us by contributing one!

### `device_type`


[String](https://docs.godotengine.org/en/stable/classes/class_string.html) device_type


!!! note
    There is currently no description for this property. Please help us by contributing one!

### `subdevice`


[String](https://docs.godotengine.org/en/stable/classes/class_string.html) subdevice


!!! note
    There is currently no description for this property. Please help us by contributing one!

### `subdevice_id`


[String](https://docs.godotengine.org/en/stable/classes/class_string.html) subdevice_id


!!! note
    There is currently no description for this property. Please help us by contributing one!

### `subvendor_id`


[String](https://docs.godotengine.org/en/stable/classes/class_string.html) subvendor_id


!!! note
    There is currently no description for this property. Please help us by contributing one!

### `revision_id`


[String](https://docs.godotengine.org/en/stable/classes/class_string.html) revision_id


!!! note
    There is currently no description for this property. Please help us by contributing one!




------------------

## Method Descriptions

### `get_port()`


[DRMCardPort](../DRMCardPort) **get_port**(port_dir: [String](https://docs.godotengine.org/en/stable/classes/class_string.html))


Returns a [DRMCardPort](../DRMCardPort) object for the given port directory (E.g. card1-HDMI-A-1)
### `get_ports()`


[DRMCardPort[]](../DRMCardPort) **get_ports**()


Returns an array of connectors that are attached to this GPU card
### `get_clock_limits()`


[Vector2](https://docs.godotengine.org/en/stable/classes/class_vector2.html) **get_clock_limits**()


Returns the maximum and minimum GPU clock values
### `get_clock_values()`


[Vector2](https://docs.godotengine.org/en/stable/classes/class_vector2.html) **get_clock_values**()


Returns the current GPU minimum and maximum clock values
