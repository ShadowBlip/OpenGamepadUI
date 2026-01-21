# State

**Inherits:** [Resource](https://docs.godotengine.org/en/stable/classes/class_resource.html)

Object for tracking the current state of a [StateMachine](../StateMachine)
## Description

A [State](../State) represents some state of the application, such as the currently focused menu. Together with a [StateMachine](../StateMachine), a [State](../State) can be used to listen for signals whenever the state of the application changes.  A [State](../State) takes advantage of the fact that Godot resources are globally unique. This allows you to load a [State](../State) resource from anywhere in the project to subscribe to state changes.
## Properties

| Type | Name | Default |
| ---- | ---- | ------- |
| [String](https://docs.godotengine.org/en/stable/classes/class_string.html) | [name](./#name) |  |
| [Dictionary](https://docs.godotengine.org/en/stable/classes/class_dictionary.html) | [data](./#data) |  |



------------------

## Property Descriptions

### `name`


[String](https://docs.godotengine.org/en/stable/classes/class_string.html) name


Optional human-readable name for the state
### `data`


[Dictionary](https://docs.godotengine.org/en/stable/classes/class_dictionary.html) data


DEPRECATED: Use 'set_meta()' or 'get_meta()' instead

