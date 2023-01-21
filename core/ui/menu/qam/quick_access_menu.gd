extends Control

const OGUIButton := preload("res://core/ui/components/button.tscn")
const ButtonStateChanger := preload("res://core/systems/state/state_changer.tscn")
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
	var state_changer := ButtonStateChanger.instantiate()
	
	# Button state management
	state_changer.signal_name = "focus_entered"
	var state = qam.icon_bar.get_child_count()
	state_changer.state = state
	state_changer.action = state_changer.Action.REPLACE
	var _state_manager : StateManager = qam.get_node("StateManager")
	state_changer.state_manager_path = _state_manager.get_path()
	
	# Signal hook
	var _on_state_change := func(from: int, to: int, data: Dictionary):
		if to == state:
			qam_item.visible= true
			return
		qam_item.visible= false
	_state_manager.state_changed.connect(_on_state_change)

	plugin_button.add_child(state_changer)
