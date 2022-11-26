extends Node
class_name InputManager

@onready var main: Main = get_node("..")
@onready var launch_manager: LaunchManager = get_node("../LaunchManager")
@onready var state_manager: StateManager = get_node("../StateManager")

func _ready() -> void:
	state_manager.state_changed.connect(_on_state_changed)


# Set focus will use Gamescope to focus OpenGamepadUI
func set_focus(focused: bool) -> void:
	# Sets ourselves to the input focus
	var window_id = main.overlay_window_id
	if focused:
		print_debug("Focusing overlay")
		Gamescope.set_xprop(window_id, "STEAM_INPUT_FOCUS", "32c", "1")
		return
	print_debug("Un-focusing overlay")
	Gamescope.set_xprop(window_id, "STEAM_INPUT_FOCUS", "32c", "0")


# Set ourselves to focused in any state other than IN_GAME
func _on_state_changed(from: int, to: int):
	if to == StateManager.State.IN_GAME:
		set_focus(false)
		return
	set_focus(true)


func _input(event: InputEvent) -> void:
	var state = state_manager.current_state()
	
	# Handle "guide" button presses
	if event.is_action_pressed("ogui_guide"):
		# Handle cases where a game is running
		if state_manager.has_state(StateManager.State.IN_GAME):
			# If we're in game, pull up the in-game menu
			if state == StateManager.State.IN_GAME:
				state_manager.push_state(StateManager.State.IN_GAME_MENU)
			# If we're not in game, go back
			else:
				state_manager.replace_state(StateManager.State.IN_GAME)
				
		# Handle opening the main menu outside of a running game
		elif state == StateManager.State.MAIN_MENU:
			print("Removing mm state")
			state_manager.remove_state(StateManager.State.MAIN_MENU)
		elif state != StateManager.State.MAIN_MENU:
			print("Adding mm state")
			state_manager.push_state(StateManager.State.MAIN_MENU)
