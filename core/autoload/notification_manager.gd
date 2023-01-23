@icon("res://assets/icons/alert-triangle.svg")
extends Node

const Toast := preload("res://core/ui/components/toast.gd")

# Keep around a history of notifications
var notifications := []

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	get_parent().ready.connect(_on_parent_ready)


# Called when our parent is ready
func _on_parent_ready() -> void:
	pass
	#show_notification("Notification manager is ready")


# Shows the given notification
func show_notification(text: String, icon: Texture2D = null, timeout_sec: float = 5.0):
	# Get our toast UI
	var toast: Toast = get_tree().get_first_node_in_group("notification_toast")
	toast.show_toast(text, icon, timeout_sec)
