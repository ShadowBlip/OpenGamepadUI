extends Control

var state_machine := preload("res://assets/state/state_machines/global_state_machine.tres") as StateMachine
var quick_bar_state_machine := preload("res://assets/state/state_machines/quick_bar_state_machine.tres") as StateMachine
var quick_bar_menu_state := preload("res://assets/state/states/quick_bar_menu.tres") as State

@onready var glass_rect := %GlassRect
@onready var focus_group := %FocusGroup as FocusGroup


func _ready() -> void:
	quick_bar_menu_state.state_entered.connect(_on_state_entered)
	quick_bar_menu_state.state_exited.connect(_on_state_exited)
	
	
func _on_state_entered(_from: State) -> void:
	if focus_group:
		focus_group.grab_focus()


func _on_state_exited(_to: State) -> void:
	pass
