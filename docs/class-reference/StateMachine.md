# StateMachine

**Inherits:** [Resource](https://docs.godotengine.org/en/stable/classes/class_resource.html)

Manages the current [State](../State) for some part of the application.
## Description

A [StateMachine](../StateMachine) is responsible for managing an arbitrary number of [State](../State) objects. The [StateMachine](../StateMachine) keeps a "stack" of states that can be set, pushed, popped, removed, or cleared, and will fire signals for each kind of change. This can allow the application to update and respond to different states of the [StateMachine](../StateMachine).  Only one [State](../State) is considered the "current" state in a [StateMachine](../StateMachine): the last state in the stack. A [State](../State) will fire the "entered" signal whenever it becomes the "current" state, and fires the "exited" signal whenever it leaves the "current" state.  The [StateMachine](../StateMachine) takes advantage of the fact that Godot resources are globally unique. This allows you to load a [StateMachine](../StateMachine) resource from anywhere in the project to subscribe to state changes.
## Properties

| Type | Name | Default |
| ---- | ---- | ------- |
| [String](https://docs.godotengine.org/en/stable/classes/class_string.html) | [logger_name](./#logger_name) | "StateMachine" |
| [int](https://docs.godotengine.org/en/stable/classes/class_int.html) | [minimum_states](./#minimum_states) | 1 |
| [State[]](../State) | [allowed_states](./#allowed_states) | [] |
| [CustomLogger](../CustomLogger) | [logger](./#logger) | <unknown> |

## Methods

| Returns | Signature |
| ------- | --------- |
| [State](../State) | [current_state](./#current_state)() |
| void | [refresh](./#refresh)() |
| void | [set_state](./#set_state)(new_stack: [State[]](../State)) |
| void | [push_state](./#push_state)(state: [State](../State)) |
| void | [push_state_front](./#push_state_front)(state: [State](../State)) |
| [State](../State) | [pop_state](./#pop_state)() |
| void | [replace_state](./#replace_state)(state: [State](../State)) |
| void | [remove_state](./#remove_state)(state: [State](../State)) |
| void | [clear_states](./#clear_states)() |
| [int](https://docs.godotengine.org/en/stable/classes/class_int.html) | [stack_length](./#stack_length)() |
| [State[]](../State) | [stack](./#stack)() |
| [bool](https://docs.godotengine.org/en/stable/classes/class_bool.html) | [has_state](./#has_state)(state: [State](../State)) |


------------------

## Property Descriptions

### `logger_name`


[String](https://docs.godotengine.org/en/stable/classes/class_string.html) logger_name = <span style="color: red;">"StateMachine"</span>


Name of the state machine to use for logging purposes
### `minimum_states`


[int](https://docs.godotengine.org/en/stable/classes/class_int.html) minimum_states = <span style="color: red;">1</span>


The minimum number of states that this [StateMachine](../StateMachine) must have. This parameter can be used to ensure that states cannot be popped below this number of states.
### `allowed_states`


[State[]](../State) allowed_states = <span style="color: red;">[]</span>


If set, only the given [State](../State) objects will be allowed to be added to the [StateMachine](../StateMachine). Will panic if an invalid state is added to the stack. If empty, all [State](../State) objects will be allowed.
### `logger`


[CustomLogger](../CustomLogger) logger


!!! note
    There is currently no description for this property. Please help us by contributing one!




------------------

## Method Descriptions

### `current_state()`


[State](../State) **current_state**()


Returns the current state at the end of the state stack
### `refresh()`


void **refresh**()


Emits the 'refreshed' signal on the current [State](../State). This can be used to trigger hand-offs between multiple state machines.
### `set_state()`


void **set_state**(new_stack: [State[]](../State))


Set state will set the entire state stack to the given array of states
### `push_state()`


void **push_state**(state: [State](../State))


Push state will push the given state to the top of the state stack.
### `push_state_front()`


void **push_state_front**(state: [State](../State))


Pushes the given state to the front of the stack
### `pop_state()`


[State](../State) **pop_state**()


Pop state will remove the last state from the stack and return it.
### `replace_state()`


void **replace_state**(state: [State](../State))


Replaces the current state at the end of the stack with the given state
### `remove_state()`


void **remove_state**(state: [State](../State))


Removes all instances of the given state from the stack
### `clear_states()`


void **clear_states**()


Removes all states
### `stack_length()`


[int](https://docs.godotengine.org/en/stable/classes/class_int.html) **stack_length**()


Returns the length of the state stack
### `stack()`


[State[]](../State) **stack**()


Returns the current state stack
### `has_state()`


[bool](https://docs.godotengine.org/en/stable/classes/class_bool.html) **has_state**(state: [State](../State))


Returns true if the given state exists anywhere in the state stack
