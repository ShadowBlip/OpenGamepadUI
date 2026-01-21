# VisibilityManager

**Inherits:** [Node](https://docs.godotengine.org/en/stable/classes/class_node.html)

Update visibility based on [State](../State) changes to a [StateMachine](../StateMachine)
## Description

DEPRECATED in favor of [StateWatcher](../StateWatcher) with a child [Effect](../Effect). The [VisibilityManager](../VisibilityManager) manages the visibility of its parent node based on the current [State](../State) of a [StateMachine](../StateMachine). This enables nodes to be visible or invisible only during the correct state(s), allowing menus to hide themselves or become visible depending on the state. Optionally, [Transition](../Transition) nodes can be added as a child to [VisibilityManager](../VisibilityManager) to play an animation to show or hide the node.
## Properties

| Type | Name | Default |
| ---- | ---- | ------- |
| [StateMachine](../StateMachine) | [state_machine](./#state_machine) | <Object> |
| [State](../State) | [state](./#state) |  |
| [Resource[]](https://docs.godotengine.org/en/stable/classes/class_resource.html) | [visible_during](./#visible_during) | [] |
| [CustomLogger](../CustomLogger) | [logger](./#logger) | <unknown> |

## Methods

| Returns | Signature |
| ------- | --------- |
| [bool](https://docs.godotengine.org/en/stable/classes/class_bool.html) | [has_transitions](./#has_transitions)() |
| void | [enter](./#enter)() |
| void | [exit](./#exit)() |


------------------

## Property Descriptions

### `state_machine`


[StateMachine](../StateMachine) state_machine


The state machine instance to use for managing state changes
### `state`


[State](../State) state


Toggles visibility when this state is entered
### `visible_during`


[Resource[]](https://docs.godotengine.org/en/stable/classes/class_resource.html) visible_during = <span style="color: red;">[]</span>


Toggles visibility when any of these states are entered, but the main state exists in the state stack
### `logger`


[CustomLogger](../CustomLogger) logger


!!! note
    There is currently no description for this property. Please help us by contributing one!




------------------

## Method Descriptions

### `has_transitions()`


[bool](https://docs.godotengine.org/en/stable/classes/class_bool.html) **has_transitions**()


!!! note
    There is currently no description for this method. Please help us by contributing one!

### `enter()`


void **enter**()


!!! note
    There is currently no description for this method. Please help us by contributing one!

### `exit()`


void **exit**()


!!! note
    There is currently no description for this method. Please help us by contributing one!

