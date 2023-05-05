extends Control

var LaunchManager := load("res://core/global/launch_manager.tres") as LaunchManager
var BoxArtManager := load("res://core/global/boxart_manager.tres") as BoxArtManager
var LibraryManager := load("res://core/global/library_manager.tres") as LibraryManager
var state_machine := (
	preload("res://assets/state/state_machines/global_state_machine.tres") as StateMachine
)
var in_game_menu_state := preload("res://assets/state/states/in_game_menu.tres") as State
var in_game_state := preload("res://assets/state/states/in_game.tres") as State

@onready var resume_button := $%ResumeButton
@onready var game_logo: TextureRect = $%GameLogo
@onready var button_container := $%ButtonContainer


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	visible = false
	in_game_menu_state.state_entered.connect(_on_game_menu_entered)
	in_game_state.state_entered.connect(_on_game_state_entered)
	in_game_state.state_removed.connect(_on_game_state_removed)
	LaunchManager.app_launched.connect(_on_app_launched)
	LaunchManager.app_stopped.connect(_on_app_closed)
	LaunchManager.app_switched.connect(_on_app_switched)


func _on_game_menu_entered(_from: State) -> void:
	resume_button.grab_focus.call_deferred()


func _on_game_state_entered(_from: State) -> void:
	visible = true


func _on_game_state_removed() -> void:
	visible = false


func _on_resume_button_button_up() -> void:
	state_machine.set_state([in_game_state])


func _on_exit_button_button_up() -> void:
	# TODO: Handle this better
	LaunchManager.stop(LaunchManager.get_current_app())


func _on_app_launched(app: RunningApp):
	print("APP LAUNCHED!!!", app.launch_item.name)
	var item := LibraryManager.get_app_by_name(app.launch_item.name)
	print("Found library item: ", item)
	if not item:
		print("No library item!")
		return
	game_logo.visible = false
	var logo := await BoxArtManager.get_boxart(item, BoxArtProvider.LAYOUT.LOGO) as Texture2D
	print("Found boxart: ", logo)
	game_logo.texture = logo
	game_logo.visible = true


func _on_app_closed(app: RunningApp):
	print("App was CLOSED! ", app.launch_item.name)
	game_logo.texture = null


func _on_app_switched(_from: RunningApp, to: RunningApp):
	if not to:
		return
	_on_app_launched(to)
