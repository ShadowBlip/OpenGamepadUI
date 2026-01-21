# InputPlumberMapping

**Inherits:** [Resource](https://docs.godotengine.org/en/stable/classes/class_resource.html)

Resource for a single mapping in an InputPlumber input profile
## Description

This resource is used to represent a single mapping of a source event to a target event.
## Properties

| Type | Name | Default |
| ---- | ---- | ------- |
| [String](https://docs.godotengine.org/en/stable/classes/class_string.html) | [name](./#name) |  |
| [InputPlumberEvent](../InputPlumberEvent) | [source_event](./#source_event) |  |
| [InputPlumberEvent[]](../InputPlumberEvent) | [target_events](./#target_events) |  |

## Methods

| Returns | Signature |
| ------- | --------- |
| [InputPlumberMapping](../InputPlumberMapping) | [from_source_capability](./#from_source_capability)(capability: [String](https://docs.godotengine.org/en/stable/classes/class_string.html)) |
| [InputPlumberMapping](../InputPlumberMapping) | [from_dict](./#from_dict)(dict: [Dictionary](https://docs.godotengine.org/en/stable/classes/class_dictionary.html)) |
| [Dictionary](https://docs.godotengine.org/en/stable/classes/class_dictionary.html) | [to_dict](./#to_dict)() |


------------------

## Property Descriptions

### `name`


[String](https://docs.godotengine.org/en/stable/classes/class_string.html) name


!!! note
    There is currently no description for this property. Please help us by contributing one!

### `source_event`


[InputPlumberEvent](../InputPlumberEvent) source_event


!!! note
    There is currently no description for this property. Please help us by contributing one!

### `target_events`


[InputPlumberEvent[]](../InputPlumberEvent) target_events


!!! note
    There is currently no description for this property. Please help us by contributing one!




------------------

## Method Descriptions

### `from_source_capability()`


[InputPlumberMapping](../InputPlumberMapping) **from_source_capability**(capability: [String](https://docs.godotengine.org/en/stable/classes/class_string.html))


Create a new mapping from the given source capability string.
### `from_dict()`


[InputPlumberMapping](../InputPlumberMapping) **from_dict**(dict: [Dictionary](https://docs.godotengine.org/en/stable/classes/class_dictionary.html))


!!! note
    There is currently no description for this method. Please help us by contributing one!

### `to_dict()`


[Dictionary](https://docs.godotengine.org/en/stable/classes/class_dictionary.html) **to_dict**()


!!! note
    There is currently no description for this method. Please help us by contributing one!

