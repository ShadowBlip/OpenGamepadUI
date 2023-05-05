extends Control

var LaunchManager := preload("res://core/global/launch_manager.tres") as LaunchManager
var state_machine := preload("res://assets/state/state_machines/global_state_machine.tres") as StateMachine
var main_menu_state := preload("res://assets/state/states/main_menu.tres") as State
var in_game_menu_state := preload("res://assets/state/states/in_game_menu.tres") as State
var running_apps := {}
var running_buttons := {}

@onready var focus_node := $%HomeButton
@onready var button_container := $%ButtonContainer
@onready var separator := $%HSeparator

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	main_menu_state.state_entered.connect(_on_state_entered)
	in_game_menu_state.state_entered.connect(_on_state_entered)
	LaunchManager.app_launched.connect(_on_app_launched)
	LaunchManager.app_stopped.connect(_on_app_closed)
	
	
func _on_state_entered(_from: State) -> void:
	if state_machine.current_state() == main_menu_state:
		focus_node.grab_focus.call_deferred()


func _on_app_launched(app: RunningApp):
	separator.visible = true
	running_apps[app.launch_item.name] = app
	var button := Button.new()
	button.name = app.launch_item.name
	button.text = app.launch_item.name
	var on_button_up := func():
		LaunchManager.set_current_app(app)
	button.button_up.connect(on_button_up)
	running_buttons[app.launch_item.name] = button
	button_container.add_child(button)
	button_container.move_child(button, 0)
	

func _on_app_closed(app: RunningApp):
	var button := running_buttons[app.launch_item.name] as Button
	button.queue_free()
	running_buttons.erase(app.launch_item.name)
	running_apps.erase(app.launch_item.name)
	if len(running_apps) == 0:
		separator.visible = false
