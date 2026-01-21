# Sandbox

**Inherits:** [Resource](https://docs.godotengine.org/en/stable/classes/class_resource.html)


## Methods

| Returns | Signature |
| ------- | --------- |
| [PackedStringArray](https://docs.godotengine.org/en/stable/classes/class_packedstringarray.html) | [get_command](./#get_command)(app: [LibraryLaunchItem](../LibraryLaunchItem)) |
| [bool](https://docs.godotengine.org/en/stable/classes/class_bool.html) | [is_available](./#is_available)() |
| [Sandbox](../Sandbox) | [get_sandbox](./#get_sandbox)() |


------------------

## Method Descriptions

### `get_command()`


[PackedStringArray](https://docs.godotengine.org/en/stable/classes/class_packedstringarray.html) **get_command**(app: [LibraryLaunchItem](../LibraryLaunchItem))


Returns an array defining the command line to launch the given application in a sandbox. E.g. ["firejail", "--noprofile", "--"](https://docs.godotengine.org/en/stable/classes/class_"firejail", "--noprofile", "--".html)
### `is_available()`


[bool](https://docs.godotengine.org/en/stable/classes/class_bool.html) **is_available**()


Returns whether or not the given sandbox implementation is available
### `get_sandbox()`


[Sandbox](../Sandbox) **get_sandbox**()


Returns the best sandbox to use for launching apps
