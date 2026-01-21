# PlatformNixOS

**Inherits:** [OSPlatform](../OSPlatform)


## Properties

| Type | Name | Default |
| ---- | ---- | ------- |
| [SettingsManager](../SettingsManager) | [settings_manager](./#settings_manager) | <unknown> |
| [NotificationManager](../NotificationManager) | [notification_manager](./#notification_manager) | <unknown> |
| [PackedScene](https://docs.godotengine.org/en/stable/classes/class_packedscene.html) | [sections_label_scene](./#sections_label_scene) | <unknown> |
| [PackedScene](https://docs.godotengine.org/en/stable/classes/class_packedscene.html) | [button_scene](./#button_scene) | <unknown> |
| [PackedScene](https://docs.godotengine.org/en/stable/classes/class_packedscene.html) | [toggle_scene](./#toggle_scene) | <unknown> |
| [PackedScene](https://docs.godotengine.org/en/stable/classes/class_packedscene.html) | [dropdown_scene](./#dropdown_scene) | <unknown> |
| [State](../State) | [general_settings_state](./#general_settings_state) | <unknown> |
| [bool](https://docs.godotengine.org/en/stable/classes/class_bool.html) | [update_available](./#update_available) | false |
| [bool](https://docs.godotengine.org/en/stable/classes/class_bool.html) | [update_installed](./#update_installed) | false |

## Methods

| Returns | Signature |
| ------- | --------- |
| void | [ready](./#ready)(root: [Window](https://docs.godotengine.org/en/stable/classes/class_window.html)) |
| [String[]](https://docs.godotengine.org/en/stable/classes/class_string.html) | [get_binary_compatibility_cmd](./#get_binary_compatibility_cmd)(cmd: [String](https://docs.godotengine.org/en/stable/classes/class_string.html), args: [PackedStringArray](https://docs.godotengine.org/en/stable/classes/class_packedstringarray.html)) |


------------------

## Property Descriptions

### `settings_manager`


[SettingsManager](../SettingsManager) settings_manager


!!! note
    There is currently no description for this property. Please help us by contributing one!

### `notification_manager`


[NotificationManager](../NotificationManager) notification_manager


!!! note
    There is currently no description for this property. Please help us by contributing one!

### `sections_label_scene`


[PackedScene](https://docs.godotengine.org/en/stable/classes/class_packedscene.html) sections_label_scene


!!! note
    There is currently no description for this property. Please help us by contributing one!

### `button_scene`


[PackedScene](https://docs.godotengine.org/en/stable/classes/class_packedscene.html) button_scene


!!! note
    There is currently no description for this property. Please help us by contributing one!

### `toggle_scene`


[PackedScene](https://docs.godotengine.org/en/stable/classes/class_packedscene.html) toggle_scene


!!! note
    There is currently no description for this property. Please help us by contributing one!

### `dropdown_scene`


[PackedScene](https://docs.godotengine.org/en/stable/classes/class_packedscene.html) dropdown_scene


!!! note
    There is currently no description for this property. Please help us by contributing one!

### `general_settings_state`


[State](../State) general_settings_state


!!! note
    There is currently no description for this property. Please help us by contributing one!

### `update_available`


[bool](https://docs.godotengine.org/en/stable/classes/class_bool.html) update_available = <span style="color: red;">false</span>


!!! note
    There is currently no description for this property. Please help us by contributing one!

### `update_installed`


[bool](https://docs.godotengine.org/en/stable/classes/class_bool.html) update_installed = <span style="color: red;">false</span>


!!! note
    There is currently no description for this property. Please help us by contributing one!




------------------

## Method Descriptions

### `ready()`


void **ready**(root: [Window](https://docs.godotengine.org/en/stable/classes/class_window.html))


Ready will be called after the scene tree has initialized.
### `get_binary_compatibility_cmd()`


[String[]](https://docs.godotengine.org/en/stable/classes/class_string.html) **get_binary_compatibility_cmd**(cmd: [String](https://docs.godotengine.org/en/stable/classes/class_string.html), args: [PackedStringArray](https://docs.godotengine.org/en/stable/classes/class_packedstringarray.html))


NixOS typically cannot execute regular binaries, so downloaded binaries will be run with 'steam-run'.
