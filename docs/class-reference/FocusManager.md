# FocusManager

**Inherits:** [Node](https://docs.godotengine.org/en/stable/classes/class_node.html)


## Properties

| Type | Name | Default |
| ---- | ---- | ------- |
| [Control](https://docs.godotengine.org/en/stable/classes/class_control.html) | [current_focus](./#current_focus) |  |
| [bool](https://docs.godotengine.org/en/stable/classes/class_bool.html) | [process_input](./#process_input) | false |
| [String](https://docs.godotengine.org/en/stable/classes/class_string.html) | [refocus_on](./#refocus_on) | "ogui_east" |
| [bool](https://docs.godotengine.org/en/stable/classes/class_bool.html) | [intercept_children_only](./#intercept_children_only) | false |
| [FocusStack](../FocusStack) | [focus_stack](./#focus_stack) |  |
| [CustomLogger](../CustomLogger) | [logger](./#logger) | <unknown> |
| [Control](https://docs.godotengine.org/en/stable/classes/class_control.html) | [parent](./#parent) | <unknown> |

## Methods

| Returns | Signature |
| ------- | --------- |
| void | [recalculate_focus](./#recalculate_focus)() |


------------------

## Property Descriptions

### `current_focus`


[Control](https://docs.godotengine.org/en/stable/classes/class_control.html) current_focus


!!! note
    There is currently no description for this property. Please help us by contributing one!

### `process_input`


[bool](https://docs.godotengine.org/en/stable/classes/class_bool.html) process_input = <span style="color: red;">false</span>


If enabled, will intercept input and refocus on the current focus node instead
### `refocus_on`


[String](https://docs.godotengine.org/en/stable/classes/class_string.html) refocus_on = <span style="color: red;">"ogui_east"</span>


The InputEvent that will trigger refocusing the current focus node
### `intercept_children_only`


[bool](https://docs.godotengine.org/en/stable/classes/class_bool.html) intercept_children_only = <span style="color: red;">false</span>


If true, only intercept input and refocus if a descendent node has focus
### `focus_stack`


[FocusStack](../FocusStack) focus_stack


Menus with multiple levels of focus can be part of a chain of focus
### `logger`


[CustomLogger](../CustomLogger) logger


!!! note
    There is currently no description for this property. Please help us by contributing one!

### `parent`


[Control](https://docs.godotengine.org/en/stable/classes/class_control.html) parent


!!! note
    There is currently no description for this property. Please help us by contributing one!




------------------

## Method Descriptions

### `recalculate_focus()`


void **recalculate_focus**()


Recalculate the focus neighbors of the container's children
