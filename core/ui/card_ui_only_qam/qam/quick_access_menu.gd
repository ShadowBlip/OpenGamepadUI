extends Control

var state_machine := (
	preload("res://assets/state/state_machines/global_state_machine.tres") as StateMachine
)
const qam_state_machine := preload("res://assets/state/state_machines/qam_state_machine.tres")
const qam_card_scene := preload("res://core/ui/card_ui/qam/qam_card.tscn")

var launch_manager := load("res://core/global/launch_manager.tres") as LaunchManager
var qam_state := preload("res://assets/state/states/quick_access_menu.tres") as State
var qam_focus := preload("res://core/ui/card_ui/qam/quick_access_menu_focus.tres") as FocusStack

@onready var viewport: VBoxContainer = $%Viewport
@onready var focus_group := $%FocusGroup as FocusGroup
@onready var playing_container := $%PlayingNowContainer
@onready var game_label := $%GameNameLabel


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	qam_state.state_entered.connect(_on_state_entered)
	qam_state.state_exited.connect(_on_state_exited)
	launch_manager.app_switched.connect(_on_app_switched)

func _on_state_entered(_from: State) -> void:
	if focus_group:
		focus_group.grab_focus()


func _on_state_exited(_to: State) -> void:
	qam_focus.pop()


func _on_app_switched(_from: RunningApp, to: RunningApp) -> void:
	if to == null:
		playing_container.visible = false
		return

	playing_container.visible = true
	game_label.text = to.launch_item.name
	# TODO: Implement fetching game icon and setting it


# Adds the given Control menu to the QAM. A focus node can be given which will
# be the first node to focus
func add_child_menu(qam_item: Control, icon: Texture2D, focus_node: Control = null, title: String = ""):
	# Create a QAM card
	var qam_card := qam_card_scene.instantiate()
	var content := qam_card.get_node("MarginContainer/CardVBoxContainer/ContentContainer")
	content.add_child(qam_item)

	# Backwards compatibility
	# If no title was specified, try to find a section label to use instead
	if title == "":
		var section := qam_item.find_child("SectionLabel")
		if section.get("text") != null:
			title = section.text
			section.queue_free()
		else:
			title = "Plugin"
	qam_card.title = title

	# Backwards compatibility
	# Replace FocusManager with FocusGroup
	var focus_manager := qam_item.find_child("FocusManager")
	if focus_manager:
		var focus_parent := focus_manager.get_parent()
		focus_manager.queue_free()
		var focus_group := FocusGroup.new()
		focus_group.focus_stack = load("res://core/ui/card_ui/qam/quick_access_menu_focus.tres")
		focus_parent.add_child(focus_group)

	viewport.add_child(qam_card)
