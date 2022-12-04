extends Control

@onready var state_mgr: StateManager = get_node("/root/Main/StateManager")
@onready var icon_bar: VBoxContainer = $MarginContainer/HBoxContainer/IconBar
@onready var viewport: VBoxContainer = $MarginContainer/HBoxContainer/Viewport

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	visible = false
	state_mgr.state_changed.connect(_on_state_changed)
	

func _on_state_changed(from: int, to: int, _data: Dictionary) -> void:
	visible = to == StateManager.State.QUICK_ACCESS_MENU

	# Don't do anything if its not our time.
	if not visible:
		return

	
	var button: Button = icon_bar.get_child(0)
	button.grab_focus()
