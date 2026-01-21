# QuickBarCard

**Inherits:** [Container](https://docs.godotengine.org/en/stable/classes/class_container.html)


## Properties

| Type | Name | Default |
| ---- | ---- | ------- |
| [String](https://docs.godotengine.org/en/stable/classes/class_string.html) | [title](./#title) | "Section" |
| [bool](https://docs.godotengine.org/en/stable/classes/class_bool.html) | [is_toggled](./#is_toggled) | false |
| [VBoxContainer](https://docs.godotengine.org/en/stable/classes/class_vboxcontainer.html) | [header_container](./#header_container) | <unknown> |
| [Label](https://docs.godotengine.org/en/stable/classes/class_label.html) | [label](./#label) | <unknown> |
| [TextureRect](https://docs.godotengine.org/en/stable/classes/class_texturerect.html) | [highlight](./#highlight) | <unknown> |
| [VBoxContainer](https://docs.godotengine.org/en/stable/classes/class_vboxcontainer.html) | [content_container](./#content_container) | <unknown> |
| [FocusGroupSetter](../FocusGroupSetter) | [focus_group_setter](./#focus_group_setter) | <unknown> |
| [SmoothScrollEffect](../SmoothScrollEffect) | [smooth_scroll](./#smooth_scroll) | <unknown> |
| [GrowerEffect](../GrowerEffect) | [grower](./#grower) | <unknown> |
| [bool](https://docs.godotengine.org/en/stable/classes/class_bool.html) | [effect_in_progress](./#effect_in_progress) | false |
| [FocusGroup](../FocusGroup) | [focus_group](./#focus_group) |  |
| [CustomLogger](../CustomLogger) | [logger](./#logger) | <unknown> |

## Methods

| Returns | Signature |
| ------- | --------- |
| void | [add_header](./#add_header)(content: [Control](https://docs.godotengine.org/en/stable/classes/class_control.html), alignment: [int](https://docs.godotengine.org/en/stable/classes/class_int.html)) |
| void | [add_content](./#add_content)(content: [Control](https://docs.godotengine.org/en/stable/classes/class_control.html)) |


------------------

## Property Descriptions

### `title`


[String](https://docs.godotengine.org/en/stable/classes/class_string.html) title = <span style="color: red;">"Section"</span>


!!! note
    There is currently no description for this property. Please help us by contributing one!

### `is_toggled`


[bool](https://docs.godotengine.org/en/stable/classes/class_bool.html) is_toggled = <span style="color: red;">false</span>


!!! note
    There is currently no description for this property. Please help us by contributing one!

### `header_container`


[VBoxContainer](https://docs.godotengine.org/en/stable/classes/class_vboxcontainer.html) header_container


!!! note
    There is currently no description for this property. Please help us by contributing one!

### `label`


[Label](https://docs.godotengine.org/en/stable/classes/class_label.html) label


!!! note
    There is currently no description for this property. Please help us by contributing one!

### `highlight`


[TextureRect](https://docs.godotengine.org/en/stable/classes/class_texturerect.html) highlight


!!! note
    There is currently no description for this property. Please help us by contributing one!

### `content_container`


[VBoxContainer](https://docs.godotengine.org/en/stable/classes/class_vboxcontainer.html) content_container


!!! note
    There is currently no description for this property. Please help us by contributing one!

### `focus_group_setter`


[FocusGroupSetter](../FocusGroupSetter) focus_group_setter


!!! note
    There is currently no description for this property. Please help us by contributing one!

### `smooth_scroll`


[SmoothScrollEffect](../SmoothScrollEffect) smooth_scroll


!!! note
    There is currently no description for this property. Please help us by contributing one!

### `grower`


[GrowerEffect](../GrowerEffect) grower


!!! note
    There is currently no description for this property. Please help us by contributing one!

### `effect_in_progress`


[bool](https://docs.godotengine.org/en/stable/classes/class_bool.html) effect_in_progress = <span style="color: red;">false</span>


!!! note
    There is currently no description for this property. Please help us by contributing one!

### `focus_group`


[FocusGroup](../FocusGroup) focus_group


!!! note
    There is currently no description for this property. Please help us by contributing one!

### `logger`


[CustomLogger](../CustomLogger) logger


!!! note
    There is currently no description for this property. Please help us by contributing one!




------------------

## Method Descriptions

### `add_header()`


void **add_header**(content: [Control](https://docs.godotengine.org/en/stable/classes/class_control.html), alignment: [int](https://docs.godotengine.org/en/stable/classes/class_int.html))


Add the given content as the header to the card. Disables the section header when used.
### `add_content()`


void **add_content**(content: [Control](https://docs.godotengine.org/en/stable/classes/class_control.html))


Add the given content to the card
