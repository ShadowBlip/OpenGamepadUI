extends Control

@onready var state_mgr: StateManager = get_node("/root/Main/StateManager")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	visible = false
	get_parent().visible = false
	state_mgr.state_changed.connect(_on_state_changed)


func _on_state_changed(from: int, to: int):
	visible = to == StateManager.State.MAIN_MENU or to == StateManager.State.IN_GAME_MENU
	get_parent().visible = visible


func _on_home_button_button_up() -> void:
	state_mgr.replace_state(StateManager.State.HOME)
