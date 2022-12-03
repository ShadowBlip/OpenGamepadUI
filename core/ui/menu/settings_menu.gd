extends Control

enum STATES {
	NONE,
	GENERAL,
	MANAGE_PLUGINS,
	PLUGIN_STORE,
	POWER,
}

@onready var local_state_manager := $StateManager
@onready var state_manager: StateManager = get_node("/root/Main/StateManager")
@onready var general_button := $MainContainer/MenuMarginContainer/VBoxContainer/GeneralButton
@onready var button_container := $MainContainer/MenuMarginContainer/VBoxContainer

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	state_manager.state_changed.connect(_on_state_changed)

func _on_state_changed(from: StateManager.State, to: StateManager.State, data: Dictionary):
	var is_visible = state_manager.has_state(StateManager.State.SETTINGS)
	if not is_visible:
		visible = false
		return
	if to == StateManager.State.IN_GAME:
		state_manager.remove_state(StateManager.State.SETTINGS)

	general_button.grab_focus.call_deferred()
	visible = true

func _on_local_state_change(from: int, to: int, data: Dictionary) -> void:
	pass
