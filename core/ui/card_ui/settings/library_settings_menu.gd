extends ScrollContainer

var settings_manager := load("res://core/global/settings_manager.tres") as SettingsManager
var library_manager := load("res://core/global/library_manager.tres") as LibraryManager
var state_machine := load("res://assets/state/state_machines/global_state_machine.tres") as StateMachine
var settings_state := load("res://assets/state/states/settings.tres") as State
var game_settings_state := preload("res://assets/state/states/game_settings.tres") as State
var button_scene := load("res://core/ui/components/card_button.tscn") as PackedScene

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


func _on_state_entered(_from: State) -> void:
	# Clear old buttons
	for child in container.get_children():
		if not child is CardButton:
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
