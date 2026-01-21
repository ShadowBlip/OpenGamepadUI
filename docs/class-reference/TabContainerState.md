# TabContainerState

**Inherits:** [Resource](https://docs.godotengine.org/en/stable/classes/class_resource.html)

Shared resource for the state of a tab container
## Description

Resource used to watch and manipulate the state of a tab container regardless of where UI components are in the scene tree.
## Properties

| Type | Name | Default |
| ---- | ---- | ------- |
| [int](https://docs.godotengine.org/en/stable/classes/class_int.html) | [current_tab](./#current_tab) | 0 |
| [PackedStringArray](https://docs.godotengine.org/en/stable/classes/class_packedstringarray.html) | [tabs_text](./#tabs_text) |  |

## Methods

| Returns | Signature |
| ------- | --------- |
| void | [add_tab](./#add_tab)(tab_text: [String](https://docs.godotengine.org/en/stable/classes/class_string.html), node: [ScrollContainer](https://docs.godotengine.org/en/stable/classes/class_scrollcontainer.html)) |
| void | [remove_tab](./#remove_tab)(tab_text: [String](https://docs.godotengine.org/en/stable/classes/class_string.html)) |


------------------

## Property Descriptions

### `current_tab`


[int](https://docs.godotengine.org/en/stable/classes/class_int.html) current_tab = <span style="color: red;">0</span>


!!! note
    There is currently no description for this property. Please help us by contributing one!

### `tabs_text`


[PackedStringArray](https://docs.godotengine.org/en/stable/classes/class_packedstringarray.html) tabs_text


!!! note
    There is currently no description for this property. Please help us by contributing one!




------------------

## Method Descriptions

### `add_tab()`


void **add_tab**(tab_text: [String](https://docs.godotengine.org/en/stable/classes/class_string.html), node: [ScrollContainer](https://docs.godotengine.org/en/stable/classes/class_scrollcontainer.html))


Add the given tab
### `remove_tab()`


void **remove_tab**(tab_text: [String](https://docs.godotengine.org/en/stable/classes/class_string.html))


Remove the given tab
