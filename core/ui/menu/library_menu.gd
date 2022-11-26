extends Control

@onready var state_manager: StateManager = get_node("/root/Main/StateManager")
@onready var library_manager: LibraryManager = get_node("/root/Main/LibraryManager")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	state_manager.state_changed.connect(_on_state_changed)
	visible = false


func _on_state_changed(from: StateManager.State, to: StateManager.State) -> void:
	visible = state_manager.has_state(StateManager.State.LIBRARY)
	if not visible:
		return
	if visible and to == StateManager.State.IN_GAME:
		state_manager.remove_state(StateManager.State.LIBRARY)
