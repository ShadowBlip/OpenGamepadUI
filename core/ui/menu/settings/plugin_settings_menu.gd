extends ScrollContainer

const button_scene := preload("res://core/ui/components/button.tscn")
const settings_content := preload("res://core/ui/menu/settings/plugin_settings_content.tscn")

var state_machine := preload("res://assets/state/state_machines/plugin_settings_state_machine.tres")

@onready var plugin_menu_container := $HBoxContainer/MarginContainer/PluginSettings
@onready var plugins_content_container := $HBoxContainer/PluginSettingsContentContainer
@onready var no_plugins_label := $HBoxContainer/PluginSettingsContentContainer/Label


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_populate_plugins()


# Populates the menu with plugins
func _populate_plugins():
	# Clear any existing plugin menus
	for node in plugin_menu_container.get_children():
		plugin_menu_container.remove_child(node)
		node.queue_free()
	
	# Clear any plugin content menus
	for node in plugins_content_container.get_children():
		if node == no_plugins_label:
			continue
		remove_child(node)
		node.queue_free()
	
	# Build the plugin settings content and menu button for each plugin
	for plugin_id in PluginLoader.get_loaded_plugins():
		var meta: Dictionary = PluginLoader.plugins[plugin_id]
		var plugin: Plugin = PluginLoader.plugin_nodes[plugin_id]
		var plugin_settings := plugin.get_settings_menu()
		
		# Build a content container for each plugin
		var plugin_content_container := settings_content.instantiate()
		plugin_content_container.name = plugin_id
		plugin_content_container.visible = false

		# Create a menu state for this plugin, so visibility can be toggled
		# when it is in focus
		var state := State.new()
		state.name = plugin_id
		
		# Connect the visibility manager for this plugin to the state
		var visibility := plugin_content_container.get_node("VisibilityManager") as VisibilityManager
		visibility.state = state

		# Set the plugin version in the settings menu
		var version_label := plugin_content_container.get_node("%VersionValueLabel") as Label
		version_label.text = meta["plugin.version"]
		
		# Wire up the enable toggle button to enable/disable the plugin
		var enable_button := plugin_content_container.get_node("%EnabledCheckButton") as CheckButton
		enable_button.button_pressed = PluginLoader.is_initialized(plugin_id)
		var on_enable_toggle := func(toggled: bool):
			if toggled:
				PluginLoader.initialize_plugin(plugin_id)
				return
			PluginLoader.uninitialize_plugin(plugin_id)
		enable_button.toggled.connect(on_enable_toggle)
		
		# Add the plugin settings content to the plugin content container
		if plugin_settings != null:
			var content_layout := plugin_content_container.get_node("%ContentLayout")
			content_layout.add_child(plugin_settings)
		
		# Callback method for menu button focus to switch to the plugin state and
		# show the plugin settings
		var on_focus := func ():
			state_machine.replace_state(state)
		
		# Build the menu button
		var button := button_scene.instantiate()
		button.text = meta["plugin.name"]
		button.focus_entered.connect(on_focus)
		plugin_menu_container.add_child(button)
		
		# Add the plugin content to our list of plugin content
		plugins_content_container.add_child(plugin_content_container)
	
	# If no plugins are available, display a message that there are no plugin
	# settings.
	if plugins_content_container.get_child_count() == 1:
		no_plugins_label.visible = true
		return
	no_plugins_label.visible = false
