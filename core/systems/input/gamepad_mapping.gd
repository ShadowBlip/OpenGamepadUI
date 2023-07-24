@icon("res://assets/editor-icons/mind-map.svg")
@tool
extends Resource
class_name GamepadMapping

## Defines a mapping of a single controller interface to another type of input
##
## GamepadMappings are part of a [GamepadProfile], which defines the input
## mapping of gamepad input to another type of input.

## Optional name of the gamepad mapping
@export var name: String

## A mappable event to translate from
@export var source_event: MappableEvent

## Mappable events to translate to
@export var output_events: Array[MappableEvent]
