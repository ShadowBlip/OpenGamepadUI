@icon("res://assets/icons/box.svg")
extends Node
class_name Plugin

## Base class for Plugins
##
## The Plugin class provides an interface and light API for creating plugins.
## New plugins should inherit from this class and will automatically get
## added to the scene tree as a child of the [PluginLoader] when it is loaded.

## The base resource directory for a given plugin. This will be set by the
## [PluginLoader] when it is loaded. Useful for loading plugin-specific
## resources.
var plugin_base: String
var cache: String
var logger := Log.get_logger("Plugin")

const OGUIButton := preload("res://core/ui/components/button.tscn")
const ButtonStateChanger := preload("res://core/systems/state/state_changer.tscn")
const quick_bar_state_machine := preload("res://assets/state/state_machines/quick_bar_state_machine.tres")


func _init() -> void:
	ready.connect(add_to_group.bind("plugin"))


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass


## To be overridden by plugin implementation. Should unload changes done by
## the plugin.
func unload() -> void:
	pass


## To be overridden by plugin implementation. Should return a scene with plugin
## settings. This scene will be included in the plugin settings menu to let
## users modify plugin-specific settings.
func get_settings_menu() -> Control:
	return null


## Adds the given library implementation as a child of the plugin. A [Library]
## node will automatically register itself with the [LibraryManager] when it
## enters the scene tree.
func add_library(library: Library) -> void:
	add_child(library)


## Adds the given store implementation as a child of the plugin. A [Store]
## node will automatically register itself with the [StoreManager] when it
## enters the scene tree.
func add_store(store: Store) -> void:
	add_child(store)


## Adds the given boxart provider as a child of the plugin. A [BoxArtProvider]
## node will automatically register itself with the [BoxArtManager] when it
## enters the scene tree.
func add_boxart(boxart: BoxArtProvider) -> void:
	add_child(boxart)


## Deprecated method for adding a plugin to the quick bar.
func add_to_qam(qb_item: Control, icon: Texture2D, focus_node: Control = null) -> void:
	logger.warn("Deprecation Warning: The function \'add_to_qam\' has been deprecated and will be removed in a future update. \
	Control node \"" + qb_item.name + "\" using deprecated function.")
	add_to_quick_bar(qb_item, icon, focus_node)


## Adds the given menu scene to the Quick Bar Menu
func add_to_quick_bar(qb_item: Control, icon: Texture2D, focus_node: Control = null) -> void:
	var qb := get_tree().get_first_node_in_group("quick-bar")
	if not qb:
		(
			logger
			. error(
				(
					"Unable to find the Quick Bar Menu. Plugin {} can not be loaded."
					. format(qb_item.name)
				)
			)
		)
		return

	qb.add_child_menu(qb_item, icon, focus_node)


## Adds the given overlay
func add_overlay(overlay: OverlayProvider) -> void:
	# Find the overlay container node
	var container := get_tree().get_first_node_in_group("overlay") as OverlayContainer
	if not container:
		logger.warn("Unable to find overlay container to add overlay")
		return

	# If the overlay is already in the scene tree, reparent it to the overlay
	# container
	if overlay.is_inside_tree():
		overlay.get_parent().remove_child(overlay)

	# Add the overlay to the overlay container
	container.add_overlay(overlay)
