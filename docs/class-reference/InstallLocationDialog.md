# InstallLocationDialog

**Inherits:** [Control](https://docs.godotengine.org/en/stable/classes/class_control.html)


## Properties

| Type | Name | Default |
| ---- | ---- | ------- |
| [String](https://docs.godotengine.org/en/stable/classes/class_string.html) | [text](./#text) |  |
| [String](https://docs.godotengine.org/en/stable/classes/class_string.html) | [cancel_text](./#cancel_text) | "Cancel" |
| [bool](https://docs.godotengine.org/en/stable/classes/class_bool.html) | [cancel_visible](./#cancel_visible) | true |
| [bool](https://docs.godotengine.org/en/stable/classes/class_bool.html) | [close_on_selected](./#close_on_selected) | true |
| [Vector2i](https://docs.godotengine.org/en/stable/classes/class_vector2i.html) | [custom_maximum_size](./#custom_maximum_size) |  |
| [ScrollContainer](https://docs.godotengine.org/en/stable/classes/class_scrollcontainer.html) | [scroll_container](./#scroll_container) | <unknown> |
| [Container](https://docs.godotengine.org/en/stable/classes/class_container.html) | [content_container](./#content_container) | <unknown> |
| [Label](https://docs.godotengine.org/en/stable/classes/class_label.html) | [label](./#label) | <unknown> |
| [CardButton](../CardButton) | [cancel_button](./#cancel_button) | <unknown> |
| [Effect](../Effect) | [fade_effect](./#fade_effect) | <unknown> |

## Methods

| Returns | Signature |
| ------- | --------- |
| void | [open](./#open)(return_node: [Control](https://docs.godotengine.org/en/stable/classes/class_control.html), locations: [Library.InstallLocation[]](../Library.InstallLocation) = [], message: [String](https://docs.godotengine.org/en/stable/classes/class_string.html) = "", cancel_txt: [String](https://docs.godotengine.org/en/stable/classes/class_string.html) = "") |


------------------

## Property Descriptions

### `text`


[String](https://docs.godotengine.org/en/stable/classes/class_string.html) text


Text to display in the dialog box
### `cancel_text`


[String](https://docs.godotengine.org/en/stable/classes/class_string.html) cancel_text = <span style="color: red;">"Cancel"</span>


Cancel button text
### `cancel_visible`


[bool](https://docs.godotengine.org/en/stable/classes/class_bool.html) cancel_visible = <span style="color: red;">true</span>


Whether or not the cancel button should be shown
### `close_on_selected`


[bool](https://docs.godotengine.org/en/stable/classes/class_bool.html) close_on_selected = <span style="color: red;">true</span>


Close the dialog when the user selects an option
### `custom_maximum_size`


[Vector2i](https://docs.godotengine.org/en/stable/classes/class_vector2i.html) custom_maximum_size


Maximum size that the scroll container can grow to
### `scroll_container`


[ScrollContainer](https://docs.godotengine.org/en/stable/classes/class_scrollcontainer.html) scroll_container


!!! note
    There is currently no description for this property. Please help us by contributing one!

### `content_container`


[Container](https://docs.godotengine.org/en/stable/classes/class_container.html) content_container


!!! note
    There is currently no description for this property. Please help us by contributing one!

### `label`


[Label](https://docs.godotengine.org/en/stable/classes/class_label.html) label


!!! note
    There is currently no description for this property. Please help us by contributing one!

### `cancel_button`


[CardButton](../CardButton) cancel_button


!!! note
    There is currently no description for this property. Please help us by contributing one!

### `fade_effect`


[Effect](../Effect) fade_effect


!!! note
    There is currently no description for this property. Please help us by contributing one!




------------------

## Method Descriptions

### `open()`


void **open**(return_node: [Control](https://docs.godotengine.org/en/stable/classes/class_control.html), locations: [Library.InstallLocation[]](../Library.InstallLocation) = [], message: [String](https://docs.godotengine.org/en/stable/classes/class_string.html) = "", cancel_txt: [String](https://docs.godotengine.org/en/stable/classes/class_string.html) = "")


Opens the dialog box with the given settings
