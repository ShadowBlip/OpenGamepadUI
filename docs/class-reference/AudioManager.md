# AudioManager

**Inherits:** [Resource](https://docs.godotengine.org/en/stable/classes/class_resource.html)

Manage system volume and audio devices
## Description

The AudioManager is responsible for managing the system volume and audio devices if the host supports it.
## Properties

| Type | Name | Default |
| ---- | ---- | ------- |
| [float](https://docs.godotengine.org/en/stable/classes/class_float.html) | [current_volume](./#current_volume) | <unknown> |

## Methods

| Returns | Signature |
| ------- | --------- |
| [bool](https://docs.godotengine.org/en/stable/classes/class_bool.html) | [supports_audio](./#supports_audio)() |
| [int](https://docs.godotengine.org/en/stable/classes/class_int.html) | [set_volume](./#set_volume)(value: [float](https://docs.godotengine.org/en/stable/classes/class_float.html), type: [int](https://docs.godotengine.org/en/stable/classes/class_int.html) = 0) |
| [int](https://docs.godotengine.org/en/stable/classes/class_int.html) | [toggle_mute](./#toggle_mute)() |
| [int](https://docs.godotengine.org/en/stable/classes/class_int.html) | [set_output_device](./#set_output_device)(device: [String](https://docs.godotengine.org/en/stable/classes/class_string.html)) |
| [String](https://docs.godotengine.org/en/stable/classes/class_string.html) | [get_current_output_device](./#get_current_output_device)() |
| [float](https://docs.godotengine.org/en/stable/classes/class_float.html) | [get_current_volume](./#get_current_volume)() |
| [PackedStringArray](https://docs.godotengine.org/en/stable/classes/class_packedstringarray.html) | [get_output_devices](./#get_output_devices)() |


------------------

## Property Descriptions

### `current_volume`


[float](https://docs.godotengine.org/en/stable/classes/class_float.html) current_volume


Current volume



------------------

## Method Descriptions

### `supports_audio()`


[bool](https://docs.godotengine.org/en/stable/classes/class_bool.html) **supports_audio**()


Returns true if the system has audio controls we support
### `set_volume()`


[int](https://docs.godotengine.org/en/stable/classes/class_int.html) **set_volume**(value: [float](https://docs.godotengine.org/en/stable/classes/class_float.html), type: [int](https://docs.godotengine.org/en/stable/classes/class_int.html) = 0)


Sets the current audio device volume based on the given value. The volume value should be in the form of a percent where 1.0 equals 100%. The type can be either absolute (default) or relative volume values.


```gdscript

    const AudioManager := preload("res://core/global/audio_manager.tres")
    ...
    AudioManager.set_volume(1.0) # Set volume to 100%
    AudioManager.set_volume(-0.06, AudioManager.TYPE.RELATIVE) # Decrease volume by 6%

```


### `toggle_mute()`


[int](https://docs.godotengine.org/en/stable/classes/class_int.html) **toggle_mute**()


Toggles mute on the current audio device
### `set_output_device()`


[int](https://docs.godotengine.org/en/stable/classes/class_int.html) **set_output_device**(device: [String](https://docs.godotengine.org/en/stable/classes/class_string.html))


Sets the current output device to the given device
### `get_current_output_device()`


[String](https://docs.godotengine.org/en/stable/classes/class_string.html) **get_current_output_device**()


Returns the currently set output device
### `get_current_volume()`


[float](https://docs.godotengine.org/en/stable/classes/class_float.html) **get_current_volume**()


Returns the current volume as a percentage. E.g. 0.52 is 52%
### `get_output_devices()`


[PackedStringArray](https://docs.godotengine.org/en/stable/classes/class_packedstringarray.html) **get_output_devices**()


Returns a list of audio output devices
