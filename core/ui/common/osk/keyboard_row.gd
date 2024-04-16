extends Resource
class_name KeyboardRow

## Defines a row of keys in a [KeyboardLayout]
##
## Simple container to store a row of key configs in a layout

## Keys to appear in this row of the on-screen keyboard
@export var entries: Array[KeyboardKeyConfig]
