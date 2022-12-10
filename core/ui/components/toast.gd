extends Control

var default_icon := preload("res://icon.svg")

@onready var icon_rect := $ToastContainer/PanelContainer/MarginContainer/ContentContainer/IconContainer/Icon
@onready var label := $ToastContainer/PanelContainer/MarginContainer/ContentContainer/Label
@onready var progress_bar := $ToastContainer/ProgressBar
@onready var action_button := $ToastContainer/ActionsContainer/ActionButton
@onready var dismiss_button := $ToastContainer/ActionsContainer/DismissButton
@onready var animation_player := $AnimationPlayer
@onready var timer := $TimeoutTimer

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	visible = false
	dismiss_button.pressed.connect(dismiss)


# Handle when the dismiss button is pressed
func dismiss() -> void:
	timer.stop()
	animation_player.play("hide")


# Does literally nothing
func _do_nothing() -> void:
	pass

# Shows the toast with the given text and icon which will be dismissed after
# the given timeout.
func show_toast(text: String, icon: Texture2D = null, timeout_sec: float = 5.0, show_action: bool = false):
	# Set the toast's text and icon
	label.text = text
	icon_rect.texture = default_icon
	if icon != null:
		icon_rect.texture = icon
	
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
