extends Node
class_name Launcher

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
	# Launch the game using launch manager
	var launch_manager: LaunchManager = get_node("/root/Main/LaunchManager")
	launch_manager.launch(library_item.launch_items[launcher_index])
