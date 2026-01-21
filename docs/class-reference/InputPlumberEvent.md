# InputPlumberEvent

**Inherits:** [Resource](https://docs.godotengine.org/en/stable/classes/class_resource.html)


## Properties

| Type | Name | Default |
| ---- | ---- | ------- |
| [String](https://docs.godotengine.org/en/stable/classes/class_string.html) | [keyboard](./#keyboard) |  |
| [InputPlumberMouseEvent](../InputPlumberMouseEvent) | [mouse](./#mouse) |  |
| [String](https://docs.godotengine.org/en/stable/classes/class_string.html) | [dbus](./#dbus) |  |
| [InputPlumberGamepadEvent](../InputPlumberGamepadEvent) | [gamepad](./#gamepad) |  |
| [InputPlumberTouchpadEvent](../InputPlumberTouchpadEvent) | [touchpad](./#touchpad) |  |

## Methods

| Returns | Signature |
| ------- | --------- |
| [InputPlumberEvent](../InputPlumberEvent) | [from_capability](./#from_capability)(capability: [String](https://docs.godotengine.org/en/stable/classes/class_string.html)) |
| [InputPlumberEvent](../InputPlumberEvent) | [from_event](./#from_event)(godot_event: [InputEvent](https://docs.godotengine.org/en/stable/classes/class_inputevent.html)) |
| [InputPlumberEvent](../InputPlumberEvent) | [from_dict](./#from_dict)(dict: [Dictionary](https://docs.godotengine.org/en/stable/classes/class_dictionary.html)) |
| [Dictionary](https://docs.godotengine.org/en/stable/classes/class_dictionary.html) | [to_dict](./#to_dict)() |
| [String](https://docs.godotengine.org/en/stable/classes/class_string.html) | [to_joypad_path](./#to_joypad_path)() |
| [String](https://docs.godotengine.org/en/stable/classes/class_string.html) | [to_capability](./#to_capability)() |
| [int](https://docs.godotengine.org/en/stable/classes/class_int.html) | [set_capability](./#set_capability)(capability: [String](https://docs.godotengine.org/en/stable/classes/class_string.html)) |
| [bool](https://docs.godotengine.org/en/stable/classes/class_bool.html) | [matches](./#matches)(event: [InputPlumberEvent](../InputPlumberEvent)) |
| [String](https://docs.godotengine.org/en/stable/classes/class_string.html) | [get_direction](./#get_direction)() |
| [String](https://docs.godotengine.org/en/stable/classes/class_string.html) | [get_joypad_path](./#get_joypad_path)(cap: [String](https://docs.godotengine.org/en/stable/classes/class_string.html)) |
| [PackedStringArray](https://docs.godotengine.org/en/stable/classes/class_packedstringarray.html) | [sort_capabilities](./#sort_capabilities)(caps: [PackedStringArray](https://docs.godotengine.org/en/stable/classes/class_packedstringarray.html)) |
| [String](https://docs.godotengine.org/en/stable/classes/class_string.html) | [capability_from_keycode](./#capability_from_keycode)(scancode: [int](https://docs.godotengine.org/en/stable/classes/class_int.html)) |
| [String](https://docs.godotengine.org/en/stable/classes/class_string.html) | [virtual_key_from_keycode](./#virtual_key_from_keycode)(scancode: [int](https://docs.godotengine.org/en/stable/classes/class_int.html)) |


------------------

## Property Descriptions

### `keyboard`


[String](https://docs.godotengine.org/en/stable/classes/class_string.html) keyboard


!!! note
    There is currently no description for this property. Please help us by contributing one!

### `mouse`


[InputPlumberMouseEvent](../InputPlumberMouseEvent) mouse


!!! note
    There is currently no description for this property. Please help us by contributing one!

### `dbus`


[String](https://docs.godotengine.org/en/stable/classes/class_string.html) dbus


!!! note
    There is currently no description for this property. Please help us by contributing one!

### `gamepad`


[InputPlumberGamepadEvent](../InputPlumberGamepadEvent) gamepad


!!! note
    There is currently no description for this property. Please help us by contributing one!

### `touchpad`


[InputPlumberTouchpadEvent](../InputPlumberTouchpadEvent) touchpad


!!! note
    There is currently no description for this property. Please help us by contributing one!




------------------

## Method Descriptions

### `from_capability()`


[InputPlumberEvent](../InputPlumberEvent) **from_capability**(capability: [String](https://docs.godotengine.org/en/stable/classes/class_string.html))


Create a new InputPlumberEvent from the given capability string
### `from_event()`


[InputPlumberEvent](../InputPlumberEvent) **from_event**(godot_event: [InputEvent](https://docs.godotengine.org/en/stable/classes/class_inputevent.html))


Create a new InputPlumberEvent from the given Godot event
### `from_dict()`


[InputPlumberEvent](../InputPlumberEvent) **from_dict**(dict: [Dictionary](https://docs.godotengine.org/en/stable/classes/class_dictionary.html))


Create a new InputPlumberEvent from the given JSON dictionary
### `to_dict()`


[Dictionary](https://docs.godotengine.org/en/stable/classes/class_dictionary.html) **to_dict**()


Convert the event into a JSON-serializable dictionary
### `to_joypad_path()`


[String](https://docs.godotengine.org/en/stable/classes/class_string.html) **to_joypad_path**()


Returns the controller icon path from the given event
### `to_capability()`


[String](https://docs.godotengine.org/en/stable/classes/class_string.html) **to_capability**()


Returns the capability string of the event. E.g. "Gamepad:Button:South"
### `set_capability()`


[int](https://docs.godotengine.org/en/stable/classes/class_int.html) **set_capability**(capability: [String](https://docs.godotengine.org/en/stable/classes/class_string.html))


Set the event based on the given capability string (e.g. "Gamepad:Button:South") TODO: FINISH THIS!
### `matches()`


[bool](https://docs.godotengine.org/en/stable/classes/class_bool.html) **matches**(event: [InputPlumberEvent](../InputPlumberEvent))


Returns true if the given event matches this event capability
### `get_direction()`


[String](https://docs.godotengine.org/en/stable/classes/class_string.html) **get_direction**()


Certain events can have a "direction" specified, such as for joysticks and gyro. This will return the direction if one exists and is supported.
### `get_joypad_path()`


[String](https://docs.godotengine.org/en/stable/classes/class_string.html) **get_joypad_path**(cap: [String](https://docs.godotengine.org/en/stable/classes/class_string.html))


Returns the controller icon path from the given event
### `sort_capabilities()`


[PackedStringArray](https://docs.godotengine.org/en/stable/classes/class_packedstringarray.html) **sort_capabilities**(caps: [PackedStringArray](https://docs.godotengine.org/en/stable/classes/class_packedstringarray.html))


Sorts the given string capabilities and returns them sorted
### `capability_from_keycode()`


[String](https://docs.godotengine.org/en/stable/classes/class_string.html) **capability_from_keycode**(scancode: [int](https://docs.godotengine.org/en/stable/classes/class_int.html))


Convert the given key scancode into a capability string
### `virtual_key_from_keycode()`


[String](https://docs.godotengine.org/en/stable/classes/class_string.html) **virtual_key_from_keycode**(scancode: [int](https://docs.godotengine.org/en/stable/classes/class_int.html))


Convert the given key scancode into a target keyboard event string
