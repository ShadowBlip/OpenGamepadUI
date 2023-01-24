@icon("res://assets/icons/loader.svg")
extends Node
class_name Launcher

var state_machine := preload("res://assets/state/state_machines/global_state_machine.tres") as StateMachine
var in_game_state := preload("res://assets/state/states/in_game.tres") as State

# The library item to launch
@export var library_item: LibraryItem
# Which LibraryLaunchItem in the library item to use to launch the application
@export var launcher_index: int = 0
# Signal on our parent to connect to
@export var signal_name: String = "button_up"

@onready var parent: Node = get_parent()

func _ready() -> void:
	parent.connect(signal_name, _on_launch)


func _on_launch():
	# Resume if the game is running already
	if LaunchManager.is_running(library_item.name):
		state_machine.set_state([in_game_state])
		return
	# Launch the game using launch manager
	LaunchManager.launch(library_item.launch_items[launcher_index])
