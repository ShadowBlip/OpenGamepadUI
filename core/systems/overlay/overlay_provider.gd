@icon("res://assets/editor-icons/overlay_control.svg")
extends Control
class_name OverlayProvider

## Base class to use when writing a new overlay.
##
## An [OverlayProvider] is a [Control] node that is meant to work as an overlay.
## To write a new overlay, create a new class that extends from this one.

## Unique identifier for the overlay provider
@export var provider_id: String
## Icon associated with the overlay provider
@export var icon: Texture2D
## Whether or not the overlay's layout should be managed by an [OverlayContainer]
@export var managed := true

var logger: Log.Logger


func _init() -> void:
	ready.connect(add_to_group.bind("overlay_provider"))
	anchors_preset = PRESET_FULL_RECT


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass


func _exit_tree() -> void:
	pass
