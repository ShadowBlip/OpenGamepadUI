# DisplayManager.BacklightProvider

**Inherits:** [RefCounted](https://docs.godotengine.org/en/stable/classes/class_refcounted.html)

Interface for controlling backlights (e.g. screen brightness)
## Methods

| Returns | Signature |
| ------- | --------- |
| [PackedStringArray](https://docs.godotengine.org/en/stable/classes/class_packedstringarray.html) | [get_backlights](./#get_backlights)() |
| [int](https://docs.godotengine.org/en/stable/classes/class_int.html) | [get_max_brightness_value](./#get_max_brightness_value)(_backlight: [String](https://docs.godotengine.org/en/stable/classes/class_string.html) = "") |
| [int](https://docs.godotengine.org/en/stable/classes/class_int.html) | [get_brightness_value](./#get_brightness_value)(_backlight: [String](https://docs.godotengine.org/en/stable/classes/class_string.html) = "") |
| [float](https://docs.godotengine.org/en/stable/classes/class_float.html) | [get_brightness](./#get_brightness)(_backlight: [String](https://docs.godotengine.org/en/stable/classes/class_string.html) = "") |
| [int](https://docs.godotengine.org/en/stable/classes/class_int.html) | [set_brightness](./#set_brightness)(_value: [float](https://docs.godotengine.org/en/stable/classes/class_float.html), _type: [int](https://docs.godotengine.org/en/stable/classes/class_int.html) = 0, _backlight: [String](https://docs.godotengine.org/en/stable/classes/class_string.html) = "") |


------------------

## Method Descriptions

### `get_backlights()`


[PackedStringArray](https://docs.godotengine.org/en/stable/classes/class_packedstringarray.html) **get_backlights**()


Returns all available backlights
### `get_max_brightness_value()`


[int](https://docs.godotengine.org/en/stable/classes/class_int.html) **get_max_brightness_value**(_backlight: [String](https://docs.godotengine.org/en/stable/classes/class_string.html) = "")


Returns the maximum raw brightness value of the given backlight. If No backlight is passed, then this should return the value for the "main" display. Returns -1 if there is an error fetching the value.
### `get_brightness_value()`


[int](https://docs.godotengine.org/en/stable/classes/class_int.html) **get_brightness_value**(_backlight: [String](https://docs.godotengine.org/en/stable/classes/class_string.html) = "")


Returns the current raw brightness value of the given backlight. If no backlight is passed, then this should return the value for the "main" display. Returns -1 if there is an error fetching the value.
### `get_brightness()`


[float](https://docs.godotengine.org/en/stable/classes/class_float.html) **get_brightness**(_backlight: [String](https://docs.godotengine.org/en/stable/classes/class_string.html) = "")


Returns the current brightness level for the given backlight as a percent. Returns -1 if there is an error fetching the value
### `set_brightness()`


[int](https://docs.godotengine.org/en/stable/classes/class_int.html) **set_brightness**(_value: [float](https://docs.godotengine.org/en/stable/classes/class_float.html), _type: [int](https://docs.godotengine.org/en/stable/classes/class_int.html) = 0, _backlight: [String](https://docs.godotengine.org/en/stable/classes/class_string.html) = "")


Sets the brightness for the given backlight to the given value as a percentage (e.g. 1.0 is 100% brightness). If no backlight is specified, this should set the value on _all_ discovered backlights. Returns OK if set successfully.
