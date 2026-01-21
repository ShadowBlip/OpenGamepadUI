# InputPlumberProfile

**Inherits:** [Resource](https://docs.godotengine.org/en/stable/classes/class_resource.html)

Resource for loading and saving InputPlumber Input Profiles
## Description

This resource is used to load and save InputPlumber input profiles that can be used to remap gamepad inputs.
## Properties

| Type | Name | Default |
| ---- | ---- | ------- |
| [int](https://docs.godotengine.org/en/stable/classes/class_int.html) | [version](./#version) | 1 |
| [String](https://docs.godotengine.org/en/stable/classes/class_string.html) | [kind](./#kind) | "DeviceProfile" |
| [String](https://docs.godotengine.org/en/stable/classes/class_string.html) | [name](./#name) |  |
| [int[]](https://docs.godotengine.org/en/stable/classes/class_int.html) | [target_devices](./#target_devices) |  |
| [InputPlumberMapping[]](../InputPlumberMapping) | [mapping](./#mapping) |  |

## Methods

| Returns | Signature |
| ------- | --------- |
| [InputPlumberProfile](../InputPlumberProfile) | [load](./#load)(path: [String](https://docs.godotengine.org/en/stable/classes/class_string.html)) |
| [InputPlumberProfile](../InputPlumberProfile) | [from_dict](./#from_dict)(dict: [Dictionary](https://docs.godotengine.org/en/stable/classes/class_dictionary.html)) |
| [InputPlumberProfile](../InputPlumberProfile) | [from_json](./#from_json)(json: [String](https://docs.godotengine.org/en/stable/classes/class_string.html)) |
| [String](https://docs.godotengine.org/en/stable/classes/class_string.html) | [get_target_device_string](./#get_target_device_string)(target_device: [int](https://docs.godotengine.org/en/stable/classes/class_int.html)) |
| [int](https://docs.godotengine.org/en/stable/classes/class_int.html) | [get_target_device](./#get_target_device)(target_device_str: [String](https://docs.godotengine.org/en/stable/classes/class_string.html)) |
| [int](https://docs.godotengine.org/en/stable/classes/class_int.html) | [save](./#save)(path: [String](https://docs.godotengine.org/en/stable/classes/class_string.html)) |
| [PackedStringArray](https://docs.godotengine.org/en/stable/classes/class_packedstringarray.html) | [get_mappings_source_capabilities](./#get_mappings_source_capabilities)() |
| [InputPlumberMapping[]](../InputPlumberMapping) | [get_mappings_by_source_capability](./#get_mappings_by_source_capability)(source_capability: [String](https://docs.godotengine.org/en/stable/classes/class_string.html)) |
| [Dictionary](https://docs.godotengine.org/en/stable/classes/class_dictionary.html) | [to_dict](./#to_dict)() |
| [String](https://docs.godotengine.org/en/stable/classes/class_string.html) | [to_json](./#to_json)() |


------------------

## Property Descriptions

### `version`


[int](https://docs.godotengine.org/en/stable/classes/class_int.html) version = <span style="color: red;">1</span>


Version of the config
### `kind`


[String](https://docs.godotengine.org/en/stable/classes/class_string.html) kind = <span style="color: red;">"DeviceProfile"</span>


Type of configuration schema
### `name`


[String](https://docs.godotengine.org/en/stable/classes/class_string.html) name


Name of the profile
### `target_devices`


[int[]](https://docs.godotengine.org/en/stable/classes/class_int.html) target_devices


Target input devices to emulate
### `mapping`


[InputPlumberMapping[]](../InputPlumberMapping) mapping


Input mappings



------------------

## Method Descriptions

### `load()`


[InputPlumberProfile](../InputPlumberProfile) **load**(path: [String](https://docs.godotengine.org/en/stable/classes/class_string.html))


Load the InputPlumberProfile in JSON format from the given path
### `from_dict()`


[InputPlumberProfile](../InputPlumberProfile) **from_dict**(dict: [Dictionary](https://docs.godotengine.org/en/stable/classes/class_dictionary.html))


Create an InputPlumberProfile from the given dictionary
### `from_json()`


[InputPlumberProfile](../InputPlumberProfile) **from_json**(json: [String](https://docs.godotengine.org/en/stable/classes/class_string.html))


Create an InputPlumberProfile from the given JSON string
### `get_target_device_string()`


[String](https://docs.godotengine.org/en/stable/classes/class_string.html) **get_target_device_string**(target_device: [int](https://docs.godotengine.org/en/stable/classes/class_int.html))


Return the target device string for the given target device type
### `get_target_device()`


[int](https://docs.godotengine.org/en/stable/classes/class_int.html) **get_target_device**(target_device_str: [String](https://docs.godotengine.org/en/stable/classes/class_string.html))


Return the target device for the given target device string
### `save()`


[int](https://docs.godotengine.org/en/stable/classes/class_int.html) **save**(path: [String](https://docs.godotengine.org/en/stable/classes/class_string.html))


Save the profile to the given path in JSON format
### `get_mappings_source_capabilities()`


[PackedStringArray](https://docs.godotengine.org/en/stable/classes/class_packedstringarray.html) **get_mappings_source_capabilities**()


Returns an array of source capability strings for all mappings in the profile. I.e. this will return a list of every mapping.source_event property.
### `get_mappings_by_source_capability()`


[InputPlumberMapping[]](../InputPlumberMapping) **get_mappings_by_source_capability**(source_capability: [String](https://docs.godotengine.org/en/stable/classes/class_string.html))


Return all mappings that match the given source capability. Most source capabilities will just have a single mapping, but some, like "GamepadAxis", may have multiple mappings associated with them (e.g. LeftStick -> KeyA, KeyW, KeyS, KeyD)
### `to_dict()`


[Dictionary](https://docs.godotengine.org/en/stable/classes/class_dictionary.html) **to_dict**()


Convert the profile to an easily serializable dictionary
### `to_json()`


[String](https://docs.godotengine.org/en/stable/classes/class_string.html) **to_json**()


Serialize the profile to JSON
