extends Control

var launch_manager := preload("res://core/global/launch_manager.tres") as LaunchManager
var state_machine := preload("res://assets/state/state_machines/global_state_machine.tres") as StateMachine
var quick_bar_state_machine := preload("res://assets/state/state_machines/quick_bar_state_machine.tres") as StateMachine
var quick_bar_menu_state := preload("res://assets/state/states/quick_bar_menu.tres") as State

@onready var glass_rect := %GlassRect
@onready var focus_group := %FocusGroup as FocusGroup
@onready var exit_button := %ExitGameButton as CollapsibleButton
@onready var performance_button := %PerformanceButton as CollapsibleButton
@onready var back_button := %BackButton as CollapsibleButton

@onready var menu := %MainContainer as Control
@onready var sub_menu := %SubMenuContainer as Control
@onready var performance_menu := %Performance as Control

func _ready() -> void:
	quick_bar_menu_state.state_entered.connect(_on_state_entered)
	quick_bar_menu_state.state_exited.connect(_on_state_exited)
	launch_manager.app_launched.connect(_on_app_launched)
	launch_manager.app_stopped.connect(_on_app_stopped)
	performance_button.button_up.connect(_on_submenu_switch.bind(performance_menu))
	back_button.button_up.connect(_on_back_button_pressed)


func _on_state_entered(_from: State) -> void:
	if focus_group:
		focus_group.grab_focus()


func _on_state_exited(_to: State) -> void:
	pass


func _on_app_launched(_app: RunningApp) -> void:
	exit_button.visible = true


func _on_app_stopped(_app: RunningApp) -> void:
	if launch_manager.get_running().is_empty():
		exit_button.visible = false


func _on_submenu_switch(menu_to_switch_to: Control) -> void:
	sub_menu.visible = true
	menu_to_switch_to.visible = true
	menu.visible = false
	var focusable := FocusGroup.find_focusable([menu_to_switch_to])
	if focusable:
		focusable.grab_focus.call_deferred()


func _on_back_button_pressed() -> void:
	sub_menu.visible = false
	menu.visible = true
	var focusable := FocusGroup.find_focusable([menu])
	if focusable:
		focusable.grab_focus.call_deferred()



func _input(event: InputEvent) -> void:
	if state_machine.current_state() != quick_bar_menu_state:
		return
	if event.is_action_released("ogui_back") or event.is_action_released("ogui_east"):
		_on_back_button_pressed()
		get_viewport().set_input_as_handled()
		return
