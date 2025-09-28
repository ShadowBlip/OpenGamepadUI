extends Control

signal load_started

var launch_manager := load("res://core/global/launch_manager.tres") as LaunchManager
var state_machine := (
	preload("res://assets/state/state_machines/global_state_machine.tres") as StateMachine
)
var menu_state := preload("res://assets/state/states/menu.tres") as State
var popup_state := preload("res://assets/state/states/popup.tres") as State
var in_game_state := preload("res://assets/state/states/in_game.tres") as State
var game_launching := false

@onready var fade_effect := $FadeEffect as FadeEffect
@onready var label := %RichTextLabel as RichTextLabel
@onready var progress_bar := %ProgressBar as ProgressBar


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	launch_manager.app_launched.connect(_on_app_launched)
	launch_manager.app_lifecycle_progressed.connect(_on_app_lifecycle_progress)
	launch_manager.app_lifecycle_notified.connect(_on_app_lifecycle_notified)

	var on_state_changed := func(_from: State, to: State):
		if not game_launching:
			visible = false
			return
		visible = to in [in_game_state, popup_state]
	state_machine.state_changed.connect(on_state_changed)


func _on_app_launched(app: RunningApp):
	game_launching = true
	label.text = "Loading..."
	progress_bar.visible = false
	app.app_type_detected.connect(_on_window_created, CONNECT_ONE_SHOT)
	app.app_killed.connect(_on_window_created, CONNECT_ONE_SHOT)


func _on_window_created() -> void:
	game_launching = false
	await get_tree().create_timer(0.5).timeout
	fade_effect.fade_out()


## Executed if a pre-launch app lifecycle hook is running and wants to display
## progress on the loading screen
func _on_app_lifecycle_progress(progress: float, type: AppLifecycleHook.TYPE) -> void:
	if type != AppLifecycleHook.TYPE.PRE_LAUNCH:
		return
	progress_bar.visible = true
	progress_bar.value = progress


## Executed if a pre-launch app lifecycle hook is running and wants to display
## progress text on the loading screen
func _on_app_lifecycle_notified(text: String, type: AppLifecycleHook.TYPE) -> void:
	if type != AppLifecycleHook.TYPE.PRE_LAUNCH:
		return
	label.text = text
