extends Node
class_name Plugin
@icon("res://assets/icons/box.svg")

# The base resource directory for a given plugin. Useful for loading plugin-specific
# resources.
var plugin_base: String
var cache: String
var logger := Log.get_logger("Plugin")
var OGUIButton := preload("res://core/ui/components/button.tscn")

@onready var state_manager: StateManager = get_node("/root/Main/StateManager")
@onready var input_manager: InputManager = get_node("/root/Main/InputManager")
@onready var launch_manager: LaunchManager = get_node("/root/Main/LaunchManager")
@onready var library_manager: LibraryManager = get_node("/root/Main/LibraryManager")
@onready var store_manager: StoreManager = get_node("/root/Main/StoreManager")
@onready var notification_manager: NotificationManager = get_node("/root/Main/NotificationManager")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	add_to_group("plugin")
	
	
# To be overridden by plugin implementation. Should unload changes done by
# the plugin.
func unload() -> void:
	pass


# To be overridden by plugin implementation. Should return a scene with plugin
# settings.
func get_settings_menu() -> Control:
	return null


# Registers the given library implementation
func add_library(library: Library) -> void:
	library_manager.add_child(library)


# Registers the given store implementation
func add_store(store: Store) -> void:
	store_manager.add_child(store)
	
	
func add_to_qam(qam_item: Control, icon: Texture2D) -> void:
	var qam_list := get_tree().get_nodes_in_group("qam")
	var qam: Control
	for item in qam_list:
		if item.name != "QuickAccessMenu":
			continue
			
		qam = item
		break
	if not qam:
		logger.error("Unable to find the Quick Access Menu. Plugin {} can not be loaded.".format(qam_item.name))
		return
	
	qam_item.visible = false
	qam.viewport.add_child(qam_item)
	var new_but := OGUIButton.instantiate()
	new_but.icon = icon
	new_but.custom_minimum_size = Vector2(50, 50)
	new_but.expand_icon = true
	new_but.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	qam.icon_bar.add_child(new_but)
