extends Control

const RunningGameCard := preload("res://core/ui/cardui/navigation/running_game_card.gd")
const running_card_scene := preload("res://core/ui/cardui/navigation/running_game_card.tscn")

var launch_manager := load("res://core/global/launch_manager.tres") as LaunchManager
var state_machine := preload("res://assets/state/state_machines/global_state_machine.tres") as StateMachine
var main_menu_state := preload("res://assets/state/states/main_menu.tres") as State
var in_game_menu_state := preload("res://assets/state/states/in_game_menu.tres") as State
var menu_focus := preload("res://core/ui/cardui/main-menu/main_menu_focus.tres") as FocusStack

@onready var button_container := $%ButtonContainer
@onready var focus_group := $%FocusGroup as FocusGroup


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	main_menu_state.state_entered.connect(_on_state_entered)
	main_menu_state.state_exited.connect(_on_state_exited)
	launch_manager.app_launched.connect(_on_app_launched)
	
	# Hack because we decided to have different states for main menu and in-game menu
	var on_in_game_menu := func(_from: State):
		state_machine.replace_state(main_menu_state)
	in_game_menu_state.state_entered.connect(on_in_game_menu)


func _on_state_entered(_from: State) -> void:
	if state_machine.current_state() != main_menu_state:
		return
	if focus_group:
		focus_group.grab_focus()


func _on_state_exited(_to: State) -> void:
	menu_focus.pop()


func _on_app_launched(app: RunningApp):
	# Create a new running game card
	var card: RunningGameCard = running_card_scene.instantiate()

	# Switch to the app if its card is pressed
	var on_pressed := func():
		launch_manager.set_current_app(app)
	card.pressed.connect(on_pressed)

	# Remove the card when it is killed
	var on_app_killed := func():
		card.queue_free()
	app.app_killed.connect(on_app_killed)

	# Add and move the card to the menu
	button_container.add_child(card)
	button_container.move_child(card, 0)
	card.set_running_app(app)
