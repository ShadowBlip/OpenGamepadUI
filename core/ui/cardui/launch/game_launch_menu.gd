extends Control

var SettingsManager := preload("res://core/global/settings_manager.tres")
var LaunchManager := preload("res://core/global/launch_manager.tres")
var NotificationManager := preload("res://core/global/notification_manager.tres")
var BoxArtManager := preload("res://core/global/boxart_manager.tres")
var LibraryManager := preload("res://core/global/library_manager.tres")

var state_machine := (
	preload("res://assets/state/state_machines/global_state_machine.tres") as StateMachine
)
var launcher_state := preload("res://assets/state/states/game_launcher.tres") as State
var in_game_state := preload("res://assets/state/states/in_game.tres") as State
var game_settings_state := preload("res://assets/state/states/game_settings.tres") as State
var gamepad_settings_state := preload("res://assets/state/states/gamepad_settings.tres") as State
var installing := {}
var logger := Log.get_logger("GameLaunchMenu")

@export var launch_item: LibraryLaunchItem

@onready var banner: TextureRect = $%BannerTexture
@onready var logo: TextureRect = $%LogoTexture
@onready var launch_button: Button = $%LaunchButton
@onready var loading: Control = $%LoadingAnimation
@onready var player := $%AnimationPlayer
#@onready var progress_bar: ProgressBar = $%ProgressBar


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	launcher_state.state_entered.connect(_on_state_entered)
	launcher_state.state_exited.connect(_on_state_exited)
	launch_button.button_up.connect(_on_launch)


func _on_state_entered(_from: State) -> void:
	# Fade in the banner texture
	player.play("fade_in")
	
	# Focus the first entry on state change
	launch_button.grab_focus.call_deferred()

	# Get the library item from the data passed by the state change
	if not "item" in launcher_state.data:
		logger.error("No library item found to configure launcher!")
		return

	# Configure the game launch menu based on the library item provider
	var library_item: LibraryItem = launcher_state.data["item"]
	var provider := library_item.launch_items[0] as LibraryLaunchItem
	var section := "game.{0}".format([library_item.name.to_lower()])
	var provider_id = SettingsManager.get_value(section, "provider", "")
	if provider_id != "":
		var p := library_item.get_launch_item(provider_id)
		if p != null:
			provider = p
	launch_item = provider
	logger.info("Configured launcher for game: " + library_item.name)

	# Configure the game settings state with this game
	game_settings_state.data = launcher_state.data

	# Configure the controller settings state with this game 
	gamepad_settings_state.data = launcher_state.data

	# Check if the app is installed or not
	if library_item.is_installed():
		launch_button.text = "Launch"
	else:
		launch_button.text = "Install"
	if LaunchManager.is_running(library_item.name):
		launch_button.text = "Resume"

	# Set the launcher art to placeholders while we async load the right ones.
	banner.texture = BoxArtManager.get_placeholder(BoxArtProvider.LAYOUT.BANNER)
	logo.texture = BoxArtManager.get_placeholder(BoxArtProvider.LAYOUT.LOGO)

	# Play a loading animation while the art loads
	loading.visible = true

	# Load the banner for the game
	var banner_texture = await (
		BoxArtManager . get_boxart_or_placeholder(library_item, BoxArtProvider.LAYOUT.BANNER)
	)
	var logo_texture = await (
		BoxArtManager . get_boxart_or_placeholder(library_item, BoxArtProvider.LAYOUT.LOGO)
	)
	banner.texture = banner_texture
	logo.texture = logo_texture

	loading.visible = false


func _on_state_exited(to: State) -> void:
	if to == in_game_state:
		state_machine.remove_state(launcher_state)


func _on_launch() -> void:
	# Resume if the game is running already
	if LaunchManager.is_running(launch_item.name):
		state_machine.set_state([in_game_state])
		return

	# If the app isn't installed, install it.
	if not launch_item.installed:
		_on_install()
		return

	# Launch the game using launch manager
	LaunchManager.launch(launch_item)


func _on_install() -> void:
	# Do nothing if we're already installing
	if launch_item.name in installing and installing[launch_item.name]:
		return
	var notify := Notification.new("Installing " + launch_item.name)
	NotificationManager.show(notify)

	# Start the install
	LibraryManager.install(launch_item)
	installing[launch_item.name] = true
	launch_button.disabled = true

	# Update the progress bar with install progress
	#progress_bar.visible = true
	#var on_progress := func(item: LibraryLaunchItem, progress: float):
	#	progress_bar.value = progress * 100
	#LibraryManager.item_progressed.connect(on_progress)

	# Show a notification when install completes
	var on_installed := func(item: LibraryLaunchItem, success: bool):
		launch_button.disabled = false
		var verb: String
		if success:
			verb = "completed"
			item.installed = true
			launch_button.text = "Launch"
		else:
			verb = "failed"
		var install_msg := Notification.new("Install " + verb + " for " + item.name)
		NotificationManager.show(install_msg)
		installing[launch_item.name] = false
		#progress_bar.visible = false
		#LibraryManager.item_progressed.disconnect(on_progress)
	LibraryManager.item_installed.connect(on_installed, CONNECT_ONE_SHOT)

