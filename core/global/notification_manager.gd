@icon("res://assets/icons/alert-triangle.svg")
extends Resource
class_name NotificationManager

signal notification_sent(notify: Notification)
signal notification_queued(notify: Notification)

var SettingsManager := load("res://core/global/settings_manager.tres") as SettingsManager

# Keep around a history of notifications
var _max_history := SettingsManager.get_value("general.notification", "max_history", 5) as int
var _history := [] as Array[Notification]
var _queue := [] as Array[Notification]
var ready := false
var logger := Log.get_logger("NotificationManager")


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


# Returns whether there are notifiations waiting in the queue
func has_next() -> bool:
	return _queue.size() > 0


# Returns the next notifiation waiting in the queue
func next() -> Notification:
	if _queue.size() == 0:
		logger.debug("Queue is empty. Nothing to process.")
		return null
	logger.debug("Processing notification queue")
	var notify := _queue.pop_front() as Notification

	# Add the notification to our history
	_history.push_back(notify)
	if _history.size() > _max_history:
		_history.pop_front()
	
	notification_sent.emit(notify)
	return notify


# Adds the given notification to the queue
func _queue_notification(notify: Notification):
	logger.debug("Queueing notification: " + notify.text)
	_queue.push_back(notify)
	notification_queued.emit(notify)
