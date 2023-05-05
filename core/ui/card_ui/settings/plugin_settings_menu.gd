extends ScrollContainer

const settings_content_scene := preload("res://core/ui/card_ui/settings/plugin_settings_content.tscn")
const card_scene := preload("res://core/ui/components/expandable_card.tscn")

var PluginLoader := load("res://core/global/plugin_loader.tres") as PluginLoader

@onready var content_container := $%ContentContainer
@onready var no_plugins_label := $%NoPluginsLabel
@onready var focus_group := $%FocusGroup as FocusGroup


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_populate_plugins()
	PluginLoader.plugins_reloaded.connect(_populate_plugins)

	# Create and start a timer to check for plugin updates
	var update_timer := Timer.new()
	update_timer.one_shot = false
	update_timer.process_callback = Timer.TIMER_PROCESS_IDLE
	update_timer.timeout.connect(PluginLoader.on_update_timeout)
	update_timer.wait_time = 300 # Five minutes seems reasonable
	add_child(update_timer)
	update_timer.start()


# Populates the menu with plugins
func _populate_plugins():
	# Clear any plugin content menus
	for node in content_container.get_children():
		if node in [no_plugins_label, focus_group]:
			continue
		node.queue_free()

	# Build the plugin settings content and menu button for each plugin
	for plugin_id in PluginLoader.get_loaded_plugins():
		var plugin_settings := _build_menu_for_plugin(plugin_id)
		plugin_settings.name = plugin_id + "Card"
		content_container.add_child(plugin_settings)

	# If no plugins are available, display a message that there are no plugin
	# settings.
	if content_container.get_child_count() == 2:
		no_plugins_label.visible = true
		return
	no_plugins_label.visible = false


# Creates a settings menu for the given plugin.
func _build_menu_for_plugin(plugin_id: String) -> Control:
	var meta := PluginLoader.get_plugin_meta(plugin_id)
	
	# Build an expandable card to contain the plugin settings
	var card := card_scene.instantiate()
	card.title = meta["plugin.name"]
	var card_content := card.get_node("%ContentContainer")

	# Build a content container for the given plugin
	var plugin_content_container := settings_content_scene.instantiate()
	plugin_content_container.name = plugin_id
	plugin_content_container.visible = true
	card_content.add_child(plugin_content_container)

	# Set the plugin name label
	var name_label := plugin_content_container.get_node("%PluginNameText")
	name_label.text = meta["plugin.name"]

	# Set the plugin version in the settings menu
	var version_label := plugin_content_container.get_node("%PluginVersionText")
	version_label.text = meta["plugin.version"]

	# Get the settings menu from the plugin if it exists
	var plugin := PluginLoader.get_plugin(plugin_id)
	var plugin_settings: Control = null
	if plugin:
		plugin_settings = plugin.get_settings_menu()
	
	# Ensure that the plugin menu's size matches its children so the
	# card can properly expand
	if plugin_settings:
		_config_settings_menu(plugin_settings, plugin_content_container)

	# Wire up the enable toggle button to enable/disable the plugin
	var enable_button := plugin_content_container.get_node("%PluginEnabledToggle")
	enable_button.button_pressed = PluginLoader.is_initialized(plugin_id)
	enable_button.toggled.connect(_on_plugin_toggled.bind(plugin_id, plugin_content_container))

	# No need to populate the plugin-specific settings menu if it's disabled
	if not PluginLoader.is_initialized(plugin_id):
		return card

	# If the plugin doesn't provide a settings menu, return it as-is
	if plugin_settings == null:
		return card

	# Add the plugin settings content to the plugin content container
	var content_layout := plugin_content_container.get_node("%ContentLayout")
	content_layout.add_child(plugin_settings)

	return card


# Adds a focus group to the settings menu and ensures the minimum size is set so
# it can be expanded properly.
func _config_settings_menu(plugin_settings: Control, plugin_content_container: Control) -> void:
	# Get the plugin content focus group
	var plugin_content_focus_group := plugin_content_container.get_node("%FocusGroup")
	
	# Create a focus group for the plugin settings
	var plugin_focus_group := FocusGroup.new()
	plugin_focus_group.name = "FocusGroup"
	plugin_focus_group.focus_stack = load("res://core/ui/card_ui/settings/settings_menu_focus.tres")
	plugin_settings.add_child(plugin_focus_group)
	for child in plugin_settings.get_children():
		if not child is Control:
			continue
		var on_ready := func():
			plugin_settings.custom_minimum_size += child.size
			plugin_content_focus_group.focus_neighbor_bottom = plugin_focus_group
			plugin_focus_group.focus_neighbor_top = plugin_content_focus_group
			plugin_focus_group.recalculate_focus()
			plugin_content_focus_group.recalculate_focus()
		plugin_settings.ready.connect(on_ready, CONNECT_ONE_SHOT)


func _on_plugin_toggled(toggled: bool, plugin_id: String, plugin_content_container: Control) -> void:
	# Add the plugin settings menu if enabled
	var content_layout := plugin_content_container.get_node("%ContentLayout")
	
	# Unload the plugin and remove its menu
	if not toggled:
		PluginLoader.uninitialize_plugin(plugin_id)
		PluginLoader.disable_plugin(plugin_id)
		content_layout.get_child(-1).queue_free()
		return
	
	# Otherwise, load the plugin and add its settings menu
	PluginLoader.enable_plugin(plugin_id)
	PluginLoader.initialize_plugin(plugin_id)
	
	# Get the settings menu from the plugin if it exists
	var plugin := PluginLoader.get_plugin(plugin_id)
	var plugin_settings: Control = null
	if plugin:
		plugin_settings = plugin.get_settings_menu()
	if not plugin_settings:
		return
	
	# Configure and add the plugin settings menu
	_config_settings_menu(plugin_settings, plugin_content_container)
	content_layout.add_child(plugin_settings)
