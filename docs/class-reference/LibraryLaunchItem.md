# LibraryLaunchItem

**Inherits:** [Resource](https://docs.godotengine.org/en/stable/classes/class_resource.html)

LibraryLaunchItem is a library provider-specific structure that describes how to launch a game.
## Description

A LibraryLaunchItem is a provider-specific resource that describes a library item and how to launch it. It is always tied to a [LibraryItem](../LibraryItem).
## Properties

| Type | Name | Default |
| ---- | ---- | ------- |
| [String](https://docs.godotengine.org/en/stable/classes/class_string.html) | [provider_app_id](./#provider_app_id) |  |
| [String](https://docs.godotengine.org/en/stable/classes/class_string.html) | [name](./#name) |  |
| [String](https://docs.godotengine.org/en/stable/classes/class_string.html) | [command](./#command) |  |
| [PackedStringArray](https://docs.godotengine.org/en/stable/classes/class_packedstringarray.html) | [args](./#args) |  |
| [Dictionary](https://docs.godotengine.org/en/stable/classes/class_dictionary.html) | [env](./#env) |  |
| [String](https://docs.godotengine.org/en/stable/classes/class_string.html) | [cwd](./#cwd) |  |
| [PackedStringArray](https://docs.godotengine.org/en/stable/classes/class_packedstringarray.html) | [tags](./#tags) |  |
| [PackedStringArray](https://docs.godotengine.org/en/stable/classes/class_packedstringarray.html) | [categories](./#categories) |  |
| [bool](https://docs.godotengine.org/en/stable/classes/class_bool.html) | [installed](./#installed) |  |
| [bool](https://docs.godotengine.org/en/stable/classes/class_bool.html) | [hidden](./#hidden) |  |
| [Dictionary](https://docs.godotengine.org/en/stable/classes/class_dictionary.html) | [metadata](./#metadata) |  |

## Methods

| Returns | Signature |
| ------- | --------- |
| [Dictionary](https://docs.godotengine.org/en/stable/classes/class_dictionary.html) | [to_dict](./#to_dict)() |
| [LibraryLaunchItem](../LibraryLaunchItem) | [from_dict](./#from_dict)(d: [Dictionary](https://docs.godotengine.org/en/stable/classes/class_dictionary.html)) |
| [int](https://docs.godotengine.org/en/stable/classes/class_int.html) | [get_app_id](./#get_app_id)() |


------------------

## Property Descriptions

### `provider_app_id`


[String](https://docs.godotengine.org/en/stable/classes/class_string.html) provider_app_id


!!! note
    There is currently no description for this property. Please help us by contributing one!

### `name`


[String](https://docs.godotengine.org/en/stable/classes/class_string.html) name


!!! note
    There is currently no description for this property. Please help us by contributing one!

### `command`


[String](https://docs.godotengine.org/en/stable/classes/class_string.html) command


!!! note
    There is currently no description for this property. Please help us by contributing one!

### `args`


[PackedStringArray](https://docs.godotengine.org/en/stable/classes/class_packedstringarray.html) args


!!! note
    There is currently no description for this property. Please help us by contributing one!

### `env`


[Dictionary](https://docs.godotengine.org/en/stable/classes/class_dictionary.html) env


!!! note
    There is currently no description for this property. Please help us by contributing one!

### `cwd`


[String](https://docs.godotengine.org/en/stable/classes/class_string.html) cwd


!!! note
    There is currently no description for this property. Please help us by contributing one!

### `tags`


[PackedStringArray](https://docs.godotengine.org/en/stable/classes/class_packedstringarray.html) tags


!!! note
    There is currently no description for this property. Please help us by contributing one!

### `categories`


[PackedStringArray](https://docs.godotengine.org/en/stable/classes/class_packedstringarray.html) categories


!!! note
    There is currently no description for this property. Please help us by contributing one!

### `installed`


[bool](https://docs.godotengine.org/en/stable/classes/class_bool.html) installed


!!! note
    There is currently no description for this property. Please help us by contributing one!

### `hidden`


[bool](https://docs.godotengine.org/en/stable/classes/class_bool.html) hidden


!!! note
    There is currently no description for this property. Please help us by contributing one!

### `metadata`


[Dictionary](https://docs.godotengine.org/en/stable/classes/class_dictionary.html) metadata


!!! note
    There is currently no description for this property. Please help us by contributing one!




------------------

## Method Descriptions

### `to_dict()`


[Dictionary](https://docs.godotengine.org/en/stable/classes/class_dictionary.html) **to_dict**()


!!! note
    There is currently no description for this method. Please help us by contributing one!

### `from_dict()`


[LibraryLaunchItem](../LibraryLaunchItem) **from_dict**(d: [Dictionary](https://docs.godotengine.org/en/stable/classes/class_dictionary.html))


!!! note
    There is currently no description for this method. Please help us by contributing one!

### `get_app_id()`


[int](https://docs.godotengine.org/en/stable/classes/class_int.html) **get_app_id**()


Returns a numerical app ID associated with the launch item
