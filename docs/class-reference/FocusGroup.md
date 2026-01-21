# FocusGroup

**Inherits:** [Node](https://docs.godotengine.org/en/stable/classes/class_node.html)

Automatically manage focus for Control nodes in a container
## Description

FocusGroup connects the focus neighbors of all control nodes in the given parent container.
## Properties

| Type | Name | Default |
| ---- | ---- | ------- |
| [Control](https://docs.godotengine.org/en/stable/classes/class_control.html) | [current_focus](./#current_focus) |  |
| [FocusStack](../FocusStack) | [focus_stack](./#focus_stack) |  |
| [String](https://docs.godotengine.org/en/stable/classes/class_string.html) | [back_action](./#back_action) | "ogui_east" |
| [bool](https://docs.godotengine.org/en/stable/classes/class_bool.html) | [wrap_focus](./#wrap_focus) | true |
| [FocusGroup](../FocusGroup) | [focus_neighbor_bottom](./#focus_neighbor_bottom) |  |
| [FocusGroup](../FocusGroup) | [focus_neighbor_top](./#focus_neighbor_top) |  |
| [FocusGroup](../FocusGroup) | [focus_neighbor_left](./#focus_neighbor_left) |  |
| [FocusGroup](../FocusGroup) | [focus_neighbor_right](./#focus_neighbor_right) |  |
| [Control](https://docs.godotengine.org/en/stable/classes/class_control.html) | [neighbor_control](./#neighbor_control) | <unknown> |
| [CustomLogger](../CustomLogger) | [logger](./#logger) | <unknown> |
| [Control](https://docs.godotengine.org/en/stable/classes/class_control.html) | [parent](./#parent) | <unknown> |

## Methods

| Returns | Signature |
| ------- | --------- |
| void | [recalculate_focus](./#recalculate_focus)() |
| void | [grab_focus](./#grab_focus)() |
| [bool](https://docs.godotengine.org/en/stable/classes/class_bool.html) | [is_focused](./#is_focused)() |
| [bool](https://docs.godotengine.org/en/stable/classes/class_bool.html) | [is_in_focus_stack](./#is_in_focus_stack)() |
| [Node](https://docs.godotengine.org/en/stable/classes/class_node.html) | [find_focusable](./#find_focusable)(nodes: [Node[]](https://docs.godotengine.org/en/stable/classes/class_node.html), root: [Node](https://docs.godotengine.org/en/stable/classes/class_node.html) = null) |


------------------

## Property Descriptions

### `current_focus`


[Control](https://docs.godotengine.org/en/stable/classes/class_control.html) current_focus


The current focus of the focus group
### `focus_stack`


[FocusStack](../FocusStack) focus_stack


DEPRECATED: Use [InputWatcher](../InputWatcher) nodes with [FocusSetter](../FocusSetter) to handle back input. Menus with multiple levels of focus groups can be part of a chain of focus
### `back_action`


[String](https://docs.godotengine.org/en/stable/classes/class_string.html) back_action = <span style="color: red;">"ogui_east"</span>


The InputEvent that will trigger focusing a parent focus group
### `wrap_focus`


[bool](https://docs.godotengine.org/en/stable/classes/class_bool.html) wrap_focus = <span style="color: red;">true</span>


Whether or not to wrap around focus chains
### `focus_neighbor_bottom`


[FocusGroup](../FocusGroup) focus_neighbor_bottom


!!! note
    There is currently no description for this property. Please help us by contributing one!

### `focus_neighbor_top`


[FocusGroup](../FocusGroup) focus_neighbor_top


!!! note
    There is currently no description for this property. Please help us by contributing one!

### `focus_neighbor_left`


[FocusGroup](../FocusGroup) focus_neighbor_left


!!! note
    There is currently no description for this property. Please help us by contributing one!

### `focus_neighbor_right`


[FocusGroup](../FocusGroup) focus_neighbor_right


!!! note
    There is currently no description for this property. Please help us by contributing one!

### `neighbor_control`


[Control](https://docs.godotengine.org/en/stable/classes/class_control.html) neighbor_control


!!! note
    There is currently no description for this property. Please help us by contributing one!

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
### `grab_focus()`


void **grab_focus**()


Grab focus on the currently focused node in the group and push this group to the top of the focus stack
### `is_focused()`


[bool](https://docs.godotengine.org/en/stable/classes/class_bool.html) **is_focused**()


Returns true if this focus group is the currently focus in the focus stack.
### `is_in_focus_stack()`


[bool](https://docs.godotengine.org/en/stable/classes/class_bool.html) **is_in_focus_stack**()


Returns true if this focus group is anywhere in the focus stack.
### `find_focusable()`


[Node](https://docs.godotengine.org/en/stable/classes/class_node.html) **find_focusable**(nodes: [Node[]](https://docs.godotengine.org/en/stable/classes/class_node.html), root: [Node](https://docs.godotengine.org/en/stable/classes/class_node.html) = null)


!!! note
    There is currently no description for this method. Please help us by contributing one!

