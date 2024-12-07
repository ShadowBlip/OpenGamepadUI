@tool
extends Container

signal pressed
signal button_up
signal button_down
signal nonchild_focused

const plugin_icon := preload("res://assets/ui/icons/plugin-solid.svg")
const install_icon := preload("res://assets/ui/icons/download-cloud-2-fill.svg")
const upgrade_icon := preload("res://assets/ui/icons/upgrade.svg")
const delete_icon := preload("res://assets/ui/icons/round-delete-forever.svg")

var notification_manager := load("res://core/global/notification_manager.tres") as NotificationManager
var plugin_loader := load("res://core/global/plugin_loader.tres") as PluginLoader
var download_url: String
var project_url: String
var sha256: String
var plugin_id: String
var logger: Logger

@onready var plugin_texture := $%Icon
@onready var plugin_name_label := $%NameLabel
@onready var summary_label := $%SummaryLabel
@onready var action_button := $%ActionButton
@onready var update_button := $%UpgradeButton
@onready var highlight := $%HighlightTexture as TextureRect
@onready var focus_group := $%FocusGroup as FocusGroup


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Do nothing if running in the editor
	if Engine.is_editor_hint():
		return

	var on_focus_exited := func():
		self._on_unfocus.call_deferred()
	focus_exited.connect(on_focus_exited)
	theme_changed.connect(_on_theme_changed)

	# Find the parent theme and update if required
	var effective_theme := ThemeUtils.get_effective_theme(self)
	if effective_theme:
		_on_theme_changed()

	update_button.visible = plugin_loader.is_upgradable(plugin_id)
	action_button.pressed.connect(_on_install_button)
	update_button.pressed.connect(_on_update_button)
	plugin_loader.plugin_upgradable.connect(_on_update_available)
	_set_installed_state()


func _on_theme_changed() -> void:
	# Configure the highlight texture from the theme
	var highlight_texture := get_theme_icon("highlight", "ExpandableCard")
	if highlight_texture:
		highlight.texture = highlight_texture


# Updates the store item based on whether it is installed
func _set_installed_state():
	if plugin_loader.is_installed(plugin_id):
		action_button.texture = delete_icon
		return
	action_button.texture = install_icon


func set_logger(logger_name: String) -> void:
	logger = Log.get_logger(logger_name)


# Handle install/uninstall
func _on_install_button() -> void:
	var notify := Notification.new("Installing plugin " + plugin_id)
	notify.icon = plugin_icon
	# Handle uninstall
	if plugin_loader.is_installed(plugin_id):
		notify.text = "Plugin " + plugin_id + " uninstalled"
		if plugin_loader.uninstall_plugin(plugin_id) != OK:
			notify.text = "Plugin " + plugin_id + " failed to uninstall"
			logger.error("Failed to uninstall plugin: " + plugin_id)
		_set_installed_state()
		notification_manager.show(notify)
		return

	# Handle install
	notification_manager.show(notify)
	plugin_loader.install_plugin(plugin_id, download_url, sha256)
	await plugin_loader.plugin_installed
	_set_installed_state()
	notify = Notification.new("Plugin " + plugin_id + " installed")
	notify.icon = plugin_icon
	notification_manager.show(notify)


# Shows in the store item if an update is available
func _on_update_available(name: String, type: int) -> void:
	# Ignore other plugins
	if name != plugin_id:
		return
	if type != PluginLoader.update_type.UPDATE:
		return
	update_button.visible = true


# Handle updates
func _on_update_button() -> void:
	var notify := Notification.new("Updating plugin " + plugin_id)
	notify.icon = plugin_icon
	notification_manager.show(notify)
	plugin_loader.install_plugin(plugin_id, download_url, sha256)
	await plugin_loader.plugin_installed
	notify = Notification.new("Plugin " + plugin_id + " updated")
	notify.icon = plugin_icon
	notification_manager.show(notify)
	plugin_loader.set_plugin_upgraded(plugin_id)
	update_button.visible = false


func _on_unfocus() -> void:
	# Emit a signal if a non-child node grabs focus
	var viewport := get_viewport()
	if not viewport:
		return
	var focus_owner := viewport.gui_get_focus_owner()
	if not self.is_ancestor_of(focus_owner):
		nonchild_focused.emit()
		return

	# If a child has focus, listen for focus changes until a non-child has focus
	viewport.gui_focus_changed.connect(_on_focus_change)


func _on_focus_change(focused: Control) -> void:
	# Don't do anything if the focused node is a child
	if self.is_ancestor_of(focused):
		return

	# If a non-child has focus, emit a signal to indicate that this node and none
	# of its children have focus.
	nonchild_focused.emit()
	var viewport := get_viewport()
	if viewport.gui_focus_changed.is_connected(_on_focus_change):
		viewport.gui_focus_changed.disconnect(_on_focus_change)


func _gui_input(event: InputEvent) -> void:
	if event.is_action("ui_accept"):
		if event.is_pressed():
			button_down.emit()
			pressed.emit()
		else:
			button_up.emit()
