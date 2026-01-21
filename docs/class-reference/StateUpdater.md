# StateUpdater

**Inherits:** [Node](https://docs.godotengine.org/en/stable/classes/class_node.html)

Update the state of a state machine when a signal fires
## Description

The [StateUpdater](../StateUpdater) can be added as a child to any node that exposes signals. Upon entering the scene tree, the [StateUpdater](../StateUpdater) connects to a given signal on its parent, and will update the configured state machine's state to the given state, allowing menus to react to state changes (e.g. changing menus)
## Properties

| Type | Name | Default |
| ---- | ---- | ------- |
| [StateMachine](../StateMachine) | [state_machine](./#state_machine) |  |
| [String](https://docs.godotengine.org/en/stable/classes/class_string.html) | [on_signal](./#on_signal) |  |
| [State](../State) | [state](./#state) |  |
| [int](https://docs.godotengine.org/en/stable/classes/class_int.html) | [action](./#action) | 0 |



------------------

## Property Descriptions

### `state_machine`


[StateMachine](../StateMachine) state_machine


The state machine instance to use for managing state changes
### `on_signal`


[String](https://docs.godotengine.org/en/stable/classes/class_string.html) on_signal


Signal on our parent to connect to. When this signal fires, the [StateUpdater](../StateUpdater) will change the state machine to the given state.
### `state`


[State](../State) state


The state to change to when the given signal is emitted.
### `action`


[int](https://docs.godotengine.org/en/stable/classes/class_int.html) action = <span style="color: red;">0</span>


Whether to push, pop, replace, or set the state when the signal has fired.

