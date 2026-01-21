# InputPlumber

**Inherits:** [Node](https://docs.godotengine.org/en/stable/classes/class_node.html)

Manages routing input to and from InputPlumber.
## Description

The InputPlumberManager class is responsible for handling dbus messages to and from the InputPlumber input manager daemon.
## Properties

| Type | Name | Default |
| ---- | ---- | ------- |
| [InputPlumberInstance](../InputPlumberInstance) | [instance](./#instance) | load(...) |

## Methods

| Returns | Signature |
| ------- | --------- |
| void | [load_target_modified_profile](./#load_target_modified_profile)(device: [CompositeDevice](../CompositeDevice), path: [String](https://docs.godotengine.org/en/stable/classes/class_string.html), profile_modifier: [String](https://docs.godotengine.org/en/stable/classes/class_string.html) = "") |


------------------

## Property Descriptions

### `instance`


[InputPlumberInstance](../InputPlumberInstance) instance = <span style="color: red;">load(...)</span>


!!! note
    There is currently no description for this property. Please help us by contributing one!




------------------

## Method Descriptions

### `load_target_modified_profile()`


void **load_target_modified_profile**(device: [CompositeDevice](../CompositeDevice), path: [String](https://docs.godotengine.org/en/stable/classes/class_string.html), profile_modifier: [String](https://docs.godotengine.org/en/stable/classes/class_string.html) = "")


Load the given profile on the composite device, optionally specifying a profile modifier, which is a target device string (e.g. "deck", "ds5-edge", etc.) to adapt the profile for. This will update the profile with target-specific defaults, like mapping left/right pads to the DualSense center pad if no other mappings are defined.
