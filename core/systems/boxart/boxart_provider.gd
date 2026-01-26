@icon("res://assets/editor-icons/twotone-image-search.svg")
@abstract
extends Node
class_name BoxArtProvider

## Base class for BoxArt implementations
## 
## The BoxArtProvider class provides an interface for providing sources of 
## game artwork. To create a new BoxArtProvider, simply extend this class and 
## implement its methods. When a BoxArtProvider node enters the scene tree, it 
## will automatically register itself with the global [BoxArtManager].
##
## When a menu requires showing artwork for a particular game, it will request 
## that artwork from the [BoxArtManager]. The manager, in turn, will request 
## artwork from all registered boxart providers until it finds one.

## Should be emitted when boxart has been loaded
signal boxart_loaded(texture: Texture2D)

## Different layouts of boxart that are supported
enum LAYOUT {
	GRID_PORTRAIT, ## Game art in portrait aspect ratio
	GRID_LANDSCAPE, ## Game art in landscape aspect ratio
	BANNER, ## Game art banner displayed in the game launcher menu
	LOGO, ## Game art logo
	GRID_SQUARE, ## Game art square tile
	ICON, ## Square icon
}

var BoxArtManager := load("res://core/global/boxart_manager.tres") as BoxArtManager

## Unique identifier for the boxart provider
@export var provider_id: String
## Icon for boxart provider
@export var provider_icon: Texture2D
## Logger name used for debug messages
@export var logger_name := provider_id
## Log level of the logger.
@export var log_level: Log.LEVEL = Log.LEVEL.INFO

@onready var logger := Log.get_logger(logger_name, log_level)


func _init() -> void:
	ready.connect(add_to_group.bind("boxart_provider"))
	ready.connect(BoxArtManager.register_provider.bind(self))


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass


## Returns the game artwork as a texture for the given game in the given 
## layout. This method should be overriden in the extending class.
func get_boxart(item: LibraryItem, kind: LAYOUT) -> Texture2D:
	return null


func _exit_tree() -> void:
	BoxArtManager.unregister_provider(self)
