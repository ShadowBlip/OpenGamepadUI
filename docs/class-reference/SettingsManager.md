# SettingsManager

**Inherits:** [Resource](https://docs.godotengine.org/en/stable/classes/class_resource.html)

Get and set user settings
## Description

The SettingsManager is a simple class responsible for getting and setting user-specific settings. These settings are stored in a single file at user://settings.cfg.
## Properties

| Type | Name | Default |
| ---- | ---- | ------- |
| [String](https://docs.godotengine.org/en/stable/classes/class_string.html) | [settings_file](./#settings_file) | "user://settings.cfg" |
| [CustomLogger](../CustomLogger) | [logger](./#logger) | <unknown> |

## Methods

| Returns | Signature |
| ------- | --------- |
| void | [save](./#save)() |
| void | [reload](./#reload)() |
| [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html) | [get_value](./#get_value)(section: [String](https://docs.godotengine.org/en/stable/classes/class_string.html), key: [String](https://docs.godotengine.org/en/stable/classes/class_string.html), default: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html) = null) |
| [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html) | [get_library_value](./#get_library_value)(item: [LibraryItem](../LibraryItem), key: [String](https://docs.godotengine.org/en/stable/classes/class_string.html), default: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html) = null) |
| void | [set_value](./#set_value)(section: [String](https://docs.godotengine.org/en/stable/classes/class_string.html), key: [String](https://docs.godotengine.org/en/stable/classes/class_string.html), value: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html), persist: [bool](https://docs.godotengine.org/en/stable/classes/class_bool.html) = true) |
| void | [set_library_value](./#set_library_value)(item: [LibraryItem](../LibraryItem), key: [String](https://docs.godotengine.org/en/stable/classes/class_string.html), value: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html), persist: [bool](https://docs.godotengine.org/en/stable/classes/class_bool.html) = true) |
| void | [erase_section_key](./#erase_section_key)(section: [String](https://docs.godotengine.org/en/stable/classes/class_string.html), key: [String](https://docs.godotengine.org/en/stable/classes/class_string.html), persist: [bool](https://docs.godotengine.org/en/stable/classes/class_bool.html) = true) |
| void | [erase_library_key](./#erase_library_key)(item: [LibraryItem](../LibraryItem), key: [String](https://docs.godotengine.org/en/stable/classes/class_string.html), persist: [bool](https://docs.godotengine.org/en/stable/classes/class_bool.html) = true) |


------------------

## Property Descriptions

### `settings_file`


[String](https://docs.godotengine.org/en/stable/classes/class_string.html) settings_file = <span style="color: red;">"user://settings.cfg"</span>


!!! note
    There is currently no description for this property. Please help us by contributing one!

### `logger`


[CustomLogger](../CustomLogger) logger


!!! note
    There is currently no description for this property. Please help us by contributing one!




------------------

## Method Descriptions

### `save()`


void **save**()


!!! note
    There is currently no description for this method. Please help us by contributing one!

### `reload()`


void **reload**()


!!! note
    There is currently no description for this method. Please help us by contributing one!

### `get_value()`


[Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html) **get_value**(section: [String](https://docs.godotengine.org/en/stable/classes/class_string.html), key: [String](https://docs.godotengine.org/en/stable/classes/class_string.html), default: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html) = null)


!!! note
    There is currently no description for this method. Please help us by contributing one!

### `get_library_value()`


[Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html) **get_library_value**(item: [LibraryItem](../LibraryItem), key: [String](https://docs.godotengine.org/en/stable/classes/class_string.html), default: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html) = null)


!!! note
    There is currently no description for this method. Please help us by contributing one!

### `set_value()`


void **set_value**(section: [String](https://docs.godotengine.org/en/stable/classes/class_string.html), key: [String](https://docs.godotengine.org/en/stable/classes/class_string.html), value: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html), persist: [bool](https://docs.godotengine.org/en/stable/classes/class_bool.html) = true)


!!! note
    There is currently no description for this method. Please help us by contributing one!

### `set_library_value()`


void **set_library_value**(item: [LibraryItem](../LibraryItem), key: [String](https://docs.godotengine.org/en/stable/classes/class_string.html), value: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html), persist: [bool](https://docs.godotengine.org/en/stable/classes/class_bool.html) = true)


!!! note
    There is currently no description for this method. Please help us by contributing one!

### `erase_section_key()`


void **erase_section_key**(section: [String](https://docs.godotengine.org/en/stable/classes/class_string.html), key: [String](https://docs.godotengine.org/en/stable/classes/class_string.html), persist: [bool](https://docs.godotengine.org/en/stable/classes/class_bool.html) = true)


!!! note
    There is currently no description for this method. Please help us by contributing one!

### `erase_library_key()`


void **erase_library_key**(item: [LibraryItem](../LibraryItem), key: [String](https://docs.godotengine.org/en/stable/classes/class_string.html), persist: [bool](https://docs.godotengine.org/en/stable/classes/class_bool.html) = true)


!!! note
    There is currently no description for this method. Please help us by contributing one!

