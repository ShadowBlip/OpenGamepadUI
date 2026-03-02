extends MarginContainer

var notification_manager := preload("res://core/global/notification_manager.tres") as NotificationManager


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	notification_manager.notification_sent.connect(_on_notification_sent)


func _on_notification_sent(notify: Notification) -> void:
	pass
