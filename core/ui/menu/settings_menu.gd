extends Control

const plugin_store_item_scene: PackedScene = preload("res://core/ui/components/plugin_store_item.tscn")

signal plugin_store_loaded(plugin_items: Dictionary)

@onready var state_manager: StateManager = get_node("/root/Main/StateManager")
@onready var plugin_loader: PluginLoader = get_node("/root/Main/PluginLoader")
@onready var general_button := $MainContainer/MenuMarginContainer/VBoxContainer/GeneralButton
@onready var plugin_store_grid := $MainContainer/ContentMarginContainer/ScrollContainer/PluginStore
@onready var http_image := $HTTPImageFetcher

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	state_manager.state_changed.connect(_on_state_changed)
	plugin_store_loaded.connect(_on_plugin_store_loaded)
	load_plugin_store_items()
	visible = false
	
	
func _on_state_changed(from: StateManager.State, to: StateManager.State, data: Dictionary):
	var is_visible = state_manager.has_state(StateManager.State.SETTINGS)
	if not is_visible:
		visible = false
		return
	if to == StateManager.State.IN_GAME:
		state_manager.remove_state(StateManager.State.SETTINGS)

	general_button.grab_focus.call_deferred()
	visible = true


# Loads available plugins from the plugin store and emits the 'plugin_store_loaded'
# signal with the loaded items
func load_plugin_store_items():
	# Fetch available plugins from the plugin store
	var plugin_items = await plugin_loader.get_plugin_store_items()
	plugin_store_loaded.emit(plugin_items)


# Gets executed on plugin store items loaded
func _on_plugin_store_loaded(plugin_items: Dictionary):
	# Clear the current grid of items
	for child in plugin_store_grid.get_children():
		plugin_store_grid.remove_child(child)
		child.queue_free()
	_populate_plugin_store_items(plugin_store_grid, plugin_items)


# Populates the plugin store grid with the given plugin items
func _populate_plugin_store_items(grid: Container, plugin_items: Dictionary):
	for plugin_id in plugin_items.keys():
		var plugin: Dictionary = plugin_items[plugin_id]

		# Build the store item
		var store_item := plugin_store_item_scene.instantiate()
		store_item.visible = false
		grid.add_child(store_item)
		
		store_item.plugin_name_label.text = plugin["plugin.name"]
		store_item.author_label.text = "Author: " + plugin["author.name"]
		store_item.summary_label.text = plugin["plugin.summary"]
		
		# Load the plugin image
		if len(plugin["store.images"]) > 0:
			var image = await http_image.fetch(plugin["store.images"][0])
			if image != null:
				store_item.plugin_texture.texture = image
		
		# Add the store item
		store_item.visible = true
		
