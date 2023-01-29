@icon("res://assets/icons/box.svg")
extends Node
class_name Plugin

# The base resource directory for a given plugin. Useful for loading plugin-specific
# resources.
var plugin_base: String
var cache: String
var logger := Log.get_logger("Plugin")

const OGUIButton := preload("res://core/ui/components/button.tscn")
const ButtonStateChanger := preload("res://core/systems/state/state_changer.tscn")
const qam_state_machine := preload("res://assets/state/state_machines/qam_state_machine.tres")

func _init() -> void:
	ready.connect(add_to_group.bind("plugin"))


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass

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
	LibraryManager.add_child(library)


# Registers the given store implementation
func add_store(store: Store) -> void:
	StoreManager.add_child(store)
	

# Adds the given menu to the Quick Access Menu
func add_to_qam(qam_item: Control, icon: Texture2D, focus_node: Control = null) -> void:
	var qam := get_tree().get_first_node_in_group("qam")
	if not qam:
		logger.error("Unable to find the Quick Access Menu. Plugin {} can not be loaded.".format(qam_item.name))
		return
	
	qam.add_child_menu(qam_item, icon, focus_node)
