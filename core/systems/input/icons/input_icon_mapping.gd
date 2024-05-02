extends Resource
class_name InputIconMapping

## Icon mapping for input devices

## Name of the icon mapping
@export var name: String

## Input device names to match
@export var device_names: PackedStringArray

@export_category("Button Mappings")
@export var north: Texture
@export var south: Texture
@export var east: Texture
@export var west: Texture
@export var guide: Texture
