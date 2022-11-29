# LibraryLaunchItem is a library-specific structure that describes how to launch
# a game.
extends Resource
class_name LibraryLaunchItem
@icon("res://assets/icons/box.svg")

@export var _id: String
@export var _provider_id: String
@export var provider_app_id: String
@export var name: String
@export var command: String
@export var args: PackedStringArray
@export var tags: PackedStringArray
@export var categories: PackedStringArray
@export var installed: bool
