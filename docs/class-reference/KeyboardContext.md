# KeyboardContext

**Inherits:** [Resource](https://docs.godotengine.org/en/stable/classes/class_resource.html)

Route on-screen keyboard input
## Description

A KeyboardContext defines how the on-screen keyboard should route its key input. If the context type is set to TYPE.GODOT, the keyboard will update the given control node's text from the keyboard. If it is TYPE.X11, it will send virtual key pressess to the game via Xlib/evdev.
## Properties

| Type | Name | Default |
| ---- | ---- | ------- |
| [int](https://docs.godotengine.org/en/stable/classes/class_int.html) | [type](./#type) |  |
| [Control](https://docs.godotengine.org/en/stable/classes/class_control.html) | [target](./#target) |  |
| [bool](https://docs.godotengine.org/en/stable/classes/class_bool.html) | [close_on_submit](./#close_on_submit) | true |



------------------

## Property Descriptions

### `type`


[int](https://docs.godotengine.org/en/stable/classes/class_int.html) type


The type of keyboard context
### `target`


[Control](https://docs.godotengine.org/en/stable/classes/class_control.html) target


For non-TYPE.X11 contexts, which node to send text input to
### `close_on_submit`


[bool](https://docs.godotengine.org/en/stable/classes/class_bool.html) close_on_submit = <span style="color: red;">true</span>


Whether or not the keyboard should close after submition

