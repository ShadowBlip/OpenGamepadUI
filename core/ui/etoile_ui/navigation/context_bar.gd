extends MarginContainer

var launch_manager := preload("res://core/global/launch_manager.tres") as LaunchManager
var state_machine := preload("res://assets/state/state_machines/menu_state_machine.tres") as StateMachine
var game_details_state := preload("res://assets/state/states/game_launcher.tres") as State

@onready var accept := %AcceptIcon as InputIcon
@onready var details := %DetailsIcon as InputIcon
@onready var back := %BackIcon as InputIcon
@onready var options := %OptionsIcon as InputIcon


func _ready() -> void:
	get_viewport().gui_focus_changed.connect(_on_focus_changed)


func _on_focus_changed(node: Control) -> void:
	if node is GameTile:
		_on_game_tile_focused(node as GameTile)
		return
	if node is CardButton:
		pass


func _on_game_tile_focused(tile: GameTile) -> void:
	if tile.is_library_tile:
		return
	var library_item := tile.library_item
	if not library_item:
		accept.text = tr("Play Now")
		details.text = tr("Details")
		back.visible = state_machine.current_state() in [game_details_state]
		options.visible = state_machine.current_state() in []
		return

	if launch_manager.is_running(library_item.name):
		accept.text = tr("Resume")
