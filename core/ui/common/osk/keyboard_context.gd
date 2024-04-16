extends Resource
class_name KeyboardContext

## Route on-screen keyboard input
##
## A KeyboardContext defines how the on-screen keyboard should route its key
## input. If the context type is set to TYPE.GODOT, the keyboard will update
## the given control node's text from the keyboard. If it is TYPE.X11, it will
## send virtual key pressess to the game via Xlib/evdev.

## Type of Keyboard context
# TODO: Break these up into their own classes
enum TYPE {
	DBUS, ## ROutes keyboard input to a dbus input manager
	GODOT,  ## Routes keyboard input to a Godot control node (i.e. textbox)
	X11,  ## Routes keyboard input to the currently running game
}

## Emitted when the on-screen keyboard submits this context
signal submitted
## Emitted when the keyboard is opened with this context
signal entered
## Emitted when the keyboard is closed with this context
signal exited
## Emitted when the user has selected a keymap input key
signal keymap_input_selected(key_event: NativeEvent)

## The type of keyboard context
var type: TYPE
## For non-TYPE.X11 contexts, which node to send text input to
var target: Control
## Whether or not the keyboard should close after submition
var close_on_submit: bool = true


func _init(t: TYPE = TYPE.GODOT, tgt: Control = null, close_after_submit: bool = true) -> void:
	type = t
	target = tgt
	close_on_submit = close_after_submit
