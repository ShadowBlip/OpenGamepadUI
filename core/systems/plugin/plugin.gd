extends Node
class_name Plugin
@icon("res://assets/icons/box.svg")

# The base resource directory for a given plugin. Useful for loading plugin-specific
# resources.
var plugin_base: String
var cache: String

@onready var state_manager: StateManager = get_node("/root/Main/StateManager")
@onready var input_manager: InputManager = get_node("/root/Main/InputManager")
@onready var launch_manager: LaunchManager = get_node("/root/Main/LaunchManager")
@onready var library_manager: LibraryManager = get_node("/root/Main/LibraryManager")
@onready var store_manager: StoreManager = get_node("/root/Main/StoreManager")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	add_to_group("plugin")


# Registers the given library implementation
func add_library(library: Library) -> void:
	library_manager.add_child(library)


# Registers the given store implementation
func add_store(store: Store) -> void:
	store_manager.add_child(store)
