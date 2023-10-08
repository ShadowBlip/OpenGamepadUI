extends Control

var state_machine := (
	preload("res://assets/state/state_machines/global_state_machine.tres") as StateMachine
)
const overlay_modestate_machine := preload("res://assets/state/state_machines/overlay_mode_state_machine.tres")
const OGUIButton := preload("res://core/ui/components/button.tscn")
const transition_fade_in := preload("res://core/ui/components/transition_fade_in.tscn")

var quick_bar_state := preload("res://assets/state/states/quick_bar_menu.tres") as State

@onready var icon_bar: VBoxContainer = $%IconBar
@onready var viewport: VBoxContainer = $%Viewport
@onready var focus_manager := $%FocusManager as FocusManager


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	quick_bar_state.state_entered.connect(_on_state_entered)


func _on_state_entered(_from: State) -> void:
	if focus_manager and focus_manager.current_focus:
		focus_manager.current_focus.grab_focus.call_deferred()


# Adds the given Control menu to the Quick Bar. A focus node can be given which will
# be the first node to focus
func add_child_menu(qb_item: Control, icon: Texture2D, focus_node: Control = null):
	var qb := self

	# Plugin viewport
	qb_item.visible = false
	qb.viewport.add_child(qb_item)

	## Plugin menu button
	var plugin_button := OGUIButton.instantiate()
	plugin_button.icon = icon
	plugin_button.custom_minimum_size = Vector2(50, 50)
	plugin_button.expand_icon = true
	plugin_button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER

	# Set up new button's focus
	plugin_button.focus_mode = Control.FOCUS_ALL

	# Try to wire up the node to focus when you press the menu button
	var focus_setter := FocusSetter.new()
	focus_setter.target = qb_item
	focus_setter.on_signal = "pressed"
	plugin_button.add_child(focus_setter)

	# Add the plugin button to the quick bar icon bar
	qb.icon_bar.add_child(plugin_button)

	# Replace the quick bar menu state with the state of the plugin
	var state := State.new()
	state.name = qb_item.name
	var state_updater := StateUpdater.new()
	state_updater.state_machine = overlay_modestate_machine
	state_updater.on_signal = "focus_entered"
	state_updater.state = state
	state_updater.action = StateUpdater.ACTION.PUSH

	# Create a transition for the menu
	var transition_container := TransitionContainer.new()
	transition_container.name = "TransitionContainer"
	var transition := transition_fade_in.instantiate()
	transition_container.add_child(transition)
	qb_item.add_child(transition_container)

	# Create a visibility manager to turn visibility of the sub-menu on when
	# it changes to its state.
	var visibility_manager := VisibilityManager.new()
	visibility_manager.state_machine = overlay_modestate_machine
	visibility_manager.state = state
	visibility_manager.visible_during = []
	qb_item.add_child(visibility_manager)
	plugin_button.add_child(state_updater)
