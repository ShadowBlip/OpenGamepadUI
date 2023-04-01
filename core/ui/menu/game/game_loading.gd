extends Control

var launch_manager := load("res://core/global/launch_manager.tres") as LaunchManager



# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var on_app_launched := func(app: RunningApp):
		visible = true
		app.window_id_changed.connect(_on_window_created, CONNECT_ONE_SHOT)
		app.app_killed.connect(_on_window_created, CONNECT_ONE_SHOT)
	launch_manager.app_launched.connect(on_app_launched)


func _on_window_created() -> void:
	visible = false
