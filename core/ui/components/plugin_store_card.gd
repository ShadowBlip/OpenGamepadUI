extends PanelContainer

signal pressed
signal button_up
signal button_down

const plugin_icon := preload("res://assets/ui/icons/plugin-solid.svg")
const install_icon := preload("res://assets/ui/icons/download-cloud-2-fill.svg")
const upgrade_icon := preload("res://assets/ui/icons/upgrade.svg")
const delete_icon := preload("res://assets/ui/icons/round-delete-forever.svg")

@export_category("Animation")
@export var highlight_speed := 0.1

@export_category("AudioSteamPlayer")
@export_file("*.ogg") var focus_audio = "res://assets/audio/interface/536764__egomassive__toss.ogg"
@export_file("*.ogg") var select_audio = "res://assets/audio/interface/96127__bmaczero__contact1.ogg"

var NotificationManager := load("res://core/global/notification_manager.tres") as NotificationManager
var PluginLoader := load("res://core/global/plugin_loader.tres") as PluginLoader
var highlight_tween: Tween
var focus_audio_stream = load(focus_audio)
var select_audio_stream = load(select_audio)
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
	focus_entered.connect(_on_focus)
	focus_exited.connect(_on_unfocus)
	theme_changed.connect(_on_theme_changed)
	_on_theme_changed()
	update_button.visible = PluginLoader.is_upgradable(plugin_id)
	action_button.pressed.connect(_on_install_button)
	update_button.pressed.connect(_on_update_button)
	PluginLoader.plugin_upgradable.connect(_on_update_available)
	_set_installed_state()


func _on_theme_changed() -> void:
	# Configure the highlight texture from the theme
	var highlight_texture := get_theme_icon("highlight", "ExpandableCard")
	if highlight_texture:
		highlight.texture = highlight_texture


# Updates the store item based on whether it is installed
func _set_installed_state():
	if PluginLoader.is_installed(plugin_id):
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


func _on_focus() -> void:
	_highlight()


func _on_unfocus() -> void:
	# If a child focus group is focused, don't do anything. That means that
	if not focus_group:
		logger.warn("No focus group defined!")
		return

	# a child node is focused and we want the card to remain "selected"
	if focus_group.is_in_focus_stack():
		return
	
	_unhighlight()


func _highlight() -> void:
	if highlight_tween:
		highlight_tween.kill()
	highlight_tween = get_tree().create_tween()
	highlight_tween.tween_property(highlight, "visible", true, 0)
	highlight_tween.tween_property(highlight, "modulate", Color(1, 1, 1, 1), 0)
	_play_sound(focus_audio_stream)
	
	
func _unhighlight() -> void:
	if highlight_tween:
		highlight_tween.kill()
	highlight_tween = get_tree().create_tween()
	highlight_tween.tween_property(highlight, "modulate", Color(1, 1, 1, 1), 0)
	highlight_tween.tween_property(highlight, "modulate", Color(1, 1, 1, 0), highlight_speed)
	highlight_tween.tween_property(highlight, "visible", false, 0)


func _play_sound(stream: AudioStream) -> void:
	var audio_player: AudioStreamPlayer = $AudioStreamPlayer
	audio_player.stream = stream
	audio_player.play()


func _gui_input(event: InputEvent) -> void:
	if event.is_action("ui_accept"):
		if event.is_pressed():
			button_down.emit()
			pressed.emit()
		else:
			button_up.emit()
