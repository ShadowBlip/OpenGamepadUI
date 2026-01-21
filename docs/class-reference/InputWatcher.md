# InputWatcher

**Inherits:** [Node](https://docs.godotengine.org/en/stable/classes/class_node.html)

Fires signals based on configured input events
## Description

The [InputWatcher](../InputWatcher) fires signals based on detected input events. This enables other nodes to react to inputs through signals in the editor.
## Properties

| Type | Name | Default |
| ---- | ---- | ------- |
| [bool](https://docs.godotengine.org/en/stable/classes/class_bool.html) | [stop_propagation](./#stop_propagation) |  |
| [int](https://docs.godotengine.org/en/stable/classes/class_int.html) | [process_input_mode](./#process_input_mode) | 3 |
| [String](https://docs.godotengine.org/en/stable/classes/class_string.html) | [action](./#action) |  |
| [CustomLogger](../CustomLogger) | [logger](./#logger) | <unknown> |



------------------

## Property Descriptions

### `stop_propagation`


[bool](https://docs.godotengine.org/en/stable/classes/class_bool.html) stop_propagation


If true, consumes the event, marking it as handled so no other nodes try to handle this input event.
### `process_input_mode`


[int](https://docs.godotengine.org/en/stable/classes/class_int.html) process_input_mode = <span style="color: red;">3</span>


Always process inputs or only when parent node is visible
### `action`


[String](https://docs.godotengine.org/en/stable/classes/class_string.html) action


Name of the input action in the InputMap to watch for
### `logger`


[CustomLogger](../CustomLogger) logger


!!! note
    There is currently no description for this property. Please help us by contributing one!


