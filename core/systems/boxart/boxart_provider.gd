@icon("res://assets/icons/image.svg")
extends Node
class_name BoxArtProvider

signal boxart_loaded(texture: Texture2D)

# The different layouts of boxart that are supported
enum LAYOUT {
	GRID_PORTRAIT,
	GRID_LANDSCAPE,
	BANNER,
	LOGO,
}

var BoxArtManager := load("res://core/global/boxart_manager.tres") as BoxArtManager

# Unique identifier for the boxart provider
@export var provider_id: String
# Icon for boxart provider
@export var provider_icon: Texture2D
@export var logger_name := provider_id
@export var log_level: Log.LEVEL = Log.LEVEL.INFO

@onready var logger := Log.get_logger(logger_name, log_level)


func _init() -> void:
	ready.connect(add_to_group.bind("boxart_provider"))
	ready.connect(BoxArtManager.register_provider.bind(self))


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass


# To be implemented by a provider
func get_boxart(item: LibraryItem, kind: LAYOUT) -> Texture2D:
	return null


func _exit_tree() -> void:
	BoxArtManager.unregister_provider(self)
