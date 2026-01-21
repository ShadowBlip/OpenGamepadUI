# OverlayInputManager

**Inherits:** [InputManager](../InputManager)

Manages global input while ion overlay mode
## Description

The OverlayInputManager class is responsible for handling global input while the quick bar or configuration menu are open while permitting underlay process chords to function, such as the Steam Quick Access Menu chord.

To include this functionality, add this as a node to the root node in the scene tree.
## Properties

| Type | Name | Default |
| ---- | ---- | ------- |
| [StateMachine](../StateMachine) | [menu_state_machine](./#menu_state_machine) | <Object> |
| [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html) | [base_state](./#base_state) | <Object> |

## Methods

| Returns | Signature |
| ------- | --------- |
| [String](https://docs.godotengine.org/en/stable/classes/class_string.html) | [get_default_global_profile_path](./#get_default_global_profile_path)() |
| void | [action_release](./#action_release)(dbus_path: [String](https://docs.godotengine.org/en/stable/classes/class_string.html), action: [String](https://docs.godotengine.org/en/stable/classes/class_string.html), strength: [float](https://docs.godotengine.org/en/stable/classes/class_float.html) = 1.0) |
| void | [action_press](./#action_press)(dbus_path: [String](https://docs.godotengine.org/en/stable/classes/class_string.html), action: [String](https://docs.godotengine.org/en/stable/classes/class_string.html), strength: [float](https://docs.godotengine.org/en/stable/classes/class_float.html) = 1.0) |


------------------

## Property Descriptions

### `menu_state_machine`


[StateMachine](../StateMachine) menu_state_machine


!!! note
    There is currently no description for this property. Please help us by contributing one!

### `base_state`


[Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html) base_state


!!! note
    There is currently no description for this property. Please help us by contributing one!




------------------

## Method Descriptions

### `get_default_global_profile_path()`


[String](https://docs.godotengine.org/en/stable/classes/class_string.html) **get_default_global_profile_path**()


!!! note
    There is currently no description for this method. Please help us by contributing one!

### `action_release()`


void **action_release**(dbus_path: [String](https://docs.godotengine.org/en/stable/classes/class_string.html), action: [String](https://docs.godotengine.org/en/stable/classes/class_string.html), strength: [float](https://docs.godotengine.org/en/stable/classes/class_float.html) = 1.0)


Queue a release event for the given action
### `action_press()`


void **action_press**(dbus_path: [String](https://docs.godotengine.org/en/stable/classes/class_string.html), action: [String](https://docs.godotengine.org/en/stable/classes/class_string.html), strength: [float](https://docs.godotengine.org/en/stable/classes/class_float.html) = 1.0)


Queue a pressed event for the given action
