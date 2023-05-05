extends Control

var game_settings_state := preload("res://assets/state/states/game_settings.tres") as State
var library_item: LibraryItem

@onready var game_name_label := $%GameNameLabel as Label
@onready var menu_container := $%SideMenuContainer as Control


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	game_settings_state.state_entered.connect(_on_state_entered)


func _on_state_entered(_from: State) -> void:
	if "item" in game_settings_state.data:
		library_item = game_settings_state.data["item"] as LibraryItem

	# Set the selected game's name
	if library_item:
		game_name_label.text = library_item.name
	else:
		game_name_label.text = ""

	# Grab the first button from the menu container
	for child in menu_container.get_children():
		if not child is Button:
			continue
		child.grab_focus.call_deferred()
		break
