extends Control

var state_machine := (
	preload("res://assets/state/state_machines/global_state_machine.tres") as StateMachine
)
const quick_bar_state_machine := preload("res://assets/state/state_machines/quick_bar_state_machine.tres")
const qb_card_scene := preload("res://core/ui/card_ui/quick_bar/qb_card.tscn")	

var launch_manager := load("res://core/global/launch_manager.tres") as LaunchManager
var quick_bar_menu_state := preload("res://assets/state/states/quick_bar_menu.tres") as State
var qb_focus := preload("res://core/ui/card_ui/quick_bar/quick_bar_menu_focus.tres") as FocusStack

@onready var viewport: VBoxContainer = $%Viewport
@onready var focus_group := $%FocusGroup as FocusGroup
@onready var playing_container := $%PlayingNowContainer
@onready var game_label := $%GameNameLabel
@onready var notify_button := $%NotifyButton
@onready var notify_card := $%NotificationsCard


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	quick_bar_menu_state.state_entered.connect(_on_state_entered)
	quick_bar_menu_state.state_exited.connect(_on_state_exited)
	launch_manager.app_switched.connect(_on_app_switched)

	# Handle when the notifications button is pressed
	var on_notify_pressed := func():
		open_notifications()
	notify_button.pressed.connect(on_notify_pressed)


func open_notifications() -> void:
	notify_card.grab_focus()
	notify_card._on_pressed()


func _on_state_entered(_from: State) -> void:
	if focus_group:
		focus_group.grab_focus()


func _on_state_exited(_to: State) -> void:
	qb_focus.pop()


func _on_app_switched(_from: RunningApp, to: RunningApp) -> void:
	if to == null:
		playing_container.visible = false
		return

	playing_container.visible = true
	game_label.text = to.launch_item.name
	# TODO: Implement fetching game icon and setting it


# Adds the given Control menu to the quick bar. A focus node can be given which will
# be the first node to focus
func add_child_menu(qb_item: Control, icon: Texture2D, focus_node: Control = null, title: String = ""):
	# Create a qucik bar card
	var qb_card := qb_card_scene.instantiate()
	var content := qb_card.get_node("MarginContainer/CardVBoxContainer/ContentContainer")
	content.add_child(qb_item)

	# Backwards compatibility
	# If no title was specified, try to find a section label to use instead
	if title == "":
		var section := qb_item.find_child("SectionLabel")
		if section.get("text") != null:
			title = section.text
			section.queue_free()
		else:
			title = "Plugin"
	qb_card.title = title

	# Backwards compatibility
	# Replace FocusManager with FocusGroup
	var focus_manager := qb_item.find_child("FocusManager")
	if focus_manager:
		var focus_parent := focus_manager.get_parent()
		focus_manager.queue_free()
		var focus_group := FocusGroup.new()
		focus_group.focus_stack = load("res://core/ui/card_ui/qb/quick_bar_menu_focus.tres")
		focus_parent.add_child(focus_group)

	viewport.add_child(qb_card)
