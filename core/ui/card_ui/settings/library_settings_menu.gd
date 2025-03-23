extends ScrollContainer

var settings_manager := load("res://core/global/settings_manager.tres") as SettingsManager
var library_manager := load("res://core/global/library_manager.tres") as LibraryManager
var state_machine := load("res://assets/state/state_machines/menu_state_machine.tres") as StateMachine
var settings_state := load("res://assets/state/states/settings.tres") as State
var game_settings_state := preload("res://assets/state/states/game_settings.tres") as State
var button_scene := load("res://core/ui/components/card_button.tscn") as PackedScene

@onready var local_library_toggle := $%LocalLibraryToggle as Toggle
@onready var max_recent_slider := $%MaxRecentAppsSlider
@onready var no_hidden_label := $%NoHiddenLabel
@onready var container := $%VBoxContainer


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	settings_state.state_entered.connect(_on_state_entered)
	settings_state.state_exited.connect(_on_state_exited)

	# Configure home menu
	var max_recent := settings_manager.get_value("general.home", "max_home_items", 10) as int
	max_recent_slider.value = max_recent

	# Configure desktop library
	await get_tree().process_frame
	var enable_local_library := settings_manager.get_value("general", "enable_local_library", true) as bool
	local_library_toggle.button_pressed = enable_local_library
	local_library_toggle.toggled.connect(_on_local_library_toggled)
	_on_local_library_toggled(enable_local_library)


func _on_state_entered(_from: State) -> void:
	# Clear old buttons
	for child in container.get_children():
		if not child is CardButton:
			continue
		if child.name == "RefreshButton":
			continue
		container.remove_child(child)
		child.queue_free()

	# Find all hidden library items
	var modifiers: Array[Callable] = [
		library_manager.filter_by_hidden,
	]
	var hidden := library_manager.get_library_items(modifiers)

	# Show the label if no hidden items are found
	no_hidden_label.visible = hidden.size() == 0

	# Create a button for each hidden library item
	for item in hidden:
		var button := button_scene.instantiate() as CardButton
		button.text = item.name
		
		# Configure the button to open the game settings menu
		var on_pressed := func():
			game_settings_state.data["item"] = item
			game_settings_state.set_meta("item", item)
			state_machine.push_state(game_settings_state)
		button.pressed.connect(on_pressed)
		
		container.add_child(button)


func _on_state_exited(_to: State) -> void:
	pass


func _on_local_library_toggled(enabled: bool) -> void:
	if enabled:
		_enable_local_library()
		return
	_disable_local_library()


func _enable_local_library() -> void:
	var library := library_manager.get_library_by_id("desktop")
	if library:
		return
	library = load("res://core/systems/library/library_desktop.tscn").instantiate()

	var main := get_tree().get_first_node_in_group("main")
	if not main:
		return
	main.add_child(library)


func _disable_local_library() -> void:
	var library := library_manager.get_library_by_id("desktop")
	if not library:
		return
	library_manager.unregister_library(library)
	library.queue_free()
