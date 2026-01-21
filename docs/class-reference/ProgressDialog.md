# ProgressDialog

**Inherits:** [Control](https://docs.godotengine.org/en/stable/classes/class_control.html)


## Properties

| Type | Name | Default |
| ---- | ---- | ------- |
| [String](https://docs.godotengine.org/en/stable/classes/class_string.html) | [text](./#text) |  |
| [float](https://docs.godotengine.org/en/stable/classes/class_float.html) | [value](./#value) | 0.0 |
| [String](https://docs.godotengine.org/en/stable/classes/class_string.html) | [cancel_text](./#cancel_text) | "Cancel" |
| [bool](https://docs.godotengine.org/en/stable/classes/class_bool.html) | [cancel_visible](./#cancel_visible) | true |
| [bool](https://docs.godotengine.org/en/stable/classes/class_bool.html) | [close_on_selected](./#close_on_selected) | true |
| [Label](https://docs.godotengine.org/en/stable/classes/class_label.html) | [label](./#label) | <unknown> |
| [ProgressBar](https://docs.godotengine.org/en/stable/classes/class_progressbar.html) | [progress_bar](./#progress_bar) | <unknown> |
| [Button](https://docs.godotengine.org/en/stable/classes/class_button.html) | [cancel_button](./#cancel_button) | <unknown> |
| [Effect](../Effect) | [fade_effect](./#fade_effect) | <unknown> |

## Methods

| Returns | Signature |
| ------- | --------- |
| void | [open](./#open)(message: [String](https://docs.godotengine.org/en/stable/classes/class_string.html) = "", cancel_txt: [String](https://docs.godotengine.org/en/stable/classes/class_string.html) = "") |
| void | [close](./#close)() |


------------------

## Property Descriptions

### `text`


[String](https://docs.godotengine.org/en/stable/classes/class_string.html) text


Text to display in the dialog box
### `value`


[float](https://docs.godotengine.org/en/stable/classes/class_float.html) value = <span style="color: red;">0.0</span>


Confirm button text
### `cancel_text`


[String](https://docs.godotengine.org/en/stable/classes/class_string.html) cancel_text = <span style="color: red;">"Cancel"</span>


Cancel button text
### `cancel_visible`


[bool](https://docs.godotengine.org/en/stable/classes/class_bool.html) cancel_visible = <span style="color: red;">true</span>


!!! note
    There is currently no description for this property. Please help us by contributing one!

### `close_on_selected`


[bool](https://docs.godotengine.org/en/stable/classes/class_bool.html) close_on_selected = <span style="color: red;">true</span>


Close the dialog when the user selects an option
### `label`


[Label](https://docs.godotengine.org/en/stable/classes/class_label.html) label


!!! note
    There is currently no description for this property. Please help us by contributing one!

### `progress_bar`


[ProgressBar](https://docs.godotengine.org/en/stable/classes/class_progressbar.html) progress_bar


!!! note
    There is currently no description for this property. Please help us by contributing one!

### `cancel_button`


[Button](https://docs.godotengine.org/en/stable/classes/class_button.html) cancel_button


!!! note
    There is currently no description for this property. Please help us by contributing one!

### `fade_effect`


[Effect](../Effect) fade_effect


!!! note
    There is currently no description for this property. Please help us by contributing one!




------------------

## Method Descriptions

### `open()`


void **open**(message: [String](https://docs.godotengine.org/en/stable/classes/class_string.html) = "", cancel_txt: [String](https://docs.godotengine.org/en/stable/classes/class_string.html) = "")


Opens the dialog box with the given settings
### `close()`


void **close**()


Closes the progress dialog
