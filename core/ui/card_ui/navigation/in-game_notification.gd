extends Control

signal notification_received
signal notification_finished

var PID: int = OS.get_process_id()
var gamescope := load("res://core/systems/gamescope/gamescope.tres") as GamescopeInstance
var notification_manager := load("res://core/global/notification_manager.tres") as NotificationManager
var default_icon := preload("res://icon.svg")
var overlay_window_id: int

@onready var panel := $%PanelContainer as PanelContainer
@onready var texture := $%TextureRect as TextureRect
@onready var label := $%Label as Label
@onready var effect := $%SlideEffect as SlideEffect
@onready var timer := $%TimeoutTimer as Timer


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var xwayland := gamescope.get_xwayland(gamescope.XWAYLAND_TYPE_OGUI)
	if xwayland:
		var overlay_window_ids := xwayland.get_windows_for_pid(PID)
		if not overlay_window_ids.is_empty():
			overlay_window_id = overlay_window_ids[0]
	panel.visible = false
	# Subscribe to any notifications
	notification_manager.notification_queued.connect(_on_notification_queued)
	_on_notification_queued.call_deferred(null)
	
	# Continue showing any other queued messages
	var on_finished := func():
		var xwland := gamescope.get_xwayland(gamescope.XWAYLAND_TYPE_OGUI)
		if xwland:
			xwland.set_notification(overlay_window_id, 0)
		_on_notification_queued(null)
	effect.slide_out_finished.connect(on_finished)


# Show notifications when they are queued
func _on_notification_queued(_notify: Notification) -> void:
	if _is_showing():
		return
	# TODO: Only consume the notification if in in-game state
	var notify := notification_manager.next()
	if not notify:
		return
	var xwayland := gamescope.get_xwayland(gamescope.XWAYLAND_TYPE_OGUI)
	if xwayland:
		xwayland.set_notification(overlay_window_id, 1)	
	show_toast(notify.text, notify.icon, notify.timeout)


func _is_showing() -> bool:
	return panel.visible


# Shows the toast with the given text and icon which will be dismissed after
# the given timeout.
func show_toast(text: String, icon: Texture2D = null, timeout_sec: float = 5.0):
	# Set the toast's text and icon
	label.text = text
	texture.texture = default_icon
	if icon != null:
		texture.texture = icon
	
	# Setup and start the timer to dismiss the toast
	var hide_toast := func():
		notification_finished.emit()
	timer.timeout.connect(hide_toast, CONNECT_ONE_SHOT)
	timer.start(timeout_sec)
	notification_received.emit()
	
