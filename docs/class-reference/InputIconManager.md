# InputIconManager

**Inherits:** [Resource](https://docs.godotengine.org/en/stable/classes/class_resource.html)

[InputIconManager](../InputIconManager) is responsible for managing what input glyphs to show in the UI
## Description

The InputIconManager will keep track of the last used input device and signal when the input device has changed to allow the UI to display the appropriate glyphs. In order for [InputIconManager](../InputIconManager) to work correctly, a [InputIconProcessor](../InputIconProcessor) must be added to the scene.
## Properties

| Type | Name | Default |
| ---- | ---- | ------- |
| [State](../State) | [in_game_state](./#in_game_state) | <unknown> |
| [InputPlumberInstance](../InputPlumberInstance) | [input_plumber](./#input_plumber) | <unknown> |
| [CustomLogger](../CustomLogger) | [logger](./#logger) | <unknown> |
| [bool](https://docs.godotengine.org/en/stable/classes/class_bool.html) | [disabled](./#disabled) | false |
| [int](https://docs.godotengine.org/en/stable/classes/class_int.html) | [last_input_type](./#last_input_type) | 1 |
| [String](https://docs.godotengine.org/en/stable/classes/class_string.html) | [last_input_device](./#last_input_device) |  |

## Methods

| Returns | Signature |
| ------- | --------- |
| [Dictionary](https://docs.godotengine.org/en/stable/classes/class_dictionary.html) | [discover_mappings](./#discover_mappings)(mappings_dir: [String](https://docs.godotengine.org/en/stable/classes/class_string.html)) |
| [Dictionary](https://docs.godotengine.org/en/stable/classes/class_dictionary.html) | [discover_device_mappings](./#discover_device_mappings)(mappings_dir: [String](https://docs.godotengine.org/en/stable/classes/class_string.html)) |
| void | [refresh](./#refresh)() |
| [Texture[]](https://docs.godotengine.org/en/stable/classes/class_texture.html) | [parse_path](./#parse_path)(path: [String](https://docs.godotengine.org/en/stable/classes/class_string.html), mapping_name: [String](https://docs.godotengine.org/en/stable/classes/class_string.html) = "", input_type: [int](https://docs.godotengine.org/en/stable/classes/class_int.html) = last_input_type) |
| [InputIconMapping](../InputIconMapping) | [load_matching_mapping](./#load_matching_mapping)(device_name: [String](https://docs.godotengine.org/en/stable/classes/class_string.html)) |
| [String](https://docs.godotengine.org/en/stable/classes/class_string.html) | [get_mapping_name_from_device](./#get_mapping_name_from_device)(device_name: [String](https://docs.godotengine.org/en/stable/classes/class_string.html)) |
| void | [set_last_input_type](./#set_last_input_type)(_last_input_type: [int](https://docs.godotengine.org/en/stable/classes/class_int.html)) |


------------------

## Property Descriptions

### `in_game_state`


[State](../State) in_game_state


!!! note
    There is currently no description for this property. Please help us by contributing one!

### `input_plumber`


[InputPlumberInstance](../InputPlumberInstance) input_plumber


!!! note
    There is currently no description for this property. Please help us by contributing one!

### `logger`


[CustomLogger](../CustomLogger) logger


!!! note
    There is currently no description for this property. Please help us by contributing one!

### `disabled`


[bool](https://docs.godotengine.org/en/stable/classes/class_bool.html) disabled = <span style="color: red;">false</span>


Disable/Enable signaling on input type changes
### `last_input_type`


[int](https://docs.godotengine.org/en/stable/classes/class_int.html) last_input_type = <span style="color: red;">1</span>


The last detected input type
### `last_input_device`


[String](https://docs.godotengine.org/en/stable/classes/class_string.html) last_input_device


The device name of the last detected input



------------------

## Method Descriptions

### `discover_mappings()`


[Dictionary](https://docs.godotengine.org/en/stable/classes/class_dictionary.html) **discover_mappings**(mappings_dir: [String](https://docs.godotengine.org/en/stable/classes/class_string.html))


Discover all input icon mappings from the specified path
### `discover_device_mappings()`


[Dictionary](https://docs.godotengine.org/en/stable/classes/class_dictionary.html) **discover_device_mappings**(mappings_dir: [String](https://docs.godotengine.org/en/stable/classes/class_string.html))


Discover all input icon mapping devices from the specified path
### `refresh()`


void **refresh**()


Refresh all icons
### `parse_path()`


[Texture[]](https://docs.godotengine.org/en/stable/classes/class_texture.html) **parse_path**(path: [String](https://docs.godotengine.org/en/stable/classes/class_string.html), mapping_name: [String](https://docs.godotengine.org/en/stable/classes/class_string.html) = "", input_type: [int](https://docs.godotengine.org/en/stable/classes/class_int.html) = last_input_type)


Parse the given input path and return the texture(s) associated with that type of input. The input path can either be in the form of "joypad/south" for specific inputs, or the name of an event action defined in the project's input map (i.e. "ui_accept"). Optionally, a mapping name can be passed to get a specific icon from a specific mapping.
### `load_matching_mapping()`


[InputIconMapping](../InputIconMapping) **load_matching_mapping**(device_name: [String](https://docs.godotengine.org/en/stable/classes/class_string.html))


Load and return the mapping that matches the given device.
### `get_mapping_name_from_device()`


[String](https://docs.godotengine.org/en/stable/classes/class_string.html) **get_mapping_name_from_device**(device_name: [String](https://docs.godotengine.org/en/stable/classes/class_string.html))


Returns the mapping name for the given device name. The mapping name is the "name" property of an [InputIconMapping](../InputIconMapping).
### `set_last_input_type()`


void **set_last_input_type**(_last_input_type: [int](https://docs.godotengine.org/en/stable/classes/class_int.html))


Set the last input type to the given value and emit a signal
