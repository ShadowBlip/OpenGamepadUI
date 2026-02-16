@abstract
extends Node
class_name MetadataProvider

## Base class for Metadata implementations
## 
## The MetadataProvider class provides an interface for providing sources of 
## game metadata. To create a new MetadataProvider, simply extend this class and 
## implement its methods. When a MetadataProvider node enters the scene tree, it 
## will automatically register itself with the global [MetadataManager].
##
## When a menu requires showing metadata for a particular game, it will request 
## that metadata from the [MetadataManager]. The manager, in turn, will request 
## metadata from all registered metadata providers until it finds one.

var metadata_manager := preload("res://core/systems/metadata/metadata_manager.tres") as MetadataManager

## Unique identifier for the boxart provider
@export var provider_id: String
## Icon for boxart provider
@export var provider_icon: Texture2D


func _init() -> void:
	ready.connect(add_to_group.bind("metadata_provider"))
	ready.connect(metadata_manager.register_provider.bind(self))


## Returns a text summary of the given library item
@warning_ignore("unused_parameter")
func get_summary(item: LibraryItem) -> String:
	return ""


func _exit_tree() -> void:
	metadata_manager.unregister_provider(self)
