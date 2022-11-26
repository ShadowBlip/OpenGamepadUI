extends Control

@onready var state_mgr: StateManager = get_node("/root/Main/StateManager")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	state_mgr.state_changed.connect(_on_state_changed)

	# Grab the first button as focus
	var button: Button = $MarginContainer/HBoxContainer/Button
	button.grab_focus.call_deferred()

func _on_state_changed(from: int, to: int):
	visible = state_mgr.has_state(StateManager.State.HOME)
	if visible and to == StateManager.State.IN_GAME:
		state_mgr.remove_state(StateManager.State.HOME)
	if to == StateManager.State.HOME:
		# Grab the first button as focus
		var button: Button = $MarginContainer/HBoxContainer/Button
		button.grab_focus.call_deferred()
