extends Control

const qam_state_machine := preload("res://assets/state/state_machines/qam_state_machine.tres")
const OGUIButton := preload("res://core/ui/components/button.tscn")
const transition_fade_in := preload("res://core/ui/components/transition_fade_in.tscn")
var qam_state := preload("res://assets/state/states/quick_access_menu.tres") as State

@onready var icon_bar: VBoxContainer = $MarginContainer/HBoxContainer/IconBar
@onready var viewport: VBoxContainer = $MarginContainer/HBoxContainer/Viewport
@onready var notifications_menu: HFlowContainer = $MarginContainer/HBoxContainer/Viewport/NotificationsMenu
@onready var quick_settings_menu: Node = $MarginContainer/HBoxContainer/Viewport/QuickSettingsMenu


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	visible = false
	qam_state.state_entered.connect(_on_state_entered)
	qam_state.state_exited.connect(_on_state_exited)


func _on_state_entered(_from: State) -> void:
	visible = true
	var button: Button = icon_bar.get_child(0)
	button.grab_focus()


func _on_state_exited(_to: State) -> void:
	visible = false


func add_child_menu(qam_item: Control, icon: Texture2D):
	var qam := self
	
	var first_qam_item : Node
	var last_qam_item : Node
	
	# Plugin viewport
	qam_item.visible = false
	qam.viewport.add_child(qam_item)

	# Get existing children so we can manage focus
	var qam_children := qam.icon_bar.get_child_count()
	if qam_children > 0:
		first_qam_item = qam.icon_bar.get_child(0)
		last_qam_item = qam.icon_bar.get_child(qam_children-1)
	print(first_qam_item.name)
	print(last_qam_item.name)
	
	## Plugin menu button
	var plugin_button := OGUIButton.instantiate()
	plugin_button.icon = icon
	plugin_button.custom_minimum_size = Vector2(50, 50)
	plugin_button.expand_icon = true
	plugin_button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	plugin_button.pressed.connect(qam_item._on_pressed)
	qam.icon_bar.add_child(plugin_button)
	print(get_path_to(plugin_button))
	
	# Set up new button's focus
	plugin_button.focus_mode = Control.FOCUS_ALL
	plugin_button.focus_neighbor_bottom = "../" + first_qam_item.name
	plugin_button.focus_neighbor_left = "../" + last_qam_item.name
	plugin_button.focus_neighbor_right = "../" + first_qam_item.name
	plugin_button.focus_neighbor_top = "../" + last_qam_item.name
	plugin_button.focus_next = "../" + first_qam_item.name
	plugin_button.focus_previous = "../" + last_qam_item.name
	
	# Update existing focus buttons.
	first_qam_item.focus_neighbor_left = "../" + plugin_button.name
	first_qam_item.focus_neighbor_top = "../" + plugin_button.name
	first_qam_item.focus_previous = "../" + plugin_button.name
	last_qam_item.focus_neighbor_bottom = "../" + plugin_button.name
	last_qam_item.focus_neighbor_right = "../" + plugin_button.name
	last_qam_item.focus_next = "../" + plugin_button.name
	
	# Replace the QAM state with the state of the QAM plugin
	var state := State.new()
	state.name = qam_item.name
	var state_updater := StateUpdater.new()
	state_updater.state_machine = qam_state_machine
	state_updater.on_signal = "focus_entered"
	state_updater.state = state
	state_updater.action = StateUpdater.ACTION.REPLACE
	
	# Create a transition for the menu
	var transition_container := TransitionContainer.new()
	transition_container.name = "TransitionContainer"
	var transition := transition_fade_in.instantiate()
	transition_container.add_child(transition)
	qam_item.add_child(transition_container)
	
	# Create a visibility manager to turn visibility of the sub-menu on when
	# it changes to its state.
	var visibility_manager := VisibilityManager.new()
	visibility_manager.state_machine = qam_state_machine
	visibility_manager.state = state
	visibility_manager.visible_during = []
	qam_item.add_child(visibility_manager)
	
	plugin_button.add_child(state_updater)


func _on_notifications_pressed():
	pass # Replace with function body.


func _on_quick_settings_button_pressed():
	quick_settings_menu.focus_node.grab_focus()
	pass # Replace with function body.


func _on_performance_button_pressed():
	pass # Replace with function body.


func _on_help_button_pressed():
	pass # Replace with function body.
