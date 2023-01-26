@icon("res://assets/icons/alert-triangle.svg")
extends Node

signal notification_sent(notify: Notification)
signal notification_queued(notify: Notification)

const Toast := preload("res://core/ui/components/toast.gd")

# Keep around a history of notifications
var _max_history := SettingsManager.get_value("general.notification", "max_history", 5)
var _history := [] as Array[Notification]
var _queue := [] as Array[Notification]
var _toast: Toast
var logger := Log.get_logger("NotificationManager")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	get_parent().ready.connect(_on_parent_ready)


# Called when our parent is ready
func _on_parent_ready() -> void:
	_toast = get_tree().get_first_node_in_group("notification_toast")
	if _toast == null:
		return
	_toast.toast_finished.connect(_on_toast_finished)


# Queues the given notification to be shown
func show(notify: Notification):
	_queue_notification(notify)


# Returns a list of notifications
func get_notification_history() -> Array[Notification]:
	return _history.duplicate()


# Shows the given notification
# DEPRECATED
func show_notification(text: String, icon: Texture2D = null, timeout_sec: float = 5.0):
	var notify := Notification.new(text)
	notify.icon = icon
	notify.timeout = timeout_sec
	show(notify)


# Process the notification queue after each one finishes
func _on_toast_finished():
	logger.debug("Toast finished displaying, processing queue")
	_process_queue()


# Adds the given notification to the queue
func _queue_notification(notify: Notification):
	logger.debug("Queueing notification: " + notify.text)
	_queue.push_back(notify)
	notification_queued.emit(notify)
	
	# If we just queued and no notifications are showing, start processing
	if _toast != null and _queue.size() == 1:
		if _toast.is_showing():
			logger.debug("Toast is still showing. Processing after it's finished")
			return
		logger.debug("Only one message in queue and toast is hidden. Starting processing.")
		_process_queue()


# Removes items from the queue and shows them
func _process_queue():
	if _queue.size() == 0:
		logger.debug("Queue is empty. Nothing to process.")
		return
	logger.debug("Processing notification queue")
	var notify := _queue.pop_front()
	
	# Add the notification to our history
	_history.push_back(notify)
	if _history.size() > _max_history:
		_history.pop_front()
	
	# Show the notification
	if _toast != null:
		_toast.show_toast(notify.text, notify.icon, notify.timeout)
	else:
		logger.info(notify.text)
	notification_sent.emit(notify)
