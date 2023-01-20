extends Control

@onready var state_mgr: StateManager = get_node("/root/Main/StateManager")
@onready var launch_mgr: LaunchManager = get_node("/root/Main/LaunchManager")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	visible = false
	state_mgr.state_changed.connect(_on_state_changed)


func _on_state_changed(from: int, to: int, _data: Dictionary):
	# Set the resume button focus
	if to == StateManager.STATE.IN_GAME_MENU:
		var button: Button = $MarginContainer/VBoxContainer/ResumeButton
		button.grab_focus.call_deferred()
	
	# If we're no longer in-game, remove ourselves from the state stack.
	if not state_mgr.has_state(StateManager.STATE.IN_GAME) and state_mgr.has_state(StateManager.STATE.IN_GAME_MENU):
		state_mgr.remove_state(StateManager.STATE.IN_GAME_MENU)
	
	# If we're not switching to the in-game state, disable ourselves
	if to != StateManager.STATE.IN_GAME_MENU:
		visible = false
		return
	visible = true


func _on_resume_button_button_up() -> void:
	state_mgr.replace_state(StateManager.STATE.IN_GAME)


func _on_exit_button_button_up() -> void:
	# TODO: Handle this better
	launch_mgr.stop(launch_mgr.running[-1])
