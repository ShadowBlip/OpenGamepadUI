# APUDatabase

**Inherits:** [Resource](https://docs.godotengine.org/en/stable/classes/class_resource.html)


## Properties

| Type | Name | Default |
| ---- | ---- | ------- |
| [APUEntry[]](../APUEntry) | [apu_list](./#apu_list) |  |
| [String](https://docs.godotengine.org/en/stable/classes/class_string.html) | [database_name](./#database_name) |  |
| [Dictionary](https://docs.godotengine.org/en/stable/classes/class_dictionary.html) | [apu_map](./#apu_map) |  |
| [bool](https://docs.godotengine.org/en/stable/classes/class_bool.html) | [loaded](./#loaded) | false |
| [CustomLogger](../CustomLogger) | [logger](./#logger) | <unknown> |

## Methods

| Returns | Signature |
| ------- | --------- |
| void | [load_db](./#load_db)() |
| [APUEntry](../APUEntry) | [get_apu](./#get_apu)(apu_name: [String](https://docs.godotengine.org/en/stable/classes/class_string.html)) |


------------------

## Property Descriptions

### `apu_list`


[APUEntry[]](../APUEntry) apu_list


!!! note
    There is currently no description for this property. Please help us by contributing one!

### `database_name`


[String](https://docs.godotengine.org/en/stable/classes/class_string.html) database_name


!!! note
    There is currently no description for this property. Please help us by contributing one!

### `apu_map`


[Dictionary](https://docs.godotengine.org/en/stable/classes/class_dictionary.html) apu_map


!!! note
    There is currently no description for this property. Please help us by contributing one!

### `loaded`


[bool](https://docs.godotengine.org/en/stable/classes/class_bool.html) loaded = <span style="color: red;">false</span>


!!! note
    There is currently no description for this property. Please help us by contributing one!

### `logger`


[CustomLogger](../CustomLogger) logger


!!! note
    There is currently no description for this property. Please help us by contributing one!




------------------

## Method Descriptions

### `load_db()`


void **load_db**()


Load entries that are set in the APUDatabase resource file into a map. NOTE: This needs to be called after _init() in order for the exported apu_list to be populated.
### `get_apu()`


[APUEntry](../APUEntry) **get_apu**(apu_name: [String](https://docs.godotengine.org/en/stable/classes/class_string.html))


Returns an [APUEntry](../APUEntry) of the given APU
