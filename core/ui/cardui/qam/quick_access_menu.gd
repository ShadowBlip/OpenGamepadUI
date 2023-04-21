extends Control

var state_machine := (
	preload("res://assets/state/state_machines/global_state_machine.tres") as StateMachine
)
const qam_state_machine := preload("res://assets/state/state_machines/qam_state_machine.tres")
const qam_card_scene := preload("res://core/ui/cardui/qam/qam_card.tscn")

var launch_manager := load("res://core/global/launch_manager.tres") as LaunchManager
var qam_state := preload("res://assets/state/states/quick_access_menu.tres") as State

@onready var viewport: VBoxContainer = $%Viewport
@onready var focus_group := $%FocusGroup as FocusGroup
@onready var playing_container := $%PlayingNowContainer
@onready var game_label := $%GameNameLabel


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	qam_state.state_entered.connect(_on_state_entered)


func _on_state_entered(_from: State) -> void:
	# Update the "playing now" container
	_update_playing_now()
	
	if focus_group:
		focus_group.grab_focus()


func _update_playing_now() -> void:
	if launch_manager.get_running().size() == 0:
		playing_container.visible = false
		return
	var app := launch_manager.get_current_app()
	playing_container.visible = true
	game_label.text = app.launch_item.name
	# TODO: Implement fetching game icon and setting it


# Adds the given Control menu to the QAM. A focus node can be given which will
# be the first node to focus
func add_child_menu(qam_item: Control, icon: Texture2D, focus_node: Control = null):
	print("ADD QAM ITEM: ", qam_item)

	# TODO: Backwards compatibility
	# Replace FocusManager with FocusGroup

	# Create a QAM card
	var qam_card := qam_card_scene.instantiate()
	viewport.add_child(qam_card)
