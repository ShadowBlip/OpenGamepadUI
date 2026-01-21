# KeyboardKeyConfig

**Inherits:** [Resource](https://docs.godotengine.org/en/stable/classes/class_resource.html)

Defines a single key configuration for the on-screen keyboard
## Description

A key configuration is one key that is part of a [KeyboardLayout](../KeyboardLayout) which defines the type of key it is.
## Properties

| Type | Name | Default |
| ---- | ---- | ------- |
| [int](https://docs.godotengine.org/en/stable/classes/class_int.html) | [type](./#type) | 0 |
| [InputEventKey](https://docs.godotengine.org/en/stable/classes/class_inputeventkey.html) | [input](./#input) |  |
| [InputEventKey](https://docs.godotengine.org/en/stable/classes/class_inputeventkey.html) | [mode_shift_input](./#mode_shift_input) |  |
| [Texture2D](https://docs.godotengine.org/en/stable/classes/class_texture2d.html) | [icon](./#icon) |  |
| [float](https://docs.godotengine.org/en/stable/classes/class_float.html) | [stretch_ratio](./#stretch_ratio) | 1.0 |
| [int](https://docs.godotengine.org/en/stable/classes/class_int.html) | [action](./#action) | 0 |

## Methods

| Returns | Signature |
| ------- | --------- |
| [String](https://docs.godotengine.org/en/stable/classes/class_string.html) | [get_text](./#get_text)(mode_shifted: [bool](https://docs.godotengine.org/en/stable/classes/class_bool.html) = false) |


------------------

## Property Descriptions

### `type`


[int](https://docs.godotengine.org/en/stable/classes/class_int.html) type = <span style="color: red;">0</span>


Whether this is a normal key or special key
### `input`


[InputEventKey](https://docs.godotengine.org/en/stable/classes/class_inputeventkey.html) input


The keyboard event associated with this key
### `mode_shift_input`


[InputEventKey](https://docs.godotengine.org/en/stable/classes/class_inputeventkey.html) mode_shift_input


The keyboard event associated with this key when SHIFT is being held
### `icon`


[Texture2D](https://docs.godotengine.org/en/stable/classes/class_texture2d.html) icon


An icon to display for this key on the on-screen keyboard
### `stretch_ratio`


[float](https://docs.godotengine.org/en/stable/classes/class_float.html) stretch_ratio = <span style="color: red;">1.0</span>


How much space relative to other keys in the row to take up
### `action`


[int](https://docs.godotengine.org/en/stable/classes/class_int.html) action = <span style="color: red;">0</span>


An action for TYPE.SPECIAL keys to take



------------------

## Method Descriptions

### `get_text()`


[String](https://docs.godotengine.org/en/stable/classes/class_string.html) **get_text**(mode_shifted: [bool](https://docs.godotengine.org/en/stable/classes/class_bool.html) = false)


!!! note
    There is currently no description for this method. Please help us by contributing one!

