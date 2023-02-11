extends ScrollContainer

const button_scene := preload("res://core/ui/components/button.tscn")
const settings_content := preload("res://core/ui/menu/settings/plugin_settings_content.tscn")

var state_machine := preload("res://assets/state/state_machines/plugin_settings_state_machine.tres")
var _plugin_containers := {}
var _plugin_content := {}

@onready var plugin_menu_container := $HBoxContainer/MarginContainer/PluginSettings
@onready var plugins_content_container := $HBoxContainer/PluginSettingsContentContainer
@onready var no_plugins_label := $HBoxContainer/PluginSettingsContentContainer/Label


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_populate_plugins()
	PluginLoader.plugin_initialized.connect(_on_plugin_initialized)
	PluginLoader.plugin_uninitialized.connect(_on_plugin_uninitialized)


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
		_on_plugin_initialized(plugin_id)
	
	# If no plugins are available, display a message that there are no plugin
	# settings.
	if plugins_content_container.get_child_count() == 1:
		no_plugins_label.visible = true
		return
	no_plugins_label.visible = false


# Creates a menu button and adds the settings menu for the given plugin.
func _populate_menu_for_plugin(plugin_id: String) -> void:
	var meta := PluginLoader.get_plugin_meta(plugin_id)
	
	# Build a content container for each plugin
	var plugin_content_container := settings_content.instantiate()
	plugin_content_container.name = plugin_id
	plugin_content_container.visible = false
	_plugin_containers[plugin_id] = plugin_content_container

	# Create a menu state for this plugin, so visibility can be toggled
	# when it is in focus
	var state := State.new()
	state.name = plugin_id
	
	# Connect the visibility manager for this plugin to the state
	var visibility := plugin_content_container.get_node("VisibilityManager") as VisibilityManager
	visibility.state = state

	# Set the plugin name label
	var name_label := plugin_content_container.get_node("%PluginNameText")
	name_label.text = meta["plugin.name"]

	# Set the plugin version in the settings menu
	var version_label := plugin_content_container.get_node("%PluginVersionText")
	version_label.text = meta["plugin.version"]
	
	# Wire up the enable toggle button to enable/disable the plugin
	var enable_button := plugin_content_container.get_node("%PluginEnabledToggle")
	enable_button.button_pressed = PluginLoader.is_initialized(plugin_id)
	var on_enable_toggle := func(toggled: bool):
		if toggled:
			PluginLoader.enable_plugin(plugin_id)
			PluginLoader.initialize_plugin(plugin_id)
			return
		PluginLoader.uninitialize_plugin(plugin_id)
		PluginLoader.disable_plugin(plugin_id)
	enable_button.toggled.connect(on_enable_toggle)
	
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


func _on_plugin_initialized(plugin_id: String) -> void:
	# If a menu for the plugin hasn't been populated yet, populate it.
	if not plugin_id in _plugin_containers:
		_populate_menu_for_plugin(plugin_id)
	
	# No need to populate the plugin-specific settings menu if it's disabled
	if not PluginLoader.is_initialized(plugin_id):
		return
	
	# Get the populated menu and add the plugin settings content to it.
	var plugin_content_container: Node = _plugin_containers[plugin_id]
	var plugin := PluginLoader.get_plugin(plugin_id)
	var plugin_settings := plugin.get_settings_menu()
	if plugin_settings == null:
		return
	
	# Add the plugin settings content to the plugin content container
	var content_layout := plugin_content_container.get_node("%ContentLayout")
	content_layout.add_child(plugin_settings)
	_plugin_content[plugin_id] = plugin_settings
	

func _on_plugin_uninitialized(plugin_id: String) -> void:
	if not plugin_id in _plugin_content:
		return
	var plugin_settings: Node = _plugin_content[plugin_id]
	var parent := plugin_settings.get_parent()
	parent.remove_child(plugin_settings)
	plugin_settings.queue_free()
	_plugin_content.erase(plugin_id)
