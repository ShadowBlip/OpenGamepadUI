extends ScrollContainer

@export var state_manager_path: NodePath

const button_scene := preload("res://core/ui/components/button.tscn")
const state_changer := preload("res://core/systems/state/state_changer.tscn")

@onready var plugin_loader: PluginLoader = get_node("/root/Main/PluginLoader")
@onready var state_manager: StateManager = get_node(state_manager_path)
@onready var settings_menu := $"../../.."
@onready var plugin_menu_container := $HBoxContainer/MarginContainer/PluginSettings
@onready var plugin_content_container := $HBoxContainer/PluginSettingsContentContainer
@onready var no_plugins_label := $HBoxContainer/PluginSettingsContentContainer/Label


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	state_manager.state_changed.connect(_on_state_change)
	visible = false
	_populate_plugins()


func _on_state_change(from: int, to: int, data: Dictionary) -> void:
	if to != settings_menu.STATES.MANAGE_PLUGINS:
		visible = false
		return
	visible = true


# Populates the menu with plugins
func _populate_plugins():
	# Clear any existing plugin menus
	for node in plugin_menu_container.get_children():
		remove_child(node)
		node.queue_free()
	
	# Clear any plugin content menus
	for node in plugin_content_container.get_children():
		if node.name == "Label":
			continue
		remove_child(node)
		node.queue_free()
	
	# Build the plugin settings content and menu button for each plugin
	for plugin_id in plugin_loader.plugins.keys():
		var meta: Dictionary = plugin_loader.plugins[plugin_id]
		var plugin: Plugin = plugin_loader.plugin_nodes[plugin_id]
		var plugin_settings := plugin.get_settings_menu()
		if plugin_settings == null:
			continue
		plugin_settings.visible = false
		plugin_content_container.add_child(plugin_settings)
		
		# Callback method for menu button focus to show plugin settings
		var on_focus := func ():
			plugin_settings.visible = true
		var on_unfocus := func ():
			plugin_settings.visible = false
		
		# Build the menu button
		var button := button_scene.instantiate()
		button.text = meta["plugin.name"]
		button.focus_entered.connect(on_focus)
		button.focus_exited.connect(on_unfocus)
		plugin_menu_container.add_child(button)
	
	# If no plugins are available, display a message that there are no plugin
	# settings.
	if plugin_content_container.get_child_count() == 1:
		no_plugins_label.visible = true
		return
	no_plugins_label.visible = false
