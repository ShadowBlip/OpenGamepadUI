extends Control

const notification_scene := preload("res://core/ui/components/notification_container.tscn")

var NotificationManager := (
	load("res://core/global/notification_manager.tres") as NotificationManager
)
var label_settings := LabelSettings.new()

@onready var container := $%HFlowContainer
@onready var no_notifications := $%NoNotifications

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	label_settings.font_size = 12
	label_settings.line_spacing = 0
	NotificationManager.notification_sent.connect(_on_notification_sent)
	for child in container.get_children():
		if child.name in ["FocusGroup", "NoNotifications"]:
			continue
		child.queue_free()


func _on_notification_sent(_notify: Notification) -> void:
	for child in container.get_children():
		if child.name in ["FocusGroup", "NoNotifications"]:
			continue
		child.queue_free()
	var history := NotificationManager.get_notification_history()
	
	if history.size() > 0:
		no_notifications.visible = true
	else:
		no_notifications.visible = false

	var i := history.size()
	while i > 0:
		var notify := history[i - 1] as Notification
		var notification := notification_scene.instantiate() as NotificationContainer
		notification.text = notify.text
		if notify.icon:
			notification.icon_texture = notify.icon
		notification.icon_size = Vector2(24, 24)
		notification.custom_minimum_size = Vector2(220, 0)
		notification.label_settings = label_settings
		container.add_child(notification)
		i -= 1
