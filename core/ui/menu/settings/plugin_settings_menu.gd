extends ScrollContainer

const button_scene := preload("res://core/ui/components/button.tscn")

@onready var settings_menu := $"../../.."
@onready var plugin_menu_container := $HBoxContainer/MarginContainer/PluginSettings
@onready var plugin_content_container := $HBoxContainer/PluginSettingsContentContainer
@onready var no_plugins_label := $HBoxContainer/PluginSettingsContentContainer/Label


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_populate_plugins()


# Populates the menu with plugins
func _populate_plugins():
	# Clear any existing plugin menus
	for node in plugin_menu_container.get_children():
		remove_child(node)
		node.queue_free()
	
	# Clear any plugin content menus
	for node in plugin_content_container.get_children():
		if node == no_plugins_label:
			continue
		remove_child(node)
		node.queue_free()
	
	# Build the plugin settings content and menu button for each plugin
	for plugin_id in PluginLoader.plugins.keys():
		var meta: Dictionary = PluginLoader.plugins[plugin_id]
		var plugin: Plugin = PluginLoader.plugin_nodes[plugin_id]
		var plugin_settings := plugin.get_settings_menu()
		if plugin_settings == null:
			continue
		plugin_settings.visible = false
		plugin_content_container.add_child(plugin_settings)
		
		# Callback method for menu button focus to show plugin settings
		var on_focus := func ():
			for child in plugin_content_container.get_children():
				child.visible = false
			plugin_settings.visible = true
		
		# Build the menu button
		var button := button_scene.instantiate()
		button.text = meta["plugin.name"]
		button.focus_entered.connect(on_focus)
		plugin_menu_container.add_child(button)
	
	# If no plugins are available, display a message that there are no plugin
	# settings.
	if plugin_content_container.get_child_count() == 1:
		no_plugins_label.visible = true
		return
	no_plugins_label.visible = false
