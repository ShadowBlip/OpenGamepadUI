# CardInputIconButton

**Inherits:** [PanelContainer](https://docs.godotengine.org/en/stable/classes/class_panelcontainer.html)


## Properties

| Type | Name | Default |
| ---- | ---- | ------- |
| [bool](https://docs.godotengine.org/en/stable/classes/class_bool.html) | [disabled](./#disabled) | false |
| [bool](https://docs.godotengine.org/en/stable/classes/class_bool.html) | [click_focuses](./#click_focuses) | true |
| [CustomLogger](../CustomLogger) | [logger](./#logger) | <unknown> |
| [InputIcon](../InputIcon) | [input_icon](./#input_icon) | <unknown> |
| [TextureRect](https://docs.godotengine.org/en/stable/classes/class_texturerect.html) | [highlight](./#highlight) | <unknown> |

## Methods

| Returns | Signature |
| ------- | --------- |
| void | [set_target_device_icon_mapping](./#set_target_device_icon_mapping)(mapping_name: [String](https://docs.godotengine.org/en/stable/classes/class_string.html)) |
| [int](https://docs.godotengine.org/en/stable/classes/class_int.html) | [set_target_icon](./#set_target_icon)(capability: [String](https://docs.godotengine.org/en/stable/classes/class_string.html)) |


------------------

## Property Descriptions

### `disabled`


[bool](https://docs.godotengine.org/en/stable/classes/class_bool.html) disabled = <span style="color: red;">false</span>


!!! note
    There is currently no description for this property. Please help us by contributing one!

### `click_focuses`


[bool](https://docs.godotengine.org/en/stable/classes/class_bool.html) click_focuses = <span style="color: red;">true</span>


!!! note
    There is currently no description for this property. Please help us by contributing one!

### `logger`


[CustomLogger](../CustomLogger) logger


!!! note
    There is currently no description for this property. Please help us by contributing one!

### `input_icon`


[InputIcon](../InputIcon) input_icon


!!! note
    There is currently no description for this property. Please help us by contributing one!

### `highlight`


[TextureRect](https://docs.godotengine.org/en/stable/classes/class_texturerect.html) highlight


!!! note
    There is currently no description for this property. Please help us by contributing one!




------------------

## Method Descriptions

### `set_target_device_icon_mapping()`


void **set_target_device_icon_mapping**(mapping_name: [String](https://docs.godotengine.org/en/stable/classes/class_string.html))


Set the target input icon's icon mapping
### `set_target_icon()`


[int](https://docs.godotengine.org/en/stable/classes/class_int.html) **set_target_icon**(capability: [String](https://docs.godotengine.org/en/stable/classes/class_string.html))


Configures the button for the given mappable event. If a path cannot be found, this will return an error.
