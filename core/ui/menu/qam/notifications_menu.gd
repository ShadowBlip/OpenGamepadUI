extends Control

const notification_scene := preload("res://core/ui/components/notification_container.tscn")

var label_settings := LabelSettings.new()

@export var focus_node : Node = $NotificationContainer


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	label_settings.font_size = 12
	label_settings.line_spacing = 0
	NotificationManager.notification_sent.connect(_on_notification_sent)
	for child in get_children():
		if child.name in ["VisibilityManager", "TransitionContainer"]:
			continue
		child.queue_free()


func _on_notification_sent(_notify: Notification) -> void:
	for child in get_children():
		if child.name in ["VisibilityManager", "TransitionContainer"]:
			continue
		child.queue_free()
	var history := NotificationManager.get_notification_history()
	for i in range(history.size(), 0, -1):
		var notify := history[i-1] as Notification
		var notification := notification_scene.instantiate() as NotificationContainer
		notification.text = notify.text
		if notify.icon:
			notification.icon_texture = notify.icon
		notification.icon_size = Vector2(24, 24)
		notification.custom_minimum_size = Vector2(220, 0)
		notification.label_settings = label_settings
		add_child(notification)


func _on_notification_container_focus_entered():
	if focus_node.get_child_count() > 0:
		focus_node.get_child(0).grab_focus()
