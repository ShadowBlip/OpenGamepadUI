extends Control

@onready var state_mgr: StateManager = get_node("/root/Main/StateManager")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	state_mgr.state_changed.connect(_on_state_changed)


func _on_state_changed(from: int, to: int):
	visible = to == StateManager.State.HOME
