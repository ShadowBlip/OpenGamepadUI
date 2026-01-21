# OSPlatform

**Inherits:** [PlatformProvider](../PlatformProvider)


## Properties

| Type | Name | Default |
| ---- | ---- | ------- |
| [Texture2D](https://docs.godotengine.org/en/stable/classes/class_texture2d.html) | [logo](./#logo) |  |

## Methods

| Returns | Signature |
| ------- | --------- |
| [String[]](https://docs.godotengine.org/en/stable/classes/class_string.html) | [get_binary_compatibility_cmd](./#get_binary_compatibility_cmd)(cmd: [String](https://docs.godotengine.org/en/stable/classes/class_string.html), args: [PackedStringArray](https://docs.godotengine.org/en/stable/classes/class_packedstringarray.html)) |


------------------

## Property Descriptions

### `logo`


[Texture2D](https://docs.godotengine.org/en/stable/classes/class_texture2d.html) logo


Logo of the OS



------------------

## Method Descriptions

### `get_binary_compatibility_cmd()`


[String[]](https://docs.godotengine.org/en/stable/classes/class_string.html) **get_binary_compatibility_cmd**(cmd: [String](https://docs.godotengine.org/en/stable/classes/class_string.html), args: [PackedStringArray](https://docs.godotengine.org/en/stable/classes/class_packedstringarray.html))


If the OS requires running regular binaries through a compatibility tool, this method should return the given command/args prepended with the compatibility tool to use.
