extends HFlowContainer

@export var state_manager_path: NodePath

signal plugin_store_loaded(plugin_items: Dictionary)

const plugin_store_item_scene: PackedScene = preload("res://core/ui/components/plugin_store_item.tscn")
var PluginLoader := load("res://core/global/plugin_loader.tres") as PluginLoader
var plugin_store_state := preload("res://assets/state/states/settings_plugin_store.tres") as State

@onready var http_image := $HTTPImageFetcher
@onready var settings_menu := $"../../../.." #verbose?

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	plugin_store_loaded.connect(_on_plugin_store_loaded)
	plugin_store_state.state_entered.connect(_on_state_entered)
	load_plugin_store_items()


func _on_state_entered(_from: State) -> void:
	load_plugin_store_items()


# Loads available plugins from the plugin store and emits the 'plugin_store_loaded'
# signal with the loaded items
func load_plugin_store_items():
	# Fetch available plugins from the plugin store
	var plugin_items = await PluginLoader.get_plugin_store_items()
	plugin_store_loaded.emit(plugin_items)


# Gets executed on plugin store items loaded
func _on_plugin_store_loaded(plugin_items: Dictionary):
	# Clear the current grid of items
	var keep_nodes := [$HTTPImageFetcher, $VisibilityManager]
	for child in self.get_children():
		if child in keep_nodes:
			continue
		self.remove_child(child)
		child.queue_free()
	_populate_plugin_store_items(self, plugin_items)


# Populates the plugin store grid with the given plugin items
func _populate_plugin_store_items(grid: Container, plugin_items: Dictionary):
	for plugin_id in plugin_items.keys():
		var plugin: Dictionary = plugin_items[plugin_id]

		# Build the store item
		var store_item := plugin_store_item_scene.instantiate()
		store_item.visible = false
		store_item.download_url = plugin["archive.url"]
		store_item.project_url = plugin["plugin.link"]
		store_item.sha256 = plugin["archive.sha256"]
		store_item.plugin_id = plugin["plugin.id"]
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
		
