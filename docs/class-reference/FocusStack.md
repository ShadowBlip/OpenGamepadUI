# FocusStack

**Inherits:** [Resource](https://docs.godotengine.org/en/stable/classes/class_resource.html)

Manages the focus flow using a stack
## Description

Keeps track of levels of focus through a stack
## Properties

| Type | Name | Default |
| ---- | ---- | ------- |
| [FocusGroup[]](../FocusGroup) | [stack](./#stack) | [] |
| [CustomLogger](../CustomLogger) | [logger](./#logger) | <unknown> |

## Methods

| Returns | Signature |
| ------- | --------- |
| [FocusGroup](../FocusGroup) | [current_focus](./#current_focus)() |
| [bool](https://docs.godotengine.org/en/stable/classes/class_bool.html) | [is_focused](./#is_focused)(group: [FocusGroup](../FocusGroup)) |
| [bool](https://docs.godotengine.org/en/stable/classes/class_bool.html) | [is_in_stack](./#is_in_stack)(group: [FocusGroup](../FocusGroup)) |
| [int](https://docs.godotengine.org/en/stable/classes/class_int.html) | [size](./#size)() |
| void | [push](./#push)(group: [FocusGroup](../FocusGroup)) |
| [FocusGroup](../FocusGroup) | [pop](./#pop)() |
| void | [clear](./#clear)() |


------------------

## Property Descriptions

### `stack`


[FocusGroup[]](../FocusGroup) stack = <span style="color: red;">[]</span>


!!! note
    There is currently no description for this property. Please help us by contributing one!

### `logger`


[CustomLogger](../CustomLogger) logger


!!! note
    There is currently no description for this property. Please help us by contributing one!




------------------

## Method Descriptions

### `current_focus()`


[FocusGroup](../FocusGroup) **current_focus**()


Returns the currently focused focus group
### `is_focused()`


[bool](https://docs.godotengine.org/en/stable/classes/class_bool.html) **is_focused**(group: [FocusGroup](../FocusGroup))


Returns whether or not the given focus group is currently focused
### `is_in_stack()`


[bool](https://docs.godotengine.org/en/stable/classes/class_bool.html) **is_in_stack**(group: [FocusGroup](../FocusGroup))


Returns true if the given focus group exists anywhere in the stack
### `size()`


[int](https://docs.godotengine.org/en/stable/classes/class_int.html) **size**()


Current size of the focus stack
### `push()`


void **push**(group: [FocusGroup](../FocusGroup))


Push the given focus group to the top of the focus stack and call its grab_focus method
### `pop()`


[FocusGroup](../FocusGroup) **pop**()


Remove and return the focus group at the top of the focus stack and call the next focus group's grab_focus method.
### `clear()`


void **clear**()


Clear the focus stack
