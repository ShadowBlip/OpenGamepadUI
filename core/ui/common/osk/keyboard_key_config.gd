extends Resource
class_name KeyboardKeyConfig

## Defines a single key configuration for the on-screen keyboard
##
## A key configuration is one key that is part of a [KeyboardLayout] which
## defines the type of key it is.

## Defines the key type
enum TYPE {
	NORMAL,  ## Normal keyboard key input
	SPECIAL,  ## Special key input that does not exist on physical keyboards
}

## Actions for TYPE.SPECIAL keys
enum ACTION {
	NONE,
	CLOSE_KEYBOARD,
}

## Whether this is a normal key or special key
@export var type: TYPE = TYPE.NORMAL
## The keyboard event associated with this key
@export var input: InputEventKey
## The keyboard event associated with this key when SHIFT is being held
@export var mode_shift_input: InputEventKey
## An icon to display for this key on the on-screen keyboard
@export var icon: Texture2D
## How much space relative to other keys in the row to take up
@export var stretch_ratio: float = 1
## An action for TYPE.SPECIAL keys to take
@export var action: ACTION = ACTION.NONE


# Returns the text representation of this key
func get_text(mode_shifted: bool = false) -> String:
	var event := input
	if mode_shifted and mode_shift_input:
		event = mode_shift_input

	var display: String
	display = String.chr(event.unicode)
	if event.unicode == 0 or display == "":
		display = event.as_text()

	return display
