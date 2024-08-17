extends ScrollContainer

signal plugin_store_loaded(plugin_items: Dictionary)

const plugin_store_card_scene: PackedScene = preload("res://core/ui/components/plugin_store_card.tscn")
var plugin_loader := load("res://core/global/plugin_loader.tres") as PluginLoader
var notification_manager := load("res://core/global/notification_manager.tres") as NotificationManager
var plugin_nodes := {}

@onready var container := $%HFlowContainer as HFlowContainer
@onready var focus_group := $%FocusGroup as FocusGroup
@onready var http_image := $HTTPImageFetcher as HTTPImageFetcher


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	plugin_store_loaded.connect(_on_plugin_store_loaded)
	plugin_loader.plugin_upgradable.connect(_on_plugin_upgradable)
	visibility_changed.connect(load_plugin_store_items)
	load_plugin_store_items()


# Loads available plugins from the plugin store and emits the 'plugin_store_loaded'
# signal with the loaded items
func load_plugin_store_items():
	# Fetch available plugins from the plugin store
	var plugin_items = await plugin_loader.get_plugin_store_items()
	plugin_store_loaded.emit(plugin_items)


# Gets executed on plugin store items loaded
func _on_plugin_store_loaded(plugin_items: Dictionary):
	# Clear the current grid of items
	var keep_nodes := [focus_group]
	for plugin_id in plugin_items.keys():
		if plugin_id in plugin_nodes:
			keep_nodes.append(plugin_nodes[plugin_id])
	
	for child in container.get_children():
		if child in keep_nodes:
			continue
		container.remove_child(child)
		child.queue_free()
		
	_populate_plugin_store_items(container, plugin_items)


# Populates the plugin store grid with the given plugin items
func _populate_plugin_store_items(grid: Container, plugin_items: Dictionary):
	for plugin_id in plugin_items.keys():
		if plugin_id in plugin_nodes:
			continue
			
		var plugin: Dictionary = plugin_items[plugin_id]

		# Build the store item
		var store_item := plugin_store_card_scene.instantiate()
		store_item.visible = false
		store_item.download_url = plugin["archive.url"]
		store_item.project_url = plugin["plugin.link"]
		store_item.sha256 = plugin["archive.sha256"]
		store_item.plugin_id = plugin["plugin.id"]
		store_item.name = store_item.plugin_id
		grid.add_child(store_item)
		store_item.plugin_name_label.text = plugin["plugin.name"]
		store_item.summary_label.text = plugin["plugin.summary"]
		
		# Load the plugin image
		if len(plugin["store.images"]) > 0:
			var image = await http_image.fetch(plugin["store.images"][0])
			if image != null:
				store_item.plugin_texture.texture = image
		
		# Add the store item
		store_item.visible = true


func _on_plugin_upgradable(plugin_id: String, update_type: int) -> void:
	var notify := Notification.new("")
	if update_type == PluginLoader.update_type.NEW:
		notify.text=("New plugin available: {0}".format([plugin_id]))

	if update_type == PluginLoader.update_type.UPDATE:
		notify.text=("Plugin upgrade available: {0}".format([plugin_id]))

	notification_manager.show(notify)
