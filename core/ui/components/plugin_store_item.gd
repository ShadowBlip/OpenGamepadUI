extends Control

const plugin_icon := preload("res://assets/ui/icons/plugin-solid.svg")

var NotificationManager := (
	load("res://core/global/notification_manager.tres") as NotificationManager
)
var PluginLoader := load("res://core/global/plugin_loader.tres") as PluginLoader
var download_url: String
var project_url: String
var sha256: String
var plugin_id: String
var logger: Logger

@onready var plugin_name_label := $MarginContainer/VBoxContainer/PluginNameLabel
@onready var plugin_texture := $MarginContainer/VBoxContainer/HBoxContainer/TextureRect
@onready var author_label := $MarginContainer/VBoxContainer/HBoxContainer/VBoxContainer/AuthorLabel
@onready var summary_label := $MarginContainer/VBoxContainer/HBoxContainer/VBoxContainer/SummaryLabel
@onready var install_button := $MarginContainer/HBoxContainer/InstallButton
@onready var update_button := $MarginContainer/HBoxContainer/UpdateButton

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	update_button.visible = PluginLoader.is_upgradable(plugin_id)
	install_button.button_up.connect(_on_install_button)
	update_button.button_up.connect(_on_update_button)
	PluginLoader.plugin_upgradable.connect(_on_update_available)
	_set_installed_state()


# Updates the store item based on whether it is installed
func _set_installed_state():
	if PluginLoader.is_installed(plugin_id):
		install_button.text = "Uninstall"
		return
	install_button.text = "Install"


func set_logger(logger_name: String) -> void:
	logger = Log.get_logger(logger_name)


# Handle install/uninstall
func _on_install_button() -> void:
	var notify := Notification.new("Installing plugin " + plugin_id)
	notify.icon = plugin_icon
	# Handle uninstall
	if PluginLoader.is_installed(plugin_id):
		notify.text = "Plugin " + plugin_id + " uninstalled"
		if PluginLoader.uninstall_plugin(plugin_id) != OK:
			notify.text = "Plugin " + plugin_id + " failed to uninstall"
			logger.error("Failed to uninstall plugin: " + plugin_id)
		_set_installed_state()
		NotificationManager.show(notify)
		return

	# Handle install
	NotificationManager.show(notify)
	PluginLoader.install_plugin(plugin_id, download_url, sha256)
	await PluginLoader.plugin_installed
	_set_installed_state()
	notify = Notification.new("Plugin " + plugin_id + " installed")
	notify.icon = plugin_icon
	NotificationManager.show(notify)


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
	NotificationManager.show(notify)
	PluginLoader.install_plugin(plugin_id, download_url, sha256)
	await PluginLoader.plugin_installed
	notify = Notification.new("Plugin " + plugin_id + " updated")
	notify.icon = plugin_icon
	NotificationManager.show(notify)
	PluginLoader.set_plugin_upgraded(plugin_id)
	update_button.visible = false
