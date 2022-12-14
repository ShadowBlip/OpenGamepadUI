extends Control

@onready var state_mgr: StateManager = get_node("/root/Main/StateManager")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	visible = false
	state_mgr.state_changed.connect(_on_state_changed)
	

func _on_state_changed(from: int, to: int, _data: Dictionary) -> void:
	visible = to == StateManager.State.MAIN_MENU or to == StateManager.State.IN_GAME_MENU
	
	# Set the home button focus
	if to == StateManager.State.MAIN_MENU:
		var button: Button = $MarginContainer/VBoxContainer/HomeButton
		button.grab_focus.call_deferred()


func _on_power_button_pressed() -> void:
	get_tree().quit()

