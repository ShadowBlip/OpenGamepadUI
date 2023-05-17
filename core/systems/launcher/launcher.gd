@icon("res://assets/icons/loader.svg")
extends Node
class_name Launcher

const LaunchManager := preload("res://core/global/launch_manager.tres")
var LibraryManager := preload("res://core/global/library_manager.tres")
const NotificationManager := preload("res://core/global/notification_manager.tres")

var state_machine := (
	preload("res://assets/state/state_machines/global_state_machine.tres") as StateMachine
)
var in_game_state := preload("res://assets/state/states/in_game.tres") as State
var installing := {}

# The library item to launch
@export var launch_item: LibraryLaunchItem
# Signal on our parent to connect to
@export var signal_name: String = "button_up"

@onready var parent: Node = get_parent()


func _ready() -> void:
	parent.connect(signal_name, _on_launch)


func _on_launch():
	# Resume if the game is running already
	if LaunchManager.is_running(launch_item.name):
		state_machine.set_state([in_game_state])
		return

	# If the app isn't installed, install it.
	if not launch_item.installed:
		if launch_item.name in installing and installing[launch_item.name]:
			return
		var notify := Notification.new("Installing " + launch_item.name)
		NotificationManager.show(notify)
		LibraryManager.install(launch_item)
		LibraryManager.item_installed.connect(_on_installed)
		installing[launch_item.name] = true
		return

	# Launch the game using launch manager
	LaunchManager.launch(launch_item)


func _on_installed(item: LibraryLaunchItem, success: bool) -> void:
	var verb := "failed"
	if success:
		verb = "completed"
	var notify := Notification.new("Install " + verb + " for " + item.name)
	NotificationManager.show(notify)
	installing[launch_item.name] = false
