# BackInputHandler

**Inherits:** [Node](https://docs.godotengine.org/en/stable/classes/class_node.html)

DEPRECATED: Use [InputWatcher](../InputWatcher) with [StateUpdater](../StateUpdater) instead
## Properties

| Type | Name | Default |
| ---- | ---- | ------- |
| [StateMachine](../StateMachine) | [state_machine](./#state_machine) | <Object> |
| [State[]](../State) | [process_input_during](./#process_input_during) | [] |
| [int](https://docs.godotengine.org/en/stable/classes/class_int.html) | [minimum_states](./#minimum_states) | 1 |
| [CustomLogger](../CustomLogger) | [logger](./#logger) | <unknown> |



------------------

## Property Descriptions

### `state_machine`


[StateMachine](../StateMachine) state_machine


The state machine to use to update when back input is pressed
### `process_input_during`


[State[]](../State) process_input_during = <span style="color: red;">[]</span>


Pop the state machine when back input is pressed during any of these states
### `minimum_states`


[int](https://docs.godotengine.org/en/stable/classes/class_int.html) minimum_states = <span style="color: red;">1</span>


Minimum number of states in the state machine stack. [BackInputHandler](../BackInputHandler) will not pop the state machine stack beyond this number.
### `logger`


[CustomLogger](../CustomLogger) logger


Will show logger events with the prefix BackInputHandler

