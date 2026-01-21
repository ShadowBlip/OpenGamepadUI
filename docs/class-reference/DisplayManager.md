# DisplayManager

**Inherits:** [Resource](https://docs.godotengine.org/en/stable/classes/class_resource.html)

DisplayManager is responsible for managing display settings
## Description

Global display manager for managing display settings
## Properties

| Type | Name | Default |
| ---- | ---- | ------- |
| [CustomLogger](../CustomLogger) | [logger](./#logger) | <unknown> |
| [DisplayManager.BacklightProvider](../DisplayManager.BacklightProvider) | [brightness_provider](./#brightness_provider) | _get_backlight_provider() |
| [PackedStringArray](https://docs.godotengine.org/en/stable/classes/class_packedstringarray.html) | [backlights](./#backlights) | get_backlight_paths() |

## Methods

| Returns | Signature |
| ------- | --------- |
| [bool](https://docs.godotengine.org/en/stable/classes/class_bool.html) | [supports_brightness](./#supports_brightness)() |
| [int](https://docs.godotengine.org/en/stable/classes/class_int.html) | [set_brightness](./#set_brightness)(value: [float](https://docs.godotengine.org/en/stable/classes/class_float.html), type: [int](https://docs.godotengine.org/en/stable/classes/class_int.html) = 0, backlight: [String](https://docs.godotengine.org/en/stable/classes/class_string.html) = "") |
| [float](https://docs.godotengine.org/en/stable/classes/class_float.html) | [get_brightness](./#get_brightness)(backlight_path: [String](https://docs.godotengine.org/en/stable/classes/class_string.html)) |
| [int](https://docs.godotengine.org/en/stable/classes/class_int.html) | [get_brightness_value](./#get_brightness_value)(backlight_path: [String](https://docs.godotengine.org/en/stable/classes/class_string.html)) |
| [int](https://docs.godotengine.org/en/stable/classes/class_int.html) | [get_max_brightness_value](./#get_max_brightness_value)(backlight_path: [String](https://docs.godotengine.org/en/stable/classes/class_string.html)) |
| [PackedStringArray](https://docs.godotengine.org/en/stable/classes/class_packedstringarray.html) | [get_backlight_paths](./#get_backlight_paths)() |


------------------

## Property Descriptions

### `logger`


[CustomLogger](../CustomLogger) logger


!!! note
    There is currently no description for this property. Please help us by contributing one!

### `brightness_provider`


[DisplayManager.BacklightProvider](../DisplayManager.BacklightProvider) brightness_provider = <span style="color: red;">_get_backlight_provider()</span>


!!! note
    There is currently no description for this property. Please help us by contributing one!

### `backlights`


[PackedStringArray](https://docs.godotengine.org/en/stable/classes/class_packedstringarray.html) backlights = <span style="color: red;">get_backlight_paths()</span>


!!! note
    There is currently no description for this property. Please help us by contributing one!




------------------

## Method Descriptions

### `supports_brightness()`


[bool](https://docs.godotengine.org/en/stable/classes/class_bool.html) **supports_brightness**()


Returns true if OpenGamepadUI has access to adjust brightness
### `set_brightness()`


[int](https://docs.godotengine.org/en/stable/classes/class_int.html) **set_brightness**(value: [float](https://docs.godotengine.org/en/stable/classes/class_float.html), type: [int](https://docs.godotengine.org/en/stable/classes/class_int.html) = 0, backlight: [String](https://docs.godotengine.org/en/stable/classes/class_string.html) = "")


Sets the brightness on all discovered backlights to the given value as a percentage (e.g. 1.0 is 100% brightness)
### `get_brightness()`


[float](https://docs.godotengine.org/en/stable/classes/class_float.html) **get_brightness**(backlight_path: [String](https://docs.godotengine.org/en/stable/classes/class_string.html))


Returns the current brightness level for the given backlight as a percent
### `get_brightness_value()`


[int](https://docs.godotengine.org/en/stable/classes/class_int.html) **get_brightness_value**(backlight_path: [String](https://docs.godotengine.org/en/stable/classes/class_string.html))


Returns the current brightness value for the given backlight
### `get_max_brightness_value()`


[int](https://docs.godotengine.org/en/stable/classes/class_int.html) **get_max_brightness_value**(backlight_path: [String](https://docs.godotengine.org/en/stable/classes/class_string.html))


Returns the maximum brightness for the given backlight
### `get_backlight_paths()`


[PackedStringArray](https://docs.godotengine.org/en/stable/classes/class_packedstringarray.html) **get_backlight_paths**()


Returns a list of all detected backlight devices
