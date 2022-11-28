extends Node
class_name Launcher

# The command for the launcher to execute
@export var cmd: String
# Arguments to the command to launch
@export var args: PackedStringArray
# Signal on our parent to connect to
@export var signal_name: String = "button_up"
# If true, will launch the game directly, bypassing the launch menu
@export var direct: bool = false

@onready var parent: Node = get_parent()

func _ready() -> void:
	parent.connect(signal_name, _on_launch)

func _on_launch():
	# Launch the game directly if direct is true
	if direct:
		var launch_manager: LaunchManager = get_node("/root/Main/LaunchManager")
		launch_manager.launch(cmd, args)
		return

	# Push the game launcher state
	if not parent.library_item:
		push_error("Parent node has no library item set!")
		return

	# Switch to the game launcher state
	var state_manager: StateManager = get_node("/root/Main/StateManager")
	state_manager.push_state(StateManager.State.GAME_LAUNCHER, true, {"item": parent.library_item})
