@icon("res://assets/editor-icons/mind-map.svg")
@tool
extends Resource
class_name GamepadMapping

## Defines a mapping of a single controller interface to another type of input
##
## GamepadMappings are part of a [GamepadProfile], which defines the input
## mapping of gamepad input to another type of input.

## Defines possible output event behaviors from this gamepad mapping
enum OUTPUT_BEHAVIOR {
	SEQUENCE, ## Execute each output event one after another
	AXIS, ## Execute the first output event if the source event's value is 1. Execute the second output event if the source event's value is -1.
}

## Optional name of the gamepad mapping
@export var name: String

## A mappable event to translate from
@export var source_event: MappableEvent

## Mappable events to translate to
@export var output_events: Array[MappableEvent]

## Determines how output events should be executed during input translation
@export var output_behavior := OUTPUT_BEHAVIOR.SEQUENCE
