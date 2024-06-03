extends ScrollContainer

var settings_manager := load("res://core/global/settings_manager.tres") as SettingsManager
var library_manager := load("res://core/global/library_manager.tres") as LibraryManager
var library_state := load("res://assets/state/states/game_settings_library.tres") as State
var game_settings_state := load("res://assets/state/states/game_settings.tres") as State
var library_item: LibraryItem
var logger := Log.get_logger("GameSettingsLibrary")

@onready var hide_toggle := $%HideToggle as Toggle


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	library_state.state_entered.connect(_on_state_entered)
	library_state.state_exited.connect(_on_state_exited)
	
	# When the hide button is toggled, update the settings for this library item
	var on_hide_toggled := func(is_hidden: bool):
		if not library_item:
			return
		settings_manager.set_library_value(library_item, "hidden", is_hidden)
		library_item.is_hidden = is_hidden
		if is_hidden:
			library_manager.library_item_hidden.emit(library_item)
		else:
			library_manager.library_item_unhidden.emit(library_item)
	hide_toggle.toggled.connect(on_hide_toggled)


func _on_state_entered(_from: State) -> void:
	# Get the current library item
	if game_settings_state.has_meta("item"):
		library_item = game_settings_state.get_meta("item") as LibraryItem
	elif "item" in game_settings_state.data:
		library_item = game_settings_state.data["item"] as LibraryItem

	if not library_item:
		logger.warn("No library item set in game settings state to configure")
		return

	# Find the settings
	var is_hidden := settings_manager.get_library_value(library_item, "hidden", false) as bool
	hide_toggle.button_pressed = is_hidden


func _on_state_exited(_to: State) -> void:
	library_item = null
