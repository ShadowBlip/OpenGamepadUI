extends Control

var state_machine := (
	preload("res://assets/state/state_machines/global_state_machine.tres") as StateMachine
)
const qam_state_machine := preload("res://assets/state/state_machines/qam_state_machine.tres")
const OGUIButton := preload("res://core/ui/components/button.tscn")
const transition_fade_in := preload("res://core/ui/components/transition_fade_in.tscn")

var qam_state := preload("res://assets/state/states/quick_access_menu.tres") as State

@onready var icon_bar: VBoxContainer = $MarginContainer/HBoxContainer/IconBar
@onready var viewport: VBoxContainer = $MarginContainer/HBoxContainer/Viewport
@onready
var notifications_menu: HFlowContainer = $MarginContainer/HBoxContainer/Viewport/NotificationsMenu
@onready var power_tools_menu: Control = $MarginContainer/HBoxContainer/Viewport/PowerToolsMenu
@onready var quick_settings_menu: Control = $MarginContainer/HBoxContainer/Viewport/QuickSettingsMenu
@onready var performance_menu: Control = $MarginContainer/HBoxContainer/Viewport/PerformanceMenu
@onready var last_icon: Control = icon_bar.get_child(0)


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	visible = false
	qam_state.state_entered.connect(_on_state_entered)
	qam_state.state_exited.connect(_on_state_exited)

	for child in icon_bar.get_children():
		if not child is Control:
			continue
		child.focus_entered.connect(_on_icon_focused.bind(child))
		child.gui_input.connect(_on_icon_gui_input)


func _on_state_entered(_from: State) -> void:
	last_icon.grab_focus()
	visible = true
	set_process_input(true)


func _on_state_exited(_to: State) -> void:
	visible = false
	set_process_input(false)


func _on_icon_focused(child: Control) -> void:
	last_icon = child


# gui_input gets processed only when it is focused, and after _input. This will
# only be called when an icon is focused and the back button was pressed
func _on_icon_gui_input(event: InputEvent) -> void:
	if not event.is_action_pressed("ogui_east"):
		return
	state_machine.pop_state()


# Input always gets processed before gui_input
func _input(event: InputEvent) -> void:
	if not visible:
		return
	if not event.is_action_pressed("ogui_east"):
		return
	last_icon.grab_focus.call_deferred()


# Adds the given Control menu to the QAM. A focus node can be given which will
# be the first node to focus
func add_child_menu(qam_item: Control, icon: Texture2D, focus_node: Control = null):
	var qam := self

	var first_qam_item: Control
	var last_qam_item: Control

	# Plugin viewport
	qam_item.visible = false
	qam.viewport.add_child(qam_item)

	# Get existing children so we can manage focus
	var qam_children := qam.icon_bar.get_child_count()
	if qam_children > 0:
		first_qam_item = qam.icon_bar.get_child(0)
		last_qam_item = qam.icon_bar.get_child(qam_children - 1)

	## Plugin menu button
	var plugin_button := OGUIButton.instantiate()
	plugin_button.icon = icon
	plugin_button.custom_minimum_size = Vector2(50, 50)
	plugin_button.expand_icon = true
	plugin_button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	plugin_button.focus_entered.connect(_on_icon_focused.bind(plugin_button))
	plugin_button.gui_input.connect(_on_icon_gui_input)
	qam.icon_bar.add_child(plugin_button)

	# Try to wire up the node to focus when you press the menu button
	if focus_node != null:
		plugin_button.pressed.connect(focus_node.grab_focus)
	else:
		for child in qam_item.get_children():
			if not child is Control:
				continue
			plugin_button.pressed.connect(child.grab_focus)
			break

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
	pass  # Replace with function body.


func _on_quick_settings_button_pressed():
	quick_settings_menu.focus_node.grab_focus.call_deferred()


func _on_performance_button_pressed():
	performance_menu.focus_node.grab_focus.call_deferred()


func _on_help_button_pressed():
	pass  # Replace with function body.


func _on_power_tools_button_pressed():
	power_tools_menu.focus_node.grab_focus.call_deferred()
