extends Node
class_name StateChanger

enum Action {
	PUSH,
	POP,
	REPLACE,
	SET,
}

# Signal on our parent to connect to
@export var signal_name: String = "button_up"
# The state to change to when the given signal is emitted
@export var state: int = 0
# The action to perform with the state manager
@export var action: Action = Action.PUSH
# Data to pass with the state change
@export var data: Dictionary = {}
@export var state_manager_path: String = "/root/Main/StateManager"
@onready var parent: Node = get_parent()

func _ready() -> void:
	parent.connect(signal_name, _on_signal)

func _on_signal():
	# Switch to the given state
	var state_manager: StateManager = get_node(state_manager_path)

	# Manage the state based on the given action
	match action:
		Action.PUSH:
			state_manager.push_state(state, true, data)
		Action.POP:
			state_manager.pop_state()
		Action.REPLACE:
			state_manager.replace_state(state, true, data)
		Action.SET:
			state_manager.set_state([state])
