extends Control

var default_icon := preload("res://icon.svg")

signal toast_finished

@onready var notification_container := $ToastContainer/NotificationContainer
@onready var progress_bar := $ToastContainer/ProgressBar
@onready var action_button := $ToastContainer/ActionsContainer/ActionButton
@onready var dismiss_button := $ToastContainer/ActionsContainer/DismissButton
@onready var animation_player := $AnimationPlayer
@onready var timer := $TimeoutTimer

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	visible = false
	animation_player.animation_finished.connect(_on_animation_finished)
	dismiss_button.pressed.connect(dismiss)


# Handle when the dismiss button is pressed
func dismiss() -> void:
	timer.stop()
	animation_player.play("hide")


func _on_animation_finished(anim_name: String):
	if anim_name != "hide":
		return
	toast_finished.emit()


# Does literally nothing
func _do_nothing() -> void:
	pass
	

func is_showing() -> bool:
	return animation_player.is_playing()


# Shows the toast with the given text and icon which will be dismissed after
# the given timeout.
func show_toast(text: String, icon: Texture2D = null, timeout_sec: float = 5.0, show_action: bool = false):
	# Set the toast's text and icon
	notification_container.text = text
	notification_container.icon_texture = default_icon
	if icon != null:
		notification_container.icon_texture = icon
	
	# Setup and start the timer to dismiss the toast
	var hide := func ():
		animation_player.play("hide")
	timer.timeout.connect(hide, CONNECT_ONE_SHOT)
	timer.start(timeout_sec)
	
	# Show/hide the action button
	action_button.visible = show_action
	
	# Play the show animation to show the toast
	animation_player.play("show")


# Shows the toast with the given text and icon and an action to perform.
func show_action_toast(text: String, icon: Texture2D = null, timeout_sec: float = 5.0, action_text: String = "Action", action: Callable = _do_nothing):
	# Set the action on the action button
	action_button.pressed.connect(action, CONNECT_ONE_SHOT)
	action_button.text = action_text
	
	# Set the toast's text and icon
	show_toast(text, icon, timeout_sec, true)
