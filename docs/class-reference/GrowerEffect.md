# GrowerEffect

**Inherits:** [Effect](../Effect)

Grow the given target's custom minimum size to the size of the given content
## Description

Optionally an inside panel and separator can be specified to make them visible when the parent fully grows.
## Properties

| Type | Name | Default |
| ---- | ---- | ------- |
| [Control](https://docs.godotengine.org/en/stable/classes/class_control.html) | [target](./#target) | get_parent() |
| [Control](https://docs.godotengine.org/en/stable/classes/class_control.html) | [content_container](./#content_container) |  |
| [Control](https://docs.godotengine.org/en/stable/classes/class_control.html) | [inside_panel](./#inside_panel) |  |
| [Control](https://docs.godotengine.org/en/stable/classes/class_control.html) | [separator](./#separator) |  |
| [float](https://docs.godotengine.org/en/stable/classes/class_float.html) | [grow_speed](./#grow_speed) | 0.2 |
| [Tween](https://docs.godotengine.org/en/stable/classes/class_tween.html) | [tween](./#tween) |  |
| [String](https://docs.godotengine.org/en/stable/classes/class_string.html) | [shrink_signal](./#shrink_signal) |  |

## Methods

| Returns | Signature |
| ------- | --------- |
| void | [grow](./#grow)() |
| void | [shrink](./#shrink)() |


------------------

## Property Descriptions

### `target`


[Control](https://docs.godotengine.org/en/stable/classes/class_control.html) target = <span style="color: red;">get_parent()</span>


The target node to grow. This will animate the minimum custom size of this node to be the size of the content container.
### `content_container`


[Control](https://docs.godotengine.org/en/stable/classes/class_control.html) content_container


Content that the target node will grow to match the size.
### `inside_panel`


[Control](https://docs.godotengine.org/en/stable/classes/class_control.html) inside_panel


Optional inside panel to toggle visibility after growing.
### `separator`


[Control](https://docs.godotengine.org/en/stable/classes/class_control.html) separator


Optional separator to toggle visibility after growing.
### `grow_speed`


[float](https://docs.godotengine.org/en/stable/classes/class_float.html) grow_speed = <span style="color: red;">0.2</span>


The speed of the grow animation in seconds.
### `tween`


[Tween](https://docs.godotengine.org/en/stable/classes/class_tween.html) tween


!!! note
    There is currently no description for this property. Please help us by contributing one!

### `shrink_signal`


[String](https://docs.godotengine.org/en/stable/classes/class_string.html) shrink_signal


!!! note
    There is currently no description for this property. Please help us by contributing one!




------------------

## Method Descriptions

### `grow()`


void **grow**()


!!! note
    There is currently no description for this method. Please help us by contributing one!

### `shrink()`


void **shrink**()


!!! note
    There is currently no description for this method. Please help us by contributing one!

