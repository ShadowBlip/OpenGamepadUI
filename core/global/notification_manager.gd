@icon("res://assets/icons/alert-triangle.svg")
extends Resource
class_name NotificationManager

## Resource API for displaying arbitrary notifications
##
## The NotificationManager is responsible for providing an API to display 
## arbitrary notifications to the user and maintain a history of those 
## notifications. It also manages a queue of notifications so only one 
## notification shows at a time.[br][br]
##
##     [codeblock]
##     const NotificationManager := preload("res://core/global/notification_manager.tres")
##     ...
##     var notify := Notification.new("Hello world!")
##     notify.icon = load("res://assets/icons/critical.png")
##     NotificationManager.show(notify)
##     [/codeblock]

## Emitted when a notification is shown to the user
signal notification_sent(notify: Notification)
## Emitted when a notification has been queued
signal notification_queued(notify: Notification)

var settings_manager := load("res://core/global/settings_manager.tres") as SettingsManager

# Keep around a history of notifications
var _max_history := settings_manager.get_value("general.notification", "max_history", 5) as int
var _history := [] as Array[Notification]
var _queue := [] as Array[Notification]
var ready := false
var logger := Log.get_logger("NotificationManager")


## Queues the given notification to be shown
func show(notify: Notification):
	_queue_notification(notify)


## Returns a list of notifications
func get_notification_history() -> Array[Notification]:
	return _history.duplicate()


# Shows the given notification
# DEPRECATED
func show_notification(text: String, icon: Texture2D = null, timeout_sec: float = 5.0):
	var notify := Notification.new(text)
	notify.icon = icon
	notify.timeout = timeout_sec
	show(notify)


## Returns whether there are notifiations waiting in the queue
func has_next() -> bool:
	return _queue.size() > 0


## Returns the next notifiation waiting in the queue
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
