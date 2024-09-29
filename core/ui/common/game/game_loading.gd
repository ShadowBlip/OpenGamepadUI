extends Control

var launch_manager := load("res://core/global/launch_manager.tres") as LaunchManager


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	launch_manager.app_launched.connect(_on_app_launched)


func _on_app_launched(app: RunningApp):
	visible = true
	app.app_type_detected.connect(_on_window_created, CONNECT_ONE_SHOT)
	app.app_killed.connect(_on_window_created, CONNECT_ONE_SHOT)


func _on_window_created() -> void:
	visible = false
