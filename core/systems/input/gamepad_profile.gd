@icon("res://assets/ui/icons/gamepad-bold.svg")
extends Resource
class_name GamepadProfile

## A gamepad profile is a managed gamepad profile that can remap inputs.
##
## A gamepad profile describes a controller mapping. With it, you can map
## controller inputs to keyboard and mouse actions, or other gamepad actions.

## Name of the gamepad profile
@export var name: String
@export var mapping: Array[GamepadMapping]
