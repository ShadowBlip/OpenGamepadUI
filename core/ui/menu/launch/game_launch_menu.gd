extends Control

var state_machine := preload("res://assets/state/state_machines/global_state_machine.tres") as StateMachine
var launcher_state := preload("res://assets/state/states/game_launcher.tres") as State
var in_game_state := preload("res://assets/state/states/in_game.tres") as State
var logger := Log.get_logger("GameLaunchMenu")

@onready var banner: TextureRect = $ScrollContainer/VBoxContainer/GameBanner
@onready var logo: TextureRect = $ScrollContainer/VBoxContainer/GameBanner/MarginContainer/GameLogo
@onready var launch_button: Button = $ScrollContainer/VBoxContainer/LaunchBarMargin/LaunchBar/LaunchButtonContainer/LaunchButton


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	launcher_state.state_entered.connect(_on_state_entered)
	launcher_state.state_exited.connect(_on_state_exited)
	
	
func _on_state_entered(_from: State) -> void:
	# Focus the first entry on state change
	launch_button.grab_focus.call_deferred()

	# Get the library item from the data passed by the state change
	if not "item" in launcher_state.data:
		logger.error("No library item found to configure launcher!")
		return

	# Configure the game launch menu based on the library item
	var library_item: LibraryItem = launcher_state.data["item"]
	var launcher: Launcher = launch_button.get_node("Launcher")
	launcher.library_item = library_item
	logger.info("Configured launcher for game: " + library_item.name)

	# Load the banner for the game
	banner.texture = await BoxArtManager.get_boxart_or_placeholder(library_item, BoxArtProvider.LAYOUT.BANNER)
	logo.texture = await BoxArtManager.get_boxart_or_placeholder(library_item, BoxArtProvider.LAYOUT.LOGO)
	
	# Check if the app is installed or not
	if library_item.is_installed():
		launch_button.text = "Launch"
	else:
		launch_button.text = "Install"
	if LaunchManager.is_running(library_item.name):
		launch_button.text = "Resume"


func _on_state_exited(to: State) -> void:
	if to == in_game_state:
		state_machine.remove_state(launcher_state)
