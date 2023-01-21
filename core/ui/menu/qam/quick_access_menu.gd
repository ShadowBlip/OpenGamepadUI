extends Control

const qam_state_machine := preload("res://assets/state/state_machines/qam_state_machine.tres")
const OGUIButton := preload("res://core/ui/components/button.tscn")
var qam_state := preload("res://assets/state/states/quick_access_menu.tres") as State

@onready var icon_bar: VBoxContainer = $MarginContainer/HBoxContainer/IconBar
@onready var viewport: VBoxContainer = $MarginContainer/HBoxContainer/Viewport

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
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
	
	# Plugin viewport
	qam_item.visible = false
	qam.viewport.add_child(qam_item)
	
	# Plugin menu button
	var plugin_button := OGUIButton.instantiate()
	plugin_button.icon = icon
	plugin_button.custom_minimum_size = Vector2(50, 50)
	plugin_button.expand_icon = true
	plugin_button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	qam.icon_bar.add_child(plugin_button)
	
	# Replace the QAM state with the state of the QAM plugin
	var state_updater := StateUpdater.new()
	state_updater.state_machine = qam_state_machine
	state_updater.on_signal = "focus_entered"
	state_updater.state = State.new()
	state_updater.action = StateUpdater.ACTION.REPLACE
	
	# Create a visibility manager to turn visibility of the sub-menu on when
	# it changes to its state.
	var visibility_manager := VisibilityManager.new()
	visibility_manager.state_machine = qam_state_machine
	visibility_manager.state = state_updater.state
	visibility_manager.visible_during = []
	qam_item.add_child(visibility_manager)
	
	plugin_button.add_child(state_updater)
