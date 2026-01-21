# CardMappingButtonGroup

**Inherits:** [VBoxContainer](https://docs.godotengine.org/en/stable/classes/class_vboxcontainer.html)


## Properties

| Type | Name | Default |
| ---- | ---- | ------- |
| [State](../State) | [change_input_state](./#change_input_state) | <unknown> |
| [PackedScene](https://docs.godotengine.org/en/stable/classes/class_packedscene.html) | [button_scene](./#button_scene) | <unknown> |
| [CustomLogger](../CustomLogger) | [logger](./#logger) | <unknown> |
| [VBoxContainer](https://docs.godotengine.org/en/stable/classes/class_vboxcontainer.html) | [container](./#container) | <unknown> |
| [FocusGroup](../FocusGroup) | [focus_group](./#focus_group) | <unknown> |
| [Dropdown](../Dropdown) | [dropdown](./#dropdown) | <unknown> |
| [ValueSlider](../ValueSlider) | [deadzone](./#deadzone) | <unknown> |

## Methods

| Returns | Signature |
| ------- | --------- |
| void | [set_source_device_icon_mapping](./#set_source_device_icon_mapping)(mapping_name: [String](https://docs.godotengine.org/en/stable/classes/class_string.html)) |
| void | [set_target_device_icon_mapping](./#set_target_device_icon_mapping)(mapping_name: [String](https://docs.godotengine.org/en/stable/classes/class_string.html)) |
| void | [set_source_capability](./#set_source_capability)(capability: [String](https://docs.godotengine.org/en/stable/classes/class_string.html)) |
| void | [set_callback](./#set_callback)(callback: [Callable](https://docs.godotengine.org/en/stable/classes/class_callable.html)) |
| [bool](https://docs.godotengine.org/en/stable/classes/class_bool.html) | [has_mappings](./#has_mappings)() |
| void | [set_mapping_type](./#set_mapping_type)(mapping_type: [int](https://docs.godotengine.org/en/stable/classes/class_int.html)) |
| void | [set_mappings](./#set_mappings)(mappings: [InputPlumberMapping[]](../InputPlumberMapping)) |
| void | [clear_mapping_buttons](./#clear_mapping_buttons)() |
| void | [update](./#update)() |


------------------

## Property Descriptions

### `change_input_state`


[State](../State) change_input_state


!!! note
    There is currently no description for this property. Please help us by contributing one!

### `button_scene`


[PackedScene](https://docs.godotengine.org/en/stable/classes/class_packedscene.html) button_scene


!!! note
    There is currently no description for this property. Please help us by contributing one!

### `logger`


[CustomLogger](../CustomLogger) logger


!!! note
    There is currently no description for this property. Please help us by contributing one!

### `container`


[VBoxContainer](https://docs.godotengine.org/en/stable/classes/class_vboxcontainer.html) container


!!! note
    There is currently no description for this property. Please help us by contributing one!

### `focus_group`


[FocusGroup](../FocusGroup) focus_group


!!! note
    There is currently no description for this property. Please help us by contributing one!

### `dropdown`


[Dropdown](../Dropdown) dropdown


!!! note
    There is currently no description for this property. Please help us by contributing one!

### `deadzone`


[ValueSlider](../ValueSlider) deadzone


!!! note
    There is currently no description for this property. Please help us by contributing one!




------------------

## Method Descriptions

### `set_source_device_icon_mapping()`


void **set_source_device_icon_mapping**(mapping_name: [String](https://docs.godotengine.org/en/stable/classes/class_string.html))


Set the source input icon's icon mapping
### `set_target_device_icon_mapping()`


void **set_target_device_icon_mapping**(mapping_name: [String](https://docs.godotengine.org/en/stable/classes/class_string.html))


Set the target input icon's icon mapping
### `set_source_capability()`


void **set_source_capability**(capability: [String](https://docs.godotengine.org/en/stable/classes/class_string.html))


Set the source capability for this container
### `set_callback()`


void **set_callback**(callback: [Callable](https://docs.godotengine.org/en/stable/classes/class_callable.html))


!!! note
    There is currently no description for this method. Please help us by contributing one!

### `has_mappings()`


[bool](https://docs.godotengine.org/en/stable/classes/class_bool.html) **has_mappings**()


Returns true if the group has any mappings configured.
### `set_mapping_type()`


void **set_mapping_type**(mapping_type: [int](https://docs.godotengine.org/en/stable/classes/class_int.html))


Update the group based on the mapping type.
### `set_mappings()`


void **set_mappings**(mappings: [InputPlumberMapping[]](../InputPlumberMapping))


Configures the container for the given input mappings. This method assumes that the given mappings are all for the same source event.
### `clear_mapping_buttons()`


void **clear_mapping_buttons**()


Clear all mapping buttons from the container
### `update()`


void **update**()


Update the group based on the type
