extends Control

@onready var state_manager: StateManager = get_node("/root/Main/StateManager")
@onready var boxart_manager: BoxArtManager = get_node("/root/Main/BoxArtManager")
@onready var banner: TextureRect = $ScrollContainer/VBoxContainer/GameBanner
@onready var logo: TextureRect = $ScrollContainer/VBoxContainer/GameBanner/MarginContainer/GameLogo
@onready var launch_button: Button = $ScrollContainer/VBoxContainer/LaunchBarMargin/LaunchBar/LaunchButtonContainer/LaunchButton

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	state_manager.state_changed.connect(_on_state_changed)
	visible = false
	
	
func _on_state_changed(from: StateManager.State, to: StateManager.State, data: Dictionary):
	var is_visible = state_manager.has_state(StateManager.State.GAME_LAUNCHER)
	if not is_visible:
		visible = false
		return
	if to == StateManager.State.IN_GAME:
		state_manager.remove_state(StateManager.State.GAME_LAUNCHER)

	# Focus the first entry on state change
	launch_button.grab_focus.call_deferred()

	# Get the library item from the data passed by the state change
	if not "item" in data:
		push_error("No library item found to configure launcher!")
		visible = true
		return

	# Configure the game launch menu based on the library item
	var library_item: LibraryItem = data["item"]
	var launcher: Launcher = launch_button.get_node("Launcher")
	launcher.library_item = library_item

	# Load the banner for the game
	banner.texture = await boxart_manager.get_boxart_or_placeholder(library_item, BoxArtManager.Layout.BANNER)
	logo.texture = await boxart_manager.get_boxart_or_placeholder(library_item, BoxArtManager.Layout.LOGO)
	
	# Check if the app is installed or not
	if library_item.is_installed():
		launch_button.text = "Launch"
	else:
		launch_button.text = "Install"
	
	visible = true
	
