@icon("res://assets/editor-icons/library.svg")
extends Node
class_name Library

## Base class for Library implementations
## 
## The Library class provides an interface for creating new library 
## implementations. To create a new library, simply extend this class and 
## implement its methods. When a Library node is added to the scene tree, it 
## will automatically register itself with the global [LibraryManager].
##
## @tutorial:            https://github.com/ShadowBlip/OpenGamepadUI/blob/main/docs/plugins/TUTORIALS.md#writing-a-library-plugin

## Should be emitted when a library item is installed
signal install_completed(item: LibraryLaunchItem, success: bool)
## Should be emitted when a library item is updated
signal update_completed(item: LibraryLaunchItem, success: bool)
## Should be emitted when a library item is uninstalled
signal uninstall_completed(item: LibraryLaunchItem, success: bool)
## Should be emitted when a library item install is progressing
signal install_progressed(item: LibraryLaunchItem, percent_completed: float)

var LibraryManager := load("res://core/global/library_manager.tres") as LibraryManager

## Unique identifier for the library
@export var library_id: String
## Optional store that this library is linked to
@export var store_id: String
## Icon for library provider
@export var library_icon: Texture2D
## Whether or not the library provider supports uninstalls
@export var supports_uninstall := true
## Logger name used for debug messages
@export var logger_name := library_id
## Log level of the logger.
@export var log_level: Log.LEVEL = Log.LEVEL.INFO

@onready var _cache_dir := "/".join(["library", library_id])
@onready var logger := Log.get_logger(logger_name, log_level)


func _init() -> void:
	add_to_group("library")
	ready.connect(LibraryManager.register_library.bind(self))


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass


## Returns an array of available library launch items that this library provides.
## This method should be overriden in the child class.
## Example:
##     [codeblock]
##     func get_library_launch_items() -> Array[LibraryLaunchItem]:
##             var item: LibraryLaunchItem = LibraryLaunchItem.new()
##             item.name = "vkCube"
##             item.command = "vkcube"
##             item.args = []
##             item.tags = ["vkcube"]
##             item.installed = true
##     
##             return [item]
##     [/codeblock]
func get_library_launch_items() -> Array[LibraryLaunchItem]:
	return []


## Installs the given library item. This method should be overriden in the 
## child class, if it supports it.
func install(item: LibraryLaunchItem) -> void:
	pass


## Updates the given library item. This method should be overriden in the 
## child class, if it supports it.
func update(item: LibraryLaunchItem) -> void:
	pass


## Uninstalls the given library item. This method should be overriden in the 
## child class if it supports it.
func uninstall(item: LibraryLaunchItem) -> void:
	pass


## Should return true if the given library item has an update available
func has_update(item: LibraryLaunchItem) -> bool:
	return false


func _exit_tree() -> void:
	LibraryManager.unregister_library(self)
