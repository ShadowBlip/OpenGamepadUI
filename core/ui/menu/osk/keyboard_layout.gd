extends Resource
class_name KeyboardLayout

## Defines the rows and columns of the on-screen keyboard
##
## A keyboard layout defines the look and key configuration of the on-screen
## keyboard

## Name of the keyboard layout
@export var name: String = "Default"
## Keyboard rows that belong to this layout
@export var rows: Array[KeyboardRow]
